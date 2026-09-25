# Configuration

The four files here declare data. They do not render UI, run commands, or
contain logic — each file only calls the declaration interfaces listed in
`../AGENTS.md`. The catalog validates everything at startup, before the
questionnaire asks a single question.

| File | Declares |
| --- | --- |
| `settings.sh` | Plain shell variables: the Homebrew path, retry count, retry delay. |
| `messages.sh` | Every user-facing string, under `message_define <key> "<text>"`. |
| `packages.sh` | `package_group` lists and `package_category` sections. |
| `procedures.sh` | One block per procedure, plus the questions and labels for it. |

Keys in `messages.sh` are namespaced: `error.*`, `status.*`, `stage.*`,
`option.*`, `label.*`, `prompt.*`, `question.*`, `flags.*`, and the single
`package_category_other` fallback label. The per-procedure strings
(`procedure.<id>.question`, `.label`, `.description`) are declared next to the
procedure itself in `procedures.sh`, not here. Logic picks a key, the UI prints
what logic hands it.

## Adding a package to an existing section

The most common change. Add the name to the group; the category and the
procedure reference already point at that group.

```bash
package_group brew monitors \
  lazydocker nvtop tio btop      # btop is new
```

That single edit is enough. The package appears in the `Monitoring` section of
the checkbox list and in the flat list the action installs.

## Adding a new section

Three steps, in this order. The order is required: a category checks that its
member groups already exist, so it cannot be declared before them.

```bash
# 1. packages.sh — the group. It must not be empty to be a category member.
package_group brew network \
  mtr nmap

# 2. packages.sh — the category. Members are groups, never other categories.
package_category brew networking "Network" network
```

```bash
# 3. procedures.sh — the link from a procedure to the category.
procedure_packages homebrew_extended \
  brew dev_tools \
  brew terminal \
  brew monitoring \
  brew media \
  brew networking
```

Line order in `procedure_packages` is section order in the checkbox list, and
group order inside `package_category` is package order inside the section. Move
a line to move a section.

## Groups, categories, and links

| Entity | What it is |
| --- | --- |
| `package_group <source> <name> <pkg>...` | A plain list of package names under `source:name`. |
| `package_category <source> <name> "<Label>" <group>...` | A display label plus an ordered set of groups under `source:name`. |
| `procedure_packages <id> <source> <name> [<source> <name>...]` | The groups and categories one procedure installs, as space-separated pairs. |

A category never holds package names itself — packages always live in
groups, and a category only gathers groups under one label. The `<source>`
prefix is arbitrary and is what makes names unique: `brew` and `brew_cask` are
separate sources, and `procedure_packages` must use the same prefix the group
was declared with.

Note the two calling conventions, which are not the same. `package_group` and
`package_category` take `<source> <name>` as two separate arguments, and so does
`procedure_packages` — but every reference after the procedure ID is another
pair. Writing `brew:optional` instead of `brew optional` fails with
`must be provided in pairs` or leaves the name unresolved.

Groups and categories share one namespace per source. A name may not be declared
twice, and a group may not reuse a category name. A procedure may reference the
same name as either a group or a category — the catalog resolves it.

## What the questionnaire shows

Only procedures marked with `procedure_selectable` render a checkbox list.
Today that is `homebrew_extended` alone; every other procedure installs its
packages whole after a yes/no question.

That flag is what makes categories visible. A category referenced from a
non-selectable procedure still works — `catalog_packages` flattens it — but
the list is not drawn, so there is nothing to group on screen.

Selecting a section header toggles every package in that section, and the header
shows `[x]`, `[-]`, or `[ ]` depending on how many of its packages are marked.
`All` on the first row marks or clears every package. Group headers and `All`
are never part of the result — only package names are.

Grouping is presentation only. An action still calls `catalog_packages` and gets
one flat array, and the item rows always match that array in order.

In `--yolo` mode nothing is asked: every available package is selected
automatically, so new packages install without appearing in any list.

## Validation

The catalog validates itself on every run, and the same check runs standalone:

```bash
/opt/homebrew/bin/bash script/tests/config_validation.sh
```

Common errors and what they mean:

| Message | Cause |
| --- | --- |
| `must be provided in pairs` | `procedure_packages` got an odd number of arguments after the procedure ID. |
| `references an unknown package group: <source:name>` | A category or procedure names a group that was never declared, or still names a removed one. The key is reported as `source:name` even though the call passes two arguments. |
| `references an empty package group: <key>` | A category member has no packages. The section would be a row the cursor can reach but Space cannot act on. |
| `Package category declared more than once` | The same category name appears twice. |
| `Package group declared more than once` | The same group name appears twice. |
| `group name is already used by a category` | A group reuses a category name in the same source. |
| `category name is already used by a group` | The same collision in the other direction. |
| `needs a label` / `needs at least one package group` | A category was declared with an empty label or no members. |
| `has no question message` | A procedure block is missing one of its three `procedure.<id>.*` messages. |

## Pitfalls

- **No de-duplication.** If a procedure reaches the same group twice —
  directly and through a category — its packages are listed twice and
  installed twice. Keep a procedure's references disjoint.
- **Declaration order inside `packages.sh` is always groups first, categories
  second.** A category declared before one of its members is rejected.
- **Members must be groups, not categories.** Categories do not nest.
- **A category is referenced by its own name**, not by the groups it contains.

For procedures, actions, and the interfaces these declarations use, see
`../README.md` and `../AGENTS.md`.
