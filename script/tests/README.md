# UI manual tests

## Automated tests (non-interactive)

The suite requires bash 5. Run from the repository root. On macOS install
Homebrew bash first (`brew install bash`) and run with
`/opt/homebrew/bin/bash`:

```bash
bash script/tests/config_validation.sh
bash script/tests/workflow.sh
bash script/tests/ui.sh
bash script/tests/layer_dependencies.sh
```

| Script | What it verifies |
| --- | --- |
| `config_validation.sh` | Procedure and package catalog declarations are valid. |
| `workflow.sh` | In-memory yes/no selection and dependency filtering rules. |
| `ui.sh` | UI output functions: detail text, single-choice menu, checkbox menu, stage headings, timeline rows. |
| `layer_dependencies.sh` | Layering rules — config/UI/logic must not depend on forbidden modules. |

## Manual UI tests (interactive)

Require a real terminal (TTY). Each case renders the component, then you rate it:

`[y] pass  [n] fail  [s] skip  [q] quit` — an empty Enter counts as `y`.

The tests are split into two parts: static elements (rendered output only) and
dynamic elements (interactive controls the user can touch).

### Part 1 — static: `static_ui.sh`

Static elements only draw output and never interact with the user.

```bash
bash script/tests/manual/static_ui.sh              # run all static tests
bash script/tests/manual/static_ui.sh ui_stage     # run one component
bash script/tests/manual/static_ui.sh --list       # list available components
```

| Component | What it checks |
| --- | --- |
| `ui_stage` | Stage heading, separator, metadata; empty and long values. |
| `ui_summary_item` | Summary row: ●/○ symbol, color, yes/no label. |
| `ui_summary_item_packages` | Package summary row: count `>0` vs `=0`, status. |
| `ui_timeline_active` | Active row: marker + `01/08` progress + label + timer; truncation and time format. |
| `ui_timeline_finished` | Final row: ● success / × failure, label, duration. |
| `ui_timeline_output` | Action output line (`│` + text); trimming on last `\r`. |

### Part 2 — dynamic: `dynamic_ui.sh`

Dynamic elements are interactive controls the user can touch: yes/no
questions, single-choice lists, checkbox lists.

```bash
bash script/tests/manual/dynamic_ui.sh             # run all dynamic tests
bash script/tests/manual/dynamic_ui.sh ui_select   # run one component
bash script/tests/manual/dynamic_ui.sh --list      # list available components
```

| Component | What it checks |
| --- | --- |
| `ui_select` | Single-choice menu: keyboard navigation, default highlight, detail text, the yes/no questionnaire question (2 options), many options, exit codes. |
| `ui_multiselect` | Checkbox list: Space toggle, All shortcut, count line, resulting selection, duplicates, exit codes. |

Note: the questionnaire's yes/no questions are not a separate element — they
are `ui_select` with two options (`Yes`/`No`), covered in the `ui_select` suite.

Dynamic tests are interactive by design: use arrow keys, Space, and Enter to
confirm a selection before rating the case.
