#!/bin/bash

function do_tests() {
    cd $1
    print_status $2 ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS
    cd ..
}

. ../common.bash core
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	(do_tests parser Parser)
	(do_tests seman Semantic)
	(do_tests visibility Visibility)

	TESTS=*.v3
fi

execute_tests
exit $?
