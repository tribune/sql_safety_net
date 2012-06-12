require 'spec_helper'

describe SqlSafetyNet::ExplainPlan::Mysql do

  class MockMysqlConnection; end
  SqlSafetyNet::ExplainPlan.enable_on_connection_adapter!(MockMysqlConnection, :mysql)
  
  let(:connection){ MockMysqlConnection.new }
  let(:sql){ "SELECT * FROM *" }
  
  it "should detect table scans" do
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"type" => "ALL", "rows" => 100}])
    
    SqlSafetyNet.override_config do |config|
      config.table_scan_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("table scan on 100 rows")
      
      config.table_scan_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should be_empty
    end
  end
  
  it "should detect no indexes being used" do
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"key" => nil, "rows" => 100}])
    
    SqlSafetyNet.override_config do |config|
      config.table_scan_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("no index used")
      
      config.table_scan_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should_not include("no index used")
    end
  end
  
  it "should detect no indexes possible" do
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"possible_keys" => nil, "rows" => 100}])
    
    SqlSafetyNet.override_config do |config|
      config.table_scan_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("no index possible")
      
      config.table_scan_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should_not include("no index possible")
    end
  end
  
  it "should detect dependent subqueries" do
    connection.should_receive(:select).with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"select_type" => "dependent", "rows" => 100}])
    alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
    alerts.should include("dependent subquery")
  end
  
  it "should detect uncacheable subqueries" do
    connection.should_receive(:select).with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"select_type" => "uncacheable", "rows" => 100}])
    alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
    alerts.should include("uncacheable subquery")
  end
  
  it "should detect full scan on null key" do
    connection.should_receive(:select).with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"Extra" => "full scan on null key", "rows" => 100}])
    alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
    alerts.should include("full scan on null key")
  end
  
  it "should detect excess temporary table usage" do
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"Extra" => "using temporary", "rows" => 100}])
    
    SqlSafetyNet.override_config do |config|
      config.temporary_table_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("uses temporary table for 100 rows")
      
      config.temporary_table_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should_not include("uses temporary table for 100 rows")
    end
  end
  
  it "should detect excess filesort usage" do
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"Extra" => "filesort", "rows" => 100}])
    
    SqlSafetyNet.override_config do |config|
      config.filesort_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("uses filesort for 100 rows")
      
      config.filesort_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should_not include("uses filesort for 100 rows")
    end
  end
  
  it "should detect examining too many rows" do
    connection.should_receive(:select).twice.with("EXPLAIN #{sql}", "EXPLAIN", []).and_return([{"rows" => 100}])
    
    SqlSafetyNet.override_config do |config|
      config.examined_rows_limit = 99
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should include("examined 100 rows")
      
      config.examined_rows_limit = 100
      alerts = connection.sql_safety_net_analyze_query_plan(sql, [])
      alerts.should be_empty
    end
  end

end
