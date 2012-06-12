require 'spec_helper'

describe SqlSafetyNet::QueryInfo do
  
  describe "constructor" do
    it "should keep the sql passed in to the constructor" do
      query_info = SqlSafetyNet::QueryInfo.new("SELECT * FROM *")
      query_info.sql.should == "SELECT * FROM *"
    end
    
    it "should keep the elapsed time passed in :elapsed_time option" do
      query_info = SqlSafetyNet::QueryInfo.new("SELECT * FROM *", :elapsed_time => 0.1)
      query_info.elapsed_time.should == 0.1
    end
    
    it "should keep the rows passed in :rows option" do
      query_info = SqlSafetyNet::QueryInfo.new("SELECT * FROM *", :rows => 10)
      query_info.rows.should == 10
    end
    
    it "should keep the result_size passed in :result_size option" do
      query_info = SqlSafetyNet::QueryInfo.new("SELECT * FROM *", :result_size => 100)
      query_info.result_size.should == 100
    end
    
    it "should keep the cached value passed in :cached option" do
      query_info = SqlSafetyNet::QueryInfo.new("SELECT * FROM *", :cached => true)
      query_info.cached?.should == true
    end
  end
  
  describe "alerts" do
    it "should not have any alerts by default" do
      query_info = SqlSafetyNet::QueryInfo.new("SELECT * FROM *")
      query_info.alerts.should == []
    end
    
    it "should indicate if it has any alerts" do
      query_info = SqlSafetyNet::QueryInfo.new("SELECT * FROM *")
      query_info.alerts?.should == false
      query_info.alerts << "problem"
      query_info.alerts?.should == true
    end
  end
  
end
