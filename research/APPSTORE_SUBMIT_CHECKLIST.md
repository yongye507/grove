# Grove Timer · App Store 提审 Checklist

> 更新：2026-11-26  
> 目标：可提审的 1.0.0（当前判定：功能可内测，提审仍部分 NO-GO）  
> ASC 应用名：**Grove Timer** · Bundle ID：`com.grove.focus` · SKU：`grove-focus-001`  
> 桌面显示名仍为 **Grove**（`CFBundleDisplayName`，可与商店名不同）

## P0 · 阻塞上架

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | 计时页 / 完成卡树不被挡住 | **完成** | 树冠留顶边距；计时移到树下方；完成卡去掉易溢出的 scale |
| 2 | 最小 Settings 页 | **完成** | 宽限秒数、Unlock/Restore、隐私链接、版本号；Plant 齿轮入口 |
| 3 | 去掉 Paywall 模拟器调试文案 | **完成** | 加载中 / 失败态生产文案 |
| 4 | App Icon（含 1024） | **完成** | `AppIcon.appiconset/AppIcon.png`（可再人工精修） |
| 5 | 版本号改为 1.0.0 | **完成** | `project.yml` MARKETING_VERSION |
| 6 | 隐私政策（App 内全文 + 公网页 + ASC URL） | **完成** | App 内 Settings 可看；公网与 Connect 已填：`https://yongye507.github.io/grove/privacy.html` |
| 7 | Privacy Nutrition Labels / PrivacyInfo | **完成** | 工程 `PrivacyInfo.xcprivacy` + Connect 已勾不收集 |
| 8 | DEVELOPMENT_TEAM + 证书 | **工程已配置** | Team `FH4DFRTFXF`。上传须用 **Xcode 26+（iOS 26 SDK）** Archive；另已加 `UIRequiresFullScreen` 修方向校验 |
| 8b | ASC 新建 App | **完成** | 商店名 **Grove Timer**；主要语言 English (U.S.) |
| 9 | ASC 创建 Non-Consumable IAP | **完成** | `com.grove.focus.lifetime`（Lifetime Unlock）；提审前记得关联到 App 版本 |
| 10 | TestFlight 真机冒烟 | 待办 | 枯萎 / 通知 / 购买 / 恢复 |
| 11 | 商店截图 + 元数据定稿 | 待办 | 标题用 Grove Timer；副标题/描述/关键词 |

## P1 · 首发体验

| # | 项 | 状态 |
|---|----|------|
| 12 | 拨盘时长写回 `defaultDurationSec` | **完成** |
| 13 | 通知被拒后的引导入口 | 待办（可放 Settings） |
| 14 | QA preview 仅 DEBUG | **完成** |

## P1b · 多语言（工程）

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 15 | String Catalog 英 / 简中 | **完成** | `Localizable.xcstrings` + `InfoPlist.xcstrings`；跟随系统语言 |
| 16 | ASC 商店本地化 | 待办 | Connect 里为简中等地区加截图/描述（可后做） |

## P2 · 可放 1.1+

- 自定义 Tag / 筛选 / Tag 统计
- 白噪音
- 更多语言（日/繁中/韩等，在 String Catalog 加列即可）
- Live Activity
- SwiftData 版本化迁移

## 完成定义（可点 Submit）

- [ ] P0 全绿（含真实隐私 URL、Team、ASC IAP、TestFlight、截图）
- [ ] TestFlight：种成、枯萎、通知、购买、恢复各至少 1 次成功
- [ ] Connect：隐私标签、IAP、截图与 1.0.0 元数据齐

## 下一步（按顺序）

1. ~~隐私政策 URL~~ **已完成**；Connect 里再勾 **Privacy Labels**（不收集）
2. ~~创建 IAP~~ **已完成**：`com.grove.focus.lifetime`
3. Xcode：**Product → Archive → Distribute App → App Store Connect**
4. TestFlight 真机冒烟：种成 / 枯萎 / 通知 / 购买 / 恢复（含 Lifetime 购买/恢复）
5. 商店截图 + 元数据（标题 **Grove Timer**）→ Submit（提审前把 IAP 关联到该版本）
