# Root module for the gem.
#
# This module provide access to the singleton configuration object as well as hooks
# for enabling features.
#
# Since the analysis code is intended only for development mode
# it is not enabled by default. You can enable it by calling the enable methods
# in an config/initializers file:
#
#   if Rails.env.development?
#     SqlSafetyNet.enable_on_cache_store!(ActiveSupport::Cache::Store)
#     SqlSafetyNet.enable_on_connection_adapter!(ActiveRecord::Base.connection.class)
#     SqlSafetyNet::ExplainPlan.enable_on_connection_adapter!(ActiveRecord::Base.connection.class, :mysql) # assuming MySQL adapter
#     Rails.configuration.middleware.use(SqlSafetyNet::Middleware)
#   end
#
# Or you can simply enable the default configuration by calling:
#
#   SqlSafetyNet.enable! if Rails.env.development?
module SqlSafetyNet
  autoload :CacheStore, File.expand_path("../sql_safety_net/cache_store.rb", __FILE__)
  autoload :Configuration, File.expand_path("../sql_safety_net/configuration.rb", __FILE__)
  autoload :ConnectionAdapter, File.expand_path("../sql_safety_net/connection_adapter.rb", __FILE__)
  autoload :ExplainPlan, File.expand_path("../sql_safety_net/explain_plan.rb", __FILE__)
  autoload :Formatter, File.expand_path("../sql_safety_net/formatter.rb", __FILE__)
  autoload :Middleware, File.expand_path("../sql_safety_net/middleware.rb", __FILE__)
  autoload :QueryAnalysis, File.expand_path("../sql_safety_net/query_analysis.rb", __FILE__)
  autoload :QueryInfo, File.expand_path("../sql_safety_net/query_info.rb", __FILE__)
  
  class << self
    # Enable SQL analysis on your Rails app. This method can be called from your development.rb
    # file. It will enable analysis on the default database connection class and insert
    # middleware into the Rack stack that will add debugging information to responses.
    def enable!
      enable_on_cache_store!(ActiveSupport::Cache::Store)
      connection_class = ActiveRecord::Base.connection.class
      enable_on_connection_adapter!(connection_class)
      if connection_class.name.match(/mysql/i)
        ExplainPlan.enable_on_connection_adapter!(connection_class, :mysql)
      elsif connection_class.name.match(/postgres/i)
        ExplainPlan.enable_on_connection_adapter!(connection_class, :postgresql)
      end
      Rails.configuration.middleware.use(Middleware)
    end
    
    # Enable SQL analysis on a connection adapter.
    def enable_on_connection_adapter!(connection_adapter_class)
      connection_adapter_class.send(:include, ConnectionAdapter) unless connection_adapter_class.include?(ConnectionAdapter)
    end
    
    # Enable monitoring on fetches from an ActiveSupport::Cache::Store class. This
    # will allow reporting which queries are in cache blocks in the analysis.
    def enable_on_cache_store!(cache_store_class)
      cache_store_class.send(:include, CacheStore) unless cache_store_class.include?(CacheStore)
    end
    
    # Get the configuration. There is only ever one configuration. The values in the
    # configuration can be changed. If you only need to change them temporarily, see
    # +override_config+.
    def config
      @config ||= Configuration.new
    end
    
    # Set configuration values within a block. The block given to this method will
    # be yielded to with a clone of the configuration. Any changes to the configuration
    # will only persist within the block.
    def override_config
      save_val = config
      begin
        @config = save_val.dup
        @config.style = @config.style.dup
        yield(@config)
      ensure
        @config = save_val
      end
    end
  end
end
