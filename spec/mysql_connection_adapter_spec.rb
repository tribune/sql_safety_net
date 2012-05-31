require 'spec_helper'

describe SqlSafetyNet::ConnectionAdapter::MysqlAdapter do
  
  before(:each) do
    @connection = SqlSafetyNet::MysqlTestModel.connection
  end

  it "should use query plan analysis to flag queries" do
    query_plan = [{'type' => 'ALL', 'rows' => 200}]
    @connection.should_receive(:select_without_sql_safety_net).with('EXPLAIN Select sql', 'EXPLAIN', []).and_return(query_plan)
    @connection.should_receive(:analyze_query_plan).with(query_plan).and_return(["bad query"])
    @connection.analyze_query('Select sql', 'name', []).should == {:query_plan => query_plan, :flags => ["bad query"]}
  end

  it "should only analyze query plans for select statements" do
    @connection.should_not_receive(:select_without_sql_safety_net)
    @connection.should_not_receive(:analyze_query_plan)
    @connection.analyze_query('Execute sql', 'name', []).should == nil
  end

  it "should translate query plans into flags" do
    @connection.send(:analyze_query_plan, [{'type' => 'ALL', 'rows' => 500}]).should == ["table scan", "no index used", "no indexes possible"]
    @connection.send(:analyze_query_plan, [{'Extra' => 'using temporary table; using filesort', 'rows' => 200, 'key' => 'index', 'possible_keys' => 'index'}]).should == ["uses temporary table for 200 rows", "uses filesort for 200 rows"]
    @connection.send(:analyze_query_plan, [{'select_type' => 'dependent subquery', 'rows' => 20, 'key' => 'index', 'possible_keys' => 'index'}]).should == ["dependent subquery"]
    @connection.send(:analyze_query_plan, [{'select_type' => 'uncacheable subquery', 'rows' => 20, 'key' => 'index', 'possible_keys' => 'index'}]).should == ["uncacheable subquery"]
    @connection.send(:analyze_query_plan, [{'rows' => 20000, 'key' => 'index', 'possible_keys' => 'index'}]).should == ["examines 20000 rows"]
    @connection.send(:analyze_query_plan, [{'select_type' => 'SIMPLE', 'rows' => 1, 'key' => 'index', 'possible_keys' => 'index'}]).should == []
  end
  
end

