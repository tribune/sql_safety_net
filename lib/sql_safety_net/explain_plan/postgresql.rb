module SqlSafetyNet
  module ExplainPlan
    # Include this module in your PostgreSQL connection class to analyze the query plan. It will just
    # look for excess row counts in the number of rows examined or scanned. The row counts provided by
    # PostgreSQL are just estimates, so take any alerts with a grain of salt.
    module Postgresql
      def sql_safety_net_analyze_query_plan(sql, binds)
        alerts = []
        config = SqlSafetyNet.config
        explain_results = select("EXPLAIN #{sql}", "EXPLAIN", binds)
        query_plan = explain_results.collect{|r| r.values.first}
        limit = nil
        
        query_plan.each do |row|
          row_count = row.match(/\brows=(\d+)/) ? $~[1].to_i : 0
          row_count = [limit, row_count].min if limit
          if row =~ /^(\s|(->))*Limit\s/
            limit = row_count
          elsif row =~ /^(\s|(->))*Seq Scan/
            alerts << "table scan on ~#{row_count} rows" if row_count > config.table_scan_limit
          elsif row_count > config.examined_rows_limit
            alerts << "examined ~#{row_count} rows"
          end
        end
        
        alerts
      end
    end
  end
end
