---
name: commit-this
description: Suggest commit subjects or prepare user-approved commits in a Git repository. Use when explicitly requested for commit work.
disable-model-invocation: true
---

# Git commit preparation

Use only when the user explicitly requests this skill for commit work. A request to inspect or maintain this skill does not start the commit workflow or require a task number.

## Select the mode

A bare `$commit-this` invocation means **Commit existing changes** for the repository and scope established by the conversation. Prepare the plan and request native approval; do not stop after suggesting a message. Use **Subjects only** only when the user explicitly asks for message suggestions without creating commits. A request to maintain this skill remains outside the commit workflow.

- **Subjects only:** inspect the selected changes and suggest messages. Do not stage, commit, or request commit approval.
- **Commit existing changes:** inspect their contents and prepare the commit plan. Read neighboring code only to resolve a concrete uncertainty. Do not turn commit preparation into a style audit or edit code without authorization.
- **Edit and commit:** perform the requested edits, then follow the commit workflow. Follow applicable repository conventions for any authorized edits.

Include an issue/task number when the user supplies one or repository instructions require it. Otherwise proceed without one. Do not invent a number or infer it from unrelated history. Ask only when required repository metadata is missing or a material ambiguity cannot be resolved from the selected changes.

Commit preparation does not authorize builds, tests, deployment, refactoring, or unrelated edits. Perform those only within separately authorized scope.

## Inspect once, expand only when needed

1. Identify the repository and requested scope. Take one initial inventory of staged, unstaged, and untracked paths. Record existing staging and HEAD so unrelated work can be preserved.
2. Read the full staged and unstaged diffs of selected changes, and relevant untracked contents. For unrelated changes, retain path/status information; inspect their contents only when they overlap selected files or affect separation. Read enough context to understand a concrete uncertainty, without auditing the whole repository.
3. Inspect a nested repository separately only when its contents or Git reference are involved in the task.
4. Resolve message style before drafting: explicit user instructions take precedence, followed by documented repository conventions. For any unspecified style choices, inspect the five most recent relevant commit messages without patches, including bodies and footers (for example, `git log -5 --format=%B -- <selected paths>`). Use repository-wide history if the selected paths have insufficient history. Infer the established format, language, terminology, use of prefixes/scopes, task-reference placement, and whether bodies are customary. Expand only when these examples leave a concrete ambiguity; do not copy issue numbers or unrelated content.

Reuse the inspected diff and context throughout planning. Reread source or history only after relevant changes, an error, or a discrepancy. This does not replace checking the actual staged diff before each commit.

## Subjects and boundaries

- Create a separate commit for each independently meaningful, independently revertible behavior or purpose. Keep supporting code, resources, and tests together. Do not split by file, helper, or incidental detail; honor an explicit user-requested split.
- Follow explicit user instructions and repository commit conventions in project instructions, `CONTRIBUTING.md`, and commitlint configuration. Where they leave choices open, follow the consistent style found in relevant Git history. Do not introduce Conventional Commits prefixes, scopes, or a multi-paragraph body merely as a default when the repository uses another style. Use Conventional Commits (`<type>[optional scope]: <summary>`) only when neither instructions nor history establish a format. If configured, locally installed, and allowed to run, validate the candidate with commitlint before presenting the plan; do not install it for this task.
- Follow the established use of scopes and placement of task references. When instructions and history provide no convention, scopes are optional and supplied task references may use a footer such as `Refs: #123`. Do not treat a task number as a mandatory scope.
- Follow the established use of message bodies; do not add a body merely to restate the diff. Add one when needed to explain a non-obvious reason, constraint, or migration. Check for incompatibility in platform minimums, removed options, stricter configuration, and persisted formats. Mark it using the repository convention, or `!` and a `BREAKING CHANGE:` footer for Conventional Commits. Derive release effects from project tooling, not universal type-to-version assumptions.
- Write a short, specific summary using established project terminology. Follow the requested language, then documented repository conventions, then the consistent language of relevant Git history; use the language of the task only when none establishes a preference. Follow repository length rules and established subject style; otherwise keep the subject concise without a trailing period.
- If the established format uses a type, derive it from the change and show it in the approval plan. Do not require a type for formats that omit it. Ask only when the ambiguity materially changes the intended commit or conflicts with repository rules.

