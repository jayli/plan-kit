# Plan-Kit (Planify)

> Transform your Skills into a plan file-driven automation execution mode for more robust task execution

Planify is a Skill that adds plan file-based task state management to other Skills, enabling automated breakdown, execution, and tracking of complex tasks.

## ✨ Features

- Task visualization
- Execution automation
- Super fault tolerance

## 🚀 Quick Install

### Linux / macOS

```bash
bash <(curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh)
```

### Windows PowerShell

```powershell
iwr https://raw.githubusercontent.com/jayli/plan-kit/main/install.ps1 -useb | iex
```

### Windows (Git Bash / WSL)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/jayli/plan-kit/main/install.sh)
```

## 📖 Usage

### Basic Usage

```bash
# Upgrade a skill to plan-driven mode
/planify <skill-name>

# Example: upgrade the skill named report
/planify report
```

If the conversation is interrupted, you can continue with:

```
继续
go on
go ahead
```

## 📁 File Structure

```
.claude/
└── skills/
    └── planify/
        ├── SKILL.md              # Main Skill definition
        ├── example.md            # Example of a transformed Skill
        └── planify-template.md   # Plan-driven template
```

### .claude.plan.md Example

```markdown
# Task Plan

## Goal
Transform the report skill to plan-driven mode

## Task List

- [x] Check if target skill exists
- [x] Read target skill's SKILL.md file
- [ ] Verify transformation result

## Execution Log

2024-01-01 10:00 - Started task 1: Check if target skill exists ✅
2024-01-01 10:01 - Completed task 2: Read SKILL.md file ✅
```

### Automatically adding `.claude.plan.md` to ignore list

The task generates `.claude.plan.md`, which is automatically added to `.gitignore`.

## 📄 License

MIT License

## 🔗 Links

- [GitHub Repository](https://github.com/jayli/plan-kit)
- [Report Issues](https://github.com/jayli/plan-kit/issues)
