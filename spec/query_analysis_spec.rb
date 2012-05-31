require 'spec_helper'

describe SqlSafetyNet::QueryAnalysis do
  
  let(:analysis){ SqlSafetyNet::QueryAnalysis.new }
  
  it "should add a flagged query" do
    analysis.add_query("sql", "test", 10, 0.01, :query_plan => "this sucks", :flags => ["write better sql"])
    analysis.non_flagged_queries.should be_empty
    query = analysis.flagged_queries.first
    query[:sql].should == "sql"
    query[:name].should == "test"
    query[:rows].should == 10
    query[:elapsed_time].should == 0.01
    query[:query_plan].should == "this sucks"
    query[:flags].should == ["write better sql"]
    query[:cached].should == false
  end
  
  it "should add a non-flagged query" do
    analysis.add_query("sql", "test", 10, 0.01, nil)
    analysis.flagged_queries.should be_empty
    query = analysis.non_flagged_queries.first
    query[:sql].should == "sql"
    query[:name].should == "test"
    query[:rows].should == 10
    query[:elapsed_time].should == 0.01
    query[:cached].should == false
  end
  
  it "should determine if any query is flagged" do
    analysis.add_query("sql", "test", 10, 0.01, :query_plan => "this sucks", :flags => ["write better sql"])
    analysis.add_query("sql", "test", 10, 0.01, nil)
    analysis.should be_flagged
    analysis.flagged_queries?.should == true
  end
  
  it "should determine if the rows selected is flagged" do
    analysis.rows = 1000000
    analysis.should be_flagged
    analysis.too_many_rows?.should == true
  end
  
  it "should determine if the number of selects is flagged" do
    analysis.selects = 100000
    analysis.should be_flagged
    analysis.too_many_selects?.should == true
  end
  
  it "should set the analysis object within a block" do
    SqlSafetyNet::QueryAnalysis.analyze do
      SqlSafetyNet::QueryAnalysis.current.should be_a(SqlSafetyNet::QueryAnalysis)
    end
    SqlSafetyNet::QueryAnalysis.current.should == nil
  end
  
  it "should determine if a query is happening in a cache block" do
    cache = ActiveSupport::Cache::MemoryStore.new
    analysis = nil
    SqlSafetyNet::QueryAnalysis.analyze do
      val = cache.fetch("key") do
        analysis = SqlSafetyNet::QueryAnalysis.current
        analysis.add_query("sql", "test", 10, 0.01, nil)
        "woot"
      end
      val.should == "woot"
    end
    query = analysis.non_flagged_queries.first
    query[:cached].should == true
  end
end
