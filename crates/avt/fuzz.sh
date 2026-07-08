#!/usr/bin/env bash

test=${1:-prop_}

export CARGO_PROFILE_TEST_OPT_LEVEL=3

while true
do
    PROPTEST_CASES=1000000 RUST_BACKTRACE=1 cargo test "$test"
    status=$?

    if [[ $status != 0 ]] ; then
        exit "$status"
    fi
done
