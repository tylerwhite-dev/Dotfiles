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
`deploy/` directory for its logic, configuration, and UI.

See the [scenario map](specification/scenarios.md) for supported platforms,
mode compatibility, preset contents, package lists, selection defaults,
confirmation and cancellation behavior, and installation effects.

## Flags

Run without flags for the standard questionnaire, or use one of:

```bash
bash dotfiles-deploy.sh --server
bash dotfiles-deploy.sh --desktop
bash dotfiles-deploy.sh --wsl
bash dotfiles-deploy.sh --mac
bash dotfiles-deploy.sh --add-optionals  # short form: -a
bash dotfiles-deploy.sh --help          # short form: -h
```

Preset membership is configured in `config/scenarios.sh`; procedure availability
and order come from `config/procedure-order.sh` and the feature declarations.
See the [scenario map](specification/scenarios.md) for each mode's behavior.

On a clean Mac, prepare Command Line Tools, Homebrew, and Bash first. The setup
requires Bash 5 before any procedure can run, so its CLT procedure cannot
bootstrap the script from the system Bash 3.2.

## Layout

- `config/features/*.sh` contains one file per procedure. Each file owns its
  packages, categories, messages, handlers and procedure declarations.
- `config/procedure-order.sh` sets the enabled procedures and their order.
- `config/settings.sh` and `config/messages.sh` contain shared settings and
  shared UI/error messages.
- `logic/` controls the questionnaire, dependencies, execution order, processes,
  errors and environment detection. `logic/executor.sh` provides command,
  privilege, retry, download and Homebrew helpers.
- `ui/` renders values passed by callers. It does not read feature configurations.

## Adding a procedure

Create one file such as `config/features/example.sh`. Put its package
lists, categories, messages, handler functions and procedure declaration in
that file. Then add its procedure ID to `config/procedure-order.sh`.
No edit to `logic/` or `ui/` is needed.
See [config/README.md](config/README.md) for a complete example.

The loader discovers all `config/features/*.sh` in C lexicographic order.
Loading order does not control execution. The queue in `procedure-order.sh`
sets questionnaire and execution order. Remove or comment out an ID to disable
it in standard, named-scenario and optional flows. Omitted prerequisites disable their
dependants too. An empty queue runs nothing; unknown IDs, duplicates and a
queued prerequisite after its dependant are errors. Package groups must precede
categories that use them, and a procedure must precede its settings.

Feature loading only registers data and defines functions. Commands and system
checks belong inside handlers, which run after the user selects and confirms
procedures. Handlers receive `(platform, repository_dir)`, return a shell status,
and use executor helpers. They must not render UI or format messages. Use
`error_report` and `status_report` with messages defined in the same feature
file, or a shared message when several features use it.

`procedure_selectable` enables package checkboxes. Its handler reads
`workflow_selected_packages`; ordinary handlers read `catalog_packages`.
`procedure_installed_probe` reports the packages of a procedure that are
installed already, so the checkbox list starts with them marked.
`procedure_finish_handler` runs after a successful main handler with direct
terminal access for authentication and other input. Grouping changes only
presentation; the flat and grouped package lists retain declaration order.

Existing declarations and handler names remain available. Feature-specific
helpers can be reused by other features without duplicating their definition;
all files finish loading before handlers execute.

Validate declarations and dependency behavior with:

```bash
bash deploy/tests/config_validation.sh
bash deploy/tests/features.sh
bash deploy/tests/procedure_order.sh
bash deploy/tests/workflow.sh
bash deploy/tests/ui.sh
bash deploy/tests/layer_dependencies.sh
bash deploy/tests/flatpak.sh
bash deploy/tests/optionals.sh
```

## Manual UI tests

The interactive UI checks run in a real terminal (TTY). Each case renders the
component and lets you rate it: `[y] pass  [n] fail  [s] skip  [q] quit`.

```bash
bash deploy/tests/manual/static_ui.sh     # static elements: rendered output, no interaction
bash deploy/tests/manual/static_ui.sh ui_stage   # run one component
bash deploy/tests/manual/static_ui.sh --list     # list available components

bash deploy/tests/manual/dynamic_ui.sh    # dynamic elements: interactive controls
bash deploy/tests/manual/dynamic_ui.sh ui_select   # run one component
bash deploy/tests/manual/dynamic_ui.sh --list     # list available components
```

Static tests cover the stages, summary rows, and timeline rows. Dynamic tests
cover the menus the user can touch: yes/no questions, single-choice lists, and
checkbox lists. See `tests/README.md` for the full component list.
