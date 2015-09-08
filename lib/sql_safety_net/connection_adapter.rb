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
        # In Rails 4, results may be an ActiveRecord::Result
        result_hashes = results.respond_to?(:to_hash) ? results.to_hash : results
        elapsed_time = Time.now - start_time
        
        row_count = result_hashes.size
        result_size = 0
        result_hashes.each do |row|
          values = row.is_a?(Hash) ? row.values : row
          values.each{|val| result_size += val.to_s.size if val}
        end
        cached = CacheStore.in_fetch_block?

        exec_sql = get_executable_sql(sql, binds)

        query_info = QueryInfo.new(append_binds(exec_sql, binds), :elapsed_time => elapsed_time,
                                   :rows => row_count, :result_size => result_size, :cached => cached)
        queries << query_info
        
        # If connection includes a query plan analyzer then alert on issues in the query plan.
        if respond_to?(:sql_safety_net_analyze_query_plan)
          query_info.alerts.concat(sql_safety_net_analyze_query_plan(exec_sql, binds))
        end
        
        query_info.alerts.each{|alert| ActiveRecord::Base.logger.debug(alert)} if ActiveRecord::Base.logger
        
        results
      else
        yield
      end
    end

    def get_executable_sql(sql, binds)
      # In rails 3.1+, to_sql can accept an Arel AST and convert it to sql, but this should never
      #  happen; sql will always be a String otherwise the sql.match in analyze_query would fail.
      # What is this arity check for?
      if method(:to_sql).arity == 1
        sql.is_a?(String) ? sql : to_sql(sql)
      else
        to_sql(sql, binds)
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
