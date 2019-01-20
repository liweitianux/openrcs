#!/bin/sh

if [ "$(uname -s)" = "Linux" ]; then
	MAKE="${MAKE:-bmake}"
else
	MAKE="${MAKE:-make}"
fi
LOG="${LOG:-${PWD}/regress.log}"

PROGS="ci co merge rcs rcsclean rcsdiff rcsmerge rlog"
ENVS=""
for p in ${PROGS}; do
	ln -sv ../rcs ${p}
	P=$(echo "${p}" | tr '[:lower:]' '[:upper:]')
	ENVS="${ENVS} ${P}=${PWD}/${p}"
done

echo "MAKE: ${MAKE}"
echo "ENVS: ${ENVS}"
echo "LOG: ${LOG}"

[ -f "${LOG}" ] && mv ${LOG} ${LOG}.old
env ${ENVS} ${MAKE} regress REGRESS_LOG=${LOG}

echo ""
echo "===================== RESULTS ====================="
cat ${LOG}

rm -v ${PROGS}
