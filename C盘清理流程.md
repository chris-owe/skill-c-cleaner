# C盘清理完整流程

> 基于 CleanSight 工具的标准清理流程

---

## 流程概览

```
第一步：运行分析 → 第二步：查看报告 → 第三步：执行清理 → 第四步：复查确认
```

---

## 第一步：运行分析

### 方式 1：完整扫描（推荐首次使用）
```powershell
cd skill-c-cleaner
.\analyze.ps1
```

### 方式 2：只扫描安全可清理项
```powershell
cd skill-c-cleaner
.\analyze.ps1 -Categories "B,D"        # 临时文件 + 浏览器缓存
```

### 方式 3：精准扫描（已知问题领域）
```powershell
cd skill-c-cleaner
.\analyze.ps1 -Categories "C"           # 只扫开发缓存
```

---

## 第二步：查看分析报告

运行后会输出类似：

```
========================================
  CleanSight v6.1.0 - AI Disk Health Advisor
========================================

  C: [##################----] 85%
  Health Score: 40/100 ⚠️ 需关注

========================================
  扫描结果汇总
========================================

✅ 可立即释放 (安全): 8.7 GB
   - 临时文件: 2.3 GB
   - 浏览器缓存: 1.8 GB
   - 开发工具缓存: 4.6 GB

⚠️ 需确认后释放 (谨慎): 15.2 GB
   - AppData 缓存: 8.2 GB
   - 微信缓存: 4.5 GB
   - ...

========================================
  Top 3 推荐行动
========================================

1. [立即执行] 清理临时文件 + 浏览器缓存
   释放: ~4 GB | 风险: ✅ 安全 | 耗时: 1分钟

2. [本周完成] 清理开发工具缓存 (npm/pip)
   释放: ~4.6 GB | 风险: ✅ 安全 | 耗时: 2分钟

3. [谨慎操作] 清理微信缓存
   释放: ~4.5 GB | 风险: ⚠️ 需确认 | 注意: 保留聊天记录
```

---

## 第三步：执行清理

### 清理优先级

| 优先级 | 操作 | 命令 | 释放空间 | 风险 |
|--------|------|------|---------|------|
| **1** | 安全清理（临时文件/缩略图/回收站）| `.\cleaners\clean-safe.ps1 -ReallyDelete` | ~2-4 GB | ✅ 安全 |
| **2** | 清理开发缓存 | `.\cleaners\clean-dev-caches.ps1 -ReallyDelete` | ~3-10 GB | ✅ 安全 |
| **3** | 清理浏览器缓存 | 浏览器设置中清理 或 手动删除 | ~1-5 GB | ✅ 安全 |
| **4** | 清理 AppData 缓存 | 手动确认后删除 | ~5-15 GB | ⚠️ 谨慎 |

---

### 标准清理步骤

#### Step 1: 安全清理（必做）
```powershell
.\cleaners\clean-safe.ps1 -ReallyDelete
```
清理内容：
- Windows 临时文件夹 (`C:\Windows\Temp`)
- 用户临时文件夹 (`%LOCALAPPDATA%\Temp`)
- 缩略图缓存
- 回收站
- Windows 错误报告

#### Step 2: 开发工具缓存清理（可选，开发者必做）
```powershell
.\cleaners\clean-dev-caches.ps1 -ReallyDelete
```
清理内容：
- npm cache
- pip cache
- yarn cache
- cargo cache
- gradle caches

#### Step 3: 深度清理（可选，需要管理员）
```powershell
.\cleaners\clean-deep.ps1 -ReallyDelete
```
⚠️ 需要以管理员身份运行 PowerShell

---

## 第四步：复查确认

### 检查清理效果
```powershell
.\analyze.ps1
```

对比清理前后的：
- Health Score 是否提升
- 可释放空间是否减少
- C 盘剩余空间是否增加

---

## 风险等级说明

| 标记 | 含义 | 如何处理 |
|------|------|---------|
| ✅ safe | 可安全删除 | 可直接执行清理命令 |
| ⚠️ cautious | 需谨慎确认 | 查看具体内容后再决定 |
| ❌ forbidden | 禁止操作 | 不要删除 |

---

## 常见问题

### Q: 清理后空间没变化？
A: 可能是因为文件正在被使用，重启电脑后再清理

### Q: 某个文件夹清理失败？
A: 可能需要管理员权限，用管理员身份运行 PowerShell

### Q: 误删了重要文件？
A: 大多数清理项会进入回收站，可从回收站恢复

---

## 推荐清理周期

| 用户类型 | 推荐周期 | 建议命令 |
|---------|---------|---------|
| 普通用户 | 每月一次 | `clean-safe.ps1` |
| 开发者 | 每周一次 | `clean-safe.ps1` + `clean-dev-caches.ps1` |
| 重度用户 | 每天/随时 | 按需使用 `analyze.ps1 -Categories "X"` |

---

## 完整命令速查

```powershell
# 1. 分析 C 盘
.\analyze.ps1

# 2. 安全清理（临时文件/缩略图/回收站）
.\cleaners\clean-safe.ps1 -ReallyDelete

# 3. 开发缓存清理
.\cleaners\clean-dev-caches.ps1 -ReallyDelete

# 4. 深度清理（需管理员）
.\cleaners\clean-deep.ps1 -ReallyDelete

# 5. 只扫描指定类别
.\analyze.ps1 -Categories "C,D"    # 开发缓存 + 浏览器
.\analyze.ps1 -Categories "B"      # 临时文件
.\analyze.ps1 -Categories "F"       # 大文件
```
