# CleanSight (c-drive-cleaner) 项目全面分析

> 分析日期：2026-05-23
> 版本：v6.3.0

---

## 一、项目定位

**这不是一个普通的清理工具，而是一个 AI 驱动的 C 盘智能决策顾问。**

| 对比维度 | 传统工具 (CCleaner/WizTree) | CleanSight |
|---------|---------------------------|------------|
| **定位** | 执行层：帮你删文件 | 决策层：理解你 → 分析 → 智能建议 → 教你执行 |
| **工作方式** | 固定规则，一刀切 | 基于上下文、用户画像动态分析 |
| **核心价值** | 删除 | 迁移 > 删除 > 忽略 |
| **交互方式** | 图形界面操作 | 对话式 AI 交互 |

---

## 二、架构总览

```
skill-c-cleaner/
├── 📄 核心入口
│   ├── analyze.ps1          ← 一键分析入口（支持 console/markdown/json 输出）
│   ├── _common.ps1         ← 公共函数库（核心引擎）
│   └── _clean-helper.ps1    ← 清理辅助函数
│
├── 🔍 scanners/ (14个只读扫描器)
│   ├── scan-temp-files.ps1      ← B类：临时文件
│   ├── scan-dev-caches.ps1     ← C类：开发缓存
│   ├── scan-browsers.ps1       ← D类：浏览器
│   ├── scan-app-data.ps1       ← E类：应用数据
│   ├── scan-large-files.ps1    ← F类：大文件
│   ├── scan-virtual-memory.ps1  ← VM：虚拟内存
│   └── ... (共14个)
│
├── 🧹 cleaners/ (3个清理脚本)
│   ├── clean-safe.ps1       ← 安全清理（临时文件/缩略图/回收站）
│   ├── clean-deep.ps1       ← 深度清理（需要管理员）
│   └── clean-dev-caches.ps1 ← 开发缓存清理
│
├── 🚚 migrators/ (3个迁移脚本)
│   ├── migrate-appdata-junction.ps1  ← AppData 迁移（符号链接）
│   ├── migrate-dev-caches.ps1      ← 开发缓存迁移
│   └── migrate-wsl-docker.ps1      ← WSL/Docker 迁移
│
├── 📦 extensions/
│   ├── app-signatures.json       ← 100+ 应用的签名数据库（14类别）
│   ├── scan-discover.ps1         ← 未知应用发现引擎
│   └── strategy-config.json      ← 策略配置
│
├── 💾 safety/
│   ├── backup-registry.ps1       ← 注册表备份
│   ├── snapshot-before-after.ps1 ← 清理前后快照
│   └── rollback-guide.md        ← 回滚指南
│
└── 🧪 tests/ (完整测试体系)
```

---

## 三、扫描类别 (12+2 类)

| 类别 | 扫描器 | 覆盖范围 |
|------|--------|---------|
| **A** | 系统隐藏 | hiberfil.sys / pagefile.sys / 还原点 / WinSxS |
| **B** | 临时缓存 | Temp / 缩略图 / 回收站 / Update缓存 |
| **C** | 开发缓存 | npm / pip / cargo / maven / gradle / yarn / pnpm 等 |
| **D** | 浏览器 | Chrome / Edge / Firefox / Brave 等 |
| **E** | 应用数据 | IDE / 媒体 / 办公 / AI工具 |
| **F** | 大文件 | TOP 20 大文件 + 文件夹排行 |
| **G** | 特殊占用 | Docker / WSL / 游戏平台 |
| **H** | 安全软件 | EDR / NAC / 杀毒（仅了解）|
| **I** | 多版本 | 多版本残留 |
| **J** | 重复运行时 | Electron / CEF 重复 |
| **K** | 输入法 | 词库 / 日志 |
| **L** | 即时通讯 | 微信 / QQ / 钉钉缓存 |
| **VM** | 虚拟内存 | 页面文件 + 休眠文件 |
| **SI** | 搜索索引 | Windows 搜索索引 |

---

## 四、核心设计理念

### 1. 签名驱动 (Signature-Based)

应用数据库在 `app-signatures.json` 中定义，每个条目包含：

```json
{
  "name": "npm",
  "detect_paths": ["%LOCALAPPDATA%\\npm-cache"],
  "cleanable": true,
  "migratable": true,
  "migration_method": "env_var",
  "migration_key": "npm_config_cache",
  "clean_cmd": "npm cache clean --force"
}
```

支持 14 个类别，100+ 应用签名。

### 2. 风险分级系统