## Keep commit messages in the main response

Commit messages are a user-facing deliverable. Include them in the final assistant response, not only in analysis, tool output, an approval prompt, or a commentary/progress message that the app may collapse.

- In subjects-only mode, put all suggested messages in the final response.
- When waiting for approval, include the complete ordered plan in the final response, even if it was already shown before calling `request_user_input_async`. Keep the repository, exact messages, assigned paths, and any shared-file hunk descriptions together. Present the plan directly, without a sentence announcing that approval is pending or that the native dialog is open. The native dialog handles the confirmation request; a status such as "plan published" does not replace the plan.
- After creating commits, include each created commit's hash and full message in the final report. If execution stops partway through, distinguish created commits from remaining planned commits and retain the exact messages for both.
- Put each full message in its own fenced `text` block, preserving its subject, body, footers, and real line breaks. Keep numbering, repository names, paths, hashes, and status explanations outside the message block so the message can be copied directly.

## Create commits

### Prepare and publish the plan

Assign exact paths or hunks to each commit and specify their order. Before requesting approval, record the checkout, base HEAD and existing index entries. Retain a snapshot for each commit with its selected paths or hunks, resulting contents (including binary files), Git file modes, and additions or deletions. For a file split across commits, record its expected intermediate content after each commit. If the selection cannot be staged without disturbing unrelated staged changes, stop and explain the conflict.

Publish the complete ordered plan in a visible chat message before opening the approval prompt. Include the repository, exact messages with bodies and footers, assigned paths and any shared-file hunk selections. Follow the final-response format above.

### Request approval for the displayed plan

In Codex, call `request_user_input_async` once after showing the complete plan and before the final response. Use the native prompt with approve and cancel choices. Ask only whether to approve the entire displayed plan. Use conversation for confirmation if the native prompt is unavailable.

One explicit approval authorizes every commit in that plan in the displayed order. Create and verify each commit, then proceed directly to the next. Do not ask for confirmation between commits while the approved plan still matches.

A tool response such as `accepted: true` acknowledges that the prompt was opened. Wait for an explicit affirmative user response to the current plan before staging. If no answer arrives, leave the plan pending with the index and history unchanged. If the user cancels, dismisses the prompt, or says to stop, close the current attempt and invalidate its approval. A request to change messages, order, or scope, including choosing only some commits, calls for a revised visible plan and fresh approval.

### Verify before staging and committing

Process one approved commit at a time. Before staging, recheck the checkout, expected HEAD, index state and selected content against the approved snapshot. If they differ, stop before staging, explain the difference and obtain approval for an updated plan.

Compare index entries as records. When Git successfully returns no entry for an untracked path, record it as absent both when taking the snapshot and when verifying it. A command error cannot establish absence.

Stage only the approved paths or hunks. Before committing, compare the actual staged content, Git modes and additions or deletions with the approved snapshot. Confirm that unrelated staged entries are preserved and excluded from the commit. A matching path list or a passing diff check alone does not verify the content.

### Verify each result before continuing

Pass the full approved message with real line breaks through `git commit -F` or separate `-m` arguments. Let configured hooks run. Do not bypass them with `--no-verify` without explicit authorization or use `--amend` to recover from a failed attempt. After each commit, verify its expected parent, full message and committed changes against the approved snapshot before staging the next commit.

If a read-only check errors, pause writes and diagnose it. If a corrected check proves that HEAD, the index and the remaining approved content still match, continue the same plan under the existing approval. If verification remains inconclusive, stop.

If verification confirms a mismatch, a hook changes files, a commit command fails or the user stops the operation, stop further writes. If staging or a commit attempt occurred, inspect HEAD and the index before reporting. Report verified commits, any new changes or entries left staged, and the remaining plan. If a commit exists but differs from the approved snapshot, report its hash and the mismatch. Do not auto-fix hook failures in commit-existing-changes mode. A new run after a stop requires fresh approval for the remaining work.

After the last commit, check final Git status and confirm that unrelated staging and omitted changes are preserved. Report the verified hashes, full messages and checks actually performed.
