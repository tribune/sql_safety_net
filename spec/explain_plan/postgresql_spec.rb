require 'spec_helper'

describe SqlSafetyNet::ExplainPlan::Postgresql do
  class PostgresqlConnection; end
  SqlSafetyNet::ExplainPlan.enable_on_connection_adapter!(PostgresqlConnection, :postgresql)
  
  let(:connection){ PostgresqlConnection.new }
  let(:sql){ "SELECT * FROM *" }
  
  it "should flag excessive table scans" do
    query_plan = [{"QUERY PLAN"=>"Seq Scan on records  (cost=0.00..12.20 rows=100 width=335)"}]
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", 'EXPLAIN', []).and_return(query_plan)
    SqlSafetyNet.override_config do |config|
      config.table_scan_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("table scan on ~100 rows")
      
      config.table_scan_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should be_empty
    end
  end
  
  it "should flag too many rows examined" do
    query_plan = [{"QUERY PLAN"=>"Index Scan using records_pkey on records  (cost=0.00..8.27 rows=100 width=336)"}]
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", 'EXPLAIN', []).and_return(query_plan)
    SqlSafetyNet.override_config do |config|
      config.examined_rows_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("examined ~100 rows")
      
      config.examined_rows_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should be_empty
    end
  end
    
  it "should apply a limit to the rows returned" do
    query_plan = [{"QUERY PLAN"=>"Limit  (cost=0.00..0.06 rows=1 width=335)"}, {"QUERY PLAN"=>"  ->  Seq Scan on records  (cost=0.00..12.20 rows=1000000 width=335)"}]
    connection.should_receive(:select).with("EXPLAIN #{sql}", 'EXPLAIN', []).and_return(query_plan)
    alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
    alerts.should be_empty
  end
end
