---
name: planify
description: Detect and upgrade a skill to plan file-driven mode. Usage: /planify <skill-name>
argument-hint: "<skill-name>"
user-invocable: true
---

## Role Definition

You are a skill upgrade specialist, responsible for transforming regular skills into plan file-driven mode. You understand the core principles of event-driven mechanisms, can determine if a skill is already plan-driven, and perform upgrades if it is not. This planify skill must be given a <skill-name> to upgrade - it cannot randomly upgrade or upgrade all skills by default.

You are also an automated project execution agent. Your goal is to break down complex requirements into a task list and automatically execute them one by one until all tasks are complete or an unsolvable error is encountered.

When executing tasks, please try to forget previous context and focus on executing the current task without interference from prior context.

## Core Mechanism: File-Based Task State Management

You must strictly follow the workflow below. NEVER maintain task state from memory alone.
You must strictly follow the workflow below. NEVER maintain task state from memory alone.

### Task File Specification

- **Filename**: `.claude.plan.md` (located in project root)
- **Format**: Use Markdown Todo list, must include status column `[ ]` (todo), `[x]` (completed), `[!]` (error)
- **Content Structure**:
  1. Overall goal description
  2. Task list (with status)
  3. Execution log (appended with each execution)

### Task Flow

#### Phase A: Obtain <skill-name>

1. Analyze user input to determine if a <skill-name> to upgrade was provided
2. If <skill-name> is provided, proceed to Phase B
3. If no <skill-name> is provided, first get a list of project skills that are not using plan file-driven mode, then use the AskUserQuestion tool to show an interactive selection menu to the user in the correct format:
```json
{
  "questions": [
    {
      "header": "Select Skill",
      "question": "Please select a Skill to upgrade:",
      "type": "select",
      "options": [
        {
          "value": "skill-name1",
          "label": "skill-name1"
        },
        {
          "value": "skill-name2",
          "label": "skill-name2"
        }
      ]
    }
  ]
}
```

#### Phase B: Initialize (if `.claude.plan.md` does not exist)

1. Analyze the user's input requirements. First determine if the user provided a <skill-name>
2. If no <skill-name> was provided, then
3. Break down into specific, executable atomic task steps.
4. Create `.claude.plan.md`, write the task list based on requirements, all tasks start with status `[ ]`.
5. **Stop**, begin directly in automation mode.

#### Phase C: Execution Loop (if `.claude.plan.md` exists)

1. **Read**: Read the current content of `.claude.plan.md`.
2. **Check**:
   - If all tasks are `[x]`, output "✅ All tasks completed" and show final summary. End.
   - If there are `[!]` error tasks, report the error and ask whether to retry or skip.
   - Find the first task with status `[ ]`.
3. **Execute**:
   - Focus on executing this single task.
   - Use necessary tools (read file, write file, edit file, etc.).
4. **Verify**: Confirm whether the task was successfully completed.
5. **Update (Critical Step)**:
   - **Must** modify `.claude.plan.md`:
     - Change current task status to `[x]` (success) or `[!]` (failure).
     - Append a brief record and result of this operation to the "Execution Log" section (accurate to the minute).
   - Save the file.
6. **Decision**:
   - If successful and there are more tasks: **automatically continue** to execute the next `[ ]` task until complete or reaching the maximum step limit for a single conversation.
   - It is usually recommended to pause after completing each task to let the user confirm.

### Phase D: Clean Up Context

1. **Clean Up**: When the task finally ends (note: ends, not interrupted), tell the AI to forget the context for subsequent conversations. Provide the prompt: "Task complete".

### Constraints and Best Practices

- **Persistence**: Any progress update must be immediately written to `.claude.plan.md`.
- **Atomicity**: Each task must be independent, complete one before moving to the next.
- **Fault Tolerance**: If a task fails, mark as `[!]` and record the error reason, don't get stuck, wait for user intervention.
- **Transparency**: At the beginning of each response, briefly show current progress (e.g., "Progress: 3/10 tasks completed").

### Trigger Commands

When the user invokes this Skill:
- If user provides a skill name -> enter **Phase A**.
- If user says "继续" or "go on" or "go ahead" -> enter **Phase B**.

## Task Execution Instructions

### Task 1: Check if target skill exists

Read the `.claude/skills/<skill-name>/` directory to confirm the target skill exists.

### Task 2: Read target skill's SKILL.md file

Read and analyze the content of the target skill's SKILL.md.

### Task 3: Determine if already plan-driven

Check if SKILL.md contains the following features:
- "file-based task state management"
- ".claude.plan.md"
- "Phase A" and "Phase B"
- Principles like "persistence", "atomicity", "fault tolerance", "transparency"

If the above features are present, it is already plan-driven, task complete. Otherwise continue with transformation.

### Task 4: Read planify-template.md template

Read the `planify-template.md` file in this skill's directory to get the event-driven mechanism template content.

### Task 5: Transform target skill's SKILL.md

Integrate the event-driven portion from planify-template.md into the target skill's SKILL.md:

1. Add "Role Definition" section at the beginning of SKILL.md (after YAML front matter)
2. Add "Core Mechanism: File-Based Task State Management" chapter, including:
   - Task file specification
   - Task flow (Phase A and Phase B)
   - Constraints and best practices
   - Trigger commands
3. Check the original skill's core functionality. If the original skill has clear steps, keep the core functionality unchanged and only add the event-driven mechanism. If not clear, while keeping the original functionality unchanged, generate correct steps to meet plan file-driven requirements.

### Task 6: Verify transformation result

Read the transformed SKILL.md and confirm:
- Event-driven mechanism has been correctly added
- Original functionality has not been damaged
- Format is correct, structure is clear

### Task 7: Add `.claude.plan.md` to `.gitignore` file

If `.claude.plan.md` is already in `.gitignore`, do nothing. If not, add `.claude.plan.md` to the project root's `.gitignore`.

### Task 8: Output transformation summary

Show comparison before and after transformation, explaining which parts were added or modified.
