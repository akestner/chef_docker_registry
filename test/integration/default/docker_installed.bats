#!/usr/bin/env bats

@test "docker binary is found in PATH" {
  run which docker
  [ "$status" -eq 0 ]
}
