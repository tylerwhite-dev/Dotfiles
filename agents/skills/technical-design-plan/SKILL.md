---
name: technical-design-plan
description: Write concrete implementation plans organized by source file, with exact classes, fields, method changes, short code bodies, and event ordering. Use when the user wants to review how code will be implemented before edits, or asks to replace a general plan with specific technical changes.
---

# Technical design plan

For code changes, produce a file-by-file implementation plan the user can review before edits. For other technical plans, choose a structure appropriate to the task instead of inventing files or code changes. Use technology-specific examples only when relevant to the task. Write in the user's language and use the repository's programming language in code fences.

The preferred result is a concise opening decision, numbered files with exact edits and short code excerpts, followed by event ordering. Show architecture through the placement of state, methods, and calls in real code. Avoid replacing this with an architecture essay, a behavior-only description, or a checklist of work phases.

## Scope and evidence

Read project instructions and inspect relevant method bodies, callers, state owners, initialization, and persistence paths before proposing edits. Use existing repository mechanisms where sufficient.

For a planning-only request, do not modify application code or start implementation. Preserve the session's permissions for checks, builds, installation, deployment, and commits. If implementation is already authorized, honor any agreed review checkpoint without requesting duplicate permission.

Show the plan inline. Save a separate plan file only when requested or required by the project.

Distinguish existing code from proposed additions. Verify existing symbols and source locations; never invent line numbers. Use clickable absolute file links where supported. Label proposed paths as new. When source is unavailable, label the plan provisional and identify missing evidence.

## Output format

### Opening decision

Start with one or two sentences giving the implementation choice and the relevant defaults or scope. For a persistence task, for example, name the storage mechanism, default value, and whether the setting is shared or per screen. Include only decisions relevant to the actual task.

Do not repeat the entire user request unless they ask for a request-and-plan document.

### Numbered files

Organize the main plan by file in the intended implementation order. For each file:

- Name the class, interface, function, or existing block being changed, and where the edit belongs.
- State the exact addition, replacement, removal, or visibility change. Give important new fields concrete names, types, and defaults.
- Show short code excerpts containing the key methods and meaningful bodies. Signatures alone are insufficient when the implementation mechanism is what the user needs to review.
- Explain why the change belongs there and how it uses existing dependencies, lifecycle, synchronization, or storage. Keep explanations adjacent to the code they justify.

Show relevant class or interface declarations when they are new or their contracts change. Include constructor dependencies and wiring for new objects. For an existing class, show only changed members and enough context to understand them, rather than the entire class.

Make consequential choices concrete: the variable holding a request ID, the owner of a coroutine, the predicate rejecting a late result, the lock protecting a write, or the function applying restored state. Explain race protection and error behavior where they matter.

Use separate language-tagged code fences for actual code. Keep paths, numbering, and explanations outside code fences. Do not put the entire prose plan in a Kotlin code fence.

Do not introduce classes, interfaces, repositories, wrappers, or patterns just to fill the format. Preserve a local fix as a local fix. If existing callers need no edits because their public contract stays the same, name them briefly after the file list instead of adding empty file sections.

### Event ordering

After the file list, show relevant execution sequences using concrete calls. For example:

- Startup: `settingsStore.load()` -> `controller.restore(saved)` -> `applyState()`.
- User action: update in-memory state -> capture the intended value -> persist it -> update the display, according to the actual selected design.

These are format examples, not prescribed algorithms. Explain deferred initialization, restoration racing with user input, cancellation, or late responses only when applicable. State who owns important state and when each check or side effect happens.

Use a Mermaid interaction diagram when explicitly requested, or when textual call sequences do not make the interaction clear. Do not require a diagram, type table, or separate architecture section for every small change. If included, participants and method messages must agree with the file list and code excerpts.

### Relevant limits and verification

Briefly mention compatibility behavior, intentional exceptions, and focused verification scenarios when they affect the proposal. For each substantial change, specify starting conditions, actions, and observable expected results, not just a test name. Give exact commands only when verified from the project. Place these near the relevant edit or in a short closing paragraph. Avoid boilerplate sections or speculative edge-case inventories.

Distinguish proposed checks from checks actually performed. Source inspection does not establish compilation, device behavior, or durability. Do not infer persistence or migration guarantees merely from a mutex, write barrier, library name, or default property. Trace the mechanism and state uncertainty when unverified.

If correctness depends on asynchronous ordering, inspect the actual serialization or queue. Capture values before asynchronous work when necessary and explain how write ordering is maintained. Do not copy sample code without checking its race behavior.

## Final review

Before returning the plan, check that:

- The file list and code excerpts explain how the requested behavior will be implemented.
- Important methods have concrete parameters, return types, and enough body detail to review the mechanism.
- State ownership, initialization, and calls between files agree with event ordering.
- Existing facts are grounded in inspected code, and proposals and uncertainties are clear.
- The response follows the file-by-file format without unnecessary architecture paperwork.

Resolve routine technical choices in the plan. If a missing fact could materially change the design, identify it and the narrow investigation needed to settle it.
