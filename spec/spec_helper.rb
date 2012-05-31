require 'rubygems'

active_record_version = ENV['ACTIVE_RECORD_VERSION'] || ">=2.2.2"
gem 'rails', active_record_version
gem 'activerecord', active_record_version
gem 'activesupport', active_record_version
require 'active_support/all'
require 'active_record'
puts "Testing against #{ActiveRecord::VERSION::STRING}"

require 'mysql'
require 'pg'

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError
  # simplecov not installed
end

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'sql_safety_net'))

module SqlSafetyNet
  class TestModel < ActiveRecord::Base
    def self.create_tables
      connection.create_table(table_name) do |t|
        t.string :name
      end unless table_exists?
    end

    def self.drop_tables
      connection.drop_table(table_name)
    end
  
    def self.database_config
      database_yml = File.expand_path(File.join(File.dirname(__FILE__), 'database.yml'))
      raise "You must create a database.yml file in the spec directory (see example_database.yml)" unless File.exist?(database_yml)
      YAML.load_file(database_yml)
    end
  end
  
  class MysqlTestModel < TestModel
    establish_connection(database_config['mysql'])
  end
  
  class PostgresqlTestModel < TestModel
    establish_connection(database_config['postgresql'])
  end
  
  SqlSafetyNet.config.enable_on(SqlSafetyNet::MysqlTestModel.connection.class)
  SqlSafetyNet.config.enable_on(SqlSafetyNet::PostgresqlTestModel.connection.class)
end

ActiveSupport::Cache::Store.send(:include, SqlSafetyNet::CacheStore)