| 标记 | 含义 | 处理方式 |
|------|------|---------|
| ✅ safe | 纯临时/缓存，删除无副作用 | 可直接执行 |
| ⚠️ cautious | 需人工确认的低风险项 | 备份后执行 |
| ❌ forbidden | 系统核心/用户数据 | 绝不触碰 |
| 🔴 unknown | 可疑/未知 | 引导用户自行判断 |

### 3. 安全红线（永不自动执行）

- ❌ 删除系统还原点 / 关闭休眠 / 移动页面文件
- ❌ 清理 WinSxS /ResetBase
- ❌ 删除用户文档/桌面/下载
- ❌ 触碰企业安全软件 (EDR/NAC/杀毒)
- ❌ vssadmin / diskpart 操作

### 4. 三层删除保障机制 (v6.3)

```
方案A: Process.Start() + WaitForExit(120s)  ← 优先，最快
方案B: robocopy /MIR 清空                   ← 回退，快
方案C: .NET Directory.Delete()              ← 最后保障
```

### 5. Token 成本模型

| 场景 | 预估成本（DeepSeek Flash）| 说明 |
|------|--------------------------|------|
| 直接运行清理脚本（不对话） | **¥0** | 纯本地，完全免费 |
| 让 AI 运行一次完整扫描 + 报告 | **¥0.05-0.1** | AI 解读报告，给建议 |
| 让 AI 指导执行清理 + 后续追问 | **¥0.1-0.3** | 正常使用范围 |
| 调试 bug + 反复修复 | **¥1.0+** | 异常情况，不应发生 |

---

## 五、核心模块详解

### 5.1 scanners/ — 14 个只读扫描器

所有扫描器均为**只读**，不会修改任何文件：

| 脚本 | 类别 | 功能 |
|------|------|------|
| scan-system-hidden.ps1 | A | 扫描系统隐藏文件（休眠/页面/还原） |
| scan-temp-files.ps1 | B | 扫描临时文件和缓存 |
| scan-dev-caches.ps1 | C | 扫描开发工具缓存（npm/pip/cargo等）|
| scan-browsers.ps1 | D | 扫描浏览器缓存 |
| scan-app-data.ps1 | E | 扫描应用数据（IDE/办公/媒体）|
| scan-large-files.ps1 | F | 扫描TOP大文件 |
| scan-special-sources.ps1 | G | 扫描特殊占用（Docker/WSL/游戏）|
| scan-security-software.ps1 | H | 扫描安全软件（EDR/杀毒）|
| scan-multi-version.ps1 | I | 扫描多版本残留 |
| scan-duplicate-runtimes.ps1 | J | 扫描重复运行时 |
| scan-ime-data.ps1 | K | 扫描输入法数据 |
| scan-im-apps.ps1 | L | 扫描即时通讯缓存 |
| scan-virtual-memory.ps1 | VM | 扫描虚拟内存配置 |
| scan-search-index.ps1 | SI | 扫描搜索索引 |

### 5.2 cleaners/ — 3 个清理脚本

| 脚本 | 风险等级 | 功能 | 需要管理员 |
|------|---------|------|-----------|
| clean-safe.ps1 | ✅ safe | 临时文件/缩略图/回收站 | 部分 |
| clean-deep.ps1 | ⚠️ cautious | Windows更新缓存/系统缓存 | 是 |
| clean-dev-caches.ps1 | ✅ safe | 开发工具缓存（npm/pip等）| 否 |

### 5.3 migrators/ — 3 个迁移脚本

| 脚本 | 功能 | 迁移方式 |
|------|------|---------|
| migrate-appdata-junction.ps1 | AppData 目录迁移 | 符号链接 (Junction) |
| migrate-dev-caches.ps1 | 开发缓存迁移 | 环境变量重定向 |
| migrate-wsl-docker.ps1 | WSL/Docker 迁移 | 软链接/配置文件 |

### 5.4 extensions/ — 扩展系统

- **app-signatures.json**: 100+ 应用的签名数据库
- **user-custom.json**: 用户自定义签名扩展
- **scan-discover.ps1**: 未知应用发现引擎
- **strategy-config.json**: 策略配置

### 5.5 safety/ — 安全机制

- **backup-registry.ps1**: 注册表备份
- **snapshot-before-after.ps1**: 清理前后快照对比
- **rollback-guide.md**: 回滚操作指南

---

## 六、版本历史

