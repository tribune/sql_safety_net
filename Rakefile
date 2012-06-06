require 'rubygems'
require 'rake'

desc 'Default: run unit tests'
task :default => :test

begin
  require 'rspec'
  require 'rspec/core/rake_task'
  desc 'Run the unit tests'
  RSpec::Core::RakeTask.new(:test)
rescue LoadError
  task :test do
    raise "You must have rspec 2.0 installed to run the tests"
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sql_safety_net"
    gem.summary = %Q{Debug SQL statements in ActiveRecord}
    gem.description = %Q{Debug SQL statements in ActiveRecord by displaying warnings on bad queries.}
    gem.authors = ["Brian Durand"]
    gem.email = ["mdobrota@tribune.com", "ddpr@tribune.com"]
    gem.files = FileList["lib/**/*", "spec/**/*", "README.rdoc", "Rakefile", "License.txt"].to_a
    gem.has_rdoc = true
    gem.rdoc_options << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
    gem.extra_rdoc_files = ["README.rdoc"]
    gem.add_dependency('activesupport')
    gem.add_dependency('activerecord', '>= 2.2.2')
    gem.add_dependency('actionpack')
    gem.add_development_dependency('rspec', '>= 2.0.0')
    gem.add_development_dependency('mysql')
    gem.add_development_dependency('pg')
    gem.add_development_dependency('sqlite3-ruby')
  end
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
end
