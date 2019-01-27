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
#include <string.h>
#include <time.h>

#include "rcs.h"

void
rcs_set_tz(char *tz, struct rcs_delta *rdp, struct tm *tb)
{
	int tzone;
	int pos;
	char *h, *m;
	const char *errstr;
	struct tm *ltb;
	time_t now;

	if (!strcmp(tz, "LT")) {
		now = mktime(&rdp->rd_date);
		ltb = localtime(&now);
		ltb->tm_hour += ((int)ltb->tm_gmtoff/3600);
		memcpy(tb, ltb, sizeof(*tb));
	} else {
		pos = 0;
		switch (*tz) {
		case '-':
			break;
		case '+':
			pos = 1;
			break;
		default:
			errx(1, "%s: not a known time zone", tz);
		}

		h = (tz + 1);
		if ((m = strrchr(tz, ':')) != NULL)
			*(m++) = '\0';

		memcpy(tb, &rdp->rd_date, sizeof(*tb));

		tzone = strtonum(h, -23, 23, &errstr);
		if (errstr)
			errx(1, "%s: not a known time zone", tz);

		if (pos) {
			tb->tm_hour += tzone;
			tb->tm_gmtoff += (tzone * 3600);
		} else {
			tb->tm_hour -= tzone;
			tb->tm_gmtoff -= (tzone * 3600);
		}

		if ((tb->tm_hour >= 24) || (tb->tm_hour <= -24))
			tb->tm_hour = 0;

		if (m != NULL) {
			tzone = strtonum(m, 0, 59, &errstr);
			if (errstr)
				errx(1, "%s: not a known minute", m);

			if ((tb->tm_min + tzone) >= 60) {
				tb->tm_hour++;
				tb->tm_min -= (60 - tzone);
			} else
				tb->tm_min += tzone;

			tb->tm_gmtoff += (tzone*60);
		}
	}
}

/*
 * Format the broken-down time <tb> to string in <buf>.
 */
char *
rcstime_tostr(const struct tm *tb, char *buf, size_t blen)
{
	char sign;
	long zone;
	int non_hour;

	if (tb->tm_gmtoff == 0) {
		snprintf(buf, blen,
			 "%04d/%02d/%02d %02d:%02d:%02d",
			 tb->tm_year + 1900,
			 tb->tm_mon + 1,
			 tb->tm_mday,
			 tb->tm_hour,
			 tb->tm_min,
			 tb->tm_sec);
	} else {
		if (tb->tm_gmtoff > 0) {
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
	}

	return buf;
}
