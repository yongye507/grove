import Foundation
import Observation
import UIKit

enum SessionOutcomeKind: Equatable {
    case grown
    case wilted
}

/// Snapshot for the post-session outcome card (keeps UI free of live SwiftData churn).
struct SessionOutcome: Identifiable, Equatable {
    let id: UUID
    let speciesId: String
    let durationSec: Int
    let kind: SessionOutcomeKind
}

/// Owns the in-progress focus loop: countdown, grace after leaving app, succeed/fail.
///
/// Wilt grace starts only when the app enters *background* (not mere `inactive` /
/// Control Center / notification shade). That matches Forest-style rules and avoids
/// false wilts while the user is still “in” the session.
@Observable
@MainActor
final class SessionEngine {
    private(set) var active: FocusSession?
    private(set) var secondsLeft: Int = 0
    private(set) var isInGrace: Bool = false
    private(set) var graceSecondsLeft: Int = 0
    /// Set when a session ends in grown/wilted; PlantingView shows the outcome card.
    private(set) var pendingOutcome: SessionOutcome?

    /// Latest grace setting; updated by the UI so lifecycle observers stay accurate.
    var graceSec: Int = 5

    private var tickTask: Task<Void, Never>?
    private var graceTask: Task<Void, Never>?
    private var onTerminal: ((FocusSession) -> Void)?
    private var lifecycleObservers: [NSObjectProtocol] = []
    #if DEBUG
    private var didRunPreview = false
    #endif

    func bind(onTerminal: @escaping (FocusSession) -> Void) {
        self.onTerminal = onTerminal
        startLifecycleObservers()
    }

    func dismissOutcome() {
        pendingOutcome = nil
    }

    #if DEBUG
    /// QA helper — set `SIMCTL_CHILD_GROVE_PREVIEW_OUTCOME=grown|wilted` once per process.
    func previewOutcomeIfRequested() {
        guard !didRunPreview else { return }
        didRunPreview = true
        guard pendingOutcome == nil, active == nil else { return }
        let flag = ProcessInfo.processInfo.environment["GROVE_PREVIEW_OUTCOME"]
            ?? ProcessInfo.processInfo.environment["GROVE_PREVIEW_CELEBRATION"]
        switch flag {
        case "1", "grown":
            pendingOutcome = SessionOutcome(id: UUID(), speciesId: "oak", durationSec: 25 * 60, kind: .grown)
        case "wilted":
            pendingOutcome = SessionOutcome(id: UUID(), speciesId: "oak", durationSec: 25 * 60, kind: .wilted)
        default:
            break
        }
    }
    #endif

    func start(session: FocusSession, graceSec: Int) {
        self.graceSec = graceSec
        cancelTimers()
        pendingOutcome = nil
        active = session
        isInGrace = false
        graceSecondsLeft = graceSec
        secondsLeft = Int(session.remaining().rounded(.up))
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let session = self.active, session.status == .running else { return }
                let left = Int(session.remaining().rounded(.up))
                self.secondsLeft = left
                if left <= 0 {
                    self.succeed()
                    return
                }
            }
        }
    }

    /// - Parameter active: `true` when the app is usable again (active).
    /// - Parameter inBackground: `true` only for real background (home / app switcher),
    ///   not transient inactive (Control Center, banner, etc.).
    func handleScenePhase(active isActive: Bool, inBackground: Bool = false, graceSec: Int? = nil) {
        if let graceSec { self.graceSec = graceSec }
        guard let session = active, session.status == .running else { return }

        if isActive {
            // Reconcile: if we were away longer than grace, wilt on return.
            if let leftAt = session.leftAppAt {
                let elapsed = Date().timeIntervalSince(leftAt)
                if elapsed >= Double(self.graceSec) {
                    failForLeaving()
                    return
                }
            }
            cancelGrace()
            isInGrace = false
            session.leftAppAt = nil
            return
        }

        // Only real background starts wilt grace — ignore inactive-only transitions.
        guard inBackground else { return }
        beginGrace(seconds: self.graceSec)
    }

    func cancelActive() {
        guard let session = active, session.status == .running else { return }
        session.status = .cancelled
        session.endedAt = .now
        finish(session)
    }

    func stopLifecycleObservers() {
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        lifecycleObservers.removeAll()
    }

    private func startLifecycleObservers() {
        guard lifecycleObservers.isEmpty else { return }
        let center = NotificationCenter.default
        lifecycleObservers = [
            center.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleScenePhase(active: false, inBackground: true)
                }
            },
            center.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleScenePhase(active: true, inBackground: false)
                }
            }
        ]
    }

    private func beginGrace(seconds: Int) {
        // Already timing a leave — keep the original leftAppAt.
        if isInGrace, active?.leftAppAt != nil { return }

        cancelGrace()
        guard let session = active, session.status == .running else { return }
        if session.leftAppAt == nil {
            session.leftAppAt = .now
        }
        isInGrace = true
        graceSecondsLeft = seconds
        graceTask = Task { [weak self] in
            var left = seconds
            while left > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                left -= 1
                await MainActor.run { self?.graceSecondsLeft = left }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.failForLeaving() }
        }
    }

    private func failForLeaving() {
        guard let session = active, session.status == .running else { return }
        // Never overwrite a grown celebration with a wilt card.
        if pendingOutcome?.kind == .grown { return }
        session.status = .failed
        session.wilted = true
        session.endedAt = .now
        pendingOutcome = SessionOutcome(
            id: session.id,
            speciesId: session.speciesId,
            durationSec: session.durationSec,
            kind: .wilted
        )
        finish(session)
    }

    private func succeed() {
        guard let session = active, session.status == .running else { return }
        session.status = .succeeded
        session.endedAt = .now
        session.wilted = false
        pendingOutcome = SessionOutcome(
            id: session.id,
            speciesId: session.speciesId,
            durationSec: session.durationSec,
            kind: .grown
        )
        finish(session)
    }

    private func finish(_ session: FocusSession) {
        cancelTimers()
        isInGrace = false
        onTerminal?(session)
        active = nil
        secondsLeft = 0
    }

    private func cancelGrace() {
        graceTask?.cancel()
        graceTask = nil
    }

    private func cancelTimers() {
        tickTask?.cancel()
        tickTask = nil
        cancelGrace()
    }
}
