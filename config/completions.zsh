#!/usr/bin/env zsh

# afctl completion zsh supplies the checkout path before this script is sourced.
if ! (( $+functions[compdef] )); then
  autoload -Uz compinit
  compinit
fi

_afctl_skill_kinds() {
  local skill_dir
  local -a kinds

  for skill_dir in "$_afctl_completion_dir"/bin/skills/*(/N); do
    kinds+=("${skill_dir:t}")
  done

  _describe -t kinds 'skill kind' kinds
}

_afctl_ai_options() {
  local -a options

  case ${words[CURRENT - 1]} in
  -s | --scope)
    _files -/
    return
    ;;
  -f | --file)
    _files
    return
    ;;
  esac

  options=(-s --scope -c --confidence -e --effort --reasoning -f --file -a --auto --)
  compadd -a options
}

_afctl_ai() {
  local skill_dir
  local -a commands kinds

  case $CURRENT in
  3)
    commands=(codex claude ledger skills help)
    compadd -a commands
    return
    ;;
  esac

  case $words[3] in
  codex | claude)
    if (( CURRENT == 4 )); then
      kinds=(version)
      for skill_dir in "$_afctl_completion_dir"/bin/skills/*(/N); do
        kinds+=("${skill_dir:t}")
      done
      compadd -a kinds
      return
    fi

    [[ $words[4] == version ]] || _afctl_ai_options
    ;;
  ledger)
    if (( CURRENT == 4 )); then
      _afctl_skill_kinds
      return
    fi

    case ${words[CURRENT - 1]} in
    -s | --scope)
      _files -/
      ;;
    *)
      compadd -- -s --scope
      ;;
    esac
    ;;
  help)
    (( CURRENT == 4 )) && _afctl_skill_kinds
    ;;
  esac
}

_afctl_update() {
  case $CURRENT in
  3)
    _values 'directory set' ruby go services all
    ;;
  4)
    _values action latest purge dep clean done ci submodule
    ;;
  5)
    [[ $words[4] == submodule ]] && _values kind build docs feature fix refactor test
    ;;
  esac
}

_afctl_update_buf() {
  case $CURRENT in
  3)
    _values 'directory set' ruby go services all
    ;;
  4)
    _values action new done
    ;;
  5)
    [[ $words[4] == new ]] && _values kind build docs feature fix refactor test
    ;;
  esac
}

_afctl_update_ruby() {
  case $CURRENT in
  3)
    _values 'directory set' ruby services all
    ;;
  4)
    _values action new bundler done
    ;;
  5)
    case $words[4] in
    new)
      _values kind build docs feature fix refactor test
      ;;
    bundler)
      _message 'Bundler version'
      ;;
    esac
    ;;
  esac
}

_afctl_update_service() {
  case $CURRENT in
  3)
    _values action new done
    ;;
  4)
    [[ $words[3] == new ]] && _values kind build docs feature fix refactor test
    ;;
  5)
    [[ $words[3] == new ]] && _message 'go-service version'
    ;;
  esac
}

_afctl() {
  local command command_path
  local -a commands

  if (( CURRENT == 2 )); then
    commands=(completion help -h --help)
    for command_path in "$_afctl_completion_dir"/libexec/*(N); do
      [[ -x $command_path ]] && commands+=("${command_path:t}")
    done

    _describe -t commands 'afctl command' commands
    return
  fi

  command=$words[2]
  case $command in
  completion)
    (( CURRENT == 3 )) && _values shell zsh
    ;;
  ai)
    _afctl_ai
    ;;
  load)
    case $CURRENT in
    3) _values kind http grpc ;;
    4) _values service standort bezeichner ;;
    esac
    ;;
  update)
    _afctl_update
    ;;
  update-buf)
    _afctl_update_buf
    ;;
  update-ruby)
    _afctl_update_ruby
    ;;
  update-service)
    _afctl_update_service
    ;;
  update-buf-dep | update-ruby-dep | update-submodule)
    (( CURRENT == 3 )) && _values kind build docs feature fix refactor test
    ;;
  update-bundler | update-root)
    (( CURRENT == 3 )) && _message version
    ;;
  update-service-dep)
    case $CURRENT in
    3) _values kind build docs feature fix refactor test ;;
    4) _message 'go-service version' ;;
    esac
    ;;
  update-docker-dep)
    _message 'image kind, package, or version'
    ;;
  create-ci)
    (( CURRENT == 3 )) && _message 'repository name'
    ;;
  rotate-oauth-ci)
    case $CURRENT in
    3) _message 'CircleCI token' ;;
    4) _message 'project slug' ;;
    esac
    ;;
  esac
}

compdef _afctl afctl
