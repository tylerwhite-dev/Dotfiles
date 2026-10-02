# Script setup guide

This directory contains the interactive Linux and macOS setup program for the
Dotfiles repository. The program asks for all choices first, shows a review
screen, and only then runs the selected procedures. The `--yolo` flag (`-y`)
answers `yes` to every question and skips the review screen, so every
procedure that needs no package selection runs without confirmation. Optional
package sets and casks are skipped, because they install only the packages a
run explicitly chooses.

The script requires bash 5 or newer. macOS ships bash 3.2 in `/bin/bash`, so run
it on macOS with a Homebrew bash, for example
`/opt/homebrew/bin/bash dotfiles-deploy.sh`; the entry point prints this
instruction when an older bash is used.

## Entry point and runtime flow

Run the script from any directory:

```bash
bash /path/to/Dotfiles/dotfiles-deploy.sh
```

The executable entry point at the repository root resolves to this `script/`
directory, `dotfiles-deploy.sh` loads `logic/load.sh`, parses CLI flags with
`flags_parse`, and calls `setup_run`.

The application flow is:

1. `flags_parse` records CLI flags such as `--yolo` and `--add-optionals`.
2. `ui_is_interactive` rejects non-interactive input and output unless `--yolo`
   is given, which skips the interactive requirement.
3. `catalog_validate` checks the declarations, handlers, dependencies, messages,
   platforms, and package references.
4. `environment_detect` maps `/etc/os-release` or `sw_vers` to `arch`,
   `debian`, `fedora`, or `macos`.
5. `questionnaire_collect` resets selections and asks one question per available
   procedure. It does not execute commands. In `--yolo` mode every available
   procedure that is not marked `procedure_selectable` is selected without
   prompting, and the skipped ones are listed through
   `status.yolo_skipped_optionals`. A procedure marked with
   `procedure_selectable` shows a checkbox list instead of a plain yes/no
   question, and records the chosen packages with `workflow_select_packages`.
   The list is grouped under the categories its package references name. A
   selectable procedure is the marker for an optional package set: `--yolo`
   never selects one, so an optional set needs either an interactive run or
   `--add-optionals`.
6. `questionnaire_confirm` renders the selected procedures and waits for
   `Start execution`, `Restart questionnaire`, or `Exit without changes`. In
   `--yolo` mode this step is skipped and execution starts immediately.
7. `runner_run` filters selected procedures and runs them in declaration order.
8. `process_run` adds privilege preparation, timeline rendering, output capture,
   and final status handling around each action.
9. `_app_print_elapsed_time` reports the duration measured from the execution
   confirmation, not from script startup.

## Directory layout

| Path | Responsibility |
| --- | --- |
| `dotfiles-deploy.sh` | Thin executable entry point at the repository root. |
| `config/settings.sh` | Retry counts, retry delay, and the Homebrew path. |
| `config/messages.sh` | All user-facing message templates, labels, and stage text. |
| `config/packages.sh` | Named package groups for native package managers and Homebrew. |
| `config/procedures.sh` | Declarative procedure records and their message keys. |
| `logic/load.sh` | Loads interfaces, implementations, declarations, actions, and the application in dependency order. |
| `logic/catalog.sh` | Stores and validates procedure and package declarations. |
| `logic/messages.sh` | Message-template registry and formatter. |
| `logic/flags.sh` | CLI flag parsing for `-y`/`--yolo`, `-a`/`--add-optionals`, and `-h`/`--help`. |
| `logic/environment.sh` | Linux and macOS system detection. |
| `logic/workflow.sh` | In-memory yes/no selections and dependency filtering. |
| `logic/questionnaire.sh` | Business flow for questions, summary, and final action choice. |
| `logic/process.sh` | Runs one action with plain or animated output and records its status. |
| `logic/runner.sh` | Orchestrates the selected procedures in catalog order. |
| `logic/executor.sh` | Command, privilege, retry, download, temporary-file, and Homebrew helpers. |
| `logic/actions/*.sh` | System-changing implementations for individual procedures. |
| `logic/errors.sh` | Converts message keys into error and status output through the UI. |
| `logic/app.sh` | Top-level application lifecycle and elapsed-time reporting. |
| `ui/theme.sh` | Color variables, timeline frames, and animation interval. |
| `ui/terminal.sh` | Terminal capability checks and low-level text output. |
| `ui/menu.sh` | Single-choice menu rendering and arrow-key input. |
| `ui/multiselect.sh` | Temporary-screen checkbox menus, columns, and selection input. |
| `ui/stage.sh` | Stage headings and review rows. |
| `ui/timeline.sh` | Active, finished, and captured-output timeline rows. |
| `ui/ui.sh` | UI entry point that sources the UI modules. |
| `tests/*.sh` | Shell checks for declarations, workflow rules, UI output, and layer rules. |

