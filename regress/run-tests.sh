#!/bin/sh
#
# Regression tests for OpenRCS
# by Niall O'Higgins <niallo@openbsd.org>, Ray Lai <ray@cyth.net>.
#

PROGS="ci co merge rcs rcsclean rcsdiff rcsmerge rlog"
CI=${CI:-ci}
CO=${CO:-co}
MERGE=${MERGE:-merge}
RCS=${RCS:-rcs}
RCSCLEAN=${RCSCLEAN:-rcsclean}
RCSDIFF=${RCSDIFF:-rcsdiff}
RCSMERGE=${RCSMERGE:-rcsmerge}
RLOG=${RLOG:-rlog}

DIFF="${DIFF:-diff -u}"


#
# Helper functions
#

# cmp_file_perm <file> <mode_expected>
cmp_file_perm() {
    local mode
    if [ "$(uname -s)" = "Linux" ]; then
        mode=$(stat -c '%a' "$1")
    else
        mode=$(stat -f '%OLp' "$1")
    fi
    test "${mode}" = "$2"
}


#
# Tests
#

clean() {
    rm -rf \
        RCS blah.c blah.c,v description file1 file2 file3 \
        file file,v newfile newfile,v test test,v \
        test-truncated truncated.out foo foo,v bar bar,v
}

TESTS="
    ci_initial \
    ci_mflag \
    ci_lflag \
    ci_rflag \
    co_lflag \
    ci_rev \
    co_perm \
    co_perm2 \
    ci_perm \
    ci_perm2 \
    ci_dinvalid \
    ci_dold \
    ci_wflag \
    rcsdiff_uflag \
    rcsdiff_rflag \
    rcs_mflag \
    rcs_mflag2 \
    co_RCSINIT \
    ci_nflag \
    ci_Nflag \
    ci_sflag \
    co_lflag2 \
    rcsclean \
    rcsdiff \
    rcsdiff_symbols \
    merge_eflag \
    rcsmerge \
    rcsmerge_symbols \
    ci_dflag \
    ci_xflag \
    comma \
    rcs_aflag \
    rcs_eflag \
    rcs_Aflag \
    rcs_tflag_stdin \
    rcs_tflag_stdin2 \
    rcs_tflag_stdin3 \
    rcs_tflag_inline \
    rcs_tflag_file \
    rcs_oflag \
    rcs_lock_unlock \
    co_lock_filemodes \
    co_unlock_filemodes \
    ci_filemodes \
    rcs_iflag \
    rlog_lflag \
    rlog_rflag \
    rlog_zflag \
    ci_nofile \
    ci_revert \
    ci_keywords \
    ci_keywords2 \
    ci_parse_keywords \
    ci_parse_keywords2 \
    co_parse_truncated \
    ci_2files \
"

test_ci_initial() {
    echo 'this is a test file' > test
    echo "a test file" | ${CI} -q -l test
    grep -q 'this is a test file' test,v
}

# Testing 'ci test' with non-interactive log message
test_ci_mflag() {
    echo 'another revision' >> test
    ${CI} -q -m'a second revision' test
    test ! -e test &&
        grep -q 'another revision' test,v
}

# Testing 'co -l test'
test_ci_lflag() {
    ${CO} -q -l test
    test -e test
}

# Testing 'ci -r1.30 test' with non-interactive log message
test_ci_rflag() {
    echo "new stuff" >> test
    ${CI} -q -r1.30 -m'bumped rev' test
    test ! -e test
}

# Testing 'co -l test'
test_co_lflag() {
    ${CO} -q -l test
    test -e test
}

# Testing 'ci test' (should be rev 1.31) with non-interactive log message
test_ci_rev() {
    echo "a third revision" >> test
    ${CI} -q -m'this should be rev 1.31' test
    grep -q '1.31' test,v
}

# Testing 'co -u test' - ensuring permissions are 0444
test_co_perm() {
    ${CO} -q -u test
    cmp_file_perm test 444
}

# Testing 'co -l test' - ensuring permissions are 0644
test_co_perm2() {
    ${CO} -q -l test
    cmp_file_perm test 644
}

