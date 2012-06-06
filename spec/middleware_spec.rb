require 'spec_helper'

describe SqlSafetyNet::Middleware do
  
  before :all do
    SqlSafetyNet::TestModel.delete_all
    SqlSafetyNet::TestModel.create(:name => "test")
  end
  
  let(:app){ lambda{|env| [env[:status] || 200, {"Content-Type" => env[:type] || "text/plain"}, ["<body>Hello</body>"]]} }
  let(:app_with_query){ lambda{|env| SqlSafetyNet::TestModel.first; [env[:status] || 200, {"Content-Type" => env[:type] || "text/plain"}, ["<body>Hello</body>"]]} }
  
  it "should return the original response code" do
    middleware = SqlSafetyNet::Middleware.new(app)
    response = middleware.call(:status => 301)
    response = Rack::Response.new(response[2], response[0], response[1])
    response.status.should == 301
  end
  
  it "should not return the X-SqlSafetyNet header if not queries occurred" do
    middleware = SqlSafetyNet::Middleware.new(app)
    response = middleware.call(:status => 200)
    response = Rack::Response.new(response[2], response[0], response[1])
    response["X-SqlSafetyNet"].should == nil
  end
  
  it "should return the original response headers plus X-SqlSafetyNet" do
    middleware = SqlSafetyNet::Middleware.new(app_with_query)
    response = middleware.call(:status => 200)
    response = Rack::Response.new(response[2], response[0], response[1])
    response["X-SqlSafetyNet"].should include("1 query, 1 row")
  end
  
  it "should return the original body if no queries performed" do
    middleware = SqlSafetyNet::Middleware.new(app)
    response = middleware.call(:type => "text/html")
    response = Rack::Response.new(response[2], response[0], response[1])
    body = response.body.join("")
    body.should == "<body>Hello</body>"
  end
  
  it "should return the original body plus the sql analysis if HTML and not Ajax and always show is on" do
    SqlSafetyNet.override_config do |config|
      config.always_show = true
      middleware = SqlSafetyNet::Middleware.new(app_with_query)
      response = middleware.call(:type => "text/html; charset=UTF-8")
      response = Rack::Response.new(response[2], response[0], response[1])
      body = response.body.join("")
      body.should include("<body>Hello</body>")
      body.should include("_sql_safety_net_")
    end
  end
  
  it "should return the original body plus the sql analysis if XHTML and not Ajax and the queries are flagged" do
    SqlSafetyNet.override_config do |config|
      config.query_limit = 0
      middleware = SqlSafetyNet::Middleware.new(app_with_query)
      response = middleware.call(:type => "text/xhtml; charset=UTF-8")
      response = Rack::Response.new(response[2], response[0], response[1])
      body = response.body.join("")
      body.should include("<body>Hello</body>")
      body.should include("_sql_safety_net_")
    end
  end
  
  it "should return the original body only if always_on is false and no flagged query" do
    middleware = SqlSafetyNet::Middleware.new(app_with_query)
    response = middleware.call(:type => "text/html; charset=UTF-8")
    response = Rack::Response.new(response[2], response[0], response[1])
    body = response.body.join("")
    body.should == "<body>Hello</body>"
  end
  
  it "should return the original body only if Ajax" do
    middleware = SqlSafetyNet::Middleware.new(app)
    response = middleware.call(:type => "text/html", "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest")
    response = Rack::Response.new(response[2], response[0], response[1])
    body = response.body.join("")
    body.should == "<body>Hello</body>"
  end
  
  it "should return the original body only if not HTML" do
    middleware = SqlSafetyNet::Middleware.new(app)
    response = middleware.call(:type => "text/plain")
    response = Rack::Response.new(response[2], response[0], response[1])
    body = response.body.join("")
    body.should == "<body>Hello</body>"
  end
  
end
