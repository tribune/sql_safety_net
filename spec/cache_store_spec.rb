require 'spec_helper'

describe SqlSafetyNet::CacheStore do
  let(:cache){ ActiveSupport::Cache::MemoryStore.new }
  
  it "should set the caching flag on the current query analysis when fetching with a block" do
    SqlSafetyNet::QueryAnalysis.analyze do
      SqlSafetyNet::QueryAnalysis.current.caching?.should == false
      val = cache.fetch("key") do
        SqlSafetyNet::QueryAnalysis.current.caching?.should == true
        "woot"
      end
      val.should == "woot"
    end
  end
  
  it "should fetch properly even when there is not current query analysis" do
    SqlSafetyNet::QueryAnalysis.current.should == nil
    val = cache.fetch("key") do
      SqlSafetyNet::QueryAnalysis.current.should == nil
      "woot"
    end
    val.should == "woot"
  end
  
end