# Testing 'ci -u' - ensuring permissions are 0444
test_ci_perm() {
    echo "a line for ci -u" >> test
    ${CI} -q -m'message for ci -u' -u test
    cmp_file_perm test 444
}

# Testing 'ci -l' - ensuring permissions are 0644
test_ci_perm2() {
    ${CO} -q -l test
    echo "a line for ci -l" >> test
    ${CI} -q -m'message for ci -l' -l test
    cmp_file_perm test 644
}

# Testing ci with an invalid date
test_ci_dinvalid() {
    echo 'some text for invalid date text' >> test
    ${CI} -q -d'an invalid date' -m'invalid date' -l test && return 1 || true
    grep 'some text for invalid date text' test,v && return 1 || true
}

# Testing ci with a date older than previous revision
test_ci_dold() {
    echo 'some text for old date test' >> test
    ${CI} -q -d'1990-01-12 04:00:00+00' -m'old dated revision' -l test &&
        return 1 || true
    grep 'some text for old date test' test,v && return 1 || true
}

# Testing ci -wtestuser
test_ci_wflag() {
    rm -rf test
    ${CO} -q -l test
    echo "blah blah" >> test
    echo "output for ci -w" >> test
    ${CI} -q -wtestuser -mcomment -l test
    grep -q 'author testuser' test,v
}

# Testing 'rcsdiff -u test' after adding another line
test_rcsdiff_uflag() {
    echo "a line for rcsdiff test" >> test
    ${RCSDIFF} -q -u test | tail -n 5 |
        ${DIFF} rcsdiff-uflag.out -
}

# Testing 'rcsdiff -u -r1.2 test'
test_rcsdiff_rflag() {
    ${RCSDIFF} -q -u -r1.2 test | tail -n +3 |
        ${DIFF} rcsdiff-rflag.out -
}

# Testing 'rcs -m1.2:logmessage'
test_rcs_mflag() {
    ${RCS} -q -m1.2:logmessage test
    grep -q 'logmessage' test,v
}

# Testing 'rcs -m'1.2:a new log message''
test_rcs_mflag2() {
    ${RCS} -q -m1.1:'a new log message, one which is quite long and set by rcsprog' test
    grep -q 'a new log message, one which is quite long and set by rcsprog' test,v
}

# Testing RCSINIT environment variable
test_co_RCSINIT() {
    rm -rf test
    RCSINIT=-l ${CO} -q test
    cmp_file_perm test 644
}

# Testing check-in with symbol
test_ci_nflag() {
    echo "something to check in with a symbol" >> test
    ${CI} -q -n'symbolname' -m'test symbols' -l test
    grep -q 'symbolname' test,v
}

# Testing check-in, forcing symbol
test_ci_Nflag() {
    echo "something to check in with a forced symbol" >> test
    ${CI} -q -N'symbolname' -m'test force symbol' -l test
    grep -q 'test force symbol' test,v
}

# Trying some jiggerypokery with state
test_ci_sflag() {
    echo "blahblah" >> test
    ${CI} -q -l -s'SPACE S' -m"state with a space" test && return 1 || true
    grep -q 'SPACE S' test,v && return 1 || true
}

# Trying to check it out
test_co_lflag2() {
    rm -rf test
    ${CO} -q -l test
    test -e test
}

test_rcsclean() {
    touch file
    ${RCSCLEAN} -q file
    ${RCSCLEAN} -q1.1 file
    ${RCSCLEAN} -qsym file
    test -f file || return 1

    echo "." | ${CI} -q -nsym file
    ${CO} -q file
    ${RCSCLEAN} -q file
    test ! -f file || return 1
    ${CO} -q file
    ${RCSCLEAN} -q1.1 file
    test ! -f file || return 1
    ${CO} -q file
    ${RCSCLEAN} -qsym file
    test ! -f file || return 1

    ${CO} -q -l file
    ${RCSCLEAN} -q file
    test -f file || return 1
    ${RCSCLEAN} -q -u file
    test ! -f file || return 1
    ${CO} -q -l file
    echo "change" >> file
    ${RCSCLEAN} -q file
    ${RCSCLEAN} -q -u file
    test -f file || return 1
}

