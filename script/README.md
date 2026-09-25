# Setup scripts

Run the interactive setup from any directory:

```bash
bash /path/to/Dotfiles/dotfiles-deploy.sh
```

The script requires bash 5 or newer. On macOS the system ships bash 3.2, so use
a Homebrew bash (`brew install bash`, then
`/opt/homebrew/bin/bash dotfiles-deploy.sh`); the entry point prints this
instruction otherwise.

The executable entry point lives at the repository root and loads this
`script/` directory for its logic, configuration, and UI.

The setup has two phases. The questionnaire records choices without changing the
system. Execution starts only after the user confirms the summary.
The final menu opens on `Start execution`; use the arrow keys to choose another
action.

## Flags

```bash
bash dotfiles-deploy.sh --yolo
```

- `--yolo` answers `yes` to every question and starts execution without the
  confirmation summary. All available procedures run automatically.
- `-h, --help` prints usage.

Any other flag exits with status 2 and an `Unknown flag` error.

## Layout

- `dotfiles-deploy.sh` (at the repository root) loads the application logic and
  calls `setup_run`. It parses CLI flags first.
- `config/` contains settings, messages, package groups, and procedure
  declarations. It does not render UI or execute system commands.
- `ui/` renders menus, stages, messages, commands, and the execution timeline.
  UI functions receive their text from callers and do not know about procedures.
- `logic/` controls the questionnaire, dependencies, execution order, processes,
  errors, and environment detection.
- `logic/actions/` contains the system changes for each procedure.
- `logic/executor.sh` prints and executes commands and provides privilege,
  retry, download, temporary-file, and Homebrew helpers.

The main dependency direction is `config -> declaration interfaces`,
`logic -> config interfaces and UI`, and `actions -> catalog and executor`.
Files under `ui/` never read configuration or call actions.

## Adding a procedure

Add a block to `config/procedures.sh`:

```bash
procedure_define example
procedure_handler example action_run_example
procedure_platforms example arch debian fedora macos
procedure_requires_root example arch debian fedora
procedure_packages example native example_packages
message_define procedure.example.question "Run the example?"
message_define procedure.example.label "Run the example"
message_define procedure.example.description "These packages will be installed:"
```

Only `procedure_define`, `procedure_handler`, and `procedure_platforms` are
required. Use `procedure_requires`, `procedure_requires_root` (lists the
platforms that need sudo), and `procedure_packages` when the procedure needs
them. Put package groups in `config/packages.sh`. Mark a procedure with
`procedure_selectable` to present its packages as a checkbox list and install
only the chosen items.

Add the action to a file under `logic/actions/`:

```bash
action_run_example() {
  local platform="$1"
  local repository_dir="$2"
  local -a packages=()

  catalog_packages packages example "$platform" native || return
  executor_run_as_root example-package-manager install "${packages[@]}"
}
```

Actions receive the platform and repository directory, return zero on success,
and use the executor functions for commands. The loader discovers every `*.sh`
file under `logic/actions/`. The catalog validates handlers, messages,
dependencies, platforms, and package references before the questionnaire starts.

Use `error_report` with a key from `config/messages.sh` instead of putting
user-facing text in an action. Use `executor_run`, `executor_run_as_root`,
`executor_retry`, `executor_retry_as_root`, `executor_download`, and
`executor_brew` so commands remain visible during execution.

Validate declarations and dependency behavior with:

```bash
bash script/tests/config_validation.sh
bash script/tests/workflow.sh
bash script/tests/ui.sh
bash script/tests/layer_dependencies.sh
```

## Manual UI tests

The interactive UI checks run in a real terminal (TTY). Each case renders the
component and lets you rate it: `[y] pass  [n] fail  [s] skip  [q] quit`.

```bash
bash script/tests/manual/static_ui.sh     # static elements: rendered output, no interaction
bash script/tests/manual/static_ui.sh ui_stage   # run one component
bash script/tests/manual/static_ui.sh --list     # list available components

bash script/tests/manual/dynamic_ui.sh    # dynamic elements: interactive controls
bash script/tests/manual/dynamic_ui.sh ui_select   # run one component
bash script/tests/manual/dynamic_ui.sh --list     # list available components
```

Static tests cover the stages, summary rows, and timeline rows. Dynamic tests
cover the menus the user can touch: yes/no questions, single-choice lists, and
checkbox lists. See `tests/README.md` for the full component list.
