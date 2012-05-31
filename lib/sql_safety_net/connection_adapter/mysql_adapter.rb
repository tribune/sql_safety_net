module SqlSafetyNet
  module ConnectionAdapter
    # Logic for analyzing MySQL query plans.
    module MysqlAdapter
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
        flagged = []
        query_plan.each do |row|
          select_type = (row['select_type'] || '').downcase
          type = (row['type'] || '').downcase
          rows = row['rows'].to_i
          extra = (row['Extra'] || '').downcase
          key = row['key']
          possible_keys = row['possible_keys']

          flagged << 'table scan' if (type.include?('all') and rows > SqlSafetyNet.config.table_scan_limit)
          flagged << 'fulltext search' if type.include?('fulltext')
          flagged << 'no index used' if (key.blank? and rows > SqlSafetyNet.config.table_scan_limit)
          flagged << 'no indexes possible' if (possible_keys.blank? and rows > SqlSafetyNet.config.table_scan_limit)
          flagged << 'dependent subquery' if select_type.include?('dependent')
          flagged << 'uncacheable subquery' if select_type.include?('uncacheable')
          flagged << 'full scan on null key' if extra.include?('full scan on null key')
          flagged << "uses temporary table for #{rows} rows" if extra.include?('using temporary') and rows > SqlSafetyNet.config.temporary_table_limit
          flagged << "uses filesort for #{rows} rows" if extra.include?('filesort') and rows > SqlSafetyNet.config.filesort_limit
          flagged << "examines #{rows} rows" if rows > SqlSafetyNet.config.examine_rows_limit
        end
        return flagged
      end
    end
  end
end
