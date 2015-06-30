Summary: TinyDB is a query processing engine that simplifies data collection in large sensor networks.  TASK is a tool kit built around TinyDB to support the notion of "Sensor Network In a Box".
Name: task-tinydb
BuildArchitectures: noarch
Version: 1.1.3July2004cvs
Release: 1
License: Please see source
Packager: TinyOS Group, UC Berkeley and TASK group, Intel Research
Group: Development/System
URL: http://telegraph.cs.berkeley.edu/tinydb
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-root
Prefix: /opt
Requires: tinyos >= 1.1.7

%description
TinyDB is a simple query processing engine for extracting data from
networks of motes.  It runs on TinyOS and requires TinyOS and nesC 
for proper operation.  It is designed to greatly simplify many data
collection tasks, and includes support for power management, time 
synchronization, and in-network storage.

TASK stands for Tiny Application Sensor Kit.  It is a suite of tools
to support the idea of "Sensor Network In a Box".  TASK is built based
on TinyDB and includes the following additional components: TASKServer,
TASKAPI, TASKVisualizer and the TASK Field Tool.  It currently requires
a PostgreSQL database to store metadata, sensor data and network health
data.

%prep
%setup -q

%install
# Move tinyos-1.x src to /opt
rm -rf %{buildroot}/opt/tinyos-1.x
mkdir -p %{buildroot}/opt
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
cd $TOSROOT/tools/java/net
make

%preun
# Clean files
if [ $1 = 0 ]; then
  . /etc/profile.d/tinyos.sh
  cd $TOSROOT/tools/java/net/tinyos/task && make clean
  cd $TOSROOT/tools/java/net/tinyos/tinydb && make clean
  rm -f $TOSROOT/tools/java/net/tinyos/util/DTNStub.class
  cd $TOSROOT/apps/TinyDBApp && make clean
  cd $TOSROOT/apps/TASKApp && make clean
fi

