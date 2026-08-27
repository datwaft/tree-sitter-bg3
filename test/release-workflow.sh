#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

# The workflow text checks intentionally use literal shell variable syntax.
workflow="${1:-.github/workflows/release.yml}"
ci_workflow="${2:-.github/workflows/ci.yml}"
release_validator="scripts/validate-github-release.sh"
stable_release_fixture="test/fixtures/github-release/stable.json"

test -f "$workflow"
test -f "$ci_workflow"
test -f "$release_validator"
test -f "$stable_release_fixture"

tag_regex="$(sed -n 's/^[[:space:]]*if \[\[ ! "\$TAG" =~ \(.*\) \]\]; then$/\1/p' "$workflow")"
test "$tag_regex" = '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'

for tag in v0.0.0 v1.2.3 v10.20.30; do
  [[ "$tag" =~ $tag_regex ]]
done

for tag in v01.2.3 v1.02.3 v1.2.03 v1.2 v1.2.3.4 release-1.2.3; do
  if [[ "$tag" =~ $tag_regex ]]; then
    echo "accepted invalid release tag: $tag" >&2
    exit 1
  fi
done

grep -Fq 'git cat-file -t "refs/tags/$TAG"' "$workflow"
grep -Fq 'if [[ "$tag_type" != tag ]]; then' "$workflow"
grep -Fq 'git merge-base --is-ancestor "$tag_commit" origin/main' "$workflow"
grep -Fq 'echo "tag_commit=$tag_commit" >> "$GITHUB_OUTPUT"' "$workflow"
grep -Fq 'git/ref/tags/$TAG' "$workflow"
grep -Fq 'git/tags/$remote_ref_sha' "$workflow"
grep -Fq 'releases/tags/$TAG' "$workflow"
grep -Fq 'source scripts/validate-github-release.sh' "$workflow"
grep -Fq 'validate_github_release "$release_json"' "$workflow"
grep -Fq 'target_commitish" != "$TAG_COMMIT" && "$target_commitish" != main' "$release_validator"
grep -Fq 'release is not a published stable release' "$release_validator"
grep -Fq -- '--generate-notes' "$workflow"
grep -Fq 'cancel-in-progress: false' "$workflow"
grep -Fq 'uses: ./.github/workflows/ci.yml' "$workflow"
grep -Fq 'workflow_call:' "$ci_workflow"
grep -Fq 'branches:' "$ci_workflow"
grep -Fq -- '- main' "$ci_workflow"

while IFS= read -r action; do
  if [[ ! "$action" =~ @[0-9a-f]{40}([[:space:]]|$) ]]; then
    echo "third-party action is not pinned to a full commit SHA: $action" >&2
    exit 1
  fi
done < <(grep -hE '^[[:space:]]*uses: [^.]+' "$workflow" "$ci_workflow")

TAG=v1.2.3 \
TAG_COMMIT=0123456789012345678901234567890123456789 \
  bash -c 'source "$1"; release_json="$(jq -c . "$2")"; validate_github_release "$release_json"' \
  bash "$release_validator" "$stable_release_fixture"
