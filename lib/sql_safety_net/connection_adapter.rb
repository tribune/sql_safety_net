module SqlSafetyNet
  # Logic to be mixed into connection adapters allowing them to analyze queries.
  module ConnectionAdapter
    autoload :MysqlAdapter, File.expand_path('../connection_adapter/mysql_adapter', __FILE__)
    autoload :PostgreSQLAdapter, File.expand_path('../connection_adapter/postgresql_adapter', __FILE__)
    
    SELECT_STATEMENT = /^\s*SELECT\b/i
    
    def self.included(base)
      base.alias_method_chain :select, :sql_safety_net
      base.alias_method_chain :select_rows, :sql_safety_net
      base.alias_method_chain :columns, :sql_safety_net
      base.alias_method_chain :active?, :sql_safety_net
    end
    
    def active_with_sql_safety_net?
      active = disable_sql_safety_net{active_without_sql_safety_net?}
      if @logger && !active
        @logger.warn("#{adapter_name} connection not active")
      end
      active
    end

    def columns_with_sql_safety_net(table_name, name = nil)
      disable_sql_safety_net do
        columns_without_sql_safety_net(table_name, name)
      end
    end
    
    def select_rows_with_sql_safety_net(sql, name = nil, *args)
      analyze_sql_safety_net_query(sql, name, *args) do
        select_rows_without_sql_safety_net(sql, name, *args)
      end
    end
    
    # Disable query analysis within a block.
    def disable_sql_safety_net
      save_disabled = Thread.current[:sql_safety_net_disable]
      begin
        Thread.current[:sql_safety_net_disable] = true
        yield
      ensure
        Thread.current[:sql_safety_net_disable] = save_disabled
      end
    end
    
    def analyze_query(sql, *args)
      # No op; other modules may redefine to analyze query plans
    end
    
    def select_statement?(sql)
      !!sql.match(SELECT_STATEMENT)
    end
    
    protected

    def select_with_sql_safety_net(sql, name = nil, *args)
      analyze_sql_safety_net_query(sql, name, *args) do
        select_without_sql_safety_net(sql, name, *args)
      end
    end
    
    private
    
    def analyze_sql_safety_net_query(sql, name, *args)
      if Thread.current[:sql_safety_net_disable]
        yield
      else
        t = Time.now.to_f
        query_results = nil
        disable_sql_safety_net do
          query_results = yield
        end
        elapsed_time = Time.now.to_f - t
      
        unless Thread.current[:sql_safety_net_disable]
          query_info = Thread.current[:sql_safety_net_query_info]
          if query_info
            query_info.count += 1
            query_info.selects += query_results.size
          end
          analysis = QueryAnalysis.current
          if analysis
            analysis.selects += 1
            analysis.rows += query_results.size
            analysis.elapsed_time += elapsed_time
            if SqlSafetyNet.config.debug?
              flagged = (@logger ? @logger.silence{analyze_query(sql, name, *args)} : analyze_query(sql, name, *args))
              if elapsed_time * 1000 >= SqlSafetyNet.config.time_limit
                flagged ||= {}
                flagged[:flags] ||= []
                flagged[:flags] << "query time exceeded #{SqlSafetyNet.config.time_limit} ms"
              end
              analysis.add_query(sql, name, query_results.size, elapsed_time, flagged)
            end
          end
        end

        query_results
      end
    end
  end
end
