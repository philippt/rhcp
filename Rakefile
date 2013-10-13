require 'rake'
require 'rake/testtask'
#require 'rake/rdoctask'
require 'rubygems'
#Gem::manage_gems
#require 'rake/gempackagetask'

#require 'rubyforge'

$LOAD_PATH.push('lib')
require File.join(File.dirname(__FILE__), 'lib', 'rhcp')

PKG_NAME      = 'rhcp'
PKG_VERSION   = RHCP::Version.to_s
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

desc "Default Task"
task :default => [ :test ]

###############################################
### TESTS
Rake::TestTask.new() { |t|
  t.libs << "lib"
  t.libs << "test"
  t.libs << "test/rhcp"
  t.test_files = FileList['test/rhcp/**/*_test.rb']
  t.verbose = true
}


###############################################
### METRICS
task :lines do
  lines, codelines, total_lines, total_codelines = 0, 0, 0, 0

  for file_name in FileList["lib/**/*.rb"]
    f = File.open(file_name)

    while line = f.gets
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
    puts "L: #{sprintf("%4d", lines)}, LOC #{sprintf("%4d", codelines)} | #{file_name}"
    
    total_lines     += lines
    total_codelines += codelines
    
    lines, codelines = 0, 0
  end

  puts "Total: Lines #{total_lines}, LOC #{total_codelines}"
end

task :update_manifest do
  system "rake check_manifest 2>/dev/null | grep -vE 'qooxdoo|nbproject|coverage' | grep -E '^\+' | grep -vE '^$' | grep -v '(in ' | grep -vE '^\+\+\+' | cut -b 2-200 | patch"
end

# TODO add rcov
# rcov -I lib/ -x rcov.rb -x rhcp.rb test/**/*.rb

spec = Gem::Specification.new do |s|
    s.rubyforge_project = "rhcp"
    s.name       = "rhcp"
    s.version    = PKG_VERSION
    s.author = "Philipp Traeder"
    s.email      = "philipp at hitchhackers.net"
    s.homepage   = "http://rubyforge.org/projects/rhcp"
    s.platform   = Gem::Platform::RUBY
    s.summary    = "RHCP is a protocol designed for building up a command-metadata-based communication infrastructure making it easier for application developers to export commands in applications to generic clients."
    s.files      = FileList["{bin,docs,lib,test}/**/*"].exclude("rdoc").to_a
    s.require_path      = "lib"
    s.has_rdoc          = true
    s.add_dependency('json', '>= 0.0.0')
    s.bindir = 'bin'
    s.executables = 'rhcp_test_server'
end

#Rake::GemPackageTask.new(spec) do |pkg|
#    pkg.need_tar = true
#end


task :upload_gem do
  rf = RubyForge.new.configure
  rf.login
  rf.add_release("rhcp", "rhcp", PKG_VERSION, File.join("pkg", "rhcp-#{PKG_VERSION}.gem"))
end
