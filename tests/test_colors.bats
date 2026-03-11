#!/usr/bin/env bats
# Tests for ANSI color and SGR functions in zutils.zsh

load test_helper

###############################################################
# get_sgr_color tests
###############################################################

@test "get_sgr_color returns 30 for black" {
    run get_sgr_color black
    [ "$status" -eq 0 ]
    [ "$output" = "30" ]
}

@test "get_sgr_color returns 31 for red" {
    run get_sgr_color red
    [ "$status" -eq 0 ]
    [ "$output" = "31" ]
}

@test "get_sgr_color returns 32 for green" {
    run get_sgr_color green
    [ "$status" -eq 0 ]
    [ "$output" = "32" ]
}

@test "get_sgr_color returns 33 for yellow" {
    run get_sgr_color yellow
    [ "$status" -eq 0 ]
    [ "$output" = "33" ]
}

@test "get_sgr_color returns 34 for blue" {
    run get_sgr_color blue
    [ "$status" -eq 0 ]
    [ "$output" = "34" ]
}

@test "get_sgr_color returns 35 for magenta" {
    run get_sgr_color magenta
    [ "$status" -eq 0 ]
    [ "$output" = "35" ]
}

@test "get_sgr_color returns 36 for cyan" {
    run get_sgr_color cyan
    [ "$status" -eq 0 ]
    [ "$output" = "36" ]
}

@test "get_sgr_color returns 37 for white" {
    run get_sgr_color white
    [ "$status" -eq 0 ]
    [ "$output" = "37" ]
}

@test "get_sgr_color returns 0 for reset" {
    run get_sgr_color reset
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

@test "get_sgr_color returns 1 for bold" {
    run get_sgr_color bold
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "get_sgr_color returns 4 for underline" {
    run get_sgr_color underline
    [ "$status" -eq 0 ]
    [ "$output" = "4" ]
}

@test "get_sgr_color returns unknown input as-is" {
    run get_sgr_color "42"
    [ "$status" -eq 0 ]
    [ "$output" = "42" ]
}

@test "get_sgr_color returns arbitrary string as-is" {
    run get_sgr_color "not_a_color"
    [ "$status" -eq 0 ]
    [ "$output" = "not_a_color" ]
}

###############################################################
# sgr tests
###############################################################

@test "sgr produces correct escape sequence for a single code" {
    result="$(sgr 32)"
    expected=$'\033[32m'
    [ "$result" = "$expected" ]
}

@test "sgr produces correct escape sequence for reset code" {
    result="$(sgr 0)"
    expected=$'\033[0m'
    [ "$result" = "$expected" ]
}

@test "sgr produces correct escape sequence for multiple codes" {
    # Multiple args are joined by space (IFS default) via ${codes[*]}
    result="$(sgr 32 1)"
    expected=$'\033[32 1m'
    [ "$result" = "$expected" ]
}

###############################################################
# colorize tests
###############################################################

@test "colorize wraps text with single color and reset" {
    result="$(colorize "hello" green)"
    # colorize calls sgr with the resolved code, then appends sgr reset
    expected=$'\033[32m'"hello"$'\033[0m'
    [ "$result" = "$expected" ]
}

@test "colorize wraps text with multiple color codes and reset" {
    result="$(colorize "warn" yellow bold)"
    # codes array becomes (33 1), passed as "${codes[*]}" = "33 1"
    expected=$'\033[33 1m'"warn"$'\033[0m'
    [ "$result" = "$expected" ]
}

@test "colorize with red produces correct output" {
    result="$(colorize "error" red)"
    expected=$'\033[31m'"error"$'\033[0m'
    [ "$result" = "$expected" ]
}

@test "colorize handles empty text" {
    result="$(colorize "" blue)"
    expected=$'\033[34m'""$'\033[0m'
    [ "$result" = "$expected" ]
}
