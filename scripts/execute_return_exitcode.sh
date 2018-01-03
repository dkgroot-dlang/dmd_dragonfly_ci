#!/usr/bin/env bash
trap 'echo -n SSH_REMOTE_EXIT_CODE=$?' INT TERM EXIT
set -e
$@
