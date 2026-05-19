# C 盘健康向导 — 交互式安全设计方案

## 概述

为 CleanSight v6.2 新增交互式安全健康向导功能，解决三个核心问题：
1. **黑盒问题**：扫描/清理过程中用户不知道进度
2. **安全隐患**：清理缓存后程序打不开
3. **缺乏建议**：没有告诉用户可以用网页版替代桌面端

---

## 一、扫描进度反馈

### 现状
`analyze.ps1` 顺序执行 12 个扫描器，每执行完一个输出 `[1/12] ...`，但每个扫描器内部跑多久、发现了多少数据，用户完全不知道。

### 改造
在 `analyze.ps1` 中添加**实时刷新进度面板**，每 2 秒更新一次：

```
Scan Progress: [████████░░░░]  4/12
Current: D-浏览器 → Chrome
Found: 3.2 GB (9 items)
Elapsed: 15.3s
```

### 实现
- `analyze.ps1` 新增 `Show-ScanProgress` 后台作业，每 2 秒从 `$Global:CDriveScanResults` 读取累计大小
- 用 `$host.UI.RawUI.WindowTitle` 和 `Write-Host` 覆盖更新
- 不影响最终的扫描结果输出

---

## 二、AI 应用签名与网页版建议

### 现状
`app-signatures.json` 中 ai_tools 类别缺少 Kimi 和 DeepSeek，也无"网页版建议"机制。

### 改造

#### 2.1 新增签名

在 `app-signatures.json` 的 `ai_tools` 类别中追加：

```json
{ "name": "Kimi", "detect_paths": ["%APPDATA%\\Kimi", "%LOCALAPPDATA%\\Kimi"], 
  "cleanable": true, "sub_cleanable": "Cache, Code Cache, GPUCache",
  "web_alternative": "kimi.moonshot.cn" },
{ "name": "DeepSeek", "detect_paths": ["%APPDATA%\\DeepSeek", "%LOCALAPPDATA%\\DeepSeek"], 
  "cleanable": true, "sub_cleanable": "Cache, Code Cache, GPUCache",
  "web_alternative": "chat.deepseek.com" },
{ "name": "豆包", ..., "web_alternative": "doubao.com" }  // 追加字段
```

#### 2.2 扫描报告优化建议区

在扫描报告中新增"💡 优化建议"区块，检测到 AI 桌面端时显示。

#### 2.3 签名模型扩展

`app-signatures.json` 中增加 `web_alternative` 和 `uninstall_suggestion` 字段支持：

```json
"web_alternative": "https://kimi.moonshot.cn",
"uninstall_suggestion": "如不需要桌面端独有功能（文件上传、长对话），建议卸载"
```

---

## 三、交互式安全清理向导

### 现状
现有清理脚本直接执行删除，即使 `clean-safe.ps1` 有 `-ReallyDelete` 保护，也没有：
- 清理前的完整性预检
- 清理前备份
- 清理后验证应用可启动
- 一键回滚

### 架构：三步安全走廊

```
Pre-check → Clean → Verify
   ↓          ↓        ↓
  预检      执行     验证
```

### 3.1 新增文件

| 文件 | 职责 |
|------|------|
| `_wizard-ui.ps1` | 向导 UI 组件：进度面板、确认对话框、表格渲染 |
| `cleaners\clean-wizard.ps1` | 交互式向导入口：编排预检→执行→验证流程 |
| `safety\backup-file.ps1` | 文件级备份（JSON manifest + 复制到安全目录） |
| `safety\verify-clean.ps1` | 清理后验证 + 自动回滚 |

### 3.2 Pre-check（预检）

对每一项要清理的缓存：

1. **进程检测**：是否在运行 → 提示关闭
2. **完整性检测**：程序 `.exe` 是否存在 → 不存在则跳过
3. **快照记录**：记录当前目录文件列表 + 总大小到 `safety/snapshots/`
4. **风险评估**：显示"此项删除后 → 影响范围"

### 3.3 Clean（执行）

逐项 Y/N 确认模式：

```
  [1/5] 豆包缓存 — 512 MB
  路径: %APPDATA%\Doubao\User Data\Default\Cache
  💡 网页版: doubao.com (可节省 512 MB)
  
  确认清理此项? [Y/N] > Y
  
  ████████████░░░░  78%  已删 400MB/512MB  12.3s
  ✅ 完成
```

### 3.4 Verify（验证）

自动对每个清理过的应用执行：

| 验证项 | 方法 | 失败处理 |
|--------|------|---------|
| 程序本体存在 | `Test-Path "$appDir\*.exe"` | 标记异常 |
| 关键数据目录 | `Test-Path "$appDir\User Data"` | 自动从备份恢复 |
| 能启动进程 | 启动进程后 5 秒检查存活 | 自动终止 + 回滚 |
| 总体验证 | 汇总所有项的状态 | 显示通过/失败报告 |

验证失败 → 自动触发 `rollback.ps1` 恢复备份。

### 3.5 回滚机制

```
safety/snapshots/
├── 20260518-143022/
│   ├── manifest.json        ← 备份文件清单+校验和
│   ├── files/               ← 实际备份的文件
│   └── precheck.json        ← 预检时的状态快照
```

回滚步骤：
1. 读取最近一次 `manifest.json`
2. 逐一恢复文件到原始路径
3. 验证恢复后的完整性

---

## 四、`app-signatures.json` 模型扩展

新增字段：

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `web_alternative` | string | 网页版 URL | `"doubao.com"` |
| `uninstall_suggestion` | string | 卸载建议文案 | `"如不需要桌面端独有功能..."` |
| `critical_data_paths` | string[] | 不能动的重要路径 | `["User Data\\Local Storage", "config"]` |

---

## 五、不涉及范围

- ❌ 不修改已上线的 12 个扫描器脚本的逻辑（只加进度反馈）
- ❌ 不改 `clean-safe.ps1` / `clean-deep.ps1` 的现有功能（只是新增向导）
- ❌ 不会触碰系统级文件（WinSxS、hiberfil、pagefile）

---

## 六、文件变更清单

| 操作 | 文件 | 说明 |
|------|------|------|
| 修改 | `_common.ps1` | 新增 `Show-ScanProgress` 函数 |
| 修改 | `analyze.ps1` | 集成进度面板 |
| 修改 | `extensions/app-signatures.json` | 新增 Kimi/DeepSeek 签名 + web_alternative |
| 新建 | `_wizard-ui.ps1` | 向导 UI 组件 |
| 新建 | `cleaners/clean-wizard.ps1` | 交互式安全清理向导 |
| 新建 | `safety/backup-file.ps1` | 文件级备份 |
| 新建 | `safety/verify-clean.ps1` | 清理后验证 + 回滚 |
| 新建 | `safety/snapshots/.gitkeep` | 备份快照目录 |
