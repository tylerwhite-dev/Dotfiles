# Configuration

## Distribution-specific native desktop categories

`features/native-desktop.sh` owns the selectable `native_desktop` procedure.
It currently supports Arch only. Its package references use source `native`
and category names such as `native_desktop_@distribution_desktop`.
`@distribution` is substituted anywhere in a group or category name, so this
resolves to `native_desktop_arch_desktop` on Arch. The existing standalone
`native:@distribution` reference still resolves to `native:arch`.

To support another distribution, declare all three corresponding categories
and their package groups, extend `procedure_platforms`, and extend the default
package and installed-package functions for that distribution. The installed
probe currently reads the local Arch database with `pacman -Qq`; adding a
platform also requires selecting its probe behavior. Package installation uses
the shared native executor. Each supported platform's references are validated
before the questionnaire starts.

Desktop defaults live in the registered `native_desktop_default_packages`
handler, which returns additional packages only for `--desktop`. Standard and optional
mode start with installed packages alone. The procedure has no dependency on
Homebrew or the base native package procedure.

## Conditional package defaults

Register an optional handler after defining the procedure:

```bash
procedure_defaults_handler native_desktop native_desktop_default_packages
```

The handler receives `(result_array_name, platform, mode)`. It clears and fills
the caller's indexed array with additional packages to check in the menu. It
returns success with an empty array when its condition does not apply. Handlers
may read earlier procedure choices with `workflow_selection`, but must not change
workflow state, install packages, or render UI. Catalog validation rejects a
nonempty handler name unless it names an existing function.

Native desktop checks its platform and mode in its feature file. The Homebrew
extended handler checks the earlier `zsh_default` choice and uses its existing
base packages in that handler. The questionnaire has no procedure-specific default rules.
Keep procedures whose choices affect defaults earlier in `procedure-order.sh`;
the handler reads the selection already collected, without looking ahead.

`workflow_package_presets presets_result installed_result procedure_id platform
mode candidate...` performs installed-package detection, invokes the optional
defaults handler, and merges available candidates without duplicates. The two
outputs must be distinct direct array names outside its reserved
`__workflow_presets_` prefix. Presets contain installed candidates first and
additional defaults second; the installed output is kept separately to exclude
already installed packages from execution. Unknown defaults are ignored.
Both outputs are cleared at entry and published only after success. Return 1
means installed-package detection failed; return 2 means the defaults handler
failed. Either failure stops collection before the menu opens.

Both standard and optional collection use this function. Restart clears choices
and computes defaults again. Optional-only collection resets the Zsh choice, so
the Homebrew base defaults are not added in that mode.

## Procedure configuration

Each file in `features/` contains one complete procedure: package groups,
checkbox categories, messages, handler functions and declarations. Add or
extend a function by editing its feature file. To enable a new procedure,
add its ID to `procedure-order.sh`. No changes to `logic/` or `ui/` are needed.

`settings.sh` contains shared settings; `messages.sh` contains shared messages. `requirements.sh` maps named requirements to native packages or groups per distribution.

`procedure_ready_probe <id> <function>` optionally registers a read-only,
argument-free check. Return success when the procedure's target is already
installed, or failure when installation is needed. The workflow skips native
requirements of ready procedures before asking for approval. Other consumers
of the same requirement are still considered. The procedure handler remains
responsible for checking readiness again before installation.
Feature-specific errors and statuses belong in the owning feature file.

## Adding a feature

### Reading native requirements

Workflow reads requirement declarations through the catalog:

- `catalog_procedure_needs result_array_name procedure_id` returns the named
  requirements declared with `procedure_needs`, in declaration order.
- `catalog_package_needs result_array_name procedure_id platform package_id`
  returns requirements of that package only from resolved groups attached to
  the procedure. Sources remain separate, `@distribution` is expanded, and
  declarations retain their order and duplicates. Workflow deduplicates final needs. A missing package or
  declaration returns an empty array. Invalid references fail without publishing
  partial output. Use direct output array names outside each function's internal
  `__catalog_proc_needs_` or `__catalog_pkg_needs_` prefix.

