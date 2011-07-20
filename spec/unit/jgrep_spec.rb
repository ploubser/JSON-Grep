#!/usr/bin/env ruby

require File.dirname(__FILE__) + "/../spec_helper"

module JGrep
    describe JGrep do
        describe "#jgrep" do

            it "should return a valid json document" do
                result = JGrep::jgrep("[{\"foo\":1}]", "foo=1")
                result.should == [{"foo"=>1}]
            end

            it "should fail on an invalid json document" do
                STDERR.expects(:puts).with("Error. Invalid JSON given")
                expect{
                    result = JGrep::jgrep("[foo:]", "foo=1")
                }.to raise_error("exit")
            end

            it "should return '[]' if value is not present in document" do
                result = JGrep::jgrep("[{\"bar\":1}]", "foo=1")
                result.should == []
            end

        end

        describe "#format" do

            it "should correctly format integers" do
                result1, result2 = JGrep::format("1",1)
                result1.is_a?(Fixnum).should == true
                result2.is_a?(Fixnum).should == true
            end

            it "should correctly format floating point numbers" do
                result1, result2 = JGrep::format("1.1", 1.1)
                result1.is_a?(Float).should == true
                result2.is_a?(Float).should == true
            end

            it "should not format strings" do
                result1, result2 = JGrep::format("foo", "bar")
                result1.is_a?(String).should == true
                result2.is_a?(String).should == true
            end
        end

        describe "#has_object?" do

            it "should compare on a '=' operator" do
                result = JGrep::has_object?({"foo"=> 1}, "foo=1")
                result.should == true
            end

            it "should compare on a '<=' operator" do
                result = JGrep::has_object?({"foo"=> 1}, "foo<=0")
                result.should == false
            end

            it "should compare on a '>=' operator" do
                result = JGrep::has_object?({"foo"=> 1}, "foo>=0")
                result.should == true
            end

            it "should compare on a '<' operator" do
                result = JGrep::has_object?({"foo"=> 1}, "foo<1")
                result.should == false
            end

            it "should compare on a '>' operator" do
                result = JGrep::has_object?({"foo"=> 1}, "foo>0")
                result.should == true
            end
        end

        describe "#is_object_in_array?" do

            it "should return true if key=value is present in array" do
                result = JGrep::is_object_in_array?([{"foo" => 1},{"foo" => 0}], "foo=1")
                result.should == true
            end

            it "should return false if key=value is not present in array" do
                result = JGrep::is_object_in_array?([{"foo" => 1},{"foo" => 0}], "foo=2")
                result.should == false
            end
        end

        describe "#has_complex?" do

            it "should return true if complex statement is present in an array" do
                result = JGrep::has_complex?({"foo" => ["bar" => 1]}, [["statement","foo.bar=1"]])
                result.should == true
            end

            it "should return false if complex statement is not present in an array" do
                result = JGrep::has_complex?({"foo" => ["bar" => 1]}, [["statement","foo.bar=0"]])
                result.should == false
            end
        end

        describe "#eval_statement" do

            it "should return true if if document matches logical expression" do
                result = JGrep::eval_statement({"foo" => 1, "bar" => 1}, [{"statement" => "foo=1"}, {"and" => "and"}, {"statement" => "bar=1"}])
                result.should == true
            end

            it "should return false if if document doesn't match logical expression" do
                result = JGrep::eval_statement({"foo" => 1, "bar" => 1}, [{"statement" => "foo=0"}, {"and" => "and"}, {"statement" => "bar=1"}])
                result.should == false
            end
        end
    end
end
