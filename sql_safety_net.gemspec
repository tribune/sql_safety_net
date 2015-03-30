# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sql_safety_net/version'
Gem::Specification.new do |spec|
  spec.name          = 'sql_safety_net'
  spec.version       = SqlSafetyNet::VERSION
  spec.authors       = ['Brian Durand', 'Milan Dobrota']
  spec.email         = ['mdobrota@tribpub.com']
  spec.summary       = 'Debug SQL statements in ActiveRecord'
  spec.description   = 'Debug SQL statements in ActiveRecord by displaying warnings on bad queries.'
  spec.homepage      = ''

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport', '~> 3.2.0'
  spec.add_runtime_dependency 'activerecord', '~> 3.2.0'
  spec.add_runtime_dependency 'actionpack', '~> 3.2.0'

  spec.add_development_dependency 'rspec', '~> 2.8.0'
  spec.add_development_dependency 'sqlite3-ruby', '>= 0'
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
