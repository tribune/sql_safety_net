module SqlSafetyNet
  module ConnectionAdapter
    # Logic for analyzing a query plan from PostgreSQL. These plans are not terribly useful and sometimes
    # the statistics are off, so take them with a grain of salt.
    module PostgreSQLAdapter
      def analyze_query(sql, name, *args)
        if select_statement?(sql)
          query_plan = select_without_sql_safety_net("EXPLAIN #{sql}", "EXPLAIN", *args)
          query_plan_flags = analyze_query_plan(query_plan)
          unless query_plan_flags.empty?
            @logger.debug("Flagged query plan #{name} (#{query_plan_flags.join(', ')}): #{query_plan.inspect}") if @logger
            return {:query_plan => query_plan, :flags => query_plan_flags}
          end
        end
      end

      private
      
      def analyze_query_plan(query_plan)
        query_plan = query_plan.collect{|r| r.values.first}
        flagged = []
        limit = nil
        query_plan.each do |row|
          row_count = query_plan_rows_value(row)
          row_count = [limit, row_count].min if limit
          if row =~ /^(\s|(->))*Limit\s/
            limit = row_count
          elsif row =~ /^(\s|(->))*Seq Scan/
            flagged << 'table scan' if row_count > SqlSafetyNet.config.table_scan_limit
          elsif row_count > SqlSafetyNet.config.examine_rows_limit
            flagged << "examines #{row_count} rows"
          end
        end
        return flagged
      end
    
      private
    
      def query_plan_rows_value(plan_row)
        if plan_row.match(/\brows=(\d+)/)
          return $~[1].to_i
        else
          return 0
        end
      end
    end
  end
end
