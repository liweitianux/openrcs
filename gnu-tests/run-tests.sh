#!/bin/sh
#
# Run the test suite of GNU RCS.
# by Aaron LI <aly@aaronly.me>
#

if [ -n "${BINDIR}" ]; then
    export PATHPREFIX=${BINDIR}
else
    PROGS="ci co merge rcs rcsclean rcsdiff rcsmerge rlog"
    mkdir -v bin
    for p in ${PROGS}; do
        ln -sv ../../rcs bin/${p}
    done
    export PATHPREFIX=${PWD}/bin
fi

export srcdir=${PWD}
export COMPONENTS=1
export VERBOSE=1

if [ ! -f "xorlf" ]; then
    echo "Build xorlf ..."
    ${CC:-cc} -Wall -o xorlf xorlf.c
fi

if [ $# -eq 0 ]; then
    TESTS=$(ls t???)
    set -- ${TESTS}
    TO_SKIP="t010 t030 t050 t151"
    echo "Tests to skip: ${TO_SKIP}"
else
    TO_SKIP=""
fi
N=$#
echo "Tests count: ${N}"

i=0
FAILED=""
SKIPPED=""

while [ -n "$1" ]; do
    t="$1"; shift
    i=$((${i} + 1))

    echo ""
    echo -n "Running [${i}/${N}] test: "
    head -n 1 ${t}
    if echo "${TO_SKIP}" | grep -qw "${t}"; then
        ret=77
    else
        sh ${t}
        ret=$?
    fi

    if [ ${ret} -eq 0 ]; then
        echo "SUCCESS [${t}]"
    elif [ ${ret} -eq 77 ]; then
        echo "... SKIPPED [${t}] ..."
        SKIPPED="${SKIPPED} ${t}"
    else
        echo "*** FAILED [${t}] ***"
        FAILED="${FAILED} ${t}"
    fi
done

SKIPPED="${SKIPPED## }"
if [ -n "${SKIPPED}" ]; then
    echo ""
    echo ".............."
    echo "Skipped tests:"
    echo ".............."
    echo ${SKIPPED} | tr ' ' '\n' | nl
fi

echo ""
FAILED="${FAILED## }"
if [ -n "${FAILED}" ]; then
    echo "*************"
    echo "Failed tests:"
    echo "*************"
    echo ${FAILED} | tr ' ' '\n' | nl
else
    echo "=== ALL SUCCEEDED ==="
fi
