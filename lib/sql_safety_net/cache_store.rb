module SqlSafetyNet
  # Hook into ActiveSupport::Cache to set a caching flag on the QueryAnalysis whenever +fetch+ is called with a block.
  module CacheStore
    def self.included(base)
      base.alias_method_chain(:fetch, :sql_safety_net)
    end
    
    def fetch_with_sql_safety_net(*args, &block)
      analysis = QueryAnalysis.current
      saved_val = analysis.caching? if analysis
      begin
        analysis.caching = true if analysis
        fetch_without_sql_safety_net(*args, &block)
      ensure
        analysis.caching = saved_val if analysis
      end
    end
  end
end