| 版本 | 日期 | 关键词 | 规模 |
|------|------|--------|------|
| v6.3 | 2026-05-18 | 清理引擎深度优化（Timeout + robocopy回退）| ⚡ Hotfix |
| v6.2 | 2026-05-16 | 个性化学习系统 | 🧠 Minor |
| v6.1.2 | 2026-05-16 | 清理引擎性能修复 | ⚡ Hotfix |
| v6.1.0 | 2026-05-16 | 生产级重构 | 🏭 Major |
| v6.0.0 | 2026-05-13 | AI 决策层（核心转型）| 🧠 Major |
| v4.1.0 | 2026-05-12 | 扩展性系统 | 🔌 Minor |
| v4.0.0 | 2026-05-12 | 文件组架构 | 🏗️ Major |
| v3.0.0 | 2026-04-02 | 四维深度分析 | 📊 Major |
| v2.0.0 | 2026-04-01 | 结构化报告 | 📋 Minor |
| v1.0.0 | 2026-04-01 | 初始版本 | 🚀 Initial |

### v6.3 关键修复

**Bug 1: `& cmd /c` 同步阻塞无超时（P0）**
- 问题：`Remove-Directory` 直接 `& cmd /c "rmdir /s /q"`，卡住则永久阻塞
- 修复：改用 `System.Diagnostics.Process.Start()` + `WaitForExit(120s)` 带超时控制

**Bug 2: .NET `[System.IO.Directory]::Delete()` 回退仍然慢（P1）**
- 问题：当 `cmd /c rmdir` 失败时，.NET API 同样需要枚举所有文件
- 修复：改用 `robocopy $emptyDir $Path /MIR` 清空内容，再用 `rmdir` 删除空目录

**Bug 3: 清理前扫描仍用 `Get-ChildItem -Recurse` 算大小（P1）**
- 问题：大目录下极慢
- 修复：全部替换为 `Get-FolderSizeFast`（基于 robocopy /L /S /BYTES，快 10-100 倍）

---

## 七、典型使用场景

| 场景 | 推荐操作 |
|------|---------|
| 日常检查 | `.\analyze.ps1` |
| C盘快满了（紧急）| `.\analyze.ps1` + 按风险优先级执行清理 |
| 开发者周维护 | `.\cleaners\clean-dev-caches.ps1 -ReallyDelete` |
| 迁移 Docker/WSL | 使用 migrators/ 下的脚本 |
| 精准清理 | `.\analyze.ps1 -Categories "C,D"` 只扫描指定类别 |

### 命令行参数

```powershell
.\analyze.ps1                                    # 控制台输出
.\analyze.ps1 -OutputFormat markdown            # 生成 Markdown 报告
.\analyze.ps1 -OutputFormat json                # JSON 格式输出
.\analyze.ps1 -Categories "C,D"                  # 只扫描开发缓存+浏览器
```

---

## 八、核心亮点总结

1. **纯本地执行**：扫描和分析全部在本地运行，**不消耗 Token**
2. **签名可扩展**：只需添加 JSON 条目即可支持新软件，无需修改代码
3. **迁移优于删除**：教用户迁移而不是简单删除，保留功能的同时释放空间
4. **智能风险评估**：基于上下文动态判断，不是固定规则
5. **三层安全保障**：超时机制 + robocopy 回退 + 最后手段
6. **完整的测试体系**：包含场景测试、性能基准、迁移指南
7. **个性化学习**（v6.2）：用户画像 + 对话记忆，越用越懂你

---

## 九、设计哲学

> **"授人以鱼不如授人以渔"**
>
> CleanSight 不是帮你直接删文件，而是教你如何管理系统空间，让你自己做出最优决策。

**差异化公式**: `迁移 > 删除 > 忽略`

- 传统工具只会删
- AI 教你迁移保留功能的同时释放空间

---

## 十、文件清单

| 目录/文件 | 说明 |
|-----------|------|
| SKILL.md | 技能定义文件（核心文档）|
| README.md | 项目介绍文档 |
| CHANGELOG.md | 版本变更记录 |
| _common.ps1 | 公共函数库（核心引擎）|
| _clean-helper.ps1 | 清理辅助函数 |
| analyze.ps1 | 一键分析入口 |
| analyz_new.ps1 | 新版分析脚本（实验性）|
| scanners/*.ps1 | 14个只读扫描器 |
| cleaners/*.ps1 | 3个清理脚本 |
| migrators/*.ps1 | 3个迁移脚本 |
| extensions/* | 扩展系统文件 |
| safety/* | 安全机制文件 |
| memory/* | 个性化学习系统 |
| scheduled/* | 定期自动化任务 |
| tests/* | 测试评测体系 |
| examples/* | 案例库（正/负面案例）|
| reports/* | 生成的报告文件 |
