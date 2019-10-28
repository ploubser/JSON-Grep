require File.dirname(__FILE__) + "/../spec_helper"

module JGrep
  describe Scanner do
    describe "#get_token" do
      it "should identify a '(' token" do
        scanner = Scanner.new("(")
        token = scanner.get_token
        expect(token).to eq(["(", "("])
      end

      it "should identify a ')' token" do
        scanner = Scanner.new(")")
        token = scanner.get_token
        expect(token).to eq([")", ")"])
      end

      it "should identify an 'and' token" do
        scanner = Scanner.new("and ")
        token = scanner.get_token
        expect(token).to eq(%w[and and])
      end

      it "should identify a '&&' token" do
        scanner = Scanner.new("&& ")
        token = scanner.get_token
        expect(token).to eq(%w[and and])
      end

      it "should identify an 'or' token" do
        scanner = Scanner.new("or ")
        token = scanner.get_token
        expect(token).to eq(%w[or or])
      end

      it "should identify a " || " token" do
        scanner = Scanner.new("|| ")
        token = scanner.get_token
        expect(token).to eq(%w[or or])
      end

      it "should identify an 'not' token" do
        scanner = Scanner.new("not ")
        token = scanner.get_token
        expect(token).to eq(%w[not not])
      end

      it "should identify an '!' token" do
        scanner = Scanner.new("!")
        token = scanner.get_token
        expect(token).to eq(%w[not not])
      end

      it "should identify a statement token" do
        scanner = Scanner.new("foo.bar=bar")
        token = scanner.get_token
        expect(token).to eq(["statement", "foo.bar=bar"])
      end

      it "should identify a statement token with escaped parentheses" do
        scanner = Scanner.new("foo.bar=/baz\\(gronk\\)quux/")
        token = scanner.get_token
        expect(token).to eq(["statement", "foo.bar=/baz\\(gronk\\)quux/"])
      end

      it "should identify a complex array statement" do
        scanner = Scanner.new("[foo=bar and bar=foo]")
        token = scanner.get_token
        expect(token).to eq(["statement", [["statement", "foo=bar"], %w[and and], ["statement", "bar=foo"]]])
      end

      it "should fail if expression terminates with 'and'" do
        scanner = Scanner.new("and")

        expect do
          scanner.get_token
        end.to raise_error("Class name cannot be 'and', 'or', 'not'. Found 'and'")
      end

      it "should identify a '+' token" do
        scanner = Scanner.new("+foo")
        token = scanner.get_token
        expect(token).to eq(["+", "foo"])
      end

      it "should identify a '-' token" do
        scanner = Scanner.new("-foo")
        token = scanner.get_token
        expect(token).to eq(["-", "foo"])
      end
    end
  end
end
