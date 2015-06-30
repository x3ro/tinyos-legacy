dnl
dnl @synopsis CHECK_AUTOCONF213
dnl
dnl This macro checks that the found autoconf is really 2.13.
dnl AC_PREREQ doesn't make sure that we aren't using autoconf > 2.13. Grrr.
dnl 
dnl @version $Id: check_autoconf213.m4,v 1.1 2003/06/26 17:52:59 idgay Exp $
dnl @author Theodore A. Roth <troth@openavr.org>
dnl
AC_DEFUN(CHECK_AUTOCONF213,[dnl
dnl
AC_MSG_CHECKING(for autoconf-2.13)
dnl
found="no"
for ac in ${AUTOCONF} autoconf213 autoconf-2.13
do
	AUTOCONF_VER=`(${ac} --version 2>/dev/null | head -n 1 | cut -d ' ' -f 3 | cut -c -4) 2>/dev/null`
	if test $? != 0
	then
		continue
	fi
	if test "$AUTOCONF_VER" = "2.13"
	then
		found="yes"
		AUTOHEADER=autoheader`expr "$ac" : 'autoconf\(.*\)'`
		break
	fi
done
dnl
if test "${found}" = "yes"
then
	AC_MSG_RESULT(yes)
	AUTOCONF="${ac}"
else
	AC_MSG_RESULT(no)
	AUTOCONF=/bin/true
	AUTOHEADER=/bin/true
fi
])dnl
