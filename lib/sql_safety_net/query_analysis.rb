module SqlSafetyNet
  # Analysis container for the sql queries in a context.
  class QueryAnalysis
    attr_accessor :selects, :rows, :elapsed_time
    attr_reader :flagged_queries, :non_flagged_queries
    attr_writer :caching

    def initialize
      @selects = 0
      @rows = 0
      @elapsed_time = 0.0
      @flagged_queries = []
      @non_flagged_queries = []
      @caching = false
    end

    # Analyze all queries within a block.
    def self.analyze
      Thread.current[:sql_safety_net] = new
      begin
        yield
        return current
      ensure
        clear
      end
    end

    # Get the current analysis object.
    def self.current
      Thread.current[:sql_safety_net]
    end

    # Clear all query information from the current analysis.
    def self.clear
      Thread.current[:sql_safety_net] = nil
    end
    
    def caching?
      @caching
    end
    
    def flagged?
      too_many_selects? || too_many_rows? || flagged_queries?
    end
    
    def too_many_selects?
      selects > SqlSafetyNet.config.query_limit
    end

    def too_many_rows?
      rows > SqlSafetyNet.config.return_rows_limit
    end

    def flagged_queries?
      !flagged_queries.empty?
    end
    
    def add_query(sql, name, rows, elapsed_time, flagged)
      info = {:sql => sql, :name => name, :rows => rows, :elapsed_time => elapsed_time, :cached => caching?}
      if flagged.blank?
        non_flagged_queries << info
      else
        info[:query_plan] = flagged[:query_plan]
        info[:flags] = flagged[:flags]
        flagged_queries << info
      end
    end
  end
end
