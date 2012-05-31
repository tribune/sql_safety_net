require 'spec_helper'

describe SqlSafetyNet::ConnectionAdapter::PostgreSQLAdapter do

  before(:each) do
    @connection = SqlSafetyNet::PostgresqlTestModel.connection
  end

  it "should use query plan analysis to flag queries" do
    query_plan = [{"QUERY PLAN"=>"Limit  (cost=0.00..0.06 rows=1 width=335)"}, {"QUERY PLAN"=>"  ->  Seq Scan on records  (cost=0.00..12.20 rows=220 width=335)"}]
    @connection.should_receive(:select_without_sql_safety_net).with('EXPLAIN Select sql', 'EXPLAIN', []).and_return(query_plan)
    @connection.should_receive(:analyze_query_plan).with(query_plan).and_return(["bad query"])
    @connection.analyze_query('Select sql', 'name', []).should == {:query_plan => query_plan, :flags => ["bad query"]}
  end

  it "should only analyze query plans for select statements" do
    @connection.should_not_receive(:select_without_sql_safety_net)
    @connection.should_not_receive(:analyze_query_plan)
    @connection.analyze_query('Execute sql', 'name', []).should == nil
  end
  
  it "should not flag a small table scan" do
    query_plan = [{"QUERY PLAN"=>"Seq Scan on records  (cost=0.00..12.20 rows=10 width=335)"}]
    @connection.send(:analyze_query_plan, query_plan).should == []
  end
  
  it "should flag a table scan" do
    query_plan = [{"QUERY PLAN"=>"Seq Scan on records  (cost=0.00..12.20 rows=1000000 width=335)"}]
    @connection.send(:analyze_query_plan, query_plan).should == ["table scan"]
  end
  
  it "should flag too many rows returned" do
    query_plan = [{"QUERY PLAN"=>"Index Scan using records_pkey on records  (cost=0.00..8.27 rows=1000000 width=336)"}]
    @connection.send(:analyze_query_plan, query_plan).should == ["examines 1000000 rows"]
  end
    
  it "should apply a limit to the rows returned" do
    query_plan = [{"QUERY PLAN"=>"Limit  (cost=0.00..0.06 rows=1 width=335)"}, {"QUERY PLAN"=>"  ->  Seq Scan on records  (cost=0.00..12.20 rows=1000000 width=335)"}]
    @connection.send(:analyze_query_plan, query_plan).should == []
  end
  
end

