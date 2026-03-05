# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 Claude Code Skills 配置仓库，核心功能是提供 `planify` skill，用于将普通 skill 改造为基于 `.claude.plan.md` 文件驱动的事件执行模式。

## 目录结构

```
.claude/
├── settings.local.json    # 本地权限配置
└── skills/
    └── planify/           # 核心 skill
        ├── SKILL.md       # skill 定义和任务流程
        ├── example.md     # 改造后的 skill 示例
        └── planify-template.md  # plan 驱动模板
```

## 核心机制

`planify` skill 通过 `.claude.plan.md` 文件实现任务状态持久化：

- **任务状态**: `[ ]` (待办), `[x]` (完成), `[!]` (错误)
- **执行流程**:
  - 阶段 A: 分析需求，创建任务列表
  - 阶段 B: 逐项执行任务，更新状态
  - 阶段 C: 清理上下文

## 使用方法

```bash
# 升级指定 skill 为 plan 驱动模式
/planify <skill-name>

# 继续执行未完成的任务
继续 / go on / go ahead
```

## 相关文件

- `.claude.plan.md` - 任务计划文件（运行时生成，应加入 `.gitignore`）
