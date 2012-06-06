module SqlSafetyNet
  class QueryAnalysis
    attr_reader :elapsed_time, :rows, :result_size, :queries
    
    class << self
      # Get the current analysis object in scope.
      def current
        Thread.current[:sql_safety_net_request_queries]
      end
      
      # Capture queries in a block for analysis. Within the block the +current+ method
      # can be called to the the current analysis object.
      def capture
        save_val = Thread.current[:sql_safety_net_request_queries]
        begin
          queries = new
          Thread.current[:sql_safety_net_request_queries] = queries
          yield queries
        ensure
          Thread.current[:sql_safety_net_request_queries] = save_val
        end
      end
    end
    
    def initialize
      @queries = []
      @elapsed_time = 0.0
      @rows = 0
      @result_size = 0
    end
    
    # Add a QueryInfo object to the analysis.
    def <<(query_info)
      @queries << query_info
      @elapsed_time += query_info.elapsed_time
      @rows += query_info.rows
      @result_size += query_info.result_size
    end
    
    def total_queries
      queries.size
    end
    
    def alerted_queries
      queries.select{|query| query.alerts?}.size
    end
    
    def alerts?
      queries.any?{|query| query.alerts?}
    end
    
    def too_many_rows?
      rows > SqlSafetyNet.config.returned_rows_limit
    end
    
    def too_many_queries?
      total_queries > SqlSafetyNet.config.query_limit
    end
    
    def results_too_big?
      result_size > SqlSafetyNet.config.result_size_limit
    end
    
    def too_much_time?
      elapsed_time > SqlSafetyNet.config.elapsed_time_limit
    end
    
    def flagged?
      alerts? || too_many_rows? || too_many_queries? || results_too_big? || too_much_time?
    end
  end
end
