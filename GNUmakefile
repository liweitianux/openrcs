PROG=	rcs

SRCS=	ci.c co.c ident.c merge.c rcsclean.c rcsdiff.c rcsmerge.c rcsparse.c \
	rcsprog.c rlog.c rcsutil.c buf.c diff.c diff3.c rcs.c rcsnum.c \
	rcstime.c worklist.c xmalloc.c
SRCS+=	date.c
OBJS=	$(SRCS:.c=.o)

CFLAGS?=-O -std=c99 -pedantic -D_GNU_SOURCE
CFLAGS+=-D__unused="__attribute__((unused))"
CFLAGS+=-Wall -Wextra
CFLAGS+=-Wduplicated-cond -Wduplicated-branches -Wlogical-op
CFLAGS+=-Wrestrict -Wnull-dereference -Wshadow -Wformat-security
CFLAGS+=-Wwrite-strings -Wcast-qual -Wcast-align
CFLAGS+=-Wredundant-decls
#CFLAGS+=-Wconversion
CFLAGS+=-fstrict-aliasing -Wstrict-aliasing

CFLAGS+=-I.
CFLAGS+=$(shell pkg-config --cflags libbsd-overlay)
LIBS?=	$(shell pkg-config --libs libbsd-overlay)

PREFIX?=/usr/local

MAN=	ci.1 co.1 ident.1 merge.1 rcs.1 rcsclean.1 rcsdiff.1 rcsmerge.1 rlog.1

LINKS=	rcs ci \
	rcs co \
	rcs ident \
	rcs merge \
	rcs rcsclean \
	rcs rcsdiff \
	rcs rcsmerge \
	rcs rlog

all: $(PROG)

$(PROG): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LIBS)

date.c: date.y
	yacc -o $@ $<

date: date.c xmalloc.c
	$(CC) $(CFLAGS) -DTEST -o $@ $^

clean:
	rm -f $(PROG) $(OBJS) date.c date

install:
	-mkdir -p $(PREFIX)/bin $(PREFIX)/share/man/man1
	cp $(PROG) $(PREFIX)/bin
	@set $(LINKS); \
	while test $$# -ge 2; do \
		l=$$1; shift; \
		t=$$1; shift; \
		ln -sfv $$l $$PREFIX/bin/$$t; \
	done; true
	@for f in $(MAN); do \
		cp -v $$f $(PREFIX)/share/man/man1; \
	done; true

test: $(PROG)
	cd regress; sh run-tests.sh

.PHONY: all clean install test
