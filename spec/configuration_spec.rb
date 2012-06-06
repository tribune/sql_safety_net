require 'spec_helper'

describe SqlSafetyNet::Configuration do
  
  let(:config){ SqlSafetyNet::Configuration.new }
  
  describe "standard settings" do
    it "should have a query_limit with a default of 10" do
      config.query_limit.should == 10
      config.query_limit = 100
      config.query_limit.should == 100
    end
  
    it "should have a returned_rows_limit with a default of 100" do
      config.returned_rows_limit.should == 100
      config.returned_rows_limit = 200
      config.returned_rows_limit.should == 200
    end
  
    it "should have a result_size_limit with a default of 16K" do
      config.result_size_limit.should == 16 * 1024
      config.result_size_limit = 10000
      config.result_size_limit.should == 10000
    end
  
    it "should have a elapsed_time_limit with a default of 300ms" do
      config.elapsed_time_limit.should == 0.3
      config.elapsed_time_limit = 1
      config.elapsed_time_limit.should == 1
    end
  end
  
  describe "query plan limits" do
    it "should have a table_scan_limit with a default of 100 rows" do
      config.table_scan_limit.should == 100
      config.table_scan_limit = 200
      config.table_scan_limit.should == 200
    end
  
    it "should have a temporary_table_limit with a default of 100 rows" do
      config.temporary_table_limit.should == 100
      config.temporary_table_limit = 200
      config.temporary_table_limit.should == 200
    end
  
    it "should have a filesort_limit with a default of 100 rows" do
      config.filesort_limit.should == 100
      config.filesort_limit = 200
      config.filesort_limit.should == 200
    end
  
    it "should have an examined_rows_limit with a default of 5000 rows" do
      config.examined_rows_limit.should == 5000
      config.examined_rows_limit = 10000
      config.examined_rows_limit.should == 10000
    end
  end

  describe "debugging information" do
    it "should have a flag to always_show debugging info" do
      config.always_show.should == false
      config.always_show = true
      config.always_show.should == true
    end
  
    it "should have css style" do
      config.style.should == {}
      config.style = {"top" => "5px", "right" => "5px"}
      config.style.should == {"top" => "5px", "right" => "5px"}
    end
  end
end
