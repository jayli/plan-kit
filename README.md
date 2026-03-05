# Plan-Kit (Planify)

## What and why

A implementation of the **PLAN-and-Execute mode driven by the Plan file** for Claude code or other cli tools.

- Upgrade your Skills into a plan file-driven execution mode for more robust task execution
- Run the prompt text directly in PLAN-and-Execute mode. Enabling automated tracking of complex tasks.

### Comparison

- **Difference from plan mode**: Planify is simpler and more straightforward, no need to switch between modes, and can robustness-upgrade existing skills.
- **Difference from common prompts**: File-based persistence, suitable for long and complex tasks, easier to resume from interruptions.

Therefore, planify is better suited for complex skills and long tasks. If you need to repeatedly discuss and clarify the plan, please use plan mode.

### ✨ Features

- Task visualization
- Execution automation
- Extremely high fault tolerance

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

exec in your Claude Code or other cli client.

```bash
# Upgrade a skill to plan-driven mode
/planify <skill-name>

# Example: upgrade the skill named report
/planify report

# Then, when using /report, it is based on the plan-file-driven mode

# OR use the prompt words directly
/planify What's the weather like today? What should I wear
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

### Plan file Example

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

## 📄 License

MIT License

## 🔗 Links

- [GitHub Repository](https://github.com/jayli/plan-kit)
- [Report Issues](https://github.com/jayli/plan-kit/issues)
