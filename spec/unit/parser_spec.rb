#! /usr/bin/env ruby

require File.dirname(__FILE__) + "/../../jgrep"

module JGrep
        describe Parser do
            describe '#parse' do
                it "should parse statements seperated by '='" do
                    parser = Parser.new("foo.bar=bar")
                    parser.execution_stack.should == [{"statement" => "foo.bar=bar"}]
                end

                it "should parse statements seperated by '<'" do
                    parser = Parser.new("foo.bar<1")
                    parser.execution_stack.should == [{"statement" => "foo.bar<1"}]
                end

                it "should parse statements seperated by '>'" do
                    parser = Parser.new("foo.bar>1")
                    parser.execution_stack.should == [{"statement" => "foo.bar>1"}]
                end

                it "should parse statements seperated by '<='" do
                    parser = Parser.new("foo.bar<=1")
                    parser.execution_stack.should == [{"statement" => "foo.bar<=1"}]
                end

                it "should parse statements seperated by '>='" do
                    parser = Parser.new("foo.bar>=1")
                    parser.execution_stack.should == [{"statement" => "foo.bar>=1"}]
                end


                it "should parse a correct 'and' token" do
                    parser = Parser.new("foo.bar=123 and bar.foo=321")
                    parser.execution_stack.should == [{"statement" => "foo.bar=123"}, {"and" => "and"}, {"statement" => "bar.foo=321"}]
                end

                it "should not parse an incorrect and token" do
                    expect {
                        parser = Parser.new("and foo.bar=1")
                    }.to raise_error("Error at column 12. \n Expression cannot start with 'and'")
                end

                it "should parse a correct 'or' token" do
                    parser = Parser.new("foo.bar=1 or bar.foo=1")
                    parser.execution_stack.should == [{"statement" => "foo.bar=1"}, {"or" => "or"}, {"statement" => "bar.foo=1"}]
                end

                it "should not parse an incorrect and token" do
                    expect {
                        parser = Parser.new("or foo.bar=1")
                    }.to raise_error("Error at column 11. \n Expression cannot start with 'or'")
                end

                it "should parse a correct 'not' token" do
                    parser = Parser.new("! bar.foo=1")
                    parser.execution_stack.should == [{"not" => "not"}, {"statement" => "bar.foo=1"}]
                    parser = Parser.new("not bar.foo=1")
                    parser.execution_stack.should == [{"not" => "not"}, {"statement" => "bar.foo=1"}]
                end

                it "should not parse an incorrect 'not' token" do
                    expect {
                        parser = Parser.new("foo.bar=1 !")
                    }.to raise_error("Error at column 10. \nExpected 'and', 'or', ')'. Found 'not'")
                end

                it "should parse correct parentheses" do
                    parser = Parser.new("(foo.bar=1)")
                    parser.execution_stack.should == [{"(" => "("}, {"statement" => "foo.bar=1"}, {")" => ")"}]
                end

                it "should fail on incorrect parentheses" do
                    expect {
                        parser = Parser.new(")foo.bar=1(")
                    }.to raise_error("Error. Missing parentheses '('.")
                end

                it "should fail on missing parentheses" do
                    expect {
                        parser = Parser.new("(foo.bar=1")
                    }.to raise_error("Error. Missing parentheses ')'.")
                end

                it "should parse correctly formatted compound statements" do
                    parser = Parser.new("(foo.bar=1 or foo.rab=1) and (bar.foo=1)")
                    parser.execution_stack.should == [{"(" => "("}, {"statement"=>"foo.bar=1"}, {"or"=>"or"}, {"statement"=>"foo.rab=1"},
                                                     {")"=>")"}, {"and"=>"and"}, {"("=>"("}, {"statement"=>"bar.foo=1"},
                                                     {")"=>")"}]
                end

                it "should parse complex array statements" do
                    parser = Parser.new("[foo.bar=1]")
                    parser.execution_stack.should == [{"statement" => [["statement" => "foo.bar=1"}]]}]
                end

                it "should not parse failed complex array statements" do
                end

                it "should parse complex, compound array statements" do
                end

            end
        end
    end