test_rcsdiff() {
    cp -f rev1 blah.c
    echo "descr" | ${CI} -q -l -m"first rev" blah.c
    cp -f rev2 blah.c
    ${CI} -q -l -m"second rev" blah.c
    cp -f rev3 blah.c
    ${CI} -q -l -m"third rev" blah.c

    ${RCSDIFF} -q -r1.1 -r1.3 -u blah.c | tail -n +3 |
        ${DIFF} rcsdiff.out -
}

test_rcsdiff_symbols() {
    mkdir RCS
    cp -f rev1 blah.c
    echo "descr" | ${CI} -q -l -nsym1 -m"first rev" blah.c
    cp -f rev2 blah.c
    ${CI} -q -l -nsym2 -m"second rev" blah.c
    cp -f rev3 blah.c
    ${CI} -q -l -nsym3 -m"third rev" blah.c

    ${RCSDIFF} -q -rsym1 -rsym3 -u blah.c | tail -n +3 |
        ${DIFF} rcsdiff.out -
}

test_merge_eflag() {
    printf "line1\nline2\nfile1new\n" > file1
    printf "line1\nline2\n" > file2
    printf "line1\nfile3new\nline2\n" > file3
    ${MERGE} -p -q -e file1 file2 file3 |
        ${DIFF} merge-eflag.out -
}

test_rcsmerge() {
    cp -f rev1 blah.c
    echo "descr" | ${CI} -q -l -m"first rev" blah.c
    cp -f rev2 blah.c
    ${CI} -q -l -m"second rev" blah.c
    cp -f rev3 blah.c
    ${CI} -q -l -m"third rev" blah.c

    ${RCSMERGE} -q -r1.1 -r1.3 -p blah.c |
        ${DIFF} rcsmerge.out -
}

test_rcsmerge_symbols() {
    clean
    mkdir RCS
    cp -f rev1 blah.c
    echo "descr" | ${CI} -q -l -nsym1 -m"first rev" blah.c
    cp -f rev2 blah.c
    ${CI} -q -l -nsym2 -m"second rev" blah.c
    cp -f rev3 blah.c
    ${CI} -q -l -nsym3 -m"third rev" blah.c

    ${RCSMERGE} -q -rsym1 -rsym3 -p blah.c |
        ${DIFF} rcsmerge.out -
}

# Testing 'ci -d'2037-01-12 04:00:00+00' -l test
test_ci_dflag() {
    clean
    echo "some text for date test" >> test
    echo "." | ${CI} -q -d'2037-01-12 04:00:00+00' -m'dated revision' -l test
    grep -q 'dated revision' test,v
}

test_ci_xflag() {
    mkdir RCS
    rm -rf RCS/file*
    touch file
    echo "." | ${CI} -q -x,abcd/,v file
    test -e RCS/file,abcd || return 1
    test ! -e RCS/file,v || return 1

    mv -f RCS/file,abcd RCS/file,v
    ${CO} -q -l file
    echo "revision" >> file
    echo "." | ${CI} -q -x,abcd/,v/xyz file
    test ! -e RCS/file,abcd || return 1
    fgrep -q revision RCS/file,v || return 1
    test ! -e RCS/filexyz || return 1

    touch file
    echo "more" >> file
    echo "." | ${CI} -q -x file
    fgrep -q more RCS/file || return 1
}

test_comma() {
    rm -rf RCS
    mkdir RCS
    touch file,notext
    echo "." | ${CI} -q file,notext
    test -e RCS/file,notext,v || return 1
    test ! -e RCS/file,v || return 1
}

# Testing 'rcs -afoo,bar,baz'
test_rcs_aflag() {
    clean
    echo "." | ${RCS} -q -i test
    ${RCS} -q -afoo,bar,baz test
    ${RLOG} test | ${DIFF} rcs-aflag.out -
}

# Testing 'rcs -efoo,bar,baz'
test_rcs_eflag() {
    clean
    test_rcs_aflag

    ${RCS} -q -efoo,bar,baz test
    ${RLOG} test | ${DIFF} rcs-eflag.out -
}

