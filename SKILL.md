---
name: "c-drive-cleaner"
description: "AI驱动的C盘智能决策顾问——不是清理工具，而是你的磁盘健康私人AI管家。深度分析+个性化建议+安全执行指导。当用户询问C盘空间不足、想清理垃圾、释放磁盘空间、想将某些数据移出C盘时调用此技能。"
version: "6.1.0"
brand: "CleanSight"
---

# CleanSight — AI Disk Health Advisor

**我不是清理工具，我是你的 AI 磁盘健康顾问。**

```
传统工具 = 执行层：帮你删文件（但不懂你）
CleanSight = 决策层：理解你 → 分析数据 → 智能建议 → 教你安全执行
```

---

## 🧠 三大核心优势（为什么用 AI 而不是 CCleaner）

| 优势 | 传统工具 | CleanSight |
|------|---------|-----------|
| **上下文感知** | 固定规则，一刀切 | 基于你的使用习惯动态分析 |
| **动态风险评估** | 只说"能删/不能删" | 告诉你为什么 + 替代方案 + 迁移指导 |
| **知识赋能** | 删完就结束 | 教你根本解决方法，一劳永逸 |

**差异化公式**: `迁移 > 删除 > 忽略` — 传统工具只会删，AI 教你迁移保留功能的同时释放空间。

---

## 🔧 工作流程

```
用户触发 "C盘快满了" / "帮我分析C盘"
  ↓
1. 执行 12 类别只读扫描（scanners/）
  ↓
2. 生成 AI 决策报告（健康评分 + Tier 分级建议）
  ↓
3. 展示摘要 → 用户追问 → 深入分析
  ↓
4. 用户选择执行项 → AI 提供精确命令 + 安全提示
```

### 一键模式

```powershell
.\analyze.ps1                                          # 控制台输出
.\analyze.ps1 -OutputFormat markdown                   # 生成 Markdown 报告
.\analyze.ps1 -OutputFormat json                       # JSON 格式
.\analyze.ps1 -Categories "C,D"                        # 只扫描开发缓存+浏览器
```

### 扫描类别速查

| 类别 | 脚本 | 覆盖 | 适用 |
|------|------|------|------|
| A-系统隐藏 | scan-system-hidden | hiberfil/pagefile/还原点/WinSxS | 了解即可 |
| B-临时缓存 | scan-temp-files | Temp/缩略图/回收站/Update缓存 | ✅ 日常首选 |
| C-开发缓存 | scan-dev-caches | npm/pip/cargo/maven/gradle等 | 开发者必看 |
| D-浏览器 | scan-browsers | Chrome/Edge/Firefox等 | 所有人 |
| E-应用数据 | scan-app-data | IDE/媒体/办公/AI工具 | 深度清理 |
| F-大文件 | scan-large-files | TOP 20大文件+文件夹排行 | 快速定位 |
| G-特殊占用 | scan-special-sources | Docker/WSL/游戏平台 | 特殊需求 |
| H-安全软件 | scan-security-software | EDR/NAC/杀毒 | 仅了解 |
| I-多版本 | scan-multi-version | 多版本残留 | 整洁度 |
| J-重复运行时 | scan-duplicate-runtimes | Electron/CEF重复 | 高级优化 |
| K-输入法 | scan-ime-data | 词库/日志 | 细节清理 |
| L-即时通讯 | scan-im-apps | 微信/QQ/钉钉缓存 | 社交应用 |

---

## 🛡️ 安全原则

### 风险等级

| 标记 | 含义 | 处理 |
|------|------|------|
| ✅ | 纯临时/缓存，删除无副作用 | 可直接执行 |
| ⚠️ | 需人工确认的低风险项 | 备份后执行 |
| ❌ | 系统核心/企业管控/用户数据 | 绝不触碰 |
| 🔴 | 可疑/未知，AI无法确定 | 引导自行判断 |

### 安全红线（永远不自动执行）

