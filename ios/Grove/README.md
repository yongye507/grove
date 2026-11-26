# Grove（Forest 替代品 MVP）

工作名，正式品牌待定。规格见 `../../research/FOREST_MVP_SPEC.md`，验证见 `../../research/FOREST_VALIDATION.md`。

## 运行

工程已生成：`ios/Grove.xcodeproj`（由 `ios/project.yml` + xcodegen）。

```bash
cd ios
xcodegen generate   # 改 yml 或增删文件后重跑
open Grove.xcodeproj
# 或命令行：
xcodebuild -project Grove.xcodeproj -scheme Grove \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' build
```

Scheme 已挂 `Products.storekit`，模拟器可测 Lifetime 内购。

## 目录

```
Grove/
  App/GroveApp.swift
  Models/{FocusTag,TreeSpecies,FocusSession,AppSettings}.swift
  Services/{SessionEngine,GroveStore,StoreService,NotificationService}.swift
  Views/{PlantingView,GroveView,StatsView,RootTabView,PaywallView,TreeGrowthView}.swift
  Resources/{Assets.xcassets,Products.storekit}
```

## MVP 范围

P0：种树计时、离开枯萎、本地林子、Tag、StoreKit 买断、结束通知。  
不做：账号、AI、社交、系统级 App 屏蔽（P1）。
