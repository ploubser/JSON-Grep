require File.dirname(__FILE__) + "/../spec_helper"

module JGrep
  describe Parser do
    describe "#parse" do
      it "should parse statements seperated by '='" do
        parser = Parser.new("foo.bar=bar")
        expect(parser.execution_stack).to eq([{"statement" => "foo.bar=bar"}])
      end

      it "should parse statements seperated by '<'" do
        parser = Parser.new("foo.bar<1")
        expect(parser.execution_stack).to eq([{"statement" => "foo.bar<1"}])
      end

      it "should parse statements seperated by '>'" do
        parser = Parser.new("foo.bar>1")
        expect(parser.execution_stack).to eq([{"statement" => "foo.bar>1"}])
      end

      it "should parse statements seperated by '<='" do
        parser = Parser.new("foo.bar<=1")
        expect(parser.execution_stack).to eq([{"statement" => "foo.bar<=1"}])
      end

      it "should parse statements seperated by '>='" do
        parser = Parser.new("foo.bar>=1")
        expect(parser.execution_stack).to eq([{"statement" => "foo.bar>=1"}])
      end

      it "should parse statement sperated by '!='" do
        parser = Parser.new("foo.bar!=1")
        expect(parser.execution_stack).to eq([{"not" => "not"}, {"statement" => "foo.bar=1"}])
      end

      it "should parse a + token" do
        parser = Parser.new("+foo")
        expect(parser.execution_stack).to eq([{"+" => "foo"}])
      end

      it "should parse a - token" do
        parser = Parser.new("-foo")
        expect(parser.execution_stack).to eq([{"-" => "foo"}])
      end

      it "should parse a correct 'and' token" do
        parser = Parser.new("foo.bar=123 and bar.foo=321")
        expect(parser.execution_stack).to eq([{"statement" => "foo.bar=123"}, {"and" => "and"}, {"statement" => "bar.foo=321"}])
      end

      it "should not parse an incorrect and token" do
        expect do
          Parser.new("and foo.bar=1")
        end.to raise_error("Error at column 12. \n Expression cannot start with 'and'")
      end

      it "should parse a correct 'or' token" do
        parser = Parser.new("foo.bar=1 or bar.foo=1")
        expect(parser.execution_stack).to eq([{"statement" => "foo.bar=1"}, {"or" => "or"}, {"statement" => "bar.foo=1"}])
      end

      it "should not parse an incorrect and token" do
        expect do
          Parser.new("or foo.bar=1")
        end.to raise_error("Error at column 11. \n Expression cannot start with 'or'")
      end

      it "should parse a correct 'not' token" do
        parser = Parser.new("! bar.foo=1")
        expect(parser.execution_stack).to eq([{"not" => "not"}, {"statement" => "bar.foo=1"}])
        parser = Parser.new("not bar.foo=1")
        expect(parser.execution_stack).to eq([{"not" => "not"}, {"statement" => "bar.foo=1"}])
      end

      it "should not parse an incorrect 'not' token" do
        expect do
          Parser.new("foo.bar=1 !")
        end.to raise_error("Error at column 10. \nExpected 'and', 'or', ')'. Found 'not'")
      end

      it "should parse correct parentheses" do
        parser = Parser.new("(foo.bar=1)")
        expect(parser.execution_stack).to eq([{"(" => "("}, {"statement" => "foo.bar=1"}, {")" => ")"}])
      end

      it "should fail on incorrect parentheses" do
        expect do
          Parser.new(")foo.bar=1(")
        end.to raise_error("Error. Missing parentheses '('.")
      end

      it "should fail on missing parentheses" do
        expect do
          Parser.new("(foo.bar=1")
        end.to raise_error("Error. Missing parentheses ')'.")
      end

      it "should parse correctly formatted compound statements" do
        parser = Parser.new("(foo.bar=1 or foo.rab=1) and (bar.foo=1)")
        expect(parser.execution_stack).to eq([{"(" => "("}, {"statement" => "foo.bar=1"}, {"or" => "or"}, {"statement" => "foo.rab=1"},
                                              {")" => ")"}, {"and" => "and"}, {"(" => "("}, {"statement" => "bar.foo=1"},
                                              {")" => ")"}])
      end

      it "should parse complex array statements" do
        parser = Parser.new("[foo.bar=1]")
        expect(parser.execution_stack).to eq([{"statement" => [["statement", "foo.bar=1"]]}])
      end

      it "should not parse failed complex array statements" do
        expect do
          Parser.new("[foo.bar=1 or]")
        end.to raise_error("Class name cannot be 'and', 'or', 'not'. Found 'or'")
      end

      it "should not allow nested complex array statements" do
        expect do
          Parser.new("[foo.bar=1 and [foo.bar=1]]")
        end.to raise_error("Error at column 27\nError, cannot define '[' in a '[...]' block.")
      end

      it "should parse complex, compound array statements" do
        parser = Parser.new("[foo.bar=1 and foo.rab=2] and !(foo=1)")
        expect(parser.execution_stack).to eq(
          [
            {"statement" => [["statement", "foo.bar=1"], %w[and and], ["statement", "foo.rab=2"]]},
            {"and" => "and"},
            {"not" => "not"},
            {"(" => "("},
            {"statement" => "foo=1"},
            {")" => ")"}
          ]
        )
      end
    end
  end
end