## Domain entities

### Procedure

A procedure is the unit shown in the questionnaire and executed by the runner.
The catalog stores its `id`, action handler name, supported platforms, optional
procedure requirement, root requirement, and package-group references. Its
question, label, and description live in the message registry under
`procedure.<id>.question`, `procedure.<id>.label`, and
`procedure.<id>.description`.

Declare procedures in `config/procedures.sh` with this order:

```bash
procedure_define example
procedure_handler example action_run_example
procedure_platforms example arch debian fedora macos
procedure_requires example other_procedure
procedure_requires_root example arch debian fedora
procedure_packages example native example_packages
```

Only the first three declarations are required. The procedure ID must be a
lowercase identifier. A requirement must refer to a procedure declared earlier;
when it is not selected, the dependent procedure is omitted from execution.
`procedure_requires_root` lists the platforms that need root privileges; a
procedure whose platforms are not listed runs without sudo.
`procedure_finish_handler` is optional. It runs only after the main handler
succeeds, with direct terminal output so interactive prompts remain visible.

### Package group

`package_group` stores a whitespace-separated list under a `source:group` key.
`native:arch`, `native:debian`, and `native:fedora` are platform-specific groups.
`@distribution` in a procedure package reference resolves to the current
platform. `catalog_packages` expands one procedure's references into an array
for an action.

### Package category

`package_category` names an ordered set of package groups under a
`source:category` key and gives it a display label. A procedure may reference a
category instead of a group, and the questionnaire then renders a grouped
checkbox list:

```bash
package_category brew extended "Dev tools" extended_dev_tools extended_terminal
procedure_packages homebrew_extended brew extended
```

Every member group must already be declared and must not be empty, because a
group row with no items would render as a row the cursor can reach but Space
cannot act on. A member must also be a group, not another category, and a
category name may not collide with a group name.

`catalog_package_rows` prepares presentation data as two parallel arrays: display rows
and row kinds, where `g` is a group row that owns the following `i` item rows.
`catalog_packages` still returns the flat package list, and the item rows always
match it in order, so grouping is a presentation concern only. References that
are plain groups appear under a fallback group labeled by the
`package_category_other` message. A procedure with no category references
produces a plain item list with no group rows. Loose groups remain in declaration
order: adjacent loose groups share one fallback heading, and a category ends
that run. A later loose group starts a new fallback heading.

Neither function de-duplicates: referencing the same group twice lists its
packages twice. Keep a procedure's references disjoint.

### Message template

`message_define` registers immutable text by key. `message_format` expands a
template with `printf` arguments into a caller-provided variable. Configuration
owns wording; logic chooses keys; UI only prints already-rendered text.

### Workflow selection

`_WORKFLOW_SELECTIONS` maps procedure IDs to `yes` or `no`. The questionnaire
resets it before each pass. `workflow_available` filters by platform, while
`workflow_selected` also requires a positive selection and a selected procedure
requirement.

