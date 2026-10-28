---
name: review-changes
description: Review implemented code changes and related behavior for regressions, then produce actionable manual checks with concrete actions and expected results. Use when the user asks to recheck changes, assess whether related functionality broke, or prepare manual regression checks for a change.
---

# Review changes and manual checks

Read the implemented changes, inspect related behavior, and prepare manual checks. Respond in the user's language. By default, review without fixing code.

## Define the scope

- Use the files, commits, branch, or pull request specified by the user. If the current task makes the scope clear, review that scope.
- For uncommitted changes, read git status --short, staged and unstaged diffs, and relevant new files not shown by the ordinary diff. Include submodule changes when they are part of the task.
- For a commit or branch, establish the correct comparison base and name it in the report. Do not substitute a working-tree review for a commit review.
- Separate mixed changes by task context. Ask about scope only when the choice materially changes the result and context is insufficient. Preserve unrelated changes.

## Review behavior

1. Read the full diff in scope and the current implementations of changed methods with their surrounding code. Derive expected behavior from the request, requirements, and existing contracts. Do not assume the new behavior is correct merely because the code now implements it.
2. Trace the affected path from action or data source to result. Find callers, consumers, shared state, handlers, and other uses of changed components. For each affected function, identify neighboring scenarios that use the same code or state.
3. Compare behavior before and after the change. Check the main scenario and relevant risks such as initial state, repeated actions, cancellation, mode changes, permissions, value boundaries, errors, connection loss and recovery, lifecycle, and persistence. Choose cases based on the actual code; do not apply the whole list mechanically.
4. Read related tests. Run available checks that are allowed by the current task and project rules. Invoking this skill does not override restrictions on builds, app launches, devices, or external systems.
5. For each defect, state its code location, reproduction conditions, expected and actual behavior, and consequences. Separate a code-confirmed defect from a hypothesis that requires execution or equipment. Do not report style preferences as regressions.

For every material finding, determine whether it was introduced by the reviewed change or existed earlier. Use the baseline and history only when needed to confirm the cause. Report pre-existing problems separately when relevant; do not label them regressions.

For every defect, state a concrete scenario and observable consequence. If a scenario could not be confirmed, state the uncertainty and the missing verification.

Continue through the full selected diff and related scenarios after the first finding. For each suspected defect, check the changed code, its calling path, and a relevant test or reproducible example when available. Report only concrete, material correctness, security, performance, or maintainability problems the author can fix. Put unconfirmed risks separately and say what evidence is missing.

For each confirmed finding, identify the narrowest relevant location and assign severity by impact: P0 — critical widespread blocker; P1 — urgent major problem; P2 — ordinary fixable defect; P3 — minor but practically relevant issue. If a requirement is entirely missing and no changed line exists, identify where the behavior should be connected and cite the requirement source. Compare requirements against behavior before and after reviewing the code, including scenarios that were not implemented. Do not invent a finding when none exists.

Do not fix findings unless the user separately authorized fixes. Do not create commits. If fixes are authorized and made, reread the final diff and prepare scenarios for the final state.

## Prepare manual checks

Cover the changed behavior and related scenarios actually affected by the change. Put the most serious and likely regressions first. Do not use a fixed number of checks.

- State necessary starting conditions such as screen, role, mode, connection state, data, or equipment. Shared conditions may be stated before a group of scenarios.
- Choose actions for the system under review: for UI, use clicks and input; for a CLI, give commands and expected output or exit code; for an API, give requests and responses; for files and background processes, give concrete actions and observable results. Do not assume a screen or button must exist.
- Format each check as: concrete action — expected observable result. For example, click an item and state which value, label, control state, or device behavior should appear. Avoid vague outcomes such as “everything works,” “no errors,” or “check correctness.”
- Use real screen and control names from the project. If the name or way to trigger an event could not be determined, say so.
- Give exact values and wait times only when supported by requirements or code. For thresholds, check below, at, and above the boundary when relevant.
- Include checks for found defects and mark them as expected to fail on the current code. Describe the correct expected behavior.
- State when a scenario requires a server, device, or unavailable state. Do not say a manual check was performed unless it actually was.

Example:

Conditions: The Settings screen is open and Notifications is off.

1. Click Notifications — the control turns on.
2. Close and reopen Settings — Notifications remains on.

This is an example of format only. Derive scenarios and persistence behavior from the project under review.

## Final response

Present the result in this order:

1. Findings, from most to least severe, with file and line. If no defects were found, say “No code regressions were found” and state the limits of the review.
2. Briefly name the reviewed scope, related functionality, checks actually performed, and remaining uncertainties. Distinguish source inspection, static checks, tests, compilation, and device testing.
3. Give a numbered list of manual checks in the format above, with starting conditions where needed.

Do not claim “nothing broke” based only on reading the diff or passing compilation.