/*
 * Copyright (c) 1993-1999 David Gay and Gustav Hållberg
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose, without fee, and without written agreement is hereby granted,
 * provided that the above copyright notice and the following two paragraphs
 * appear in all copies of this software.
 * 
 * IN NO EVENT SHALL DAVID GAY OR GUSTAV HALLBERG BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY OR
 * GUSTAV HALLBERG HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * DAVID GAY AND GUSTAV HALLBERG SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN
 * "AS IS" BASIS, AND DAVID GAY AND GUSTAV HALLBERG HAVE NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#include "runtime/runtime.h"
#include "print.h"
#include "utils.h"
#include "interpret.h"
#include "call.h"
#include <time.h>
#ifndef AMIGA
#include <sys/time.h>
#include <sys/resource.h>
#endif

OPERATION("print", print, "x -> . Print a representation of x", 1, (value v),
	  OP_LEAF | OP_NOESCAPE)
{
  mprint(mudout, prt_print, v);
  undefined();
}

OPERATION("newline", newline, " -> . Print a newline", 0, (void),
	  OP_LEAF | OP_NOESCAPE)
{
  mputs(EOL, mudout);
  if (mudout) mflush(mudout);
  undefined();
}

OPERATION("display", display, "x -> . Display a representation of x",
	  1, (value v),
	  OP_LEAF | OP_NOESCAPE)
{
  mprint(mudout, prt_display, v);
  undefined();
}

OPERATION("examine", examine, "x -> . Examine a representation of x",
	  1, (value v),
	  OP_LEAF | OP_NOESCAPE)
{
  mprint(mudout, prt_examine, v);
  undefined();
}

TYPEDOP("ctime", ctime,
" -> n. Returns the number of milliseconds of cpu time (use difference only)",
	0, (void),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, ".n")
{
#ifdef AMIGA
  unsigned int clock[2];

  if (timer(clock)) RUNTIME_ERROR(error_bad_value);

  return (makeint(1000 * (clock[0] % 86400) + clock[1] / 1000));
#elif defined(hpux)
  return makeint(0);
#else
  struct rusage usage;

  getrusage(RUSAGE_SELF, &usage);
  return (makeint(1000 * usage.ru_utime.tv_sec + usage.ru_utime.tv_usec / 1000));
#endif
}

TYPEDOP("time", time,
" -> n. Returns the number of seconds since the 1st of January 1970 GMT",
	0, (void),
	OP_LEAF | OP_NOALLOC | OP_NOESCAPE, ".n")
{
  return makeint(time(0));
}

static value _mktime(value t, struct tm *(*convert)(const time_t *time))
{
  struct tm *tm;
  time_t timeval;
  struct vector *vtm;

  ISINT(t);
  timeval = intval(t);

  tm = convert(&timeval);
  vtm = alloc_vector(8);
  vtm->data[0] = makeint(tm->tm_sec);
  vtm->data[1] = makeint(tm->tm_min);
  vtm->data[2] = makeint(tm->tm_hour);
  vtm->data[3] = makeint(tm->tm_mday);
  vtm->data[4] = makeint(tm->tm_mon);
  vtm->data[5] = makeint(tm->tm_year);
  vtm->data[6] = makeint(tm->tm_wday);
  vtm->data[7] = makeint(tm->tm_yday);

  return vtm;
}

TYPEDOP("gmtime", gmtime,
"n -> v. Converts time in seconds to a vector of GMT time information",
	1, (value t),
	OP_LEAF | OP_NOESCAPE, "n.v")
{

  return _mktime(t, gmtime);
}

TYPEDOP("localtime", localtime,
"n -> v. Converts time in seconds to a vector of local time information",
	1, (value t),
	OP_LEAF | OP_NOESCAPE, "n.v")
{

  return _mktime(t, localtime);
}

TYPEDOP("asctime", asctime,
"v -> s. Makes a string representing a particular date, as returned by gmtime",
	1, (struct vector *vgmt),
	OP_LEAF | OP_NOESCAPE, "v.s")
{
  struct tm gmt;

  TYPEIS(vgmt, type_vector);
  if (vector_len(vgmt) < 8) RUNTIME_ERROR(error_bad_value);
  ISINT(vgmt->data[0]); gmt.tm_sec = intval(vgmt->data[0]);
  ISINT(vgmt->data[1]); gmt.tm_min = intval(vgmt->data[1]);
  ISINT(vgmt->data[2]); gmt.tm_hour = intval(vgmt->data[2]);
  ISINT(vgmt->data[3]); gmt.tm_mday = intval(vgmt->data[3]);
  ISINT(vgmt->data[4]); gmt.tm_mon = intval(vgmt->data[4]);
  ISINT(vgmt->data[5]); gmt.tm_year = intval(vgmt->data[5]);
  ISINT(vgmt->data[6]); gmt.tm_wday = intval(vgmt->data[6]);
  ISINT(vgmt->data[7]); gmt.tm_yday = intval(vgmt->data[7]);

  gmt.tm_isdst = FALSE;
#ifdef HAVE_TM_ZONE
  gmt.tm_zone = "GMT";
  gmt.tm_gmtoff = 0;
#endif

  return alloc_string(asctime(&gmt));
}

TYPEDOP("strftime", strftime,
"s v -> s. Convert a gmtime vector into text, as specified by a strftime \n\
format string. Return zero on error.",
	2, (struct string *fmt, struct vector *vgmt),
	OP_LEAF | OP_NOESCAPE, "v.s")
{
#ifdef MAX_STRING_LENGTH
  char buffer[MAX_STRING_LENGTH];
#else
  char buffer[4096];
#endif

  struct tm gmt;

  TYPEIS(fmt, type_string);
  TYPEIS(vgmt, type_vector);
  if (vector_len(vgmt) < 8) RUNTIME_ERROR(error_bad_value);
  ISINT(vgmt->data[0]); gmt.tm_sec = intval(vgmt->data[0]);
  ISINT(vgmt->data[1]); gmt.tm_min = intval(vgmt->data[1]);
  ISINT(vgmt->data[2]); gmt.tm_hour = intval(vgmt->data[2]);
  ISINT(vgmt->data[3]); gmt.tm_mday = intval(vgmt->data[3]);
  ISINT(vgmt->data[4]); gmt.tm_mon = intval(vgmt->data[4]);
  ISINT(vgmt->data[5]); gmt.tm_year = intval(vgmt->data[5]);
  ISINT(vgmt->data[6]); gmt.tm_wday = intval(vgmt->data[6]);
  ISINT(vgmt->data[7]); gmt.tm_yday = intval(vgmt->data[7]);

  gmt.tm_isdst = FALSE;
#ifdef HAVE_TM_ZONE
  gmt.tm_zone = "GMT";
  gmt.tm_gmtoff = 0;
#endif

#ifdef MAX_STRING_LENGTH
  if (strftime(buffer, MAX_STRING_LENGTH, fmt->str, &gmt))
#else
  if (strftime(buffer, 4096, fmt->str, &gmt))
#endif
    return alloc_string(buffer);
  else
    return makeint(0);
}

OPERATION("stdout", mstdout, " -> oport. Return current standard out",
	  0, (void), OP_LEAF|OP_NOESCAPE|OP_NOALLOC)
{
  return mudout;
}

OPERATION("stderr", mstderr, " -> oport. Return current standard error",
	  0, (void), OP_LEAF|OP_NOESCAPE|OP_NOALLOC)
{
  return muderr;
}

OPERATION("set_stdout!", set_stdout, 
"oport1 -> oport2. Sets standard output to oport1, returns old standard output.",
	  1, (value out), 0)
{
  Mio oldout = mudout;

  TYPEIS(out, type_outputport);
  mudout = out;

  return oldout;
}

OPERATION("set_stderr!", set_stderr, 
"oport1 -> oport2. Sets standard error to oport1, returns old standard error.",
	  1, (value err), 0) {
  Mio olderr = muderr;

  TYPEIS(err, type_outputport);
  muderr = err;

  return olderr;
}

TYPEDOP("make_string_oport", make_string_oport,
       " -> oport. Returns a new string output port.",
	0, (void),
	OP_LEAF, ".o")
{
  return make_string_outputport();
}

TYPEDOP("port_string", port_string,
       "oport -> s. Returns the contents of string port oport.",
	1, (struct oport *p),
	OP_LEAF, "o.s")
{
  TYPEIS(p, type_outputport);
  /* Warning: need to check that this is a string output port!
     But: the only externally visible output ports are of that kind,
     so not a problem so far. */

  return port_string(p);
}