A procedure marked with `procedure_selectable` records its per-package choices
in `_WORKFLOW_PACKAGE_SELECTIONS`. `workflow_select_packages` stores them and
`workflow_selected_packages` reads them back into an array. An action for a
selectable procedure must call `workflow_selected_packages` instead of
`catalog_packages` to install only the chosen packages. The questionnaire asks
for those packages with `ui_multiselect_grouped`, passing a caller-owned text
array prepared by `questionnaire_multiselect_texts`. It returns the checked
item rows only; group rows are never part of the result. The grouped menu has
no global `All` row. The checkbox menu uses a temporary screen and restores the
previous terminal view after confirmation.
On macOS, `homebrew_casks` uses the same selection UI and installs its selected
`brew_cask` packages through a direct-input finish handler.
On Linux, `flatpak_apps` installs a missing Flatpak CLI and configures system
Flathub in its main handler. The finish handler runs one
`flatpak install -y <ID>` per chosen application with direct terminal input
for authentication. Installation confirmations are accepted automatically.
Fedora's system `fedora` remote is deleted with `--force`, retaining installed
refs. Existing Flathub URLs and filters are validated before remote changes.
`--add-optionals` collects every available selectable procedure, shows a review,
prepares missing Homebrew only for selected formulae/casks, and calls
`runner_run_optionals`. This scenario satisfies manager prerequisites separately
instead of selecting the core Homebrew procedure. Ordinary workflow dependency
filtering remains unchanged. Empty optional selections make no system changes.
The macOS Command Line Tools check uses the same finish-handler mechanism before
Homebrew. It preserves a working selected Xcode or CLT; when installation is
needed, the operator completes Apple's dialog and presses Enter to verify.
Finder and Spaces are separate macOS-only procedures. Finder leaves the status
bar and hidden-file visibility unchanged; Spaces changes only `mru-spaces`.
Keyboard preferences and shortcut mappings are not modified.

### Command execution

`executor_run` prints and executes commands. `executor_resolve_command` finds
commands in PATH or the configured Homebrew bin directory, including before
shell startup files are loaded. `executor_temp_file` creates a temporary file.
Add shared command behavior to `logic/executor.sh`, not to individual actions.

### Process and timeline

`process_run` is the seam around one procedure action. It prepares sudo when the
procedure requires root and announces a password prompt when authentication is
needed. It then uses plain output for non-interactive execution
and a coprocess plus `ui_timeline_*` for interactive execution. An optional
finish handler runs in the parent process after the coprocess ends. A
successful process ends with `●`; a failure ends with `×`.

## Layer rules

- `config/` declares data through catalog and message interfaces. It must not
  call UI, workflow, executor, or system commands. A category label is
  display text passed to the UI as a row, so it belongs in
  `config/packages.sh` rather than in a message key.
- `ui/` renders values passed by callers. It must not know procedure IDs,
  package groups, workflow state, executors, or message keys.
  `catalog_package_rows` returns display rows and row kinds as parallel arrays;
  this is the catalog's presentation projection. The UI interprets the kinds
  without learning package sources, procedure IDs, or workflow state.
- `logic/` owns ordering, validation, selection, environment, and process
  behavior. It may call catalog, message, UI, and executor interfaces.
- `logic/actions/` owns system changes for one procedure. Actions receive
  `(platform, repository_dir)`, use catalog/executor helpers, and return a
  shell status. They do not format messages or render UI directly.
- `config/` owns user-facing text: shared messages in `messages.sh`, procedure
  text in `procedures.sh`, and category labels in `packages.sh`. Errors in
  actions should use `error_report <message-key>`.
- UI output variables and named inputs must be direct identifiers, not nameref
  aliases. The `__ui_` prefix is reserved for UI implementation variables.
  Catalog/workflow internals similarly use function-specific prefixes; callers
  must not use those internal names as outputs.
- Checkbox array roles must have different names. `ui_multiselect` takes
  `(result_name, prompt, texts_name, item...)`; `ui_multiselect_grouped` takes
  `(result_name, prompt, texts_name, rows_name, kinds_name)`.
- `texts_name` is an associative array with `all_label`, `status_format`,
  `navigation_hint`, and `resize_notice`. The status format receives four
  integers: first visible column, last visible column, total columns, selected
  item count. Configuration escapes conversions as `%%d` so `message_format`
  leaves `%d` for the widget. UI never reads message keys.
- Invalid checkbox input is rejected before opening the screen. Aliased role
  names return 1; empty lists, invalid names/types/rows return 2. Row arrays are
  dense indexed arrays of equal length, with g/i kinds and at least one item
  per heading. Outputs change only after confirmation. EOF returns 130;
  INT/TERM restore the screen and terminate with 130/143.
