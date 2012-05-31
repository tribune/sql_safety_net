require 'spec_helper'

describe SqlSafetyNet::Configuration do

  before :each do
    @config = SqlSafetyNet::Configuration.new
  end
  
  it "should be able to set debug" do
    @config.debug?.should == false
    @config.debug = true
    @config.debug?.should == true
    @config.debug = false
    @config.debug?.should == false
  end

  it "should be able to set header" do
    @config.header?.should == false
    @config.header = true
    @config.header?.should == true
    @config.header = false
    @config.header?.should == false
  end

  it "should be able to set table_scan_limit" do
    @config.table_scan_limit = 500
    @config.table_scan_limit.should == 500
  end

  it "should be able to set temporary_table_limit" do
    @config.temporary_table_limit = 50
    @config.temporary_table_limit.should == 50
  end

  it "should be able to set filesort_limit" do
    @config.filesort_limit = 600
    @config.filesort_limit.should == 600
  end

  it "should be able to set examine_rows_limit" do
    @config.examine_rows_limit = 1000
    @config.examine_rows_limit.should == 1000
  end

  it "should be able to set return_rows_limit" do
    @config.return_rows_limit = 1000
    @config.return_rows_limit.should == 1000
  end

  it "should be able to set query_limit" do
    @config.query_limit = 20
    @config.query_limit.should == 20
  end

  it "should be able to set time_limit" do
    @config.time_limit = 200
    @config.time_limit.should == 200
  end

  it "should be able to set always_show" do
    @config.always_show = true
    @config.always_show?.should == true
    @config.always_show = nil
    @config.always_show?.should == false
  end

end