static value pformat(struct oport *p, struct string *str,
		     int i, int nargs)
{
  uvalue l, spos;

  GCPRO2(p, str);

  l = string_len(str);
  spos = 0;
  while (spos < l)
    if (str->str[spos] == '%')
      {
	spos++;
	if (spos == l) RUNTIME_ERROR(error_bad_value);
	switch (str->str[spos])
	  {
	  default: RUNTIME_ERROR(error_bad_value);
	  case '%': pputc('%', p); break;
	  case 'c':
	    if (i >= nargs) RUNTIME_ERROR(error_wrong_parameters);
	    ISINT(vararg_get(i));
	    pputc(intval(vararg_get(i++)), p);
	    break;
	  case 'n': pputs(EOL, p); break;
	  case 'p':
	    if (i >= nargs) RUNTIME_ERROR(error_wrong_parameters);
	    ISINT(vararg_get(i));
	    if (intval(vararg_get(i++)) != 1) pputc('s', p);
	    break;
	  case 'P':
	    if (i >= nargs) RUNTIME_ERROR(error_wrong_parameters);
	    ISINT(vararg_get(i));
	    if (intval(vararg_get(i++)) != 1) pputs("ies", p);
	    else pputc('y', p);
	    break;
	  case 's':
	    if (i >= nargs) RUNTIME_ERROR(error_wrong_parameters);
	    output_value(p, prt_display, vararg_get(i++));
	    break;
	  case 'w':
	    if (i >= nargs) RUNTIME_ERROR(error_wrong_parameters);
	    output_value(p, prt_print, vararg_get(i++));
	    break;
	  }
	spos++;
      }
    else
      {
	pputc(str->str[spos], p);
	spos++;
      }

  if (i != nargs) RUNTIME_ERROR(error_wrong_parameters);

  GCPOP(2);
  varargs_pop();

  return undefined_value;
}

