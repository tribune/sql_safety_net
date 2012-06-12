require 'spec_helper'

describe SqlSafetyNet::ConnectionAdapter do
  
  let(:connection){ SqlSafetyNet::TestModel.connection }
  
  before :each do
    SqlSafetyNet::TestModel.delete_all
    SqlSafetyNet::TestModel.create!(:name => "test", :value => 10)
  end
  
  describe "injection" do
    it "should analyze queries in the select_rows method" do
      connection.should_receive(:analyze_query).with("select name, value from test_models", "SQL", []).and_yield
      connection.select_rows("select name, value from test_models", "SQL").should == [["test", 10]]
    end
    
    it "should analyze queries in the select method" do
      connection.should_receive(:analyze_query).with("select name, value from test_models", "SQL", []).and_yield
      connection.send(:select, "select name, value from test_models", "SQL").should == [{"name"=>"test", "value"=>10}]
    end
  end
  
  describe "analysis" do
    it "should not blow up if there is no current QueryAnalysis" do
      connection.select_rows("select name, value from test_models", "SQL").should == [["test", 10]]
    end
    
    context "select statements" do
      before :each do
        SqlSafetyNet::TestModel.create!(:name => "foo", :value => 100)
      end
      
      it "should analyze select statements" do
        SqlSafetyNet::QueryAnalysis.capture do |analysis|
          results = connection.send(:select, "select name, value from test_models order by name")
          results.should == [{"name" => "foo", "value" => 100}, {"name" => "test", "value" => 10}]
          analysis.queries.size.should == 1
          query_info = analysis.queries.first
          query_info.sql.should == "select name, value from test_models order by name"
          query_info.rows.should == 2
          query_info.result_size.should == 12
          query_info.elapsed_time.should > 0
        end
      end
      
      # ActiveRecord < 3.1 doesn't have the binds parameter
      if ActiveRecord::VERSION::MAJOR > 3 || (ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR >= 1)
        it "should analyze select statements using bind variables" do
          SqlSafetyNet::QueryAnalysis.capture do |analysis|
            name_column = SqlSafetyNet::TestModel.columns_hash["name"]
            results = connection.send(:select, "select name, value from test_models where name = ? order by name", "SQL", [[name_column, "foo"]])
            results.should == [{"name" => "foo", "value" => 100}]
            analysis.queries.size.should == 1
            query_info = analysis.queries.first
            query_info.sql.should == 'select name, value from test_models where name = ? order by name [["name", "foo"]]'
            query_info.rows.should == 1
            query_info.result_size.should == 6
            query_info.elapsed_time.should > 0
          end
        end
      end
      
      it "should analyze select_rows statements" do
        SqlSafetyNet::QueryAnalysis.capture do |analysis|
          results = connection.select_rows("select name, value from test_models order by name")
          results.should == [["foo", 100], ["test", 10]]
          analysis.queries.size.should == 1
          query_info = analysis.queries.first
          query_info.sql.should == "select name, value from test_models order by name"
          query_info.rows.should == 2
          query_info.result_size.should == 12
          query_info.elapsed_time.should > 0
        end
      end
    end
    
    context "non-select statements" do
      it "should not analyze schema statements" do
        SqlSafetyNet::QueryAnalysis.capture do |analysis|
          results = connection.select_rows("INSERT INTO test_models (name, value) VALUES ('moo', 1)")
          analysis.queries.should be_empty
        end
      end
      
      it "should not analyze explain statements" do
        SqlSafetyNet::QueryAnalysis.capture do |analysis|
          results = connection.select_rows("EXPLAIN select * from test_models")
          analysis.queries.should be_empty
        end
      end
      
      it "should not analyze insert statements" do
        SqlSafetyNet::QueryAnalysis.capture do |analysis|
          results = connection.select_rows("INSERT INTO test_models (name, value) VALUES ('moo', 1)")
          analysis.queries.should be_empty
        end
      end
      
      it "should not analyze update statements" do
        SqlSafetyNet::QueryAnalysis.capture do |analysis|
          results = connection.select_rows("UPDATE test_models SET value = 1 WHERE value = 10")
          analysis.queries.should be_empty
        end
      end
      
      it "should not analyze delete statements" do
        SqlSafetyNet::QueryAnalysis.capture do |analysis|
          results = connection.select_rows("DELETE FROM test_models WHERE id = 1")
          analysis.queries.should be_empty
        end
      end
    end
  end
  
  describe "ActiveRecord finders" do
    it "should analyze the queries" do
      SqlSafetyNet::QueryAnalysis.capture do |analysis|
        model = SqlSafetyNet::TestModel.all.first
        SqlSafetyNet::TestModel.find(model.id)
        analysis.total_queries.should == 2
      end
    end
  end
  
  describe "explain plan analysis" do
    it "should do further analysis on queries when the adapter support query plan analysis" do
      connection.should_receive(:respond_to?).with(:sql_safety_net_analyze_query_plan).and_return(true)
      connection.should_receive(:sql_safety_net_analyze_query_plan).with("SELECT * from test_models", []).and_return(["table scan"])
      
      SqlSafetyNet::QueryAnalysis.capture do |analysis|
        model = connection.select_all("SELECT * from test_models")
        analysis.queries.first.alerts.should == ["table scan"]
      end
    end
  end
  
end
