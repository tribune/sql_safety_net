# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "sql_safety_net"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Durand"]
  s.date = "2012-06-12"
  s.description = "Debug SQL statements in ActiveRecord by displaying warnings on bad queries."
  s.email = ["mdobrota@tribune.com", "ddpr@tribune.com"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "License.txt",
    "README.rdoc",
    "Rakefile",
    "lib/sql_safety_net.rb",
    "lib/sql_safety_net/cache_store.rb",
    "lib/sql_safety_net/configuration.rb",
    "lib/sql_safety_net/connection_adapter.rb",
    "lib/sql_safety_net/explain_plan.rb",
    "lib/sql_safety_net/explain_plan/mysql.rb",
    "lib/sql_safety_net/explain_plan/postgresql.rb",
    "lib/sql_safety_net/formatter.rb",
    "lib/sql_safety_net/middleware.rb",
    "lib/sql_safety_net/query_analysis.rb",
    "lib/sql_safety_net/query_info.rb",
    "spec/cache_store_spec.rb",
    "spec/configuration_spec.rb",
    "spec/connection_adapter_spec.rb",
    "spec/explain_plan/mysql_spec.rb",
    "spec/explain_plan/postgresql_spec.rb",
    "spec/formatter_spec.rb",
    "spec/middleware_spec.rb",
    "spec/query_analysis_spec.rb",
    "spec/query_info_spec.rb",
    "spec/spec_helper.rb",
    "spec/sql_safety_net_spec.rb"
  ]
  s.rdoc_options = ["--line-numbers", "--inline-source", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "Debug SQL statements in ActiveRecord"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<actionpack>, [">= 3.0.0"])
      s.add_development_dependency(%q<rspec>, [">= 2.0.0"])
      s.add_development_dependency(%q<sqlite3-ruby>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<activerecord>, [">= 3.0.0"])
      s.add_dependency(%q<actionpack>, [">= 3.0.0"])
      s.add_dependency(%q<rspec>, [">= 2.0.0"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<activerecord>, [">= 3.0.0"])
    s.add_dependency(%q<actionpack>, [">= 3.0.0"])
    s.add_dependency(%q<rspec>, [">= 2.0.0"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
  end
end