VAROP("pformat", pformat, 
"oport s x1 x2 ... -> . Outputs formatted string s to port, with parameters\n\
x1, ... See format() for syntax",
      OP_LEAF)
{
  struct string *str;
  struct oport *p;

  if (nargs < 2)
    RUNTIME_ERROR(error_wrong_parameters);
  p = vararg_get(0);
  TYPEIS(p, type_outputport);

  str = vararg_get(1);
  TYPEIS(str, type_string);

  return pformat(p, str, 2, nargs);
}

VAROP("format", format, 
      "s x1 x2 ... -> s. Formats string s with parameters x1, ..." EOL
      "Special entries are %x, where x can be:" EOL
      "  %   a % sign" EOL
      "  c   the character in the next parameter (an int)" EOL
      "  n   end of line" EOL
      "  p   if the next param is 1 \"\", else \"s\"" EOL
      "  P   if the next param is 1 \"y\", else \"ies\"" EOL
      "  s   a string repr. of the next param (like display)" EOL
      "  w   a string repr. of the next param (like write)",
      OP_LEAF)
{
  struct string *str;
  struct oport *p;
  value ok;

  if (nargs < 1)
    RUNTIME_ERROR(error_wrong_parameters);
  p = make_string_outputport();
  str = vararg_get(0);
  TYPEIS(str, type_string);

  GCPRO1(p);
  ok = pformat(p, str, 1, nargs);
  str = port_string(p);
  GCPOP(1);
  opclose(p);

  return ok == PRIMITIVE_STOLE_CC ? PRIMITIVE_STOLE_CC : str;
}
