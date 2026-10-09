#!/usr/bin/env bash
# shellcheck disable=SC2034

# Parse update workflow flags into update_no_pr and preserve positional arguments
# in update_args. A -- separator keeps subsequent arguments literal.
parse_update_args() {
  update_no_pr=false
  update_args=()

  while [ "$#" -gt 0 ]; do
    case $1 in
    --no-pr)
      update_no_pr=true
      ;;
    --)
      shift
      update_args+=("$@")
      break
      ;;
    *)
      update_args+=("$1")
      ;;
    esac
    shift
  done
}