- Only one checkbox screen may be active. Reopening returns 2 without changing
  traps. Existing EXIT cleanup is preserved. Shared `_ui_*` terminal helpers
  are an internal support interface for widgets; other private helpers remain
  local to their module.
- Workflow stores package names as whitespace-separated text, so package names
  must not contain whitespace. Repeated names are preserved.

Keep interfaces narrow. When a new procedure is needed, add one declaration
block, its messages, its package groups if any, and one action file. Avoid
putting procedure-specific branching into the runner or UI.

## Function map

The source comments give the local contract for every function. The main
interfaces are grouped below for quick navigation.

- Catalog: `package_group`, `package_category`, `procedure_define`, `procedure_handler`,
  `procedure_finish_handler`,
  `procedure_platforms`, `procedure_requires`, `procedure_requires_root`,
  `procedure_selectable`, `procedure_packages`, `catalog_procedure_ids`,
  `catalog_handler`, `catalog_finish_handler`, `catalog_requirement`, `catalog_requires_root`,
  `catalog_is_selectable`, `catalog_is_available`, `catalog_packages`,
  `catalog_package_rows`, and
  `catalog_validate`.
- Messages: `message_define`, `message_format`, `message_exists`.
- Flags: `flags_parse`.
- Workflow: `workflow_reset`, `workflow_select`, `workflow_selection`,
  `workflow_requirement_is_selected`, `workflow_available`, `workflow_selected`,
  `workflow_available_optionals`, `workflow_selected_optionals`,
  `workflow_select_packages`, and `workflow_selected_packages`.
- Questionnaire and application: `questionnaire_collect`,
  `questionnaire_confirm`, `questionnaire_multiselect_texts`, `runner_run`,
  `runner_run_optionals`, `process_run`, and `setup_run`.
- Execution: `executor_run`, `executor_require`, `executor_resolve_command`, `executor_run_as_root`, `executor_retry`,
  `executor_retry_as_root`, `executor_prepare_privilege`, `executor_download`,
  `executor_temp_file`, `executor_brew`, `executor_brew_bin`,
  `executor_macos_developer_tools_ready`, and `executor_restart_macos_app`.
- UI: `ui_select`, `ui_multiselect`, `ui_multiselect_grouped`, `ui_stage`, `ui_summary_item`,
  `ui_summary_item_packages`, `ui_detail`,
  `ui_command`, `ui_success_line`, `ui_heading_line`, `ui_timeline_active`,
  `ui_timeline_output`, `ui_timeline_finished`, and `ui_ansi_palette`.
- Actions: `action_install_native_packages`, `action_install_homebrew`,
  `action_install_flatpak_binary`, `action_prepare_flatpak`, `action_install_flatpak_apps`,
  `action_install_homebrew_binary`, `action_install_homebrew_extended`, `action_prepare_homebrew_casks`,
  `action_install_homebrew_casks`, `action_set_zsh_default`,
  `action_prepare_macos_command_line_tools`, `action_install_macos_command_line_tools`,
  `action_configure_macos_finder`, `action_configure_macos_spaces`,
  `action_apply_dotfiles`, `action_install_yay`, and `action_install_yay_package`.

Private helpers start with `_` and stay within their module unless an internal
support interface or a public interface is intentionally introduced. Tests may
exercise internal helpers to check their contracts.

## Validation

The suite requires bash 5 and runs from the repository root. On macOS install
Homebrew bash first (`brew install bash`) and run it with
`/opt/homebrew/bin/bash`:

```bash
bash script/tests/config_validation.sh
bash script/tests/workflow.sh
bash script/tests/ui.sh
bash script/tests/layer_dependencies.sh
bash script/tests/app.sh
bash script/tests/process.sh
bash script/tests/macos.sh
bash script/tests/flatpak.sh
bash script/tests/optionals.sh
```

Use `bash -n` for syntax-only checks. Do not run `dotfiles-deploy.sh` without an explicit
choice and confirmation. Real actions can install packages, change the login
shell, download Homebrew, build `yay`, or create Stow links.
