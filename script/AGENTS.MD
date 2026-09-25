# Script setup guide

This directory contains the interactive Linux and macOS setup program for the
Dotfiles repository. The program asks for all choices first, shows a review
screen, and only then runs the selected procedures. The `--yolo` flag
answers `yes` to every question and skips the review screen, so all available
procedures run without confirmation.

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
   procedure is selected without prompting. A procedure marked with
   `procedure_selectable` shows a checkbox list instead of a plain yes/no
   question, and records the chosen packages with `workflow_select_packages`.
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
| `logic/flags.sh` | CLI flag parsing for `--yolo`, `--add-optionals`, and `--help`. |
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
| `ui/menu.sh` | Keyboard menu rendering and arrow-key input. |
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

### Package group

`package_group` stores a whitespace-separated list under a `source:group` key.
`native:arch`, `native:debian`, and `native:fedora` are platform-specific groups.
`@distribution` in a procedure package reference resolves to the current
platform. `catalog_packages` expands one procedure's references into an array
for an action.

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
in `_WORKFLOW_PACKAGE_SELECTIONS`. `workflow_select_packages` stores them,
`workflow_selected_packages` reads them back into an array, and
`workflow_select_packages_all` selects every available package for the
non-interactive `--yolo` path. An action for a selectable procedure must call
`workflow_selected_packages` instead of `catalog_packages` to install only the
chosen packages.

### Command execution

`executor_run` prints and executes commands. `executor_temp_file` creates a
temporary file. Add shared command behavior to `logic/executor.sh`, not to
individual actions.

### Process and timeline

`process_run` is the seam around one procedure action. It prepares sudo when the
procedure requires root, then uses plain output for non-interactive execution
and a coprocess plus `ui_timeline_*` for interactive execution. A
successful process ends with `●`; a failure ends with `×`.

## Layer rules

- `config/` declares data through catalog and message interfaces. It must not
  call UI, workflow, executor, or system commands.
- `ui/` renders values passed by callers. It must not know procedure IDs,
  package groups, workflow state, executors, or message keys.
- `logic/` owns ordering, validation, selection, environment, and process
  behavior. It may call catalog, message, UI, and executor interfaces.
- `logic/actions/` owns system changes for one procedure. Actions receive
  `(platform, repository_dir)`, use catalog/executor helpers, and return a
  shell status. They do not format messages or render UI directly.
- `config/messages.sh` is the only place for user-facing setup text. Errors in
  actions should use `error_report <message-key>`.

Keep interfaces narrow. When a new procedure is needed, add one declaration
block, its messages, its package groups if any, and one action file. Avoid
putting procedure-specific branching into the runner or UI.

## Function map

The source comments give the local contract for every function. The main
interfaces are grouped below for quick navigation.

- Catalog: `package_group`, `procedure_define`, `procedure_handler`,
  `procedure_platforms`, `procedure_requires`, `procedure_requires_root`,
  `procedure_selectable`, `procedure_packages`, `catalog_procedure_ids`,
  `catalog_handler`, `catalog_requirement`, `catalog_requires_root`,
  `catalog_is_selectable`, `catalog_is_available`, `catalog_packages`, and
  `catalog_validate`.
- Messages: `message_define`, `message_format`, `message_exists`.
- Flags: `flags_parse`.
- Workflow: `workflow_reset`, `workflow_select`, `workflow_selection`,
  `workflow_requirement_is_selected`, `workflow_available`, `workflow_selected`,
  `workflow_select_packages`, `workflow_selected_packages`, and
  `workflow_select_packages_all`.
- Questionnaire and application: `questionnaire_collect`,
  `questionnaire_confirm`, `runner_run`, `process_run`, and `setup_run`.
- Execution: `executor_run`, `executor_require`, `executor_run_as_root`, `executor_retry`,
  `executor_retry_as_root`, `executor_prepare_privilege`, `executor_download`,
  `executor_temp_file`, `executor_brew`, and `executor_brew_bin`.
- UI: `ui_select`, `ui_multiselect`, `ui_stage`, `ui_summary_item`,
  `ui_summary_item_packages`, `ui_detail`,
  `ui_command`, `ui_success_line`, `ui_heading_line`, `ui_timeline_active`,
  `ui_timeline_output`, `ui_timeline_finished`, and `ui_ansi_palette`.
- Actions: `action_install_native_packages`, `action_install_homebrew`,
  `action_install_homebrew_extended`, `action_set_zsh_default`,
  `action_apply_dotfiles`, and `action_install_yay`.

Private helpers start with `_` and should stay within their module unless a
stable interface is intentionally introduced.

## Validation

The suite requires bash 5 and runs from the repository root. On macOS install
Homebrew bash first (`brew install bash`) and run it with
`/opt/homebrew/bin/bash`:

```bash
bash script/tests/config_validation.sh
bash script/tests/workflow.sh
bash script/tests/ui.sh
bash script/tests/layer_dependencies.sh
```

Use `bash -n` for syntax-only checks. Do not run `dotfiles-deploy.sh` without an explicit
choice and confirmation. Real actions can install packages, change the login
shell, download Homebrew, build `yay`, or create Stow links.
