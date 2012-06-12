module SqlSafetyNet
  # Class to store information about queries.
  class QueryInfo
    attr_reader :sql, :elapsed_time, :rows, :result_size, :alerts
    
    def initialize(sql, options = {})
      @sql = sql
      @elapsed_time = options[:elapsed_time] || 0.0
      @rows = options[:rows] || 0
      @result_size = options[:result_size] || 0
      @alerts = options[:alerts] || []
      @cached = !!options[:cached]
      analyze!
    end
    
    def cached?
      @cached
    end
    
    def alerts?
      !alerts.empty?
    end
    
    private
    
    def analyze!
      config = SqlSafetyNet.config
      alerts << "query took #{elapsed_time * 1000} ms" if elapsed_time > config.elapsed_time_limit
      alerts << "query returned #{rows}" if rows > config.returned_rows_limit
      alerts << "query returned ~#{result_size} bytes" if result_size > config.result_size_limit
    end
  end
end
