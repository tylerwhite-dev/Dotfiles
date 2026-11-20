# Deploy command line

## Purpose

Define how `dotfiles-deploy.sh` accepts arguments, identifies the host and rejects unsupported invocations before asking setup questions.

## Requirements

### Requirement: Entry point and arguments

The script SHALL run with Bash 5 or newer and locate its deployment files relative to the script. It SHALL accept zero arguments or one supported flag. With no flag it SHALL use the standard questionnaire. Supported flags are `--server`, `--desktop`, `--wsl`, `--mac`, `--add-optionals` (alias `-a`) and `--help` (alias `-h`).

#### Scenario: Run from a different working directory

- **GIVEN** Bash 5 and the path to `dotfiles-deploy.sh`
- **WHEN** the script is invoked by that path from another directory without flags
- **THEN** it loads the repository's deployment configuration and uses standard mode

#### Scenario: Reject incorrect arguments

- **WHEN** the script receives an unrecognized flag or more than one argument, including a pair containing help
- **THEN** it reports the argument error, exits with status 2 and opens no questionnaire

#### Scenario: Display help without a terminal

- **GIVEN** Bash 5 or newer
- **WHEN** the script receives only `-h` or `--help`
- **THEN** it displays usage and exits with status 0 before the interactive setup checks

#### Scenario: Reject an older Bash

- **WHEN** the script runs under Bash older than 5
- **THEN** it reports the version requirement and exits with status 1 before processing flags

### Requirement: Startup checks

Before opening the questionnaire, the script SHALL require terminal input and output, validate the procedure catalog and identify macOS or an Arch, Debian, Ubuntu or Fedora family Linux system. On Linux it SHALL detect the family using the identifiers in `/etc/os-release`. Unsupported systems and failed startup checks SHALL terminate with status 1.

#### Scenario: Redirected output

- **WHEN** standard setup is invoked with standard output redirected away from a terminal
- **THEN** the script reports that an interactive terminal is required and exits before the questionnaire

#### Scenario: Invalid procedure order

- **GIVEN** an interactive terminal and a catalog that queues a dependent procedure ahead of its prerequisite
- **WHEN** the script starts setup
- **THEN** it reports an invalid configuration before asking any setup questions

### Requirement: Mode compatibility

The script SHALL accept `--server` and `--desktop` on supported Linux hosts outside WSL, `--wsl` on supported Linux hosts in WSL, and `--mac` on macOS. Standard and optional-package modes SHALL accept every supported host. WSL detection SHALL recognize a nonempty `WSL_DISTRO_NAME` or `WSL_INTEROP`, or a kernel release containing `microsoft` without regard to case.

#### Scenario: Run the WSL preset in Debian on WSL

- **GIVEN** a supported Debian environment with WSL detected
- **WHEN** the user invokes setup with `--wsl`
- **THEN** startup accepts the mode and proceeds to the WSL questionnaire

#### Scenario: Reject the desktop preset in WSL

- **GIVEN** a supported Linux environment with WSL detected
- **WHEN** the user invokes setup with `--desktop`
- **THEN** the script reports that the mode does not match the host and exits with status 1 before the questionnaire
