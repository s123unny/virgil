#/bin/bash

. ../common.bash gc

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(cat core.gc cast.gc variants.gc large.gc)
fi

function compile_gc_tests() {
    local SHARDING=100
    local target=$1
    shift

    RT_FILES="-rt.files=$(echo $OS_SOURCES $NATIVE_SOURCES $GC_SOURCES)"
    local i=1
    while [ $i -le $# ]; do
	local args=${@:$i:$SHARDING}
	run_v3c "" -output=$T -target=$target-test -rt.gc -rt.gctables -rt.test-gc -rt.sttables -set-exec=false -heap-size=10k "$RT_FILES" -multiple $args
	i=$(($i + $SHARDING))
    done
}

function do_int_test() {
    T=$OUT/$target
    mkdir -p $T
    ALL=$T/compile.all.out
    rm -f $ALL

    if [[ "$target" =~ "x86-64" ]]; then
        HEAP='-heap-size=66m' # 64-bit needs more heap
    else
        HEAP='-heap-size=32m'
    fi

    BEFORE=$V3C_OPTS
    V3C_OPTS="$V3C_OPTS $HEAP"
    QUIET_COMPILE=1
    compile_aeneas $AENEAS_TEST $OUT $target
    V3C_OPTS="$BEFORE"

    print_status Testing "$target $HEAP" Aeneas
    if [ -x $CONFIG/run-$target ]; then
	$T/Aeneas -test -ra $VIRGIL_LOC/test/core/*.v3 | tee $T/Aeneas-gc.test.out | $PROGRESS
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

function do_exe_test() {
    set_os_sources $target
    T=$OUT/$target
    mkdir -p $T
    C=$T/compile.out
    ALL=$T/compile.all.out
    rm -f $ALL

    print_compiling "$target" ""
    compile_gc_tests $target $TESTS | tee $T/compile.all.out | $PROGRESS

    execute_target_tests $target
}

for target in $TEST_TARGETS; do
    is_gc_target $target
    if [ $? = 0 ]; then
	do_exe_test
    fi
done

for target in $TEST_TARGETS; do
    is_gc_target $target
    if [ $? = 0 ]; then
	do_int_test
    fi
done
