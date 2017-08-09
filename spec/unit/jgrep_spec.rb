require File.dirname(__FILE__) + "/../spec_helper"

module JGrep
  describe JGrep do
    describe "#validate_expression" do
      it "should be true for valid expressions" do
        expect(JGrep.validate_expression("bob=true")).to be(true)
      end

      it "should return errors for invalid ones" do
        expect(JGrep.validate_expression("something that is invalid")).to start_with("Error")
      end
    end

    describe "#jgrep" do
      it "should return a valid json document" do
        result = JGrep.jgrep("[{\"foo\":1}]", "foo=1")
        expect(result).to eq([{"foo" => 1}])
      end

      it "should fail on an invalid json document" do
        STDERR.expects(:puts).with("Error. Invalid JSON given")
        JGrep.jgrep("[foo:]", "foo=1")
      end

      it "should return '[]' if value is not present in document" do
        result = JGrep.jgrep("[{\"bar\":1}]", "foo=1")
        expect(result).to eq([])
      end

      it "should correctly return 'null' if a null value is present in the document" do
        result = JGrep.jgrep("[{\"foo\":null}]", "foo=null")
        expect(result).to eq([{"foo" => nil}])
      end

      it "should return the origional json document if no expression is given" do
        result = JGrep.jgrep("[{\"foo\":\"bar\"}]", "")
        expect(result).to eq([{"foo" => "bar"}])
      end

      it "should filter on the origional json document if not expression is given and a filter is given" do
        result = JGrep.jgrep("[{\"foo\":\"bar\"}]", "", "foo")
        expect(result).to eq(["bar"])
      end

      it "should support starting from a subdocument" do
        doc = '
                        {"results": [
                                {"foo":"bar"},
                                {"foo":"baz"}
                                ]
                        }
        '

        JGrep.verbose_on
        results = JGrep.jgrep(doc, "foo=bar", nil, "results")
        expect(results).to eq([{"foo" => "bar"}])
      end
    end

    describe "#format" do
      it "should correctly format integers" do
        result1, result2 = JGrep.format("1", 1)
        expect(result1.is_a?(Integer)).to eq(true)
        expect(result2.is_a?(Integer)).to eq(true)
      end

      it "should correctly format floating point numbers" do
        result1, result2 = JGrep.format("1.1", 1.1)
        expect(result1.is_a?(Float)).to eq(true)
        expect(result2.is_a?(Float)).to eq(true)
      end

      it "should not format strings" do
        result1, result2 = JGrep.format("foo", "bar")
        expect(result1.is_a?(String)).to eq(true)
        expect(result2.is_a?(String)).to eq(true)
      end
    end

    describe "#has_object?" do
      it "should compare on a '=' operator" do
        result = JGrep.has_object?({"foo" => 1}, "foo=1")
        expect(result).to eq(true)
      end

      it "should compare on a '<=' operator" do
        result = JGrep.has_object?({"foo" => 1}, "foo<=0")
        expect(result).to eq(false)
      end

      it "should compare on a '>=' operator" do
        result = JGrep.has_object?({"foo" => 1}, "foo>=0")
        expect(result).to eq(true)
      end

      it "should compare on a '<' operator" do
        result = JGrep.has_object?({"foo" => 1}, "foo<1")
        expect(result).to eq(false)
      end

      it "should compare on a '>' operator" do
        result = JGrep.has_object?({"foo" => 1}, "foo>0")
        expect(result).to eq(true)
      end

      it "should compare based on regular expression" do
        result = JGrep.has_object?({"foo" => "bar"}, "foo=/ba/")
        expect(result).to eq(true)
      end

      it "should compare true booleans" do
        result = JGrep.has_object?({"foo" => true}, "foo=true")
        expect(result).to eq(true)
        result = JGrep.has_object?({"foo" => false}, "foo=true")
        expect(result).to eq(false)
      end

      it "should compare true booleans" do
        result = JGrep.has_object?({"foo" => false}, "foo=false")
        expect(result).to eq(true)
        result = JGrep.has_object?({"foo" => true}, "foo=false")
        expect(result).to eq(false)
      end
    end

    describe "#is_object_in_array?" do
      it "should return true if key=value is present in array" do
        result = JGrep.is_object_in_array?([{"foo" => 1}, {"foo" => 0}], "foo=1")
        expect(result).to eq(true)
      end

      it "should return false if key=value is not present in array" do
        result = JGrep.is_object_in_array?([{"foo" => 1}, {"foo" => 0}], "foo=2")
        expect(result).to eq(false)
      end
    end

    describe "#has_complex?" do
      it "should return true if complex statement is present in an array" do
        result = JGrep.has_complex?({"foo" => ["bar" => 1]}, [["statement", "foo.bar=1"]])
        expect(result).to eq(true)
      end

      it "should return false if complex statement is not present in an array" do
        result = JGrep.has_complex?({"foo" => ["bar" => 1]}, [["statement", "foo.bar=0"]])
        expect(result).to eq(false)
      end
    end

    describe "#eval_statement" do
      it "should return true if if document matches logical expression" do
        result = JGrep.eval_statement({"foo" => 1, "bar" => 1}, [{"statement" => "foo=1"}, {"and" => "and"}, {"statement" => "bar=1"}])
        expect(result).to eq(true)
      end

      it "should return true if if document matches logical expression array" do
        result = JGrep.eval_statement({"foo" => ["bar" => 1]}, [{"statement" => [["statement", "foo.bar=1"]]}])
        expect(result).to eq(true)
      end

      it "should return false if if document doesn't match logical expression" do
        result = JGrep.eval_statement({"foo" => 1, "bar" => 1}, [{"statement" => "foo=0"}, {"and" => "and"}, {"statement" => "bar=1"}])
        expect(result).to eq(false)
      end
    end

    describe "#filter_json" do
      it "should return the correct values if there is a single filter" do
        result = JGrep.filter_json([{"foo" => 1, "bar" => 1}], "foo")
        expect(result).to eq([1])
      end

      it "should return the correct values if there are multiple filters" do
        result = JGrep.filter_json([{"foo" => 1, "foo1" => 1, "foo2" => 1}], %w[foo2 foo1])
        expect(result).to eq([{"foo2" => 1, "foo1" => 1}])
      end

      it "should return an empty set if the filter has not been found and there is only 1 filter" do
        result = JGrep.filter_json([{"foo" => 1}], "bar")
        expect(result).to eq([])
      end

      it "should not return a structure containing a key if that key is not specified in the document" do
        result = JGrep.filter_json([{"foo" => 1}], %w[foo bar])
        expect(result).to eq([{"foo" => 1}])
      end
    end

    describe "#validate_filters" do
      it "should validate correct single filter" do
        result = JGrep.validate_filters("foo")
        expect(result).to be_nil
      end

      it "should not validate if a single filter contains an invalid field" do
        expect do
          JGrep.validate_filters("and")
        end.to raise_error "Invalid field for -s filter : 'and'"
      end

      it "should correctly validate an array of filters" do
        result = JGrep.validate_filters(%w[foo bar])
        expect(result).to be_nil
      end

      it "should not validate if an array of filters contain an illegal filter" do
        expect do
          JGrep.validate_filters(%w[foo or])
        end.to raise_error "Invalid field for -s filter : 'or'"
      end
    end

    describe "#dig_path" do
      it "should return the correct key value for a hash" do
        result = JGrep.dig_path({"foo" => 1}, "foo")
        expect(result).to eq(1)
      end

      it "should return the correct value for any value that is not a hash or an array" do
        result = JGrep.dig_path(1, "foo")
        expect(result).to eq(1)
      end

      it "should return the correct value for a subvalue in an array" do
        result = JGrep.dig_path([{"foo" => 1}, {"foo" => 2}], "foo")
        expect(result).to eq([1, 2])
      end

      it "should return the correct value if a wildcard is specified" do
        result = JGrep.dig_path([{"foo" => {"bar" => 1}}], "foo.*")
        expect(result).to eq([[{"bar" => 1}]])
      end

      it "should return the correct value if the path contains a dot seperated key" do
        result = JGrep.dig_path({"foo.bar" => 1}, "foo.bar")
        expect(result).to eq(1)
        result = JGrep.dig_path({"foo" => {"foo.bar" => 1}}, "foo.foo.bar")
        expect(result).to eq(1)
      end
    end
  end
end
