require 'spec_helper'

describe SqlSafetyNet::RackHandler do

  class SqlSafetyNet::TestApp
    attr_accessor :response, :block
    
    def initialize
      @response = Rack::Response.new
    end
    
    def call (env)
      @block.call(env) if @block
      @response["Content-Type"] = env["response_content_type"] if env["response_content_type"]
      @response.finish
    end
  end
  
  before(:each) do
    SqlSafetyNet.config.debug = true
    SqlSafetyNet::QueryAnalysis.clear
  end
  
  let(:logger) do
    logger = Object.new
    def logger.warn (message)
      # noop
    end
    logger
  end
  
  let(:app){ SqlSafetyNet::TestApp.new }
  
  let(:handler){ SqlSafetyNet::RackHandler.new(app, logger) }
  
  let(:env) do
    {
      "rack.url_scheme" => "http",
      "PATH_INFO" => "/test",
      "SERVER_PORT" => 80,
      "HTTP_HOST" => "example.com",
      "REQUEST_METHOD" => "GET"
    }
  end

  it "should append the bad queries to the HTML when debug is enabled and always_show is false" do
    SqlSafetyNet.config.always_show = false
    
    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.flagged_queries << {:sql => 'sql', :query_plan => 'bad plan', :flags => ['bad query'], :rows => 4, :elapsed_time => 0.1}
    end
    app.response.write("Monkeys are neat.")
    
    r = handler.call(env)
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should include('<div id="sql_safety_net_warning"')
    response.body.join("").should include("Monkeys are neat.")
    response["X-SqlSafetyNet"].should == "selects=0; rows=0; elapsed_time=0; flagged_queries=1"
  end

  it "should not append the bad queries to the HTML when there are none and always_show is false" do
    SqlSafetyNet.config.always_show = false
    
    app.response.write("Monkeys are neat.")
       
    r = handler.call(env)
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should == "Monkeys are neat."
    response["X-SqlSafetyNet"].should == "selects=0; rows=0; elapsed_time=0; flagged_queries=0"
  end
  
  it "should append the queries to the HTML when there are none and always_show is true" do
    SqlSafetyNet.config.always_show = true
    
    app.response.write("Monkeys are neat.")
    
    r = handler.call(env)
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should include('<div id="sql_safety_net_warning"')
    response.body.join("").should include("Monkeys are neat.")
    response["X-SqlSafetyNet"].should == "selects=0; rows=0; elapsed_time=0; flagged_queries=0"
  end
  
  it "should append the bad queries to XML when debug is enabled" do
    SqlSafetyNet.config.always_show = false
    
    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.flagged_queries << {:sql => 'sql', :query_plan => 'bad plan', :flags => ['bad query'], :rows => 4, :elapsed_time => 0.1}
    end
    app.response.write("<woot>Monkeys are neat.</woot>")
    
    r = handler.call(env.merge("response_content_type" => "application/xml"))
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should_not include('<div id="sql_safety_net_warning"')
    response.body.join("").should include("<!-- SqlSafetyNet")
    response.body.join("").should include("<woot>Monkeys are neat.</woot>")
    Hash.from_xml(response.body.join('')).should == {"woot" => "Monkeys are neat."}
    response["X-SqlSafetyNet"].should == "selects=0; rows=0; elapsed_time=0; flagged_queries=1"
  end
  
  it "should not append the bad queries to the HTML or add a response header if debug is not enabled" do
    SqlSafetyNet.config.debug = false

    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.flagged_queries << {:sql => 'sql', :query_plan => 'bad plan', :flags => ['bad query'], :rows => 4, :elapsed_time => 0.1}
    end
    app.response.write("Monkeys are neat.")
    
    r = handler.call(env)
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should == "Monkeys are neat."
    response["X-SqlSafetyNet"].should == nil
  end
  
  it "should not append the bad queries to the HTML if not text/html" do
    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.flagged_queries << {:sql => 'sql', :query_plan => 'bad plan', :flags => ['bad query'], :rows => 4, :elapsed_time => 0.1}
    end
    app.response.write("Monkeys are neat.")
    app.response["Content-Type"] = "text/plain"
    
    r = handler.call(env)
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should == "Monkeys are neat."
    response["X-SqlSafetyNet"].should == "selects=0; rows=0; elapsed_time=0; flagged_queries=1"
  end
  
  it "should not append the bad queries to the HTML if Ajax request" do
    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.flagged_queries << {:sql => 'sql', :query_plan => 'bad plan', :flags => ['bad query'], :rows => 4, :elapsed_time => 0.1}
    end
    app.response.write("Monkeys are neat.")
    app.response["Content-Type"] = "text/plain"
    
    r = handler.call(env.merge("HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"))
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should == "Monkeys are neat."
    response["X-SqlSafetyNet"].should == "selects=0; rows=0; elapsed_time=0; flagged_queries=1"
  end
  
  it "should log too many selects even if debug is not enabled" do
    SqlSafetyNet.config.debug = false
    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.selects = 1000
    end
    logger.should_receive(:warn).with("Excess database usage: request generated 1000 queries and returned 0 rows [GET http://example.com/test]")
    r = handler.call(env)
  end
  
  it "should log too many rows even if debug is not enabled" do
    SqlSafetyNet.config.debug = false
    SqlSafetyNet.config.header = false
    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.rows = 10000
    end
    app.response.write("Monkeys are neat.")
    
    logger.should_receive(:warn).with("Excess database usage: request generated 0 queries and returned 10000 rows [GET http://example.com/test]")
    r = handler.call(env)
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should == "Monkeys are neat."
    response["X-SqlSafetyNet"].should == nil
  end
  
  it "should log too many rows even if debug is not enabled" do
    SqlSafetyNet.config.debug = false
    SqlSafetyNet.config.header = true
    app.block = lambda do |env|
      SqlSafetyNet::QueryAnalysis.current.rows = 10
    end
    app.response.write("Monkeys are neat.")
    r = handler.call(env)
    response = Rack::Response.new(r[2], r[0], r[1])
    
    response.body.join("").should == "Monkeys are neat."
    response["X-SqlSafetyNet"].should == "selects=0; rows=10; elapsed_time=0; flagged_queries=0"
  end
  
  it "should not log warnings if there are none" do
    SqlSafetyNet.config.debug = false
    logger.should_not_receive(:warn)
    r = handler.call(env)
  end

end
