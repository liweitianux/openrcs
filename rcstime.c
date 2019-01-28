/*	$OpenBSD: rcstime.c,v 1.6 2016/08/26 09:02:54 guenther Exp $	*/
/*
 * Copyright (c) 2006 Joris Vink <joris@openbsd.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL  DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <err.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#include "rcs.h"

static const char *parse_ranged(const char *, size_t, int, int, int *);
static bool parse_timezone(const char *, long *);


/*
 * Update the time info <tb>, which is a UTC time, according to the given
 * time zone <tz>.
 */
void
rcs_set_tz(const char *tz, struct tm *tb)
{
	time_t t;
	long offset;
	struct tm *ltb;

	t = timegm(tb);

	if (tz == NULL) {
		return;
	} else if (strcmp(tz, "LT") == 0) {
		ltb = localtime(&t);
		memcpy(tb, ltb, sizeof(*tb));
	} else {
		if (parse_timezone(tz, &offset) == false)
			errx(1, "%s: not a known time zone", tz);
		t += offset;
		ltb = gmtime(&t);
		ltb->tm_gmtoff = offset;
		memcpy(tb, ltb, sizeof(*tb));
	}
}

/*
 * Format the broken-down time <tb> to string in <buf>.
 */
char *
rcstime_tostr(const struct tm *tb, char *buf, size_t blen, bool iso_format)
{
	char sign;
	long zone;
	int non_hour;

	if (iso_format) {
		if (tb->tm_gmtoff >= 0) {
			sign = '+';
			zone = tb->tm_gmtoff;
		} else {
			sign = '-';
			zone = -tb->tm_gmtoff;
		}
		snprintf(buf, blen,
			 "%04d-%02d-%02d %02d:%02d:%02d%c%02d",
			 tb->tm_year + 1900,
			 tb->tm_mon + 1,
			 tb->tm_mday,
			 tb->tm_hour,
			 tb->tm_min,
			 tb->tm_sec,
			 sign,
			 (int)(zone / 3600));
		non_hour = zone % 3600;
		if (non_hour) {
			char tmp[8];
			snprintf(tmp, sizeof(tmp), ":%02d", non_hour/60);
			if (strlcat(buf, tmp, blen) >= blen)
				errx(1, "rcstime_tostr: string truncated");
		}
	} else {
		/*
		 * Traditional RCS format
		 */
		snprintf(buf, blen,
			 "%04d/%02d/%02d %02d:%02d:%02d",
			 tb->tm_year + 1900,
			 tb->tm_mon + 1,
			 tb->tm_mday,
			 tb->tm_hour,
			 tb->tm_min,
			 tb->tm_sec);
	}

	return buf;
}


static
const char *
parse_ranged(const char *s, size_t len, int min, int max, int *result)
{
	const char *end;
	int n;

	if (strlen(s) < len)
		return NULL;

	n = 0;
	end = s + len;
	while (s < end) {
		if (!isdigit((unsigned char)*s))
			return NULL;
		n = 10 * n + (*s - '0');
		s++;
	}

	if (n < min || n > max)
		return NULL;

	*result = n;
	return s;
}

/*
 * Parse the timezone in <s> and store the number of seconds east of UTC
 * in <result>.  Allowed timezone format is: (1) "LT", i.e., local time;
 * (2) "+hh[[:]mm]" or "-hh[[:]mm]".
 */
static
bool
parse_timezone(const char *s, long *result)
{
	int hh, mm;
	long offset;
	char sign;

	hh = mm = 0;
	if (*s != '+' && *s != '-')
		return false;
	sign = *s++;
	if ((s = parse_ranged(s, 2, 0, 23, &hh)) == NULL)
		return false;
	if (*s != '\0') {
		if (*s == ':')
			s++;
		if ((s = parse_ranged(s, 2, 0, 59, &mm)) == NULL)
			return false;
	}
	if (*s != '\0')
		return false;

	offset = hh * 3600L + mm * 60L;
	*result = (sign == '-') ? -offset : offset;
	return true;
}
