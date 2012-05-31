require 'active_record'
require 'action_controller'

# Collects and displays debugging information about SQL statements.
module SqlSafetyNet
  autoload :CacheStore, File.expand_path('../sql_safety_net/cache_store', __FILE__)
  autoload :Configuration, File.expand_path('../sql_safety_net/configuration', __FILE__)
  autoload :ConnectionAdapter, File.expand_path('../sql_safety_net/connection_adapter', __FILE__)
  autoload :QueryAnalysis, File.expand_path('../sql_safety_net/query_analysis', __FILE__)
  autoload :RackHandler, File.expand_path('../sql_safety_net/rack_handler', __FILE__)
  
  class << self
    # Get the configuration for the safety net.
    def config
      @config ||= SqlSafetyNet::Configuration.new
    end
    
    def init_rails
      SqlSafetyNet.config.enable_on(ActiveRecord::Base.connection.class)
      if Rails.env == "development"
        SqlSafetyNet.config.debug = true
        ActiveSupport::Cache::Store.send(:include, CacheStore)
      end
      Rails.configuration.middleware.use(SqlSafetyNet::RackHandler)
    end
  end
end