- ❌ 删除系统还原点 / 关闭休眠 / 移动页面文件
- ❌ 清理 WinSxS /ResetBase
- ❌ 删除 Program Files / 用户文档/桌面/下载
- ❌ 触碰企业安全软件(EDR/NAC/杀毒)
- ❌ vssadmin / diskpart 操作

### 安全机制

1. **只读默认**: 扫描脚本只读不写
2. **WhatIf 模式**: 清理脚本支持 `-WhatIf` 预览
3. **明确确认**: 危险操作需 `-ReallyDelete`
4. **快照备份**: `safety/snapshot-before-after.ps1`
5. **回滚指南**: `safety/rollback-guide.md`

---

## 📐 架构

```
c-drive-cleaner/
├── SKILL.md                    ← 你在这里
├── _common.ps1                 ← 公共模块（性能+统一接口）
├── analyze.ps1                 ← 一键入口（console/markdown/json）
│
├── scanners/   (12个只读扫描)
├── cleaners/   (3个清理: safe/deep/dev-caches)
├── migrators/  (3个迁移: appdata/dev-caches/wsl-docker)
├── extensions/
│   ├── app-signatures.json     ← 100+ 应用签名（14类别）
│   ├── user-custom.json        ← 用户自定义签名
│   └── scan-discover.ps1       ← 未知应用发现引擎
├── safety/     (备份+快照+回滚)
├── reports/    (生成的报告)
└── scheduled/  (定期自动化)
```

### 扩展性

新软件签名只需一行 JSON，无需修改代码：

```json
{ "name": "我的软件", "detect_paths": ["%LOCALAPPDATA%\\MyApp\\cache"], "cleanable": true, "risk_level": "safe" }
```

编辑 `extensions/user-custom.json` 保存即生效。`scan-discover.ps1` 可自动发现未知大文件夹。

---

