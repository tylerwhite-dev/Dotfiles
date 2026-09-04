# Setup scripts

Run the interactive setup from any directory:

```bash
bash /path/to/Dotfiles/script/setup.sh
```

The setup has two phases. The questionnaire records choices without changing the
system. Execution starts only after the user confirms the summary.

## Layout

- `setup.sh` is the entry point.
- `config/steps.sh` declares questions, package groups, supported distributions,
  dependencies, and the execution function for each step.
- `lib/questionnaire.sh` collects and summarizes answers.
- `lib/execution.sh` runs selected steps and provides shared command, retry,
  download, privilege, and Homebrew helpers.
- `steps/*.sh` contains the implementation of each setup step.

## Changing a step

Edit its question or package groups in `config/steps.sh`. Edit its system changes
in the matching file under `steps/`. The execution function takes no arguments,
returns zero on success, and returns nonzero on failure. It can read
`distribution_family` and load declared packages with:

```bash
steps_load_step_packages step_id "$distribution_family" package_source
```

Use `execution_run`, `execution_run_as_root`, `execution_retry`, or
`execution_retry_as_root` for commands that change the system. These helpers make
the command visible before it runs and support dry runs.

To add a step, declare it in `config/steps.sh` and add a function with the declared
name to any file under `steps/`. The runner loads every `*.sh` file in that
directory and validates that each declared function exists before asking questions.

## Dry run

Set `SETUP_DRY_RUN=1` to print selected commands without executing them:

```bash
SETUP_DRY_RUN=1 bash script/setup.sh
```

Dry-run mode still shows the questionnaire and requires summary confirmation.

For a non-interactive execution check, run:

```bash
bash script/tests/execution_dry_run.sh fedora
bash script/tests/execution_dry_run.sh arch
bash script/tests/execution_dry_run.sh debian
```
