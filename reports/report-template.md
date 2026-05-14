# 报告输出模板

使用此模板将扫描结果格式化为用户友好的报告。

---

## 输出格式

```text
╔══════════════════════════════════════════════════════╗
║     C盘深度分析报告 v4.0                             ║
║     只读模式 · 未修改任何文件                         ║
╚══════════════════════════════════════════════════════╝

━━━ 一、C盘空间概况 ━━━
总容量: {TOTAL} GB | 已用: {USED} GB ({USED_PERCENT}%) | 可用: {FREE} GB

━━━ 二、隐藏空间占用 ━━━
├─ 休眠文件(hiberfil.sys): {HIBER} GB ─ 建议: {HIBER_REC}
├─ 页面文件(pagefile.sys): {PAGE} GB ─ 建议: {PAGE_REC}
├─ 系统还原点: {RP_COUNT}个 ─ 建议: {RP_REC}
└─ WinSxS组件存储: 可回收 {WINSXS_RECLAIM} ─ 建议: {WINSXS_REC}

━━━ 三、可清理项目 ━━━

【✅ 强烈推荐删除】
├─ 临时文件/缓存/缩略图/回收站 ─ 详见扫描报告各分类
└─ 预计可释放: {SAFE_CLEANABLE} GB

【⚠️ 确认后可操作】
├─ 回收站 / Windows更新缓存等
└─ 预计可释放: {CONFIRM_CLEANABLE} GB

【💻 开发工具缓存 — 可删除 OR 可迁移】
└─ 预计可释放/迁移: {DEV_CACHE} GB

━━━ 四、🔍 C盘大文件 TOP 20 ━━━
(详见 F类扫描)

━━━ 五、⚠️ 需人工检查的项目 ━━━
├─ 🔴 C盘根目录可疑文件
├─ 🔴 多版本软件共存残留
├─ 🔴 Electron/CEF 重复运行时
└─ 🔴 安全软件数据占用(不可删但需了解)

━━━ 六、🛡️ 安全软件/管控数据 ━━━
(详见 H类扫描 — 仅作信息展示，不可删除)

━━━ 七、📦 一键迁移指南 ━━━
开发缓存迁移: .\migrators\migrate-dev-caches.ps1
AppData 迁移:  .\migrators\migrate-appdata-junction.ps1 -AppName "应用名"
WSL/Docker:    .\migrators\migrate-wsl-docker.ps1

━━━ 八、🧹 清理选项 ━━━
安全清理: .\cleaners\clean-safe.ps1           (WhatIf预览，加-ReallyDelete执行)
深度清理: .\cleaners\clean-deep.ps1           (逐项确认)
开发缓存: .\cleaners\clean-dev-caches.ps1     (逐项确认)

---
报告生成时间: {TIMESTAMP}
分析耗时: {DURATION}
扫描覆盖: 12个类别 (A-L)
```
