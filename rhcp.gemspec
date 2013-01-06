$LOAD_PATH.push('lib')
require File.join(File.dirname(__FILE__), 'lib', 'rhcp')

PKG_VERSION   = RHCP::Version.to_s

Gem::Specification.new do |s|
    s.name = "rhcp"
    s.version = RHCP::Version.to_s
    s.author = "Philipp T."
    
    s.email = "philipp at virtualop dot org"
    s.homepage = "http://rubyforge.org/projects/rhcp"
    s.platform = Gem::Platform::RUBY
    s.description = "RHCP is a protocol designed for building up a command-metadata-based communication infrastructure making it easier for application developers to export commands in applications to generic clients."
    s.summary = "command-based rpc library thing" 
    s.files      = Dir["{bin,docs,lib,test}/**/*"]
    s.require_path      = "lib"
    s.has_rdoc          = true
    s.add_dependency('json', '>= 0.0.0')
    s.bindir = 'bin'
    s.executables = 'rhcp_test_server'
end