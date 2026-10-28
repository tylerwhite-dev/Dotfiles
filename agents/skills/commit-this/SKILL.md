---
name: commit-this
description: Suggest commit subjects or prepare user-approved commits in a Git repository. Use when explicitly requested for commit work.

---

# Git commit preparation

Use only when the user explicitly requests this skill for commit work. A request to inspect or maintain this skill does not start the commit workflow or require a task number.

## Select the mode

- **Subjects only:** inspect the selected changes and suggest messages. Do not stage, commit, or request commit approval.
- **Commit existing changes:** inspect their contents and prepare the commit plan. Read neighboring code only to resolve a concrete uncertainty. Do not turn commit preparation into a style audit or edit code without authorization.
- **Edit and commit:** perform the requested edits, then follow the commit workflow. Follow applicable repository conventions for any authorized edits.

Include an issue/task number when the user supplies one or repository instructions require it. Otherwise proceed without one. Do not invent a number or infer it from unrelated history. Ask only when required repository metadata is missing or a material ambiguity cannot be resolved from the selected changes.

Commit preparation does not authorize builds, tests, deployment, refactoring, or unrelated edits. Perform those only within separately authorized scope.

## Inspect once, expand only when needed

1. Identify the repository and requested scope. Take one initial inventory of staged, unstaged, and untracked paths. Record existing staging and HEAD so unrelated work can be preserved.
2. Read the full staged and unstaged diffs of selected changes, and relevant untracked contents. For unrelated changes, retain path/status information; inspect their contents only when they overlap selected files or affect separation. Read enough context to understand a concrete uncertainty, without auditing the whole repository.
3. Inspect a nested repository separately only when its contents or Git reference are involved in the task.
4. Use the subject rules below directly. Read history only to resolve wording, format, or terminology, limited initially to five relevant subjects without patches. Expand only when those do not resolve a specific question.

Reuse the inspected diff and context throughout planning. Reread source or history only after relevant changes, an error, or a discrepancy. This does not replace checking the actual staged diff before each commit.

## Subjects and boundaries

- Create a separate commit for each independently meaningful, independently revertible behavior or purpose. Keep supporting code, resources, and tests together. Do not split by file, helper, or incidental detail; honor an explicit user-requested split.
- Follow explicit user instructions and applicable repository commit conventions. If no format is defined, use Conventional Commits: `<type>[optional scope]: <summary>`. Derive the type and summary from the diff. Common types include `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `style`, and `chore`.
- Scope is optional unless repository rules require it. Include task references in the location required by the repository; otherwise use an appropriate footer such as `Refs: #123`. Do not treat a task number as a mandatory scope.
- Add a body when it explains a non-obvious reason, constraint, or migration. Identify incompatible changes using the repository convention, or `!` and a `BREAKING CHANGE:` footer when using Conventional Commits.
- Write a short, specific summary using established project terminology. Follow the requested language and repository conventions; otherwise use the language of the task. Follow repository length rules; in their absence keep the subject concise without a trailing period.
- Choose the type that best describes the change and show it in the approval plan. Ask only when the ambiguity materially changes the intended commit or conflicts with repository rules.

## Create commits

1. Assign exact files or hunks to each commit and specify their order. Review each assigned diff using the already inspected contents. Preserve unrelated changes and pre-existing staging; when changes share a file, include only the assigned hunks. If separation cannot preserve the user's staging, stop and explain the conflict before committing.
2. Immediately before the first commit, display the complete ordered plan with every exact subject and its assigned changes. Use the active harness's native structured approval or user-input interface when one is available, with a clear approve/cancel choice tied to that exact plan. One approval should cover the complete ordered plan. If the harness has no structured interaction, ask in the conversation and wait.
3. Treat only an unambiguous affirmative selection or written answer to that exact plan as approval. One approval covers only the displayed messages, contents, and order. An earlier request to commit does not approve this final plan. If the plan changes, present the revised plan and request approval again. A negative answer or no answer creates no commit.
4. After approval, create commits one at a time. Before each commit, verify current HEAD and selected changes still match the plan, and review the actual staged diff against its assigned contents. Avoid rereading unrelated source or history. If contents differ or a commit fails, stop, report completed commits and remaining work, and obtain approval for any revised plan.
5. Check the resulting commit sequence and final Git status once. Confirm unrelated and omitted changes remain uncommitted and unrelated staging is preserved. Report created commits and the checks actually performed, without claiming compilation or device verification from static checks.
