# Forest 替代品 MVP 规格（工作名：Grove）

状态：验证通过后的开工稿 · 2026-11-24  
正式品牌名待定（避免 Forest / Flora 商标冲突）。下文暂用 **Grove**。

---

## 1. 产品一句话

打开即种，看着树长大；离开就枯萎。本地、无账号、无 AI、无订阅。核心免费，一次买断解锁全部树种与完整统计。

目标用户：学生 / 考研考证 / 反感订阅的 Forest 老用户（美区优先，英中双语后期）。

成功指标（内测 2 周）：

- 冷启动到开始专注 ≤ 2 秒（默认时长一键开种）
- ≥40% 安装用户完成 ≥3 次成功会话
- ≥10% 免费用户进入买断页且无「诱导试用」投诉话术

---

## 2. 差异化（应对审核 4.3）

| 做 | 不做 |
|---|---|
| 自有树种美术与成长阶段动画 | 不复刻 Forest 树种/图标/文案/布局 |
| 极简单屏：时长环 + 种树 + 大按钮 | 不做 AI 助手、挑战、公会、排行榜 |
| 买断制（建议 $14.99，可调 $12.99–$19.99） | 不做周/月订阅、不做强制试用倒计时 |
| 离线 + 无账号 | 不做云同步（P2）、不做账号墙 |
| 「离开 App → 树枯萎」核心循环 | MVP 不做 Screen Time 系统级屏蔽（P1） |

---

## 3. 信息架构（3 个主页）

1. **今日 / 种树台（默认）**  
   选时长（预设 15/25/45/60 + 自定义）→ 选树种（免费 3 种 / 付费全开）→ Start  
   进行中：倒计时 + 成长动画；切到后台或离开 App → 标记失败并枯萎（可配置宽限 3–5 秒防误触）
2. **我的林子**  
   日历/时间线看成功树；失败枯树半透明；按 Tag 筛选
3. **统计**  
   今日/本周专注分钟、成功率、Tag 饼图（付费解锁完整历史；免费保留近 7 天）

设置（齿轮）：白噪音开关（MVP 可 1–2 个本地音频）、宽限秒数、通知、恢复购买、关于。

---

## 4. MVP 功能清单（P0 / P1）

### P0（3–4 周内必须）

| ID | 需求 | 验收 |
|---|---|---|
| F01 | 无账号首次打开即到种树台 | 无登录墙、无强制 onboarding 超过 1 屏 |
| F02 | 一键开始默认 25 分钟会话 | 从打开到计时开始 ≤2s（热启动） |
| F03 | 倒计时在前台/锁屏 Live Activity 或本地通知结束提醒 | 结束后可再开一轮，无多余弹层超过 1 次确认 |
| F04 | 离开 App 超过宽限 → 会话失败、树枯萎 | 杀进程/切走可复现；宽限可关 |
| F05 | 成功会话写入本地 DB，林子可见 | 重启不丢 |
| F06 | Tag：Study / Work / Reading / Other + 自定义（免费上限 4） | 会话可绑 Tag；统计可筛 |
| F07 | 免费 3 树种；Lifetime解锁其余 + 完整统计 + 自定义白噪音位 | StoreKit 2；恢复购买可用 |
| F08 | 英文本地化字符串表（中文 P1） | 无硬编码面向用户的中文混排 |
| F09 | 隐私：无追踪、无第三方分析（首发） | Privacy Nutrition 标 Data Not Collected（若真无） |

### P1（上架后 2–4 周）

- Screen Time / FamilyControls 可选 Deep Focus  
- 小组件今日分钟数  
- 中文  
- 导出 CSV  
- 更多树种包（仍买断，不做订阅树种战令）

### 明确 OUT

社交种树、真实种树公益积分、AI、账号体系、Android 首发、Apple Watch（P2）。

---

## 5. 数据模型（本地）

```
Tag { id, name, color, isPreset }
TreeSpecies { id, name, isFree, assetKey }
Session {
  id, startedAt, durationSec, endedAt?,
  status: running|succeeded|failed|cancelled,
  speciesId, tagId?,
  leftAppAt?, wilted: Bool
}
Entitlement { lifetimeUnlocked: Bool, productId, transactionId? }
Settings { graceSec, defaultDurationSec, soundOn, ... }
```

存储：SwiftData 或 SQLite（推荐 SwiftData）；资产在 Application Support；无 Keychain 账号。

---

## 6. 技术选型

- iOS 17+（Live Activity 可选 iOS 16.1+；为减复杂度可先 iOS 17）
- SwiftUI + Observation
- StoreKit 2
- 后台：`scenePhase` + 宽限计时；结束用 `UNUserNotificationCenter`
- 无后端

本机现状：仅 Command Line Tools，**需安装完整 Xcode** 才能编译真机/模拟器。源码骨架放在 `ios/Grove/`。

---

## 7. ASO / 上架文案骨架

- 副标题方向：`Pomodoro · Buy Once` / `Simple Focus Timer`
- 关键词簇：pomodoro, study, session, timer, concentration, interval, offline
- 描述首段：强调「tired of subscriptions and cluttered focus apps」+ 2 秒开种 + lifetime
- 截图文案：1) Start in 2 seconds 2) Your grove grows with you 3) Leave and it wilts 4) Buy once. Yours forever.

---

## 8. 两周执行顺序

| 日 | 产出 |
|---|---|
| D0 | 装 Xcode + 开发者账号确认；定暂用名 Grove |
| D1–2 | 工程骨架、Session 状态机、本地持久化 |
| D3–5 | 种树台 UI + 成长/枯萎视觉 MVP |
| D6–7 | 林子 + 基础统计 + Tag |
| D8–9 | StoreKit 买断 + 权益门闸 |
| D10–11 | 通知/中断/宽限打磨 + TestFlight |
| D12–14 | 文案/截图、隐私标签、内测 5–10 人 |

---

## 9. 开放决策（默认值，可改）

| ID | 默认 | 说明 |
|---|---|---|
| D1 名称 | Grove（可换） | 正式上架前做商标快查 |
| D2 买断价 | $14.99 | 低于 Cat on Chair $29.99，高于 Focus To-Do 纯工具感 |
| D3 离开即枯 | 开，宽限 5s | 对齐 Forest 核心情绪，不做系统屏蔽也能验证 |
| D4 免费树种数 | 3 | 够用但让买断有感知 |
| D5 平台 | 美区 iPhone 先 | 中文/国区随后 |
