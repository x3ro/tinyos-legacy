Summary: An event-based operating environment designed for use with embedded networked sensors.
Name: tinyos
BuildArchitectures: noarch
Version: 1.1.15Dec2005cvs
Release: 1
License: Please see source
Packager: TinyOS Group, UC Berkeley
Group: Development/System
URL: http://webs.cs.berkeley.edu/tos/
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-root
Prefix: /opt
#Requires: tinyos-tools >= 1.1.0, nesc >= 1.1, avr-binutils >= 2.13.2.1, avr-gcc >= 3.3, avr-libc
Requires: tinyos-tools >= 1.1.0, nesc >= 1.1.1, avr-binutils >= 2.13.2.1, avr-gcc >= 3.3, avr-libc

%description
TinyOS is an event based operating environment designed for use with
embedded networked sensors.  It is designed to support the concurrency
intensive operations required by networked sensors while requiring minimal
hardware resources. For a full analysis and description of the
TinyOS system, its component model, and its implications for Networked
Sensor Architectures please see: "Architectural Directions for Networked
Sensors" which can be found off of http://www.tinyos.net

%prep
%setup -q

%install
# Move tinyos-1.x src to /usr/local/src
rm -rf %{buildroot}/opt/tinyos-1.x
mkdir -p %{buildroot}/opt
cp -a $RPM_BUILD_DIR/%{name}-%{version} %{buildroot}/opt/tinyos-1.x

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
/opt/tinyos-1.x/

%post
# Create a profile.d/tinyos.sh file with the user selected prefix
if [ -z "$RPM_INSTALL_PREFIX" ]; then
  RPM_INSTALL_PREFIX=/opt
fi

# Find 1.x or 2.x version of locate-jre
if [ -f /usr/bin/tos-locate-jre ]; then
  locjrescript=/usr/bin/tos-locate-jre
elif [ -f /usr/local/bin/locate-jre ]; then
  locjrescript=/usr/local/bin/locate-jre
else
  locjrescript=`which locate-jre 2>/dev/null`
  if [ -z $locjrescript ]; then
     locjrescript=`which tos-locate-jre 2>/dev/null`	
  fi
fi

sed -e "s#@prefix@#$RPM_INSTALL_PREFIX#" <<'EOF' >/etc/profile.d/tinyos.sh
# script for profile.d for bash shells, adjusted for each users
# installation by substituting @prefix@ for the actual tinyos tree
# installation point.

TOSROOT="@prefix@/tinyos-1.x"
export TOSROOT
TOSDIR="$TOSROOT/tos"
export TOSDIR
CLASSPATH=`$TOSROOT/tools/java/javapath`
export CLASSPATH
MAKERULES="$TOSROOT/tools/make/Makerules"
export MAKERULES
EOF

# Extend path for java
sed -e "s#@locjre@#$locjrescript#" <<'EOF' >>/etc/profile.d/tinyos.sh
type java >/dev/null 2>/dev/null || PATH=`@locjre@ --java`:$PATH
type javac >/dev/null 2>/dev/null || PATH=`@locjre@ --javac`:$PATH
echo $PATH | grep -q /usr/local/bin ||  PATH=/usr/local/bin:$PATH
EOF

# Then execute it, as we need the environment
. /etc/profile.d/tinyos.sh

# Compile motelist 
cd $TOSROOT/tools/src/motelist; make install

# Compile java tools
if ! ( type java >/dev/null 2>/dev/null && type javac >/dev/null 2>/dev/null ); then
  echo "Cannot find java and javac - java tools not compiled" 1>&2
  exit 0
fi
cd $TOSROOT/tools/java
make clean; make

%preun
# Remove tinyos.sh script and generated java stuff if this was the last install
if [ $1 = 0 ]; then
  . /etc/profile.d/tinyos.sh
  rm -f /etc/profile.d/tinyos.sh
  cd $TOSROOT/tools/java/net && make clean
fi

