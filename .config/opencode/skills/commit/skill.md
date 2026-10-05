---
name: Commit
description: Prepare commit message for current changes
---

## Workflow

## Step 1: Analyze Changes
Upon receiving the diff, carefully examine all modified files and lines. Determine the nature of each change:
- Is it a new feature?
- Is it a bug fix?
- Is it refactoring without behavior change?
- Is it dependency or configuration updates?
- Are there changes in tests or documentation?

## Step 2: Grouping (Clustering)
Decide whether these changes need to be split into multiple separate commits.

**Split into multiple commits if:**
1. The diff mixes different types of changes (e.g., adding a new feature AND fixing an unrelated bug in another module).
2. There are independent logical blocks (e.g., updating CI/CD pipelines AND changing application business logic).
3. Changes affect different system components that can be deployed independently.

**Keep as a single commit if:**
1. All changes relate to one specific task/feature/bug.
2. Splitting would artificially complicate the history (e.g., minor style fixes within the same function where a bug was fixed).

## Step 3: Generate Messages
For each identified group, create a commit message following the [Conventional Commits](https://www.conventionalcommits.org/) standard:
`<type>(<scope>): <subject>`

**Rules for each message:**
- **Type**: feat, fix, docs, style, refactor, perf, test, chore, ci, build.
- **Scope**: Specific module/component (if applicable).
- **Subject**: Imperative mood ("add", "fix"), lowercase start, no trailing period, max 72 characters.
- **Body**: If the change is complex, briefly explain *why* it was done.
- **Language**: English.

## Step 4: Interactive Confirmation (CRITICAL!)
Do NOT execute git commands automatically. Instead, present your plan to the user in the following format:

---
**Proposed Commit Plan:**

**Commit 1:**
Type: `[type]([scope])`
Message: `[subject]`
Details: `[brief body description, if any]`
Files: `[list of files included in this commit]`

**Commit 2:**
(If second grouping exists)
...

---
**Action Confirmation:**

Choose an option:
1. **Yes, make the commits** — I will execute the commits myself according to the plan above.
2. **No, wait** — Do nothing. I want to modify the structure or provide feedback first.

*(Note: When the user selects "Yes", you must directly execute git commands to create the commits according to the approved plan.)*

# Example Input and Output

**Input (Diff):**
Changes in two unrelated places:
1. In `src/auth/login.ts`, a password validation error was fixed.
2. In `README.md`, Docker installation instructions were updated.

**Agent Output:**

---
**Proposed Commit Plan:**

Since the changes are logically unrelated (security vs. documentation), I propose splitting them into two commits.

**Commit 1:**
Type: `fix(auth)`
Message: fix password complexity check during login
Details: Previously, case sensitivity was ignored due to loose equality. Replaced with strict comparison.
Files: `src/auth/login.ts`

**Commit 2:**
Type: `docs(readme)`
Message: add quick start guide via Docker
Details: Simplifies onboarding for new developers.
Files: `README.md`

---
**Action Confirmation:**

Choose an option:
1. **Yes, make the commits**
2. **No, wait**
---

# Constraints & Nuances
1. NEVER combine `feat` and `fix` from different tasks into one commit unless they are part of a single atomic user story.
2. If the user chooses "No, wait", wait for further instructions. Do not guess the new structure yourself until you receive feedback.
3. If changes are minimal and obvious, you may suggest a single commit, but still ask for permission before executing.
4. The output format must be clear and easily readable. Use Markdown to highlight blocks.
5. When executing commits after confirmation, ensure proper escaping of quotes in the commit messages and verify each commit was created successfully.