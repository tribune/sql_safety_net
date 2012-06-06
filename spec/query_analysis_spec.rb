require 'spec_helper'

describe SqlSafetyNet::QueryAnalysis do
  
  let(:analysis){ SqlSafetyNet::QueryAnalysis.new }
  let(:query_info){ SqlSafetyNet::QueryInfo.new("SELECT * FROM *", :elapsed_time => 0.1, :rows => 2, :result_size => 500) }
  
  it "should instantiate a query analysis inside a block" do
    SqlSafetyNet::QueryAnalysis.current.should == nil
    result = SqlSafetyNet::QueryAnalysis.capture do |analysis_1|
      analysis_1.should be_a(SqlSafetyNet::QueryAnalysis)
      SqlSafetyNet::QueryAnalysis.capture do |analysis_2|
        analysis_2.should be_a(SqlSafetyNet::QueryAnalysis)
        "hello"
      end
    end
    SqlSafetyNet::QueryAnalysis.current.should == nil
    result.should == "hello"
  end
  
  it "should track the number of queries" do
    analysis.queries.should == []
    analysis.total_queries.should == 0
    analysis << query_info
    analysis.queries.should == [query_info]
    analysis.total_queries.should == 1
    analysis << query_info
    analysis.queries.should == [query_info, query_info]
    analysis.total_queries.should == 2
  end
  
  it "should track the elasped time of all queries" do
    analysis.elapsed_time.should == 0.0
    analysis << query_info
    analysis.elapsed_time.should == 0.1
    analysis << query_info
    analysis.elapsed_time.should == 0.2
  end
  
  it "should track the rows of all queries" do
    analysis.rows.should == 0
    analysis << query_info
    analysis.rows.should == 2
    analysis << query_info
    analysis.rows.should == 4
  end
  
  it "should track the result size of all queries" do
    analysis.result_size.should == 0
    analysis << query_info
    analysis.result_size.should == 500
    analysis << query_info
    analysis.result_size.should == 1000
  end
  
  describe "flags" do
    it "should determine the number of queries that have alerts" do
      analysis.alerted_queries.should == 0
      analysis << query_info
      analysis.alerted_queries.should == 0
      analysis << SqlSafetyNet::QueryInfo.new("SELECT *", :alerts => ["boom"])
      analysis.alerted_queries.should == 1
    end
    
    it "should determine if any queries have alerts" do
      analysis.alerts?.should == false
      analysis << query_info
      analysis.alerts?.should == false
      analysis << SqlSafetyNet::QueryInfo.new("SELECT *", :alerts => ["boom"])
      analysis.alerts?.should == true
    end
    
    it "should determine if too many queries have been made" do
      SqlSafetyNet.override_config do |config|
        config.query_limit = 1
        analysis << query_info
        analysis.too_many_queries?.should == false
        analysis << query_info
        analysis.too_many_queries?.should == true
      end
    end
    
    it "should determine if too many rows have been returned" do
      SqlSafetyNet.override_config do |config|
        config.returned_rows_limit = 3
        analysis << query_info
        analysis.too_many_rows?.should == false
        analysis << query_info
        analysis.too_many_rows?.should == true
      end
    end
    
    it "should determine if the results are too big" do
      SqlSafetyNet.override_config do |config|
        config.result_size_limit = 600
        analysis << query_info
        analysis.results_too_big?.should == false
        analysis << query_info
        analysis.results_too_big?.should == true
      end
    end
    
    it "should determine if the queries take too much time" do
      SqlSafetyNet.override_config do |config|
        config.elapsed_time_limit = 0.15
        analysis << query_info
        analysis.too_much_time?.should == false
        analysis << query_info
        analysis.too_much_time?.should == true
      end
    end
  end
end
