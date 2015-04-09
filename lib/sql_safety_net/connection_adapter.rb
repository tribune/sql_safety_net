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

        expanded_sql = sql
        unless binds.empty?
          sql = "#{sql} #{binds.collect{|col, val| [col.name, val]}.inspect}"
        end
        rows = results.count
        result_size = 0
        results.each do |row|
          values = row.is_a?(Hash) ? row.values : row
          values.each{|val| result_size += val.to_s.size if val}
        end
        cached = CacheStore.in_fetch_block?
        sql_str = nil
        if method(:to_sql).arity == 1
          sql_str = (sql.is_a?(String) ? sql : to_sql(sql))
        else
          sql_str = to_sql(sql, binds)
        end
        query_info = QueryInfo.new(sql_str, :elapsed_time => elapsed_time, :rows => rows, :result_size => result_size, :cached => cached)
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

  end
end
