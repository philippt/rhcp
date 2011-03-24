# Generated from rhcp-0.2.0.gem by gem2rpm -*- rpm-spec -*-
%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%define gemname rhcp
%define geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary: RHCP is a protocol designed for building up a command-metadata-based communication infrastructure making it easier for application developers to export commands in applications to generic clients
Name: rubygem-%{gemname}
Version: 0.2.12
Release: 2%{?dist}
Group: Development/Languages
License: GPLv2+ or Ruby
URL: http://rubyforge.org/projects/rhcp
Source0: %{gemname}-%{version}.gem
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: rubygems
Requires: rubygem-json >= 1.1.9
BuildRequires: rubygems
BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
RHCP is a protocol designed for building up a command-metadata-based
communication infrastructure making it easier for application developers to
export commands in applications to generic clients.

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} \
            --force --rdoc %{SOURCE0}
mkdir -p %{buildroot}/%{_bindir}
mv %{buildroot}%{gemdir}/bin/* %{buildroot}/%{_bindir}
rmdir %{buildroot}%{gemdir}/bin
find %{buildroot}%{geminstdir}/bin -type f | xargs chmod a+x

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%{_bindir}/rhcp_test_server
%{gemdir}/gems/%{gemname}-%{version}/
%doc %{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec


%changelog
* Mon Feb 28 2011 xop <philipp@xop-consulting.com> - 0.2.12-2
- pulled up logging_broker modifications from virtualop
* Wed Feb 16 2011 xop <philipp@xop-consulting.com> - 0.2.11-1
- changed response.created_at to be a unix timestamp
* Fri Sep 10 2010 xop <philipp@xop-consulting.com> - 0.2.10-2
- refactored context handling in http_export; using thread-local variables now for accessing a ContextAwareBroker that is initialized per request
* Wed Sep 08 2010 xop <philipp@xop-consulting.com> - 0.2.10-1
- moving memcached_broker from virtualop into rhcp
- bugfix in context handling 
* Fri Jul 30 2010 xop <philipp@xop-consulting.com> - 0.2.9-1
- logging_broker: made array of blacklisted_commands overwritable by descendant classes and/or request context
* Mon Jun 07 2010 xop <philipp@xop-consulting.com> - 0.2.8-1
- bugfix: dispatching_broker was not correctly propagating the context
- minor additions for android rhcp library
- started reconstruction of the error handling parts
* Sat May 24 2010 xop <philipp@xop-consulting.com> - 0.2.6-1
- working on the logging broker
- fine-tuning context behaviour (param values overrule context keys)
* Sat May 01 2010 xop <philipp@xop-consulting.com> - 0.2.5-1
- added logging broker
* Sat May 01 2010 xop <philipp@xop-consulting.com> - 0.2.4-1
- refactored broker interface - using request now for execute() and get_lookup_values()
- this means that lookup methods get a RHCP::Request parameter now instead of context
- also, the collected_values and command_name attributes have been removed from the context
* Tue Apr 27 2010 xop <philipp@xop-consulting.com> - 0.2.3-1
- bugfix: need to clear the collected values in the context after command execution
* Sun Apr 25 2010 xop <philipp@xop-consulting.com> - 0.2.2-1
- added context implementation to all brokers 
* Sun Feb 21 2010 xop <philipp@xop-consulting.com> - 0.2.0-3
- corrected dependency meta info for rubygem-json
* Sun Feb 21 2010 xop <philipp@xop-consulting.com> - 0.2.0-2
- corrected dependency to rubygem-json; fixed to version 1.1.9
* Sun Feb 21 2010 xop <philipp@xop-consulting.com> - 0.2.0-1
- Initial package
