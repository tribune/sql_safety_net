module SqlSafetyNet
  # This module provides a hook into ActiveSupport::Cache::Store caches to keep
  # track of when a query happens inside a cache fetch block. This will be reported
  # in the analysis.
  module CacheStore
    extend ActiveSupport::Concern
    
    included do
      alias_method_chain :fetch, :sql_safety_net
    end
    
    def fetch_with_sql_safety_net(*args, &block)
      save_val = Thread.current[:sql_safety_net_in_cache_store_fetch_block]
      begin
        Thread.current[:sql_safety_net_in_cache_store_fetch_block] = true
        fetch_without_sql_safety_net(*args, &block)
      ensure
        Thread.current[:sql_safety_net_in_cache_store_fetch_block] = save_val
      end
    end
    
    class << self
      # Return +true+ if called from within a +fetch+ block.
      def in_fetch_block?
        !!Thread.current[:sql_safety_net_in_cache_store_fetch_block]
      end
    end
  end
end
