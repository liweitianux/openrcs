#!/bin/sh
#
# Compare the modification time of two files.
#
# Usage: mtimecmp.sh <file1> <file2>
# Output:
# * 0 : two files have the same modification times;
# * 1 : <file1> is newer than <file2>
# * -1 : <file1> is older than <file2>
#

get_mtime() {
    local mtime
    if [ "$(uname -s)" = "Linux" ]; then
        mtime=$(stat -c '%Y' "$1") || exit 2
    else
        mtime=$(stat -f '%m' "$1") || exit 2
    fi
    echo ${mtime}
}

if [ $# -ne 2 ]; then
    echo "usage: ${0##*/} <file1> <file2>"
    exit 1
fi

mtime1=$(get_mtime $1) || exit $?
mtime2=$(get_mtime $2) || exit $?
if [ ${mtime1} -eq ${mtime2} ]; then
    echo "0"
elif [ ${mtime1} -gt ${mtime2} ]; then
    echo "1"
else
    echo "-1"
fi
