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
On macOS, the questionnaire also offers categorized Homebrew casks. Their
installation runs with direct terminal access so password prompts stay visible.
On Linux, a separate grouped list offers the 20 applications from
`guide/linux/flatpak.md`. Selecting none skips all Flatpak preparation.

The Flatpak procedure installs the CLI through pacman, APT or DNF if absent.
Before installing native packages or a missing Flatpak CLI on Fedora, the setup
disables `fedora-cisco-openh264` with
`dnf config-manager setopt fedora-cisco-openh264.enabled=0` as root.
If disabling the repository fails, the installation stops.
It adds the official system Flathub remote or enables an existing official
remote. An unexpected URL or a client-side filter stops the procedure for
manual review. On Fedora, it removes the system `fedora` remote with `--force`:
installed applications and runtimes remain, but stop receiving updates from
that remote. User remotes are unchanged.
Each selected application runs as `flatpak install -y <ID>` without sudo.
Installation confirmations are accepted automatically; terminal access remains
available for authentication if requested.

Three additional macOS-only questions check Apple Command Line Tools, configure
Finder, and disable automatic rearrangement of Spaces. The tools check comes
before Homebrew and preserves a working CLT or full Xcode selection. When tools
are missing, it opens Apple's installer: finish installation in the system
dialog, then press Enter to verify. An incomplete installation stops execution.
Homebrew installation also checks tools readiness if that question was skipped,
and requests administrator access before running its non-interactive installer.

The Finder profile shows all filename extensions and the path bar, keeps folders
first when sorting by name, searches the current folder, and opens new windows
in Home. It does not change the status bar or hidden-file visibility. The Spaces
profile only disables rearrangement by most recent use. Each profile restarts
its respective Finder or Dock process for the current user. Keyboard preferences
and shortcut mappings are not modified. These non-selectable procedures also
run in `--yolo`; installing missing tools still needs the system dialog and Enter.

The entry point still requires Bash 5 before any procedure can run. On a clean
Mac, prepare Command Line Tools, Homebrew and Bash first; the CLT procedure is
not a bootstrap replacement for the system Bash 3.2. The automated tests replace
macOS commands; verify the preferences on your target macOS version as well.

## Flags

```bash
bash dotfiles-deploy.sh -y
bash dotfiles-deploy.sh -a
```

- `-y`, `--yolo` answers `yes` to every question and starts execution without
  the confirmation summary. Every procedure that needs no package selection
  runs automatically; optional package sets and casks are skipped and listed as
  skipped, because they install only explicitly chosen packages.
- `-a`, `--add-optionals` asks for extended Homebrew formulae, then Flatpak apps
  on Linux or casks on macOS. It shows a review before executing the selection.
  Homebrew is prepared only if selected formulae or casks need it; selecting
  only Flatpak does not require Homebrew. Missing Homebrew is installed without
  the core formula/font set, after confirmation. On macOS this also checks
  Command Line Tools and opens Apple's installer if needed. Empty selections
  perform no preparation or installation.
- `-h`, `--help` prints usage.

Any other flag exits with status 2 and an `Unknown flag` error.

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
it in standard, YOLO and optional flows. Omitted prerequisites disable their
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
`procedure_finish_handler` runs after a successful main handler with direct
terminal access for authentication and other input. Grouping changes only
presentation; the flat and grouped package lists retain declaration order.

Existing declarations and handler names remain available. Feature-specific
helpers can be reused by other features without duplicating their definition;
all files finish loading before handlers execute.

Validate declarations and dependency behavior with:

```bash
bash script/tests/config_validation.sh
bash script/tests/features.sh
bash script/tests/procedure_order.sh
bash script/tests/workflow.sh
bash script/tests/ui.sh
bash script/tests/layer_dependencies.sh
bash script/tests/flatpak.sh
bash script/tests/optionals.sh
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
