#	$OpenBSD: Makefile,v 1.40 2010/10/15 08:44:12 tobias Exp $

PROG=	rcs

WARNS?=	6
CSTD?=	c99

PREFIX?=/usr/local
BINDIR=${PREFIX}/bin
SHAREDIR=${PREFIX}/share

CFLAGS+=-I${.CURDIR}
SRCS=	ci.c co.c ident.c merge.c rcsclean.c rcsdiff.c rcsmerge.c rcsparse.c \
	rcsprog.c rlog.c rcsutil.c buf.c date.y diff.c diff3.c rcs.c rcsnum.c \
	rcstime.c worklist.c xmalloc.c

MAN=	ci.1 co.1 ident.1 merge.1 rcs.1 rcsclean.1 rcsdiff.1 rcsmerge.1 rlog.1

LINKS=	${BINDIR}/rcs ${BINDIR}/ci \
	${BINDIR}/rcs ${BINDIR}/co \
	${BINDIR}/rcs ${BINDIR}/ident \
	${BINDIR}/rcs ${BINDIR}/merge \
	${BINDIR}/rcs ${BINDIR}/rcsclean \
	${BINDIR}/rcs ${BINDIR}/rcsdiff \
	${BINDIR}/rcs ${BINDIR}/rcsmerge \
	${BINDIR}/rcs ${BINDIR}/rlog

.include <bsd.prog.mk>

beforeinstall:
	-mkdir -p ${BINDIR} ${MANDIR}1

date: date.c xmalloc.c
	${CC} ${CFLAGS} -DTEST -o ${.TARGET} ${.ALLSRC}

test: ${PROG}
	cd regress; sh run-tests.sh
