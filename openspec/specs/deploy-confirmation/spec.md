# Deploy review and confirmation

## Purpose

Define what setup may do before installation and how review, dependency prompts, restart, cancellation and interrupted input affect the run.

## Requirements

### Requirement: Review before changes

Setup SHALL collect choices and probe installed packages before making installation changes. It SHALL then display the procedure selections and the counts of packages to install, and offer Start, Restart and Exit. Optional-package mode SHALL finish successfully without review when there are no new packages to install.

#### Scenario: Exit from review

- **GIVEN** the review shows queued package installations and configuration changes
- **WHEN** the user selects Exit
- **THEN** setup exits successfully without installing packages or applying configuration changes

#### Scenario: Restart a named preset

- **GIVEN** the user changed package selections for a named preset
- **WHEN** the user selects Restart
- **THEN** setup starts the questionnaire again with selections recomputed from the preset, installed packages and current defaults

#### Scenario: Choose no new optional packages

- **WHEN** every optional checklist is confirmed with only installed packages checked or with nothing checked
- **THEN** setup reports "No optional packages were selected. Nothing to do." and exits with status 0 before review
- **AND** it neither prepares package managers nor displays elapsed execution time

### Requirement: Native dependency approval

After Start, setup SHALL prompt once per distinct applicable native dependency declared by selected procedures or packages. If the user declines a dependency, setup SHALL discard approvals from that round and offer return to review with selections preserved, restart, or exit. Installation SHALL begin only after the applicable confirmations succeed.

#### Scenario: Approve a shared build dependency once

- **GIVEN** an Arch setup that selects a missing yay and the `sdkman-cli` package
- **WHEN** the user starts from review
- **THEN** setup asks once to install `base-devel`

#### Scenario: Decline a dependency and go back to review

- **GIVEN** the user confirmed Start
- **WHEN** the user declines a native dependency and chooses to return to review
- **THEN** the procedure and package choices are still present
- **AND** no dependency has been installed and the next Start asks for approvals again

### Requirement: Missing Homebrew approval in optional mode

Optional-package setup SHALL ask for approval to install Homebrew if a selected procedure depends on Homebrew and the configured executable is missing. Declining SHALL restart the questionnaire. Selecting only native desktop packages or Flatpak apps SHALL require no Homebrew approval.

#### Scenario: Decline Homebrew installation

- **GIVEN** Homebrew is missing and an extended Homebrew package was selected in optional mode
- **WHEN** the user declines Homebrew after review and native dependency confirmation
- **THEN** setup restarts the optional questionnaire before making installation changes

### Requirement: Unreadable prompt response

Setup SHALL report interrupted input and exit with status 1 when a questionnaire, review or dependency confirmation prompt returns a read failure.

#### Scenario: Reach end of input at the review prompt

- **GIVEN** setup is waiting for Start, Restart or Exit
- **WHEN** the prompt reaches end of input before receiving a response
- **THEN** setup reports interrupted input and exits with status 1 before entering the execution stage

### Requirement: Signals during package selection

When a package checklist has opened the alternate terminal screen, setup SHALL restore the normal screen and cursor before exiting with status 130 on SIGINT or 143 on SIGTERM.

#### Scenario: Cancel an open package checklist

- **GIVEN** a package checklist is open on the alternate terminal screen
- **WHEN** the user presses Ctrl+C
- **THEN** setup restores the normal screen and cursor, and exits with status 130 before applying any selections

#### Scenario: Terminate an open package checklist

- **GIVEN** a package checklist is open on the alternate terminal screen
- **WHEN** the setup process receives SIGTERM
- **THEN** it restores the normal screen and cursor, and exits with status 143 before applying any selections
