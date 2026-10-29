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
- Follow explicit user instructions and repository commit conventions in project instructions, `CONTRIBUTING.md`, and commitlint configuration. If configured, locally installed, and allowed to run, validate the candidate with commitlint before presenting the plan; do not install it for this task. If no format is defined, use Conventional Commits: `<type>[optional scope]: <summary>`. Derive the type and summary from the diff. Common types include `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `style`, and `chore`.
- Scope is optional unless repository rules require it. Include task references in the location required by the repository; otherwise use an appropriate footer such as `Refs: #123`. Do not treat a task number as a mandatory scope.
- Add a body when it explains a non-obvious reason, constraint, or migration. Check for incompatibility in platform minimums, removed options, stricter configuration, and persisted formats. Mark it using the repository convention, or `!` and a `BREAKING CHANGE:` footer for Conventional Commits. Derive release effects from project tooling, not universal type-to-version assumptions.
- Write a short, specific summary using established project terminology. Follow the requested language and repository conventions; otherwise use the language of the task. Follow repository length rules; in their absence keep the subject concise without a trailing period.
- Choose the type that best describes the change and show it in the approval plan. Ask only when the ambiguity materially changes the intended commit or conflicts with repository rules.

## Create commits

1. Assign exact files or hunks to each commit and specify their order. Record base HEAD and retain a per-commit snapshot before requesting approval: assigned paths/hunks, resulting contents including binary data, additions/deletions, and Git file modes. Preserve unrelated changes and pre-existing staging; when changes share a file, include only the assigned hunks. If separation cannot preserve the user's staging, stop and explain the conflict before committing.
2. Before staging or committing, publish the ordered plan in a visible assistant message. For each commit, show the repository, exact message (including any body and footers), and assigned paths; describe selected hunks when a file is shared. A status such as "plan ready" is not a plan.
3. Only after publishing the plan, request confirmation through the harness's native user-input interface, or in conversation if unavailable. Offer explicit approve/cancel choices. The question must refer to the displayed plan and introduce no new contents. Wait for an explicit affirmative answer; cancellation, dismissal, or no answer grants no approval. Approval covers only that plan; changes require renewed approval.
4. After approval, create commits one at a time. Before each commit, verify the expected HEAD and compare the actual staged changes with the approved snapshot. Matching paths or passing `git diff --check` alone does not verify contents. Avoid rereading unrelated source or history. Pass the full message with real line breaks through `git commit -F` or separate `-m` arguments. Let configured hooks run; do not bypass them with `--no-verify` without explicit authorization or use `--amend` to recover from a failed commit. If contents differ, a hook changes files, or a commit fails, stop and report completed commits, any new diff, and remaining work. Do not auto-fix hook failures in commit-existing-changes mode; obtain approval for any revised plan before retrying.
5. Check the resulting commit sequence against approved snapshots and full messages, and check final Git status once. Verify paragraphs and footers contain real line breaks, not accidental literal `\n`. Confirm unrelated and omitted changes remain uncommitted and unrelated staging is preserved. Report created commits and the checks actually performed, without claiming compilation or device verification from static checks.
