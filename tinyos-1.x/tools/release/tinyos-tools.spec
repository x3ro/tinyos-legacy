Summary: TinyOS tools 
Name: tinyos-tools
Version: 1.1.0
Release: 1
License: Please see source
Group: Development/System
URL: http://webs.cs.berkeley.edu/tos/
BuildRoot: %{_tmppath}/%{name}-root
Source0: tinyos-%{version}.tar.gz
# This makes cygwin happy
Provides: /bin/sh

%description
These are compiled tools for tinyos. The source for the tools is found in 
the tinyos package. 

%prep
%setup -q -n tinyos-1.1.0

%build
make
if cygpath / >/dev/null 2>/dev/null; then
  cd tools/src/uisp/kernel/win32
  make
fi

%install
rm -rf %{buildroot}
make install prefix=%{buildroot}/usr/local
cd tools/java/jni
make rpminstall prefix=%{buildroot}/usr/local
cd ../../..
if cygpath / >/dev/null 2>/dev/null; then
  cd tools/src/uisp/kernel/win32
  install -d %{buildroot}/usr/local/lib/tinyos
  install giveio-install.exe giveio.sys %{buildroot}/usr/local/lib/tinyos
fi

%files
%defattr(-,root,root,-)
/usr/local/
%attr(4755, root, root) /usr/local/bin/uisp*

%post
jni=`/usr/local/bin/locate-jre --jni`
if [ $? != 0 ]; then
  echo "Cannot locate java - is it installed?" >&2
  exit 1
fi
if [ -f /usr/local/lib/tinyos/libgetenv.so ]; then
  install /usr/local/lib/tinyos/libgetenv.so "$jni"
else
  install /usr/local/lib/tinyos/getenv.dll "$jni"
  (cd /usr/local/lib/tinyos; ./giveio-install --install)
fi

%preun
# Remove JNI code on uninstall
if [ $1 = 0 ]; then
  jni=`/usr/local/bin/locate-jre --jni`
  rm -f "$jni/libgetenv.so" "$jni/getenv.dll"
  if [ -f /usr/local/lib/tinyos/giveio-install ]; then
    /usr/local/lib/tinyos/giveio-install --uninstall
  fi
fi


%changelog
* Wed Sep  3 2003  <dgay@barnowl.research.intel-research.net> 1.1.0-internal2.1
- All tools, no java
* Sun Aug 31 2003 root <kwright@cs.berkeley.edu> 1.1.0-internal1.1
- Initial build.
