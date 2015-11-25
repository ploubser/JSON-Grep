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
                result = JGrep::jgrep("[foo:]", "foo=1")
            end

            it "should return '[]' if value is not present in document" do
                result = JGrep::jgrep("[{\"bar\":1}]", "foo=1")
                result.should == []
            end

            it "should correctly return 'null' if a null value is present in the document" do
                result = JGrep::jgrep("[{\"foo\":null}]", "foo=null")
                result.should == [{"foo" => nil}]
            end

            it "should return the origional json document if no expression is given" do
                result = JGrep::jgrep("[{\"foo\":\"bar\"}]", "")
                result.should == [{"foo" => "bar"}]
            end

            it "should filter on the origional json document if not expression is given and a filter is given" do
                result = JGrep::jgrep("[{\"foo\":\"bar\"}]", "", "foo")
                result.should == ["bar"]
            end

            it "should support starting from a subdocument" do
                doc = %q(
                        {"results": [
                                {"foo":"bar"},
                                {"foo":"baz"}
                                ]
                        }
                )

                JGrep.verbose_on
                results = JGrep::jgrep(doc, "foo=bar", nil, "results")
                results.should == [{"foo"=>"bar"}]
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

            it "should compare based on regular expression" do
                result = JGrep::has_object?({"foo"=> "bar"}, "foo=/ba/")
                result.should == true
            end

            it "should compare true booleans" do
                result = JGrep::has_object?({"foo"=> true}, "foo=true")
                result.should == true
                result = JGrep::has_object?({"foo"=> false}, "foo=true")
                result.should == false
            end

            it "should compare true booleans" do
                result = JGrep::has_object?({"foo"=> false}, "foo=false")
                result.should == true
                result = JGrep::has_object?({"foo"=> true}, "foo=false")
                result.should == false
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

            it "should return true if if document matches logical expression array" do
                result = JGrep::eval_statement({"foo" => ["bar" => 1]}, [{"statement" => [["statement", "foo.bar=1"]]}] )
                result.should == true
            end

            it "should return false if if document doesn't match logical expression" do
                result = JGrep::eval_statement({"foo" => 1, "bar" => 1}, [{"statement" => "foo=0"}, {"and" => "and"}, {"statement" => "bar=1"}])
                result.should == false
            end
        end

        describe "#filter_json" do
            it "should return the correct values if there is a single filter" do
                result = JGrep::filter_json([{"foo" => 1, "bar" => 1}], "foo")
                result.should == [1]
            end

            it "should return the correct values if there are multiple filters" do
                result = JGrep::filter_json([{"foo" => 1, "foo1" => 1, "foo2" => 1}], ["foo2", "foo1"])
                result.should == [{"foo2"=>1, "foo1"=>1}]
            end

            it "should return an empty set if the filter has not been found and there is only 1 filter" do
                result = JGrep::filter_json([{"foo" => 1}], "bar")
                result.should == []
            end

            it "should not return a structure containing a key if that key is not specified in the document" do
                result = JGrep::filter_json([{"foo" => 1}], ["foo", "bar"])
                result.should == [{"foo" => 1}]
            end
        end

        describe "#validate_filters" do

            it "should validate correct single filter" do
                result = JGrep::validate_filters("foo")
                result.should be_nil
            end

            it "should not validate if a single filter contains an invalid field" do
                expect{
                    result = JGrep::validate_filters("and")
                }.to raise_error "Invalid field for -s filter : 'and'"
            end

            it "should correctly validate an array of filters" do
                result = JGrep::validate_filters(["foo", "bar"])
                result.should be_nil
            end

            it "should not validate if an array of filters contain an illegal filter" do
                expect{
                    result = JGrep::validate_filters(["foo", "or"])
                }.to raise_error "Invalid field for -s filter : 'or'"
            end
        end

        describe "#dig_path" do

            it "should return the correct key value for a hash" do
                result = JGrep::dig_path({"foo" => 1}, "foo")
                result.should == 1
            end

            it "should return the correct value for any value that is not a hash or an array" do
                result = JGrep::dig_path(1, "foo")
                result.should == 1
            end

            it "should return the correct value for a subvalue in an array" do
                result = JGrep::dig_path([{"foo" => 1}, {"foo" => 2}], "foo")
                result.should == [1,2]
            end

            it "should return the correct value if a wildcard is specified" do
                result = JGrep::dig_path([{"foo" => {"bar" => 1}}], "foo.*")
                result.should == [[{"bar"=>1}]]
            end

            it "should return the correct value if the path contains a dot seperated key" do
                result = JGrep::dig_path({"foo.bar" => 1}, "foo.bar")
                result.should == 1
                result = JGrep::dig_path({"foo" => {"foo.bar" =>1}}, "foo.foo.bar")
                result.should == 1
            end
        end
    end
end
