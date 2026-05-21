#!/usr/bin/env bash

# Extract the major segment from a semantic-ish version.
version_major() {
  local value=${1#v}

  echo "${value%%.*}"
}

# Return major when the major segment changes, minor otherwise.
version_bump() {
  local current=$1
  local next=$2

  if [ "$(version_major "$current")" = "$(version_major "$next")" ]; then
    echo minor
  else
    echo major
  fi
}

# Bump an image VERSION.
version_next() {
  local current=$1
  local bump=$2
  local major_version minor_version

  IFS=. read -r major_version minor_version <<< "$current"

  if [ "$bump" = major ]; then
    echo "$((major_version + 1)).0"
  else
    echo "${major_version}.$((minor_version + 1))"
  fi
}

# Read the current image VERSION from a Makefile.
image_current_version() {
  local path=$1

  awk -F':=' '$1 == "VERSION" { print $2; exit }' "$path"
}

# Rewrite a Makefile with the next image VERSION.
image_update_version() {
  local path=$1
  local next_version=$2

  awk -v version="$next_version" '
    BEGIN { updated = 0 }
    /^VERSION:=/ {
      print "VERSION:=" version
      updated = 1
      next
    }
    { print }
    END { if (!updated) exit 1 }
  ' "$path" > "$path.tmp"
  mv "$path.tmp" "$path"
}

# Escape a string for use in an extended regular expression.
version_regex_escape() {
  printf '%s\n' "$1" | sed -E 's/[][\/.^$*+?{}()|]/\\&/g'
}
