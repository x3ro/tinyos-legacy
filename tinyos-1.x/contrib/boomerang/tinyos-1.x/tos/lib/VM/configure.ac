#!/bin/sh
# Copyright (c) 2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

dnl -*- m4 -*-

# force autoconf 2.5 on Debian systems
AC_PREREQ(2.50)

AC_INIT(mate, 2.3)
AC_CONFIG_AUX_DIR(config-aux)
AM_INIT_AUTOMAKE
AC_CANONICAL_HOST

AC_PROG_CC

AC_PATH_PROG(pathperl, perl)
if test -z "$pathperl" ; then
  AC_MSG_ERROR(I can't find perl); 
fi

AM_CONDITIONAL([CYGWIN], [test "$CYGWIN"])

AC_OUTPUT(Makefile
	  languages/Makefile
	  languages/motlle/Makefile
	  languages/motlle/mate/Makefile
	  languages/motlle/tools/Makefile
	  languages/tinysql/Makefile
	  languages/tinysql/src/Makefile
	  languages/tinysql/src/tinysql)