module SqlSafetyNet
  # This module needs to be included with the specific ActiveRecord::ConnectionAdapter class
  # to collect data about all SELECT queries.
  module ConnectionAdapter
    extend ActiveSupport::Concern

    SELECT_SQL_PATTERN = /\A\s*SELECT\b/im.freeze
    IGNORED_PAYLOADS = %w(SCHEMA EXPLAIN CACHE).freeze
    
    included do
      alias_method_chain :select_rows, :sql_safety_net
      alias_method_chain :select, :sql_safety_net
    end
    
    def select_rows_with_sql_safety_net(sql, name = nil, *args)
      analyze_query(sql, name, []) do
        select_rows_without_sql_safety_net(sql, name, *args)
      end
    end
    
    protected
    
    def select_with_sql_safety_net(sql, name = nil, *args)
      binds = args.first || []
      analyze_query(sql, name, binds) do
        select_without_sql_safety_net(sql, name, *args)
      end
    end
    
    
    def analyze_query(sql, name, binds)
      queries = QueryAnalysis.current
      if queries && sql.match(SELECT_SQL_PATTERN) && !IGNORED_PAYLOADS.include?(name)
        start_time = Time.now
        results = yield
        elapsed_time = Time.now - start_time
        
        # In Rails 4, results is an ActiveRecord::Result, so use #count
        row_count = results.count
        result_size = 0
        results.each do |row|
          values = row.is_a?(Hash) ? row.values : row
          values.each{|val| result_size += val.to_s.size if val}
        end
        cached = CacheStore.in_fetch_block?

        query_info = QueryInfo.new(append_binds(sql, binds), :elapsed_time => elapsed_time,
                                   :rows => row_count, :result_size => result_size, :cached => cached)
        queries << query_info
        
        # If connection includes a query plan analyzer then alert on issues in the query plan.
        if respond_to?(:sql_safety_net_analyze_query_plan)
          query_info.alerts.concat(sql_safety_net_analyze_query_plan(sql, binds))
        end
        
        query_info.alerts.each{|alert| ActiveRecord::Base.logger.debug(alert)} if ActiveRecord::Base.logger
        
        results
      else
        yield
      end
    end

    # the returned string is for display only; it's not valid sql
    def append_binds(sql_str, binds)
      if binds.empty?
        sql_str
      else
        "#{sql_str} #{binds.map {|col, val| [col.name, val] }.inspect}"
      end
    end
  end
end
