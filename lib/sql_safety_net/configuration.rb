module SqlSafetyNet
  # This class provides configuration options for SQL analysis.
  #
  # These options specify when a warning will be triggered based on the totals from all queries
  # in a single request:
  #
  # * query_limit - the total number of queries (default to 10)
  # * returned_rows_limit - the total number of rows returned (defaults to 100)
  # * result_size_limit - the number of bytes returned by all queries (defaults to 16K)
  # * elapsed_time_limit - the number of seconds taken for all queries (defaults to 0.3)
  #
  # These options specify when a warning will be triggered on a single query. These options are only
  # available when using MySQL:
  #
  # * table_scan_limit - the number of rows in a table scan that will trigger a warning (defaults to 100)
  # * temporary_table_limit - the number of temporary table rows that will trigger a warning (defaults to 100)
  # * filesort_limit - the number of rows in a filesort operation that will trigger a warning (defaults to 100)
  # * examined_rows_limit - the number of rows examined in a query that will trigger a warning (defaults to 5000)
  #
  # These options specify details about embedding debugging info in HTML pages
  #
  # * always_show - set to true to always show debugging info; otherwise only shown if the request is flagged (defaults to false)
  # * style - set to a hash of CSS styles used to style the debugging info; defaults to appearing in the upper right corner
  class Configuration
    attr_accessor :query_limit, :returned_rows_limit, :result_size_limit, :elapsed_time_limit
    attr_accessor :table_scan_limit, :temporary_table_limit, :filesort_limit, :examined_rows_limit
    attr_accessor :always_show, :style
    
    def initialize
      @query_limit = 10
      @returned_rows_limit = 100
      @result_size_limit = 16 * 1024
      @elapsed_time_limit = 0.3
      
      @table_scan_limit = 100
      @temporary_table_limit = 100
      @filesort_limit = 100
      @examined_rows_limit = 5000
      
      @always_show = false
      @style = {}
      
      yield(self) if block_given?
    end
  end
end
