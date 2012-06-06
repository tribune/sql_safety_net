module SqlSafetyNet
  # Query plan analysis is supported out of the box for MySQL and PostgreSQL.
  #
  # If you wish to implement it for another database, you'll need to create a module that defines
  # the +sql_safety_net_analyze_query_plan+ method and takes arguments for the sql to execute and
  # an array of bind values.
  module ExplainPlan
    autoload :Mysql, File.expand_path("../explain_plan/mysql.rb", __FILE__)
    autoload :Postgresql, File.expand_path("../explain_plan/postgresql.rb", __FILE__)
    
    class << self
      # Enable query plan analysize on a connection adapter class. The explain_plan_analyzer argument
      # can either be <tt>:mysql</tt>, <tt>:postgresql</tt> or a module that defines a
      # <tt>sql_safety_net_analyze_query_plan(sql, binds)</tt> method.
      def enable_on_connection_adapter!(connection_adapter_class, explain_plan_analyzer)
        if explain_plan_analyzer.is_a?(Symbol)
          class_name = explain_plan_analyzer.to_s.camelize
          explain_plan_analyzer = ExplainPlan.const_get(class_name)
        end
        connection_adapter_class.send(:include, explain_plan_analyzer) unless connection_adapter_class.include?(explain_plan_analyzer)
      end
    end
  end
end
