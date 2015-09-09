require 'active_support/all'
require 'active_record'

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
    def self.create_table
      connection.create_table(table_name) do |t|
        t.string :name
        t.integer :value
      end unless table_exists?
    end
  end
  
  TestModel.establish_connection(:adapter => "sqlite3", :database => ":memory:")
  TestModel.create_table
end

ActiveSupport::Cache::Store.send(:include, SqlSafetyNet::CacheStore)
SqlSafetyNet.enable_on_connection_adapter!(SqlSafetyNet::TestModel.connection.class)
