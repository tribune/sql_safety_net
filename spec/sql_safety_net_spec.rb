require 'spec_helper'

describe SqlSafetyNet do
  
  it "should have a singleton config" do
    config = SqlSafetyNet.config
    config.should be_a(SqlSafetyNet::Configuration)
    config.object_id.should == SqlSafetyNet.config.object_id
  end
  
  it "should be able to override the config in a block" do
    original_config = SqlSafetyNet.config
    original_style = original_config.style.dup
    SqlSafetyNet.override_config do |config|
      config.object_id.should_not == original_config.object_id
      config.style = {"top" => "5px"}
    end
    original_config.style.should == original_style
  end
  
end
