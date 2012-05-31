module SqlSafetyNet
  # Configuration for SqlSafetyNet. The various limit attributes are used for adapters that can do query analysis. Queries
  # will be flagged if their query plan exceeds a limit.
  class Configuration
    attr_accessor :table_scan_limit, :temporary_table_limit, :filesort_limit, :return_rows_limit, :examine_rows_limit, :query_limit, :time_limit, :position
    
    def initialize
      @debug = false
      @header = false
      @table_scan_limit = 100
      @temporary_table_limit = 100
      @filesort_limit = 100
      @return_rows_limit = 100
      @examine_rows_limit = 5000
      @query_limit = 10
      @always_show = false
      @position = "top:5px; right: 5px;"
      @time_limit = 300
    end
    
    # Enable SqlSafetyNet on a connection. Unless this method is called, the code will not be mixed into the database
    # adapter. This should normally be called only in the development environment.
    def enable_on(connection_class)
      connection_class = connection_class.constantize unless connection_class.is_a?(Class)
      connection_class_name = connection_class.name.split('::').last
      include_class = ConnectionAdapter.const_get(connection_class_name) if ConnectionAdapter.const_defined?(connection_class_name)
      connection_class.send(:include, ConnectionAdapter) unless connection_class.include?(ConnectionAdapter)
      connection_class.send(:include, include_class) if include_class && !connection_class.include?(include_class)
    end
    
    def debug=(val)
      @debug = !!val
    end

    def debug?
      @debug
    end
    
    def header=(val)
      @header = !!val
    end

    def header?
      @header
    end
    
    # Set a flag to always show information about queries on rendered HTML pages. If this is not set to true, the debug
    # information will only be shown if the queries on the page exceed one of the limits.
    def always_show=(val)
      @always_show = !!val
    end
    
    def always_show?
      @always_show
    end
  end
end
