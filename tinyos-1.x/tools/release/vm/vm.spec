Summary: Mate', a framework for building application specific virtual machines for TinyOS
Name: mate-asvm
BuildArchitectures: noarch
Version: 2.19aDec2004
Release: 1
License: Please see source
Packager: Philip Levis, TinyOS Group, UC Berkeley
Group: Development/System
URL: http://www.cs.berkeley.edu/~pal/mate-web
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-root
Prefix: /opt
Requires: tinyos >= 1.1.9
AutoReqProv: no

%description
Provides a framework for building application specific virtual machines for
TinyOS. This allows you to program networks with simple, high-level scripts.
Read http://www.cs.berkeley.edu/~pal/mate-web for more details.

%prep
%setup -q

%install
# Move tinyos-1.x src to /opt
rm -rf %{buildroot}/opt/tinyos-1.x
mkdir -p %{buildroot}/opt
# You'll need to change this line to copy the files extracted from
# yourtarball to the right place in the tinyos-1.x tree
cp -a $RPM_BUILD_DIR/%{name}-%{version} %{buildroot}/opt/tinyos-1.x

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
/opt/tinyos-1.x/

%post
# This runs make in tools/java/net to compile any new java stuff you installed
# Execute tinyos.sh, as we need the environment
. /etc/profile.d/tinyos.sh

if ! ( type java >/dev/null 2>/dev/null && type javac >/dev/null 2>/dev/null ); then
  echo "Cannot find java and javac - java tools not compiled" 1>&2
  exit 0
fi
cd $TOSROOT/tools/java/net/tinyos/script
make

%preun
# Clean files
if [ $1 = 0 ]; then
  . /etc/profile.d/tinyos.sh
  cd $TOSROOT/tools/java/net/tinyos/script && make clean
  cd $TOSROOT/apps/Bombilla && rm -f MateTopLevel.nc MateConstants.h vm.vmdf README
fi

