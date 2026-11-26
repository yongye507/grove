# Forest 替代品 · 48 小时关键词与窗口验证

验证日期：2026-11-24 · 决策：选定 Forest 方向，进入 MVP  
数据来源：本地 `research/data`、iTunes Search API、公开 ASO 热度（ASO Playbook / Asonix）、Reddit r/forestapp

---

## 一、结论（GO）

**窗口成立，关键词有搜索需求，差异化空位清晰 → 进入 MVP。**

| 检查项 | 结果 |
|---|---|
| 现任者翻车是否仍在发生 | ✅ Forest v5.28–5.35（至 2026-11-18）近评 84% ≤3★；改版退化仍是主因 |
| 搜索驱动是否存在 | ✅ `pomodoro` / `pomodoro timer` / `study timer` / `focus` 有中等以上热度 |
| 用户是否在主动找替代 | ✅ r/forestapp 2026-09/10 多帖「looking for alternative」；评论文本直接问 pomodoro 替代 |
| 能否差异化（避开 4.3） | ✅ 用户要的是「旧版 Forest 体验」：快、干净、无 AI、买断；不是再做一个订阅种树社交 App |
| 竞品是否已封死空位 | ⚠️ 拥挤但未封死：Flora「太重」、Cat on Chair $30/不同机制、Plantie 有广告且过简 |

---

## 二、窗口证据（本地评论，最新 50 条）

- 评分分布：1★×27 / 2★×14 / 3★×1 / 4★×4 / 5★×4 → **低分占比 84%**
- 主题（关键词再统计）：UI/改版抱怨 ~29；多年老用户怀旧 ~32；订阅/收费 ~13；AI ~4
- `analysis.json` 主题：update/regression **35**、price/subscription **13**
- Forest 当前：免费下载 + Plus 订阅（美区公开价约 $5.99/月、$35.99/年 Early Bird）；无新用户买断；累计评分约 4.79 / 4.96 万

用户原话要什么（可直接变成产品需求）：

1. **启动更快**：少对话框、少动画、少点按即可再开一轮  
2. **UI 更简单**：找回「转圈选时长 + 种树预览」式的直觉交互  
3. **不要 AI / 不要膨胀**：反对 AI 助手、游戏化杂物、逼氪  
4. **学生友好定价**：反感订阅；愿意买断或一次性 Pro  

---

## 三、关键词 / ASO 验证

### 3.1 iTunes 搜索占位（美区，2026-11-24 实查）

| 关键词 | Top 结果特征 |
|---|---|
| `focus timer` | Focus Keeper、Focus Friend、Forest、Cat On Chair |
| `pomodoro` / `pomodoro timer` | Focus Keeper、Forest、FocusPomo、Focus To-Do |
| `study timer` | Focus Friend、Flora、Study Bunny |
| `forest focus` / `focus plant` | Forest、Flora、Focus Plant、Study Bunny |
| `deep focus` | Forest、FocusFlight、Focus Friend |
| `focus blocker` | 偏 Screen Time 品类（Opal 等），非本 MVP 主战场 |

→ 核心词被大号占满，**靠标题硬刚 Forest 不现实**；应打「compound + 定位」：`study session` / `pomodoro` / `focus timer` + 副标题强调 buy once / simple / offline。

### 3.2 公开热度（第三方转引 Apple Ads，量级参考）

| Keyword | Popularity（约） | Difficulty（约） | 备注 |
|---|---|---|---|
| session | 70 | 54 | 高需求，适合埋进标题簇 |
| study | 54 | 74 | 学生向 |
| pomodoro timer | 52 | 62 | 品类主词 |
| interval / interval timer | 52–59 | 62–67 | 可作副标题 |
| pomodoro | 48 | 60 | |
| study timer | 44–45 | 59–65 | 学生获客 |
| focus | 61 | 66 | 极卷 |
| focus timer | 20–22 | ~59 | 需求一般，竞品多 |
| focus friend | 48 | — | 品牌词，勿浪费字段 |

**ASO 初稿（待定名后填入 Connect）**

- Title（≤30）：`{Brand} Focus Timer` 或 `{Brand}: Study Session`  
- Subtitle：`Pomodoro · Buy Once`（强调买断差异）  
- Keyword 字段候选：`pomodoro,study,timer,session,concentration,interval,plant,offline,student,productivity`（去重、避开标题已出现词）

品牌搜索承接（内容/ASO 描述文案，勿像素复刻）：`Forest alternative`、`simple focus timer`、`lifetime pomodoro`。

---

## 四、竞品地图与空位

| App | 评分规模（美区量级） | 定价 | 对 Forest 逃逸用户的缺口 |
|---|---|---|---|
| Flora | ~8.3 万评 / 4.76 | 基本免费+小额 IAP | Reddit：太重、流程多、像社交/习惯全家桶 |
| Focus Friend | ~1.1 万 / 4.84 | 订阅+Lifetime $39.99 | 机制是豆子不是树；对学生偏贵 |
| Cat on Chair | ~536 / 4.91 | Lifetime $29.99 | 椅子猫≠森林扩展感；价位偏高 |
| Focus To-Do | ~1.5 万 / 4.80 | Lifetime $11.99 | 任务管理向，无种树动机 |
| FocusFlight | ~1.0 万 / 4.85 | 订阅+Lifetime | 飞行隐喻，非自然成长 |
| Plantie 等 | 小 | 去广告约 $2 | 过简（缺 tag/统计），有广告 |
| Stint / Tomatino 等 | 新/小 | 买断 $8–25 | 纯计时，无「种活物」情感钩子 |

**我们的空位（一句话）**  
> 旧版 Forest 的核心：2 秒开种、看着树长大、离开会枯萎；本地、无账号、无 AI、无订阅；核心免费 + 一次买断解锁全树种与统计。

不是：再做一个 Flora（社交/习惯重）、不是 Focus Friend（IP 萌宠订阅）、不是纯番茄钟。

---

## 五、风险与缓解

| 风险 | 等级 | 缓解 |
|---|---|---|
| 4.3 复制品拒审 | 高 | 自有美术/交互；不抄 Forest 树种与 UI；命名与文案不蹭商标 |
| Flora / Focus Friend 已分流 | 中 | 打「更快更干净」；Reddit build-in-public；买断价压到学生可接受（建议 $12.99–$19.99） |
| 窗口被 Forest 回滚修复 | 中 | 3–9 月窗口；先发 MVP；即使修复，买断+极简仍可留住嫌订阅用户 |
| 种树美术工作量 | 中 | MVP 用少量矢量/程序化成长阶段（发芽→成树→枯萎），后期再扩树种 |
| Screen Time 屏蔽 | 低（延后） | P1；首版用「离开 App 则枯萎」已够验证核心循环 |
| 本机无完整 Xcode.app | 阻塞工程 | 需安装 Xcode；Swift 6.1 CLI 已在，可先写源码骨架 |

---

## 六、GO / NO-GO 清单

- [x] 差评窗口仍热（84% 近评低分）  
- [x] 搜索词有需求（pomodoro / study / session）  
- [x] Reddit 主动求替代（2026-09/10）  
- [x] 差异化一句话可写清  
- [x] 工程量可控（无账号、无社交、无云）  
- [ ] Apple Developer + Xcode GUI（你侧环境）  
- [ ] 商标/名称最终确认  

**判定：GO → 写 MVP 规格并开工骨架。** 详见 `FOREST_MVP_SPEC.md`。