# Testing  'rcs -Atest newfile'
test_rcs_Aflag() {
    clean
    test_rcs_aflag

    echo "." | ${RCS} -q -i newfile
    ${RCS} -q -Atest newfile
    ${RLOG} newfile | ${DIFF} rcs-Aflag.out -
}

test_rcs_tflag_stdin() {
    clean
    echo 'This is a description.' | ${RCS} -q -i -t file
    fgrep -q 'This is a description.' file,v
}

test_rcs_tflag_stdin2() {
    clean
    echo '.This is not the description end.' | ${RCS} -q -i -t file
    fgrep -q '.This is not the description end.' file,v
}

test_rcs_tflag_stdin3() {
    clean
    printf "This is the description end.\n.\nThis should not be here.\n" |
        ${RCS} -q -i -t file
    fgrep -q 'This should not be here.' file,v && false || true
}

test_rcs_tflag_inline() {
    clean
    ${RCS} -q -i '-t-This is a description.' file
    fgrep -q 'This is a description.' file,v
}

test_rcs_tflag_file() {
    clean
    echo 'This is a description.' > description
    ${RCS} -q -i -tdescription file
    fgrep -q 'This is a description.' file,v
}

# Testing deletion of ranges
test_rcs_oflag() {
    clean
    cp -f rev3 blah.c
    echo "blah" | ${CI} -q blah.c
    ${CO} -q -l blah.c
    echo "blah2" >> blah.c
    echo "blah2" | ${CI} -q blah.c
    ${CO} -q -l blah.c
    echo "blah3" >> blah.c
    echo "blah3" | ${CI} -q blah.c
    ${CO} -q -l blah.c
    echo "blah4" >> blah.c
    echo "blah4" | ${CI} -q blah.c
    ${CO} -q -l blah.c
    echo "blah5" >> blah.c
    echo "blah5" | ${CI} -q blah.c
    ${CO} -q -l blah.c
    echo "blah6" >> blah.c
    echo "blah6" | ${CI} -q blah.c
    ${CO} -q -l blah.c
    ${RCS} -q -o1.3:1.5 blah.c
    tr '\n' ' ' < blah.c,v | grep -q '[[:space:]]1.3[[:space:]]' &&
        return 1 || true
    tr '\n' ' ' < blah.c,v | grep -q '[[:space:]]1.4[[:space:]]' &&
        return 1 || true
    tr '\n' ' ' < blah.c,v | grep -q '[[:space:]]1.5[[:space:]]' &&
        return 1 || true
}

test_rcs_lock_unlock() {
    clean
    mkdir RCS
    touch file
    echo "." | ${CI} -q -l file
    echo "sometext" > file
    echo "." | ${CI} -q file

    ${RCS} -q -l file
    ${RLOG} file | fgrep -x -A 1 'locks: strict' | head -n 2 | fgrep -q 1.2
    ${RCS} -q -u file
    ${RLOG} file | fgrep -x -A 1 'locks: strict' | head -n 2 | fgrep -q 1.2 &&
        return 1 || true

    ${RCS} -q -l1.1 file
    ${RLOG} file | fgrep -x -A 1 'locks: strict' | head -n 2 | fgrep -q 1.1
    ${RCS} -q -u1.1 file
    ${RLOG} file | fgrep -x -A 1 'locks: strict' | head -n 2 | fgrep -q 1.1 &&
        return 1 || true

    ${RCS} -q -l1.2 file
    ${RLOG} file | fgrep -x -A 1 'locks: strict' | head -n 2 | fgrep -q 1.2
    ${RCS} -q -u1.2 file
    ${RLOG} file | fgrep -x -A 1 'locks: strict' | head -n 2 | fgrep -q 1.2 &&
        return 1 || true

    ${RCS} -q -u file || return 1
    ${RCS} -q -l file || return 1
    ${RCS} -q -l file || return 1
    ${RCS} -q -l1.3 file && return 1 || true
    ${RCS} -q -u1.3 file && return 1 || true
}

