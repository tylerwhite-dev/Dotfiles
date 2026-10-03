#!/usr/bin/env bash
set -Eeuo pipefail

script_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_dir="$(mktemp -d)"
trap 'rm -rf -- "$fixture_dir"' EXIT
cp -R "${script_root}" "${fixture_dir}/script"
fixture_loader="${fixture_dir}/script/logic/load.sh"
feature_dir="${fixture_dir}/script/config/features"

# One feature file owns the procedure; a queue entry explicitly enables it.
cat > "${feature_dir}/feature-fixture.sh" <<'FEATURE'
#!/usr/bin/env bash
package_group fixture feature_fixture alpha beta
package_category fixture feature_fixture_category "Fixture packages" feature_fixture
action_feature_fixture() {
  printf 'main:%s:%s\n' "$1" "$2" >> "$FEATURE_EVENTS"
}
action_feature_fixture_finish() {
  printf 'finish:%s:%s\n' "$1" "$2" >> "$FEATURE_EVENTS"
}
procedure_define feature_fixture
procedure_handler feature_fixture action_feature_fixture
procedure_finish_handler feature_fixture action_feature_fixture_finish
procedure_platforms feature_fixture fedora
procedure_requires feature_fixture dotfiles
procedure_selectable feature_fixture
procedure_packages feature_fixture fixture feature_fixture_category
message_define procedure.feature_fixture.question "Fixture?"
message_define procedure.feature_fixture.label "Fixture"
message_define procedure.feature_fixture.description "Fixture packages"
FEATURE

(
  source "$fixture_loader"
  catalog_validate
  ids=()
  catalog_procedure_ids ids
  [[ "${ids[*]}" != *feature_fixture* ]]
)
# Edit only the queue config to enable the automatically discovered feature.
sed '/^)/i\  feature_fixture' "${fixture_dir}/script/config/procedure-order.sh" > "${fixture_dir}/queue"
mv -- "${fixture_dir}/queue" "${fixture_dir}/script/config/procedure-order.sh"

(
  trap ':' ERR
  previous_trap="$(trap -p ERR)"
  source "$fixture_loader"
  [[ "$(trap -p ERR)" == "$previous_trap" ]]
  catalog_validate
  ids=()
  catalog_procedure_ids ids
  [[ "${ids[*]}" == 'native_packages yay zsh_default macos_command_line_tools macos_finder macos_spaces homebrew homebrew_extended flatpak_apps homebrew_casks dotfiles feature_fixture' ]]
  packages=(); rows=(); kinds=()
  catalog_packages packages feature_fixture fedora fixture
  catalog_package_rows rows kinds feature_fixture fedora fixture
  [[ "${packages[*]}" == 'alpha beta' ]]
  [[ "${rows[*]}" == 'Fixture packages alpha beta' ]]
  [[ "${kinds[*]}" == 'g i i' ]]
  workflow_reset
  workflow_select dotfiles yes
  workflow_select feature_fixture yes
  workflow_select_packages feature_fixture beta
  selected=()
  workflow_selected selected fedora
  [[ "${selected[*]}" == 'dotfiles feature_fixture' ]]
  workflow_selected_packages packages feature_fixture
  [[ "${packages[*]}" == beta ]]
  FEATURE_EVENTS="${fixture_dir}/events"
  process_run action_feature_fixture 1 1 Fixture no fedora /fixture/repository action_feature_fixture_finish > /dev/null
  [[ "$(cat "$FEATURE_EVENTS")" == $'main:fedora:/fixture/repository\nfinish:fedora:/fixture/repository' ]]
)

# The filename is reported even when errexit exits in the middle of source.
assert_load_failure() {
  local expected_status="$1" expected_message="$2" status=0
  bash -Eeuo pipefail -c 'source "$1"' bash "$fixture_loader" > "${fixture_dir}/error" 2>&1 || status=$?
  [[ "$status" == "$expected_status" ]]
  grep -F -- "$expected_message" "${fixture_dir}/error" > /dev/null
}

printf 'return 37\n' > "${feature_dir}/005-broken.sh"
assert_load_failure 37 "${feature_dir}/005-broken.sh"
printf 'procedure_define duplicate\nprocedure_define duplicate\nprintf unexpected-success\n' > "${feature_dir}/005-broken.sh"
assert_load_failure 1 "${feature_dir}/005-broken.sh"
if grep -F unexpected-success "${fixture_dir}/error" > /dev/null; then exit 1; fi
printf 'invalid(\n' > "${feature_dir}/005-broken.sh"
assert_load_failure 2 "${feature_dir}/005-broken.sh"
rm -- "${feature_dir}"/*.sh
assert_load_failure 1 'No setup feature configurations were found.'

printf 'Feature configuration validation passed.\n'
