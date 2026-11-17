#!/usr/bin/env bats
# Tests for scripts/sbom-pr.sh: one SBOM PR per repo on a fixed branch, updated in place,
# then auto-merge (squash) with a direct-merge fallback; never fails the run on a merge miss.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/sbom-pr.sh"
  WORK="$(mktemp -d)"
  export GH_LOG="$WORK/gh.log"
  mkdir -p "$WORK/bin"
  # Stub gh: OPEN_PR_URL = an open PR for the head branch; AUTO_OK=1 = auto-merge allowed.
  cat > "$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "CALL $*" >> "$GH_LOG"
case "$1 $2" in
  "pr list") echo "${OPEN_PR_URL:-}" ;;
  "pr create") echo "https://github.com/owner/repo/pull/9" ;;
  "pr merge") [[ "${AUTO_OK:-1}" == 1 ]] || { echo "auto-merge is not allowed" >&2; exit 1; } ;;
  "api -X") [[ "${DIRECT_OK:-0}" == 1 ]] || { echo "HTTP 405" >&2; exit 1; } ;;
esac
STUB
  chmod +x "$WORK/bin/gh"
  export PATH="$WORK/bin:$PATH"
}

teardown() { rm -rf "$WORK"; }

@test "opens a PR when none is open for the branch and prints its URL" {
  run bash "$SCRIPT" owner/repo auto/sbom-update "docs: update SBOM" "body" true
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "https://github.com/owner/repo/pull/9" ]
  grep -q 'CALL pr create --repo owner/repo --base main --head auto/sbom-update' "$GH_LOG"
}

@test "reuses the open PR for the branch instead of opening another" {
  export OPEN_PR_URL="https://github.com/owner/repo/pull/5"
  run bash "$SCRIPT" owner/repo auto/sbom-update "docs: update SBOM" "body" true
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "https://github.com/owner/repo/pull/5" ]
  ! grep -q 'CALL pr create' "$GH_LOG"
}

@test "enables auto-merge (squash) on the PR" {
  run bash "$SCRIPT" owner/repo auto/sbom-update "docs: update SBOM" "body" true
  [ "$status" -eq 0 ]
  grep -q 'CALL pr merge https://github.com/owner/repo/pull/9 --repo owner/repo --auto --squash' "$GH_LOG"
}

@test "falls back to a direct squash merge when auto-merge is not available" {
  export AUTO_OK=0 DIRECT_OK=1
  run bash "$SCRIPT" owner/repo auto/sbom-update "docs: update SBOM" "body" true
  [ "$status" -eq 0 ]
  grep -q 'CALL api -X PUT repos/owner/repo/pulls/9/merge -f merge_method=squash' "$GH_LOG"
}

@test "leaves the PR open with a notice when neither merge works, without failing" {
  export AUTO_OK=0 DIRECT_OK=0
  run bash "$SCRIPT" owner/repo auto/sbom-update "docs: update SBOM" "body" true
  [ "$status" -eq 0 ]
  [[ "$output" == *"::notice::"* ]]
  [ "${lines[-1]}" = "https://github.com/owner/repo/pull/9" ]
}

@test "does not try to merge when auto_merge is false" {
  run bash "$SCRIPT" owner/repo auto/sbom-update "docs: update SBOM" "body" false
  [ "$status" -eq 0 ]
  ! grep -q 'CALL pr merge' "$GH_LOG"
  ! grep -q 'pulls/9/merge' "$GH_LOG"
}