# Testing 'co -l blah.c' for permissions inheritance
test_co_lock_filemodes() {
    mkdir RCS
    rm -rf RCS/blah.c,v blah.c
    cp -f rev3 blah.c
    chmod 444 blah.c
    echo "blah" | ${CI} -q blah.c
    chmod 755 RCS/blah.c,v
    ${CO} -q -l blah.c
    cmp_file_perm blah.c 755 || return 1

    rm -rf blah.c
    chmod 666 RCS/blah.c,v
    ${CO} -q -l blah.c
    cmp_file_perm blah.c 644 || return 1

    rm -rf blah.c
    chmod 600 RCS/blah.c,v
    ${CO} -q -l blah.c
    cmp_file_perm blah.c 600 || return 1

    rm -rf blah.c
    chmod 604 RCS/blah.c,v
    ${CO} -q -l blah.c
    cmp_file_perm blah.c 604 || return 1

    rm -rf blah.c
    chmod 754 RCS/blah.c,v
    ${CO} -q -l blah.c
    cmp_file_perm blah.c 754 || return 1
}

# Testing 'co -u blah.c' for permissions inheritance
test_co_unlock_filemodes() {
    mkdir RCS
    rm -rf RCS/blah.c,v blah.c
    cp -f rev3 blah.c
    echo "blah" | ${CI} -q blah.c
    chmod 755 RCS/blah.c,v
    ${CO} -q -u blah.c
    cmp_file_perm blah.c 555 || return 1

    rm -rf blah.c
    chmod 666 RCS/blah.c,v
    ${CO} -q -u blah.c
    cmp_file_perm blah.c 444 || return 1

    rm -rf blah.c
    chmod 600 RCS/blah.c,v
    ${CO} -q -u blah.c
    cmp_file_perm blah.c 400 || return 1

    rm -rf blah.c
    chmod 604 RCS/blah.c,v
    ${CO} -q -u blah.c
    cmp_file_perm blah.c 404 || return 1

    rm -rf blah.c
    chmod 754 RCS/blah.c,v
    ${CO} -q -u blah.c
    cmp_file_perm blah.c 554 || return 1
}

# Testing 'ci blah.c' for permissions inheritance
test_ci_filemodes() {
    mkdir RCS
    rm -rf RCS/blah.c,v blah.c
    cp -f rev3 blah.c
    chmod 755 blah.c
    echo "blah" | ${CI} -q blah.c
    cmp_file_perm RCS/blah.c,v 555 || return 1

    rm -rf RCS/blah.c,v blah.c
    cp -f rev3 blah.c
    chmod 666 blah.c
    echo "blah" | ${CI} -q blah.c
    cmp_file_perm RCS/blah.c,v 444 || return 1

    rm -rf RCS/blah.c,v blah.c
    cp -f rev3 blah.c
    chmod 700 blah.c
    echo "blah" | ${CI} -q blah.c
    cmp_file_perm RCS/blah.c,v 500 || return 1

    rm -rf RCS/blah.c,v blah.c
    cp -f rev3 blah.c
    chmod 606 blah.c
    echo "blah" | ${CI} -q blah.c
    cmp_file_perm RCS/blah.c,v 404 || return 1
}

# Test various operations on a file with no revisions.
test_rcs_iflag() {
    clean
    mkdir RCS
    echo "." | ${RCS} -i -q file
    test -f RCS/file,v || return 1
    ${CO} -q file
    test -f file || return 1
    test ! -s file || return 1
    rm -f file
    ${CO} -q -l file
    echo "text" >> file
    ${CI} -q file
    fgrep -q 1.1 RCS/file,v
}

test_rlog_lflag() {
    clean
    mkdir RCS
    touch file
    echo "rev1" | ${CI} -q -l file
    ${RLOG} -l file | fgrep -q 'revision 1.1' || return 1
    echo "line" >> file
    echo "rev2" | ${CI} -q file
    ${RLOG} -l file | fgrep -q 'revision 1.2' && false || true
}