| 彻底卸载 | [BCU](https://www.bcuninstaller.com/) |

---

## 🎯 智能扫描策略与交互确认机制（v6.1 新增）

### 核心问题

不同用户的 C 盘情况差异巨大，**一刀切的 12 类全扫描** 存在问题：

| 维度 | 差异 | 影响 |
|------|------|------|
| **磁盘大小** | 256GB vs 1TB vs 2TB | 扫描时间线性增长（大磁盘可能需要 10+ 分钟）|
| **使用率** | 45% (健康) vs 96% (紧急) | 紧急状态需要极速响应，不能等 5 分钟 |
| **用户时间** | 有 30 秒 vs 有 30 分钟 | 需要不同深度的模式匹配 |
| **Token 成本** | 全量扫描 ~10K tokens | 对于简单问题可能浪费资源 |
| **信息需求** | 只想知道 Docker 怎么办 vs 想全面优化 | 过度扫描反而造成信息过载 |

### 解决方案：5 种扫描模式 + 3 阶段交互流程

#### 📊 5 种模式对比

| 模式 | 图标 | 适用场景 | 扫描类别 | 耗时 | Token消耗(DeepSeek Flash) | 输出深度 |
|------|------|---------|---------|------|--------------------------|---------|
| **🚀 极速** | ⚡ | 时间紧/大磁盘/初步了解/紧急救援 | B+F+G (3类) | **15-30秒** | **~2.8K (¥0.02)** | 大头定位+快速建议 |
| **⚡ 快速** | 🔥 | 日常周维护/开发者常规检查 | A+B+C+D+F (6类) | **1-2分钟** | **~4.5K (¥0.03)** | 主要问题+Top5行动 |
| **🔬 标准** | ✨ | 月度全面体检/首次彻底分析 | 除H外11类 | **3-5分钟** | **~10.2K (¥0.07)** | 完整v6报告(9模块) |
| **🎯 自定义** | 🎯 | 明确知道自己要查什么 | 用户选择 | **可变** | **~1-8K** | 定制化报告 |
| **🧠 智能** | 🤖 | 不确定选什么/最省心 | AI动态决策 | **最优** | **~2-10K** | 最适合当前场景 |

> 💰 **成本参考（DeepSeek v4 Flash）**: 极速 ¥0.02 / 快速 ¥0.03 / 标准 ¥0.07
> （比 GPT-4 便宜 **10-20 倍**，性价比极高）

---

### 🔄 完整交互流程（3 阶段）

```
┌─────────────────────────────────────────────────────┐
│ Phase 1: 快速预检 (15-30秒, ~500 tokens)          │
│                                                     │
│ ✅ 采集轻量级数据：                                  │
│   • C盘总容量、已用空间、使用率                      │
│   • Windows Temp + 回收站大小                       │
│   • TOP 5 用户文件夹（仅扫 user profile）            │
│   • Docker/WSL 是否存在及大致大小                   │
│   • 开发工具快速检测（node/python/java）             │
│   • 用户类型识别（开发者/普通用户）                  │
│                                                     │
│ 输出: 结构化 JSON + 用户友好的快照摘要              │
└─────────────────────┬───────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│ Phase 2: 策略推荐 (~800-1200 tokens)                 │
│                                                     │
│ AI 基于预检结果给出个性化建议：                       │
│                                                     │
│ "检测到你的 C 盘：                                   │
│  • 总容量: 512GB | 已用: 384GB (75%)               │
│  • 状态: ⚠️ 偏高（建议关注）                         │
│  • 发现: Docker 45GB + npm缓存 12GB                │
│  • 类型: 👨‍💻 开发者                                 │
│                                                     │
│ 推荐方案（按投入产出比排序）：                        │
│                                                     │
│ ┌─ 推荐: ⚡ 快速模式 (2分钟, ¥0.03) ┐              │
│ │   ✓ Docker 占用大 → 重点扫 G 类                  │
│ │   ✓ 开发者 → C 类开发缓存是重点                  │
│ │   ✓ 性价比最高: 覆盖 95% 常见问题                │
│ └───────────────────────────────────────────        │
│                                                     │
│ 备选:                                             │
│   🚀 极速 (30秒) - 如果只想知道 Docker 怎么处理      │
│   🔬 标准 (5分钟) - 如果想做月度全面体检           │
│   🎯 自定义 - 如果你有特定想了解的内容              │
│                                                     │
│ 你想选哪个？"                                       │
└─────────────────────┬───────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│ Phase 3: 执行选定策略                               │
│                                                     │
│ 用户确认后开始扫描，显示进度：                        │
│ [████████░░░░] 60% - 扫描 C 类: 开发工具缓存...     │
│                                                     │
│ 扫描完成 → 生成对应深度的报告                        │
│                                                     │
│ 支持追问（每轮 +500-1000 tokens）：                  │
│ • "这个能删吗？为什么？"                             │
│ • "帮我生成迁移命令"                                │
│ • "对比一下方案A和B"                                 │
└─────────────────────────────────────────────────────┘
```

---

### 🧠 智能推荐算法（策略选择逻辑）

当用户选择 **🧠 智能推荐模式** 时，AI 应用以下规则：

```python
def smart_recommend(diagnosis_data):
    usage_pct = diagnosis_data.usage_percent
    free_gb = diagnosis_data.free_gb
    capacity_gb = diagnosis_data.total_gb
    user_type = diagnosis_data.user_type
    special_items = diagnosis_data.special_items
    
    # 规则1: 🔴 紧急状态（<10GB 或 >90%）
    if free_gb < 10 or usage_pct >= 90:
        return {
            'strategy': 'lightning',  # 极速模式
            'reason': '⚠️ 紧急！先用极速模式找到最大头，立即释放',
            'follow_up': 'quick'       # 后续升级到快速模式
        }
    
    # 规则2: 大磁盘 + 高使用率
    if capacity_gb >= 512 and usage_pct >= 80:
        return {
            'strategy': 'quick',
            'reason': '大磁盘+偏高使用率=快速排查即可覆盖主要矛盾'
        }
    
    # 规则3: 小磁盘 + 高使用率
    if capacity_gb < 512 and usage_pct >= 80:
        return {
            'strategy': 'standard',
            'reason': '小磁盘紧张+高使用率=需要全面分析才能有效释放'
        }
    
    # 规则4: 开发者 + 多个大型工具
    if user_type == 'developer' and len(special_items) >= 2:
        return {
            'strategy': 'quick',
            'reason': f'检测到{len(special_items)}个大占用项(Docker/npm等)，'
                    '重点扫描这些区域效率最高'
        }
    
    # 规则5: 健康 (<50%)
    if usage_pct < 50:
        return {
            'strategy': 'quick',
            'reason': 'C盘很健康，快速检查做预防性维护即可'
        }
    
    # 默认: 标准模式
    return {
        'strategy': 'standard',
        'reason': '默认推荐标准模式，确保不遗漏任何潜在问题'
    }
```

---

### 💬 交互式对话模板（可直接使用）

#### 模板 1: 首次使用/日常检查

```
用户: "帮我看一下 C 盘"

AI: 
[Phase 1: 快速预检中... 20秒]
✅ 预检完成！

📊 你的 C 盘快照:
━━━━━━━━━━━━━━━━━━━━━━━
容量: 512 GB | 已用: 384 GB (75%) | 剩余: 128 GB
状态: ⚠️ 偏高（建议关注）

发现的主要占用:
• 🔴 Docker Desktop: 45 GB (11.7%)
• 🟡 npm/pip/yarn 缓存: 12 GB (3.1%)
• 🟢 Windows Temp: 2.1 GB
• 🟢 浏览器缓存: 1.8 GB
• 🔵 其他应用数据: ~323 GB

用户类型识别: 👨‍💻 开发者（检测到 Node.js/Python/Docker）
━━━━━━━━━━━━━━━━━━━━━━━

[Phase 2: 策略推荐]

基于以上情况，我为你推荐：

┌─ ⚡ 推荐: 快速模式 (2分钟, Token ~4.5K, 成本 ≈¥0.03) ─┐
│                                                          │
│ 为什么推荐这个？                                           │
│ ✓ Docker 占用很大(45GB)，需要优先处理                     │
│ ✓ 作为开发者，开发缓存是重点优化对象                     │
│ ✓ 使用率75%不算紧急，不需要极速抢救                       │
│ ✓ 性价比最高：覆盖95%常见问题，耗时适中                   │
│                                                          │
│ 本模式将扫描:                                            │
│   A.系统隐藏  B.临时缓存  C.开发缓存                     │
│   D.浏览器    F.大文件                                    │
│                                                          │
│ 预期输出:                                                 │
│   • Docker/WSL 迁移方案（释放40GB+）                     │
│   • 开发缓存清理建议（释放10GB+）                          │
│   • Top 5 立即可执行的操作                                │
│                                                          │
└──────────────────────────────────────────────────────────┘

备选方案:
  🚀 极速模式 (30秒, ¥0.02) - 如果你只想知道 Docker 怎么处理
  🔬 标准模式 (5分钟, ¥0.07) - 如果你想做月度全面体检
  🎯 自定义 - 如果你有特定想了解的内容

你想选择哪个？或者告诉我：
  • "我时间紧" → 我推荐极速模式
  • "我想彻底清理" → 我推荐标准模式  
  • "我只关心 Docker" → 我可以只扫描 G 类
```

---

#### 模板 2: 紧急场景（C盘快满了）

```
用户: "C盘只剩 8GB 了，很卡！"

AI:
[Phase 1: 快速预检中... 12秒]
⚠️ 检测到紧急状态！

📊 你的 C 盘快照:
━━━━━━━━━━━━━━━━━━━━━━━
容量: 256 GB | 已用: 248 GB (96.9%) | 仅剩: 8 GB ⛔
状态: 🔴 危急！（Windows 可能变慢或报错）

紧急发现:
• 🔴 休眠文件 hiberfil.sys: 8 GB ← 立即可删！
• 🔴 Docker: 35 GB ← 最大单项
• 🟡 npm缓存: 6 GB
• 🟡 浏览器+临时文件: 3 GB
━━━━━━━━━━━━━━━━━━━━━━━

[Phase 2: 紧急响应]

⚡ **时间就是金钱！我推荐紧急分阶段方案：**

┌─ 🚨 紧急救援（分3阶段）───────────────────────┐
│                                                    │
│ 第1阶段: 立即执行（10秒，释放 8-16GB）         │
│   ▸ 关闭休眠功能（释放 8GB，零风险）           │
│   ▸ 清空回收站（如果有内容）                    │
│   ▸ 清理 Windows Temp（释放 1-2GB）           │
│                                                    │
│ 第2阶段: 5分钟内（额外释放 10-20GB）           │
│   ▸ 清理浏览器缓存                              │
│   ▸ 清理不常用的开发缓存                         │
│   ▸ Docker 悬空资源清理                          │
│                                                    │
│ 第3阶段: 周末执行（释放 35GB+）                  │
│   ▸ 迁移 Docker 到 D 盘                           │
│   ▸ 迁移 WSL 到 D 盘                               │
│   ▸ 设置开发环境变量到 D 盘                        │
│                                                    │
│ 预期效果:                                          │
│   10分钟后: 使用率从 97% → 85% ✅                │
│   1小时后:   使用率降至 70% 左右                   │
│                                                    │
│ 总 Token 成本: ~4K (≈¥0.03)                      │
└────────────────────────────────────────────────────┘

💬 你想：
  A. "直接给我第1阶段的命令" → 我立刻给你
  B. "先详细解释每一步" → 我用标准模式分析
  C. "帮我全部规划好" → 我生成完整的救援文档
```

---

#### 模板 3: 高级用户（明确目标）

```
用户: "我只关心 Docker 和 npm 缓存，其他不用扫"

AI:
✅ 明白！精准打击，不浪费时间。

🎯 自定义扫描配置:
━━━━━━━━━━━━━━━━━━━━━━━
扫描类别: G (特殊占用) + C (开发缓存)
聚焦目标:
  • Docker Desktop (镜像/数据卷/容器)
  • WSL2 发行版
  • npm/Yarn/pnpm/cargo 缓存
  • pip/conda 缓存（如存在）

排除扫描:
  • ❌ A 系统隐藏（hiberfil/pagefile等）
  • ❌ B 通用临时文件
  • ❌ D 浏览器数据
  • ❌ E 应用程序
  • ❌ F 大文件扫描
  • ... 其他非目标类别
━━━━━━━━━━━━━━━━━━━━━━━

⏱️ 预估耗时: 30-60秒
💰 Token 消耗: ~2K（比标准模式省 **75%**）
💰 成本: ≈¥0.014

现在开始扫描吗？
  • "开始" → 立即执行
  • "再加上 F 类（大文件）" → 我调整配置
  • "先告诉我预计会发现什么" → 我基于已有信息预估
```

---

### ⚙️ 技术实现说明

#### 快速预检脚本

新增文件: `scanners/scan-quick-diagnosis.ps1`

```powershell
# 使用方法
.\scanners\scan-quick-diagnosis.ps1                    # 控制台输出
.\scanners\scan-quick-diagnosis.ps1 -OutputFormat json     # JSON格式（供AI消费）
.\scanners\scan-quick-diagnosis.ps1 -OutputFormat markdown # Markdown报告
```

**特点**:
- 仅采集关键指标，不做深度遍历
- 使用 `Get-FolderSizeFast` 高性能计算
- 15-30秒内完成
- 输出结构化数据供 AI 决策

#### 策略配置文件

新增文件: `extensions/strategy-config.json`

包含：
- 5 种模式的完整定义（类别、耗时、Token预算、适用场景）
- DeepSeek v4 Flash 的定价模型
- 智能推荐算法的决策规则
- 交互流程的各阶段定义

AI 在 Phase 2 时读取此文件，结合预检结果生成个性化推荐。

#### 在 analyze.ps1 中集成

```powershell
# 新增参数支持
param(
    [string]$Categories = "all",
    [string]$OutputFormat = "console",
    [string]$Template = "v6-ai-decision",
    [ValidateSet("lightning", "quick", "standard", "custom", "smart", "auto")]
    [string]$Strategy = "auto"  # 新增！默认智能推荐
)

# 当 Strategy="auto" 时，先运行快速预检，再决定扫描哪些类别
if ($Strategy -eq "auto") {
    $diagnosis = & "$PSScriptRoot\scanners\scan-quick-diagnosis.ps1" -OutputFormat json
    # AI 根据 $diagnosis 推荐策略（此处可接入 LLM 或规则引擎）
    $recommendedStrategy = Get-RecommendedStrategy -Diagnosis $diagnosis
    $Categories = $recommendedStrategy.categories
}
```

---

### 📈 Token 成本控制最佳实践

#### 1. 透明化原则

每次交互都应告知用户 Token 消耗：

```
✅ 预检完成（消耗 ~500 tokens，≈¥0.0035）
⚡ 推荐策略生成中（预计 ~1000 tokens，≈¥0.007）
🔍 即将执行快速模式扫描（预计 ~3000 tokens，≈¥0.02）
   累计预计: ~4.5K tokens (≈¥0.03)
   
是否继续？ [Y/n]
```

#### 2. 预算预警机制

当累计 Token 超过阈值时主动提醒：

| 阈值 | 行为 |
|------|------|
| > 10K (¥0.07) | 提示："已使用较多Token，建议聚焦核心问题" |
| > 20K (¥0.14) | 强提醒："即将达到建议上限，考虑总结收尾" |
| > 30K (¥0.21) | 必须确认："继续深入分析将显著增加成本，确定吗？" |

#### 3. 分层加载策略

```
Layer 1 (必须): 快速预检 + 策略推荐      → ~1.5K tokens
Layer 2 (按需): 执行选定模式的扫描         → ~1.5-8K tokens  
Layer 3 (可选): 追问和深入探讨            → ~0.5-1K/轮
Layer 4 (高级): 生成完整v6报告或迁移教程    → ~2-3K tokens

用户可在任意层停止，已获得的价值不会浪费。
```

---

## 🆚 与传统工具的关系

---

## 📋 报告命名规范

| 格式 | 示例 | 含义 |
|------|------|------|
| Markdown | `CleanSight-CS-20260513-143022-72.md` | 品牌-日期-时间-健康评分 |
| JSON | `CleanSight-CS-20260513-143022-72.json` | 同上 |

报告自动包含：执行摘要 → 扫描明细 → AI决策建议(Tier分级) → 使用指南 → 工具推荐

---

## 🔄 维护规范（AI Agent Skill 工程化标准）

### 版本管理

- 遵循语义化版本：`MAJOR.MINOR.PATCH`
- 所有变更记录在 `CHANGELOG.md`
- `app-signatures.json` 的 `_schema` 版本号与主版本同步

### 更新流程

1. **签名更新**: 编辑 `app-signatures.json` 或 `user-custom.json`，无需改代码
2. **扫描器更新**: 修改 `scanners/` 下对应脚本
3. **报告格式更新**: 修改 `analyze.ps1` 中的报告生成逻辑
4. **版本发布**: 更新 `SKILL.md` version + `analyze.ps1` $VERSION + `CHANGELOG.md`

### 兼容性要求

- PowerShell 5.1+（Windows 自带）
- 不使用 PS7+ 专有语法（如三元运算符 `?:`）
- 路径使用环境变量（`$env:LOCALAPPDATA` 等）
- 应用检测前置 `Test-Path`（不存在则跳过）

### 测试验证

```powershell
# 验证扫描器正常
.\analyze.ps1 -Categories "B"    # 测试临时文件扫描
.\analyze.ps1 -OutputFormat json # 测试 JSON 输出
```

---

*CleanSight v6.1.0 — AI Disk Health Advisor*
*理解你 · 分析数据 · 智能建议 · 赋能执行*