`workflow_native_requirements` processes selected procedures in queue order,
skips ready procedures, and collects each procedure's needs before those of its
selected packages. Packages follow selection order; their needs follow catalog
declaration order. Only requirements mapped for the current platform enter the
confirmation list. A shared requirement appears once with its first consumer.
The workflow does not read the catalog's internal arrays.

Optional-only Homebrew preparation is determined by the selected procedures'
direct `procedure_requires ... homebrew` declarations. Adding another Homebrew
package procedure does not require adding its ID to application logic. This
does not introduce recursive dependency preparation for other procedures.

Package selection stores the package list and sets the procedure to yes for a nonempty list or no for an empty list. Workflow reset clears both selection maps. Absent entries read as `no` and an
empty package list, including entries for procedures removed from the queue.

### Feature example

Create `features/network-tools.sh`, for example:

```bash
#!/usr/bin/env bash

package_group native network_tools_packages curl wget

message_define error.network_tools_dnf_missing "DNF is required for network tools."

action_install_network_tools() {
  local platform="$1"
  local -a packages=()

  catalog_packages packages network_tools "$platform" native || return
  if ! command -v dnf >/dev/null 2>&1; then
    error_report error.network_tools_dnf_missing
    return 1
  fi
  executor_run_as_root \
    dnf config-manager setopt fedora-cisco-openh264.enabled=0 || return
  executor_retry_as_root "$SETUP_RETRY_ATTEMPTS" "$SETUP_RETRY_DELAY_SECONDS" \
    dnf install -y --refresh "${packages[@]}"
}

procedure_define network_tools
procedure_handler network_tools action_install_network_tools
procedure_platforms network_tools fedora
procedure_requires_root network_tools fedora
procedure_packages network_tools native network_tools_packages
message_define procedure.network_tools.question "Install network tools?"
message_define procedure.network_tools.label "Install network tools"
message_define procedure.network_tools.description "Install curl and wget."
```

The file is discovered automatically. Then put `network_tools` in the array in
`procedure-order.sh`, at the position where it should appear:

```bash
setup_procedure_order=(
  native_packages
  network_tools
  # yay
  homebrew
  homebrew_extended
  dotfiles
)
procedure_order "${setup_procedure_order[@]}"
unset setup_procedure_order
```

File names no longer need numeric prefixes. The array controls both the
questionnaire and execution. Remove or comment out an ID to disable it without
deleting its feature file. A file not listed in the queue is loaded and
validated, but its procedure is unavailable in standard, named-scenario and
`--add-optionals` workflows. An empty array enables no procedures.

Put a prerequisite before its dependant in the queue. If a prerequisite is
omitted, its dependants are omitted too, including transitive dependants.
Unknown IDs, duplicate IDs and prerequisites placed after their dependants
are configuration errors. Feature declaration order does not constrain
procedure dependencies. Group/category declaration order within a file still
applies. Use the procedure ID in new handler, group and message names because
all loaded files share their namespaces.

Top-level code only defines functions and calls declaration interfaces. It must
not run commands or inspect system state while loading. Put checks and steps
inside the handler. Add a step by editing that handler in the same file, using
`executor_run`, `executor_run_as_root` or retry helpers, and propagate failures
with `|| return` before starting the next step.

Handlers receive `(platform, repository_dir)`. Use `procedure_finish_handler`
for a second handler requiring direct terminal input after the main handler
succeeds. Both handlers belong in the same feature file. They may use
`error_report` and `status_report`, but must not call UI or `message_format`.
Shared helpers already provided by the executor remain available.

Only `procedure_define`, `procedure_handler`, `procedure_platforms` and the
three procedure messages are required. Packages, categories, requirements,
root requirements and finish handlers are optional. The catalog validates
all loaded declarations before the questionnaire starts.

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
# 1. In the feature file — the group. It must not be empty to be a category member.
package_group brew network \
  mtr nmap

# 2. In the same file — the category. Members are groups, never other categories.
package_category brew networking "Network" network
```

```bash
# 3. In the same file — the link from a procedure to the category.
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

## Display names for packages

Keep package IDs in groups and optionally declare a display alias in the same
feature file:

