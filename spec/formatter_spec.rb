require 'spec_helper'

describe SqlSafetyNet::Formatter do
  
  let(:query_info){ SqlSafetyNet::QueryInfo.new("SELECT * FROM *", :elapsed_time => 0.1, :rows => 1, :result_size => 500) }
  let(:analysis){ SqlSafetyNet::QueryAnalysis.new }
  
  it "should convert an analysis to valid XHTML" do
    analysis << query_info
    formatter = SqlSafetyNet::Formatter.new(analysis)
    html = formatter.to_html
    html.should match(/<div [^>]*id="_sql_safety_net_"/)
    parsed = ActiveSupport::XmlMini.parse(html)
    parsed["div"]["id"].should == "_sql_safety_net_"
  end
  
  it "should convert an analysis to a string" do
    analysis << query_info
    formatter = SqlSafetyNet::Formatter.new(analysis)
    text = formatter.to_s
    text.should include("1 query, 1 row")
  end
  
  it "should give a summary of an analysis" do
    analysis << query_info
    formatter = SqlSafetyNet::Formatter.new(analysis)
    formatter.summary.should == "1 query, 1 row, 0.5K, 100ms"
  end
  
  it "should pluralize words in the summary" do
    analysis << query_info
    analysis << query_info
    formatter = SqlSafetyNet::Formatter.new(analysis)
    formatter.summary.should == "2 queries, 2 rows, 1.0K, 200ms"
  end
  
  it "should creat a CSS style for the HTML div" do
    formatter = SqlSafetyNet::Formatter.new(analysis)
    style = formatter.div_style("width" => "200px", "left" => "10px", "text-decoration" => "underline", "font-weight" => nil)
    style.should include("left:10px;")
    style.should include("top:5px;")
    style.should include("width:200px")
    style.should include("text-decoration:underline")
    style.should_not include("font-weight")
  end
end
