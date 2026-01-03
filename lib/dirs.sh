#!/usr/bin/env bash
# shellcheck disable=SC2034

readonly ruby=("$HOME/code/alexfalkowski.github.io" "$HOME/code/nonnative")
readonly go=("$HOME/code/go-service" "$HOME/code/go-signal" "$HOME/code/go-sync" "$HOME/code/gocovmerge" "$HOME/code/infraops" "$HOME/code/tausch" "$HOME/code/go-health")
readonly services=("$HOME/code/go-client-template" "$HOME/code/go-service-template" "$HOME/code/bezeichner" "$HOME/code/migrieren" "$HOME/code/standort" "$HOME/code/status" "$HOME/code/web" "$HOME/code/go-monolith")
readonly all=("${ruby[@]}" "${go[@]}" "${services[@]}")
