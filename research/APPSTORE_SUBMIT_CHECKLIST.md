# Grove · App Store 提审 Checklist

> 更新：2026-11-26  
> 目标：可提审的 1.0.0（当前判定：功能可内测，提审仍部分 NO-GO）

## P0 · 阻塞上架

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 1 | 计时页 / 完成卡树不被挡住 | **完成** | 树冠留顶边距；计时移到树下方；完成卡去掉易溢出的 scale |
| 2 | 最小 Settings 页 | **完成** | 宽限秒数、Unlock/Restore、隐私链接、版本号；Plant 齿轮入口 |
| 3 | 去掉 Paywall 模拟器调试文案 | **完成** | 加载中 / 失败态生产文案 |
| 4 | App Icon（含 1024） | **完成** | `AppIcon.appiconset/AppIcon.png`（可再人工精修） |
| 5 | 版本号改为 1.0.0 | **完成** | `project.yml` MARKETING_VERSION |
| 6 | 隐私政策（App 内全文 + 公网页） | **App 内完成；Gitee 待开 Pages** | 仓库 `docs/privacy.html`；远端 `git@gitee.com:yongye507/grove.git`；预期 URL：`https://yongye507.gitee.io/grove/privacy.html` |
| 7 | Privacy Nutrition Labels / PrivacyInfo | **部分完成** | 工程已加 `PrivacyInfo.xcprivacy`（无收集）；Connect 标签仍需你勾选 |
| 8 | DEVELOPMENT_TEAM + Archive | 待办 | 真机签名（需你的 Apple Team） |
| 9 | ASC 创建 Non-Consumable IAP | 待办 | `com.grove.focus.lifetime` |
| 10 | TestFlight 真机冒烟 | 待办 | 枯萎 / 通知 / 购买 / 恢复 |
| 11 | 商店截图 + 元数据定稿 | 待办 | 标题/副标题/描述/关键词 |

## P1 · 首发体验

| # | 项 | 状态 |
|---|----|------|
| 12 | 拨盘时长写回 `defaultDurationSec` | **完成** |
| 13 | 通知被拒后的引导入口 | 待办（可放 Settings） |
| 14 | QA preview 仅 DEBUG | **完成** |

## P2 · 可放 1.1+

- 自定义 Tag / 筛选 / Tag 统计
- 白噪音
- 中文
- Live Activity
- SwiftData 版本化迁移

## 完成定义（可点 Submit）

- [ ] P0 全绿（含真实隐私 URL、Team、ASC IAP、TestFlight、截图）
- [ ] TestFlight：种成、枯萎、通知、购买、恢复各至少 1 次成功
- [ ] Connect：隐私标签、IAP、截图与 1.0.0 元数据齐

## 下一步（需你侧信息 / 账号）

1. 提供可公网访问的 **隐私政策 URL** → 替换 `SettingsView.privacyPolicyURL`
2. 填入 **DEVELOPMENT_TEAM**，Archive → TestFlight
3. App Store Connect 创建 App + Lifetime IAP
4. 准备 6.7"/6.5" 商店截图与 ASO 文案
