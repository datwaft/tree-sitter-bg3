#!/usr/bin/env bash

validate_github_release() {
  local release_json="$1"
  local release_tag target_commitish draft prerelease

  release_tag="$(jq -r 'if ((.tag_name | type) == "string" and .tag_name != "") then .tag_name else error("missing tag_name") end' <<< "$release_json")"
  target_commitish="$(jq -r 'if (.target_commitish | type) == "string" then .target_commitish else error("missing target_commitish") end' <<< "$release_json")"
  draft="$(jq -r 'if (.draft | type) == "boolean" then (.draft | tostring) else error("missing draft") end' <<< "$release_json")"
  prerelease="$(jq -r 'if (.prerelease | type) == "boolean" then (.prerelease | tostring) else error("missing prerelease") end' <<< "$release_json")"

  if [[ "$release_tag" != "$TAG" ]]; then
    echo "Existing release has unexpected tag: $release_tag" >&2
    return 1
  fi
  if [[ -n "$target_commitish" && "$target_commitish" != "$TAG" && "$target_commitish" != "$TAG_COMMIT" && "$target_commitish" != main ]]; then
    echo "Existing release has unexpected target: $target_commitish" >&2
    return 1
  fi
  if [[ "$draft" != false || "$prerelease" != false ]]; then
    echo "Existing release is not a published stable release" >&2
    return 1
  fi
}
