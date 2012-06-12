require 'spec_helper'

describe SqlSafetyNet::CacheStore do
  
  let(:cache){ ActiveSupport::Cache::MemoryStore.new }
  
  it "should determine if code is inside a cache fetch block" do
    SqlSafetyNet::CacheStore.in_fetch_block?.should == false
    val = cache.fetch("foo") do
      SqlSafetyNet::CacheStore.in_fetch_block?.should == true
      "bar"
    end
    val.should == "bar"
    SqlSafetyNet::CacheStore.in_fetch_block?.should == false
  end
  
end