# Test various cases for the -r flag
test_rlog_rflag() {
    clean
    touch file
    echo "foo" > file
    echo "descr" | ${CI} -q -m"first rev" -d'2006-01-01 00:00:00+00' -wfoo file
    ${CO} -q -l file
    echo "foo" >> file
    ${CI} -q -m"second rev" -d'2006-01-01 00:00:00+00' -wfoo file
    ${CO} -q -l file
    echo "foo" >> file
    ${CI} -q -m"third rev" -d'2006-01-01 00:00:00+00' -wfoo file

    ${RLOG} -r1.1     file | ${DIFF} rlog-rflag1.out - || return 1
    ${RLOG} -r1.1:1.3 file | ${DIFF} rlog-rflag2.out - || return 1
    ${RLOG} -r1.2:    file | ${DIFF} rlog-rflag3.out - || return 1
    ${RLOG} -r:1.1    file | ${DIFF} rlog-rflag4.out - || return 1
}

test_rlog_zflag() {
    clean
    touch file
    echo "descr" | ${CI} -q -m"first rev" -d'2006-01-01 00:00:00+00' -wfoo file
    ${RLOG} -zLT        file | ${DIFF} rlog-zflag1.out -
    ${RLOG} -z+03:14:23 file | ${DIFF} rlog-zflag2.out -
    ${RLOG} -z+03:14    file | ${DIFF} rlog-zflag3.out -
    ${RLOG} -z+0314     file | ${DIFF} rlog-zflag4.out -
    ${RLOG} -z-03:14:23 file | ${DIFF} rlog-zflag5.out -
}

test_ci_nofile() {
    ${CI} -q nonexistent && false || true
}

test_ci_revert() {
    clean
    mkdir RCS
    touch file
    echo "." | ${CI} -q -l file
    ${CI} -q -mm -l file || return 1
    # Make sure reverting doesn't unlock file.
    ${CI} -q -mm -l file
}

test_ci_keywords() {
    clean
    mkdir RCS
    sed 's/.*/$&$/' keywords.in > file
    sed 's/^[A-Z][A-Z]*[a-z][a-z]*: .*/$&$/' keywords.out > newfile
    echo "." | ${CI} -q -u file
    sed -e "s/\($[A-Z][a-z]*: \).*file,v/\1file,v/" \
        -e 's,[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9],YYYY/MM/DD HH:MI:SS,' \
        -e "s,${USER},USER," \
        file | ${DIFF} newfile -
}

# Lots of expansion.
test_ci_keywords2() {
    clean
    perl -e 'print "\$Id\$\n" x 10000;' > file
    echo "." | ${CI} -l -q file
}

test_ci_parse_keywords() {
    clean
    echo '$Id' > test
    echo "." | ${CI} -q -k test
}

test_ci_parse_keywords2() {
    clean
    echo '$Id: blah blah blah blah blah blah blah blah blah blah blah blah blah blah blah' > test
    echo "." | ${CI} -q -k test
}

# Check for correct EOF handling in rcs parser
test_co_parse_truncated() {
    clean
    (ulimit -d 5000 && ${CO} -q test-truncated > truncated.out 2>&1) &&
        return 1 || true
    grep -q 'co: could not parse admin data' truncated.out
}

test_ci_2files() {
    clean
    touch foo bar
    ${CI} -q -t-first -l foo
    test -f foo,v -a ! -f bar,v || return 1
    ${CI} -q -t-second -l foo bar
    test -f foo,v -a -f bar,v
}


#
# main
#

echo "Clean up ..."
clean
rm -f ${PROGS}

for p in ${PROGS}; do
    ln -sv ../rcs ${p}
done
export PATH=${PWD}:${PATH}

if [ $# -eq 0 ]; then
    set -- ${TESTS}
fi
N=$#
echo "Tests count: ${N}"

i=0
FAILED=""
while [ -n "$1" ]; do
    t="$1"; shift
    i=$((${i} + 1))
    echo ""
    echo "Running [${i}/${N}] test: ${t} ..."
    test_${t}
    if [ $? -eq 0 ]; then
        echo "SUCCESS"
    else
        echo "*** FAILED ***"
        FAILED="${FAILED} ${t}"
    fi
done

echo ""
echo "Clean up ..."
clean
rm -f ${PROGS}

FAILED="${FAILED## }"
if [ -n "${FAILED}" ]; then
    echo ""
    echo "*************"
    echo "Failed tests:"
    echo "*************"
    echo ${FAILED} | tr ' ' '\n' | nl
else
    echo "=== ALL SUCCEEDED ==="
fi
