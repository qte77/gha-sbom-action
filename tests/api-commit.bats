#!/usr/bin/env bats
# Tests for scripts/api-commit.sh: commits staged files through the GitHub Git Data API
# (no local git commit/push, no author/committer), so GitHub signs the commit.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/api-commit.sh"
  WORK="$(mktemp -d)"
  export GH_LOG="$WORK/gh.log"
  mkdir -p "$WORK/bin"
  # Stub gh: log each call and its --input body, answer with canned JSON.
  cat > "$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
input=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  [[ "${args[$i]}" == "--input" ]] && input="${args[$((i + 1))]}"
done
echo "CALL $*" >> "$GH_LOG"
[[ -n "$input" ]] && { echo "BODY $(jq -c . "$input")" >> "$GH_LOG"; }
case "$*" in
  *git/commits/base123*) echo "basetree1" ;;
  *git/blobs*) echo "blob-$(jq -r '.content' "$input" | base64 -d | head -c 5)" ;;
  *git/trees*) echo "tree9" ;;
  *git/commits*) echo "commit7" ;;
  *git/refs*) echo "refs/heads/x" ;;
esac
STUB
  chmod +x "$WORK/bin/gh"
  export PATH="$WORK/bin:$PATH"
  cd "$WORK" && git init -q repo && cd repo
  git config user.name t && git config user.email t@example.com && git config commit.gpgsign false
  mkdir -p sbom && echo old > sbom/gone.json && echo keep > sbom/a.json
  git add . && git commit -q -m init
  echo alpha > sbom/a.json && echo bravo > sbom/new.json && git rm -q sbom/gone.json
  git add sbom/
}

teardown() { rm -rf "$WORK"; }

@test "prints the new commit sha and creates the branch ref at it" {
  run bash "$SCRIPT" owner/repo base123 auto/sbom-1 "docs: update SBOM"
  [ "$status" -eq 0 ]
  [ "$output" = "commit7" ]
  grep -q 'CALL api repos/owner/repo/git/refs -f ref=refs/heads/auto/sbom-1 -f sha=commit7' "$GH_LOG"
}

@test "commit body has message, tree and parent, and no author or committer" {
  run bash "$SCRIPT" owner/repo base123 auto/sbom-1 "docs: update SBOM"
  [ "$status" -eq 0 ]
  body=$(grep '^BODY {"message"' "$GH_LOG" | sed 's/^BODY //')
  [ "$(jq -r .message <<<"$body")" = "docs: update SBOM" ]
  [ "$(jq -r .tree <<<"$body")" = "tree9" ]
  [ "$(jq -c .parents <<<"$body")" = '["base123"]' ]
  [ "$(jq 'has("author") or has("committer")' <<<"$body")" = "false" ]
}

@test "tree has a blob per added or modified file and a null sha per deleted file" {
  run bash "$SCRIPT" owner/repo base123 auto/sbom-1 "docs: update SBOM"
  [ "$status" -eq 0 ]
  tree=$(grep '^BODY {"base_tree"' "$GH_LOG" | sed 's/^BODY //')
  [ "$(jq -r .base_tree <<<"$tree")" = "basetree1" ]
  [ "$(jq -r '.tree[] | select(.path=="sbom/a.json") | .sha' <<<"$tree")" = "blob-alpha" ]
  [ "$(jq -r '.tree[] | select(.path=="sbom/new.json") | .sha' <<<"$tree")" = "blob-bravo" ]
  [ "$(jq -r '.tree[] | select(.path=="sbom/gone.json") | .sha' <<<"$tree")" = "null" ]
}

@test "never runs a local git commit or push" {
  run bash "$SCRIPT" owner/repo base123 auto/sbom-1 "docs: update SBOM"
  [ "$status" -eq 0 ]
  [ "$(git rev-list --count HEAD)" = "1" ]
  ! grep -q 'push' "$GH_LOG"
}

@test "fails with usage when arguments are missing" {
  run bash "$SCRIPT" owner/repo
  [ "$status" -ne 0 ]
  [[ "$output" == *usage* ]]
}
