# Grove Timer · Cursor 对话交接

> 生成：2026-11-26  
> 用途：把本机 Cursor 聊过的进度交给另一台 Cursor / 另一位开发者。  
> 代码已推：`0e923c7`（GitHub `origin` + Gitee `gitee`）

---

## 1. 项目是什么

- **产品**：Forest 类专注 App——种树计时；完成则长成，离开太久则枯萎。
- **技术**：SwiftUI + SwiftData + StoreKit 2 + Charts，iOS 17+，仅竖屏 iPhone。
- **工程路径**：`ios/Grove.xcodeproj`（XcodeGen：`ios/project.yml`）
- **Bundle ID**：`com.grove.focus`
- **Team**：`FH4DFRTFXF`
- **版本**：`1.0.0` (build 1)
- **商店名**：App Store Connect 上叫 **Grove Timer**（「Grove」被占用）
- **桌面显示名**：仍为 **Grove**（`CFBundleDisplayName`）
- **SKU**：`grove-focus-001`
- **ASC App ID**（参考）：`6839518741`

---

## 2. 当前进度（已完成）

### 产品 / 工程
- 连续拨盘 1–90 分钟；离开 App（进后台）才进枯萎宽限；Control Center 不触发。
- Week Grove 畦床、Stats（周/月/年 + 树种）、Paywall 终身买断。
- Settings：宽限秒数、Unlock/Restore、隐私、版本号。
- App Icon、PrivacyInfo.xcprivacy（声明不收集）。
- **多语言**：`Localizable.xcstrings` + `InfoPlist.xcstrings`（`en` + `zh-Hans`），跟随系统语言；品牌名 Grove 不译。
- **上传方向校验修复**：`INFOPLIST_KEY_UIRequiresFullScreen = YES`（竖屏、退出 iPad 多任务要求）。

### App Store Connect（用户已在网页完成）
- 已创建 App：**Grove Timer**，主语言 English (U.S.)。
- IAP 非消耗型：`com.grove.focus.lifetime`  
  - 显示名：`Lifetime Unlock`  
  - 描述：一次性买断文案（英文已填）
- 隐私政策 URL：`https://yongye507.github.io/grove/privacy.html`
- App 隐私标签：已勾「不收集」。

### Git
- 远程：`origin` → `git@github.com:yongye507/grove.git`  
- 备用：`gitee` → `git@gitee.com:yongye507/grove.git`  
- 交接提交：`0e923c7` — *Add en/zh-Hans String Catalog and fix App Store orientation validation.*

---

## 3. 阻塞与下一步（按优先级）

### 必须先做
1. **用 Xcode 26+（iOS 26 SDK）Archive 再上传**  
   - 旧 Xcode（iOS 18.5 SDK）会被 Connect 拒：*must be built with the iOS 26 SDK*。  
   - 另一台电脑拉代码后务必确认 Xcode 版本 ≥ 26。
2. **TestFlight 真机冒烟**  
   - 种成 / 离开枯萎 / 通知 / Lifetime 购买 / 恢复购买。
3. **商店截图 + 元数据**（标题 Grove Timer）→ 提审前把 IAP **关联到该版本** → Submit。

### 可选 / 可后做
- Settings 里「通知被拒」引导去系统设置。
- ASC 商店本地化（简中截图/描述）。
- String Catalog 再加 `ja` / `zh-Hant` 等。

详细勾选表见：`research/APPSTORE_SUBMIT_CHECKLIST.md`

---

## 4. 关键约定（别踩坑）

| 主题 | 约定 |
|------|------|
| 国际化 | 用 **String Catalog（.xcstrings）**，**不要**用 locale.mdc |
| 后台新表/接口 | 若有后端：model → repository → entity → service → handler → router → permission；SQL/permission 追加 `wbw.sql`；Echo v4 |
| 回复语言 | 对用户用中文；改代码落地，不只给建议 |
| Commit | 用户明确要求才 commit；本交接前最近一次已按要求提交并 push |
| 隐私页托管 | Gitee Pages 已不可用 → 现用 **GitHub Pages** |

---

## 5. 关键路径速查

```
ios/project.yml                          # 版本、Team、方向、knownRegions
ios/Grove/Resources/Localizable.xcstrings
ios/Grove/Resources/InfoPlist.xcstrings
ios/Grove/Resources/PrivacyInfo.xcprivacy
ios/Grove/Resources/Products.storekit    # IAP id: com.grove.focus.lifetime
ios/Grove/Services/StoreService.swift
ios/Grove/Views/PlantingView.swift       # 种植/计时主页
ios/Grove/Views/GroveView.swift          # 我的 Grove
ios/Grove/Views/StatsView.swift
docs/privacy.html                        # 与公网页同源内容
research/APPSTORE_SUBMIT_CHECKLIST.md
```

公网隐私页：https://yongye507.github.io/grove/privacy.html

---

## 6. 给另一台 Cursor 的开场提示（可直接粘贴）

```
请阅读 research/CURSOR_HANDOFF.md 和 research/APPSTORE_SUBMIT_CHECKLIST.md。

当前任务：在 Xcode 26+ 上对 ios/Grove.xcodeproj 做 Archive 并上传 App Store Connect（Grove Timer，com.grove.focus）。
已完成：ASC 建 App、IAP com.grove.focus.lifetime、隐私 URL、隐私标签、英/简中 String Catalog、UIRequiresFullScreen。
勿改商店名为 Grove（已被占用，现为 Grove Timer）。
国际化继续用 xcstrings，不要用 locale.mdc。
```

---

## 7. 对话里做过、但未自动化完成的事

- 曾尝试用 Computer Use 在 Safari 填 ASC「新建 App」，因窗口遮挡/坐标不稳，**改由用户手动创建**（成功，名为 Grove Timer）。
- GitHub SSH 曾超时；后已成功 push 到 GitHub 与 Gitee。

---

## 8. 本地聊天能否跨 Cursor 同步？

不能自动同步。可行做法：
1. 把本文件 + checklist 随仓库带走（本方案）。
2. 或使用 Cursor **Move to Cloud / Cloud Agents** 续同一云端对话。