```bash
package_group flatpak internet org.telegram.desktop com.mattermost.Desktop
package_alias flatpak org.telegram.desktop "Telegram"
package_alias flatpak com.mattermost.Desktop "Mattermost"
```

`package_alias <source> <package_id> <label>` applies to every occurrence of
that ID under the specified source. Labels may contain spaces, but must be
nonblank single-line text without tabs. IDs must be nonempty and contain no
whitespace. A repeated alias declaration for the same source and ID is an error.
Different IDs may share a label. Without an alias the menu displays the ID.
Checkbox selection, installed-package presets, workflow state and installation
always use IDs. Aliases work for any package source, including Homebrew.

## Reporting packages that are installed already

A selectable procedure can tell which of its packages exist already, so the
checkbox list starts with those packages marked:

| Entity | What it is |
| --- | --- |
| `procedure_installed_probe <id> <function>` | Registers the probe of a procedure. |

The probe is a function in the same feature file:

```bash
homebrew_extended_installed_packages() {
  executor_brew_installed "$1" formula "${@:2}"
}

procedure_installed_probe homebrew_extended homebrew_extended_installed_packages
```

The probe receives the result array name first and the candidate packages after
it, and fills the array with the installed ones. Detected packages start checked
but are excluded from the installation selection. `homebrew_extended` checks
formulae, `homebrew_casks` checks casks. A procedure without a probe starts with
an empty selection. The probe name must be a plain identifier, and the function
must exist — the catalog rejects the configuration otherwise.

A successful empty result means nothing is installed. Missing Homebrew also
returns an empty result, allowing its installation after confirmation. If an
installed-package probe fails, its partial result is discarded and the
questionnaire stops with an error before opening the checkbox list or running
any procedures. Homebrew command diagnostics remain visible on stderr.

## What the questionnaire shows

Only procedures marked with `procedure_selectable` render a checkbox list.
The selectable procedures are `homebrew_extended`, `flatpak_apps` on Linux,
and `homebrew_casks` on macOS. Other procedures install their package sets after a yes/no question.

That flag is what makes categories visible. A category referenced from a
non-selectable procedure still works — `catalog_packages` flattens it — but
the list is not drawn, so there is nothing to group on screen.

Selecting a section header toggles every package in that section, and the header
shows `[x]`, `[-]`, or `[ ]` depending on how many of its packages are marked.
The grouped list has no global `All` row. A flat checkbox list retains `All`.
Headings and `All` are never part of the result; only package names are.

Grouping is presentation only. `catalog_packages` returns the complete flat
array, and item rows match it in declaration order. Selectable actions use
`workflow_selected_packages` to install only the chosen items. Ordinary groups
appear at their declared position under `Other` when categories are present;
adjacent ordinary groups share that heading, and later runs repeat it.

Packages that are installed already start marked, so the list shows what the
machine has and the operator only confirms the rest. Marked packages stay in the
result. The optional Homebrew formula and cask handlers pass them to `brew install`
with `HOMEBREW_NO_INSTALL_UPGRADE=1`, preventing automatic upgrades of packages
that are already installed. Installing new packages can still affect dependencies.
Clearing a checkbox excludes that package from installation; it does not uninstall it.

Optional packages are installed only when explicitly selected in an interactive
run or through `--add-optionals`.

## Validation

The catalog validates itself on every run, and the same check runs standalone:

```bash
/opt/homebrew/bin/bash deploy/tests/config_validation.sh
/opt/homebrew/bin/bash deploy/tests/features.sh
bash deploy/tests/procedure_order.sh
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
- **Declaration order inside each feature file is groups first, categories
  second.** A category declared before one of its members is rejected.
- **Members must be groups, not categories.** Categories do not nest.
- **A category is referenced by its own name**, not by the groups it contains.

For procedures, actions, and the interfaces these declarations use, see
`../README.md` and `../AGENTS.md`.

## Checkbox text

`ui.multiselect.*` messages provide the All label, status format, keyboard hint,
and small-terminal notice. Logic passes an associative text array to the widget.
The status message uses `%%d` conversions: message formatting produces literal
`%d` placeholders for the UI's four counters. UI does not read message keys.
