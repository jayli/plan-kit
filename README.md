# Plan-Kit（Planify）

> 将你的 Skills 改造为基于计划文件驱动的自动化执行模式，让任务执行更稳健

Planify 是一个 Skill，为其他 Skills 添加基于计划文件的任务状态管理机制，实现复杂任务的自动化拆解、执行和追踪。

## ✨ 特性

- 任务可视化
- 执行自动化
- 超强容错

## 🚀 快速安装

### Linux / macOS

```bash
curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh | sh
```

### Windows PowerShell

```powershell
iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex
```

### Windows (Git Bash / WSL)

```bash
curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh | sh
```

## 📖 使用方法

### 基本用法

```bash
# 升级指定 skill 为 plan 驱动模式
/planify <skill-name>

# 例如：升级名为 report 的 skill
/planify report
```

如果对话中断，可以使用以下指令继续：

```
继续
go on
go ahead
```

## 📁 文件结构

```
.claude/
└── skills/
    └── planify/
        ├── SKILL.md              # Skill 主定义文件
        ├── example.md            # 改造后的 Skill 示例
        └── planify-template.md   # Plan 驱动模板
```

### .claude.plan.md 示例

```markdown
# 任务计划

## 目标
将 report skill 改造为 plan 驱动模式

## 任务列表

- [x] 检查目标 skill 是否存在
- [x] 读取目标 skill 的 SKILL.md 文件
- [ ] 判断是否已经是 plan 驱动
- [ ] 读取 planify-template.md 模板
- [ ] 改造目标 skill 的 SKILL.md
- [ ] 验证改造结果

## 执行日志

2024-01-01 10:00 - 开始执行任务 1: 检查目标 skill 是否存在 ✅
2024-01-01 10:01 - 完成任务 2: 读取 SKILL.md 文件 ✅
```

### 自动将 .claude.plan.md 加入忽略列表

任务会生成 `.claude.plan.md`，会自动添加到 `.gitignore` 中

## 📝 工作原理

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  用户指令   │ ──► │   Planify    │ ──► │  创建计划  │
│  /planify   │     │   解析器     │     │  .claude   │
└─────────────┘     └──────────────┘     │  .plan.md  │
                                          └─────────────┘
                                                 │
                                                 ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  清理上下文 │ ◄── │   更新状态   │ ◄── │   执行任务  │
│   完成！    │     │  写入文件    │     │   原子操作  │
└─────────────┘     └──────────────┘     └─────────────┘
```

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🔗 相关链接

- [GitHub 仓库](https://github.com/jayli/plan-kit)
- [报告问题](https://github.com/jayli/plan-kit/issues)
