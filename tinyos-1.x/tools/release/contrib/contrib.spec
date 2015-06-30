Summary: Contributed TinyOS packages
Name: tinyos-contrib
BuildArchitectures: noarch
Version: 1.1.4Apr2005cvs
Release: 1
License: Please see source
Packager: TinyOS Group, UC Berkeley
Group: Development/System
URL: http://webs.cs.berkeley.edu/tos/
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-root
Prefix: /opt
Requires: tinyos >= 1.1.0

%description
These are a set of packages contributed by groups external to TinyOS. Examine
the README files in each subdirectory of tinyos-1.x/contrib for more
details. The contrib packages are supported by their authors, not the TinyOS 
group. The 1.1.3 contrib package includes contrib/ucb, contrib/moteiv, and 
some beta packages.

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
