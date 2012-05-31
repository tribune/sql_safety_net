require 'spec_helper'

describe SqlSafetyNet::ConnectionAdapter do
  
  class SqlSafetyNet::TestConnectionAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
    class Model
      attr_accessor :id, :name
      def initialize (attrs)
        @id = attrs["id"]
        @name = attrs["name"]
      end
    end
    
    def columns (table_name, name = nil)
      select_rows("GET columns")
      ["id", "name"]
    end
    
    def select_rows (sql, name = nil, binds = [])
      return [{"id" => 1, "name" => "foo"}, {"id" => 2, "name" => "bar"}]
    end
    
    protected
    
    def analyze_query (sql, name, *args)
      if sql.match(/table scan/i)
        {:flags => ["table scan"]}
      end
    end
    
    def select (sql, name = nil, binds = [])
      select_rows(sql, name).collect do |row|
        Model.new(row)
      end
    end
    
    SqlSafetyNet.config.enable_on(self)
  end
  
  before(:each) do
    SqlSafetyNet.config.debug = true
    SqlSafetyNet::QueryAnalysis.clear
  end
  
  after(:each) do
    SqlSafetyNet::QueryAnalysis.clear
  end
  
  let(:connection){ SqlSafetyNet::TestConnectionAdapter.new(:connection) }

  it "should not analyze the SQL select in the columns method" do
    connection.should_receive(:columns_without_sql_safety_net).with("table", "columns").and_return(["col1", "col2"])
    analysis = SqlSafetyNet::QueryAnalysis.analyze do
      connection.columns("table", "columns").should == ["col1", "col2"]
    end
    analysis.selects.should == 0
  end

  it "should not analyze the SQL select in the active? method" do
    connection.should_receive(:active_without_sql_safety_net?).and_return(true)
    analysis = SqlSafetyNet::QueryAnalysis.analyze do
      connection.active?.should == true
    end
    analysis.selects.should == 0
  end
  
  it "should determine if a SQL statement is a select statement" do
    connection.select_statement?("SELECT * FROM TABLE").should == true
    connection.select_statement?(" \n SELECT * FROM TABLE").should == true
    connection.select_statement?("Select * From Table").should == true
    connection.select_statement?("select * from table").should == true
    connection.select_statement?("EXECUTE SELECT * FROM TABLE").should == false
  end
  
  [:select, :select_rows].each do |select_method|
    context select_method do
      it "should proxy the select method to the underlying adapter" do
        connection.should_receive("#{select_method}_without_sql_safety_net").with('Select sql', 'name').and_return([:row1, :row2])
        connection.send(select_method, 'Select sql', 'name').should == [:row1, :row2]
      end
    
      it "should count selects" do
        analysis = SqlSafetyNet::QueryAnalysis.analyze do
          connection.send(select_method, 'Select * from table')
          connection.send(select_method, 'Select * from table where whatever')
        end
        analysis.selects.should == 2
      end
    
      it "should count rows returned" do
        analysis = SqlSafetyNet::QueryAnalysis.analyze do
          connection.send(select_method, 'Select * from table')
          connection.send(select_method, 'Select * from table where whatever')
        end
        analysis.rows.should == 4
      end
  
      it "should analyze select statements and keep track of bad queries" do
        analysis = SqlSafetyNet::QueryAnalysis.analyze do
          connection.send(select_method, 'Select * from table doing table scan')
        end
        analysis.non_flagged_queries.size.should == 0
        analysis.flagged_queries.size.should == 1
        analysis.flagged_queries.first[:sql].should == 'Select * from table doing table scan'
        analysis.flagged_queries.first[:rows].should == 2
        analysis.flagged_queries.first[:flags].should == ['table scan']
      end

      it "should analyze select statements and keep track of good queries" do
        analysis = SqlSafetyNet::QueryAnalysis.analyze do
          connection.send(select_method, 'Select * from table')
        end
        analysis.flagged_queries.size.should == 0
        analysis.non_flagged_queries.size.should == 1
        analysis.non_flagged_queries.first[:sql].should == 'Select * from table'
        analysis.non_flagged_queries.first[:rows].should == 2
      end
      
      it "should flag queries that exceed the configured time limit" do
        now = Time.now
        analysis = SqlSafetyNet::QueryAnalysis.analyze do
          Time.stub(:now).and_return(now, now + 100)
          connection.send(select_method, 'Select * from table')
        end
        analysis.flagged_queries.size.should == 1
        analysis.non_flagged_queries.size.should == 0
        analysis.flagged_queries.first[:flags].should == ["query time exceeded #{SqlSafetyNet.config.time_limit} ms"]
      end

      it "should not analyze queries if debug mode disabled" do
        SqlSafetyNet.config.debug = false
        analysis = SqlSafetyNet::QueryAnalysis.analyze do
          connection.send(select_method, 'SELECT * from table with table scan')
        end
        analysis.selects.should == 1
        analysis.rows.should == 2
        analysis.flagged_queries.size.should == 0
        analysis.non_flagged_queries.size.should == 0
      end
    end
  end

end
