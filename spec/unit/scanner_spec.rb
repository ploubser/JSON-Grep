#! /usr/bin/env ruby

require File.dirname(__FILE__) + "/../spec_helper"


module JGrep
    describe Scanner do
        describe '#get_token' do
            it "should identify a '(' token" do
                scanner = Scanner.new("(")
                token = scanner.get_token
                token.should == ["(", "("]
            end

            it "should identify a ')' token" do
                scanner = Scanner.new(")")
                token = scanner.get_token
                token.should == [")", ")"]
            end

            it "should identify an 'and' token" do
                scanner = Scanner.new("and ")
                token = scanner.get_token
                token.should == ["and", "and"]
            end

            it "should identify a '&&' token" do
                scanner = Scanner.new("&& ")
                token = scanner.get_token
                token.should == ["and", "and"]
            end

            it "should identify an 'or' token" do
                scanner = Scanner.new("or ")
                token = scanner.get_token
                token.should == ["or", "or"]
            end

            it "should identify a "||" token" do
                scanner = Scanner.new("|| ")
                token = scanner.get_token
                token.should == ["or", "or"]

            end

            it "should identify an 'not' token" do
                scanner = Scanner.new("not ")
                token = scanner.get_token
                token.should == ["not", "not"]
            end

            it "should identify an '!' token" do
                scanner = Scanner.new("!")
                token = scanner.get_token
                token.should == ["not", "not"]
            end

            it "should identify a statement token" do
                scanner = Scanner.new("foo.bar=bar")
                token = scanner.get_token
                token.should == ["statement", "foo.bar=bar"]
            end

            it "should identify a complex array statement" do
                scanner = Scanner.new("[foo=bar and bar=foo]")
                token = scanner.get_token
                token.should == ["statement", [["statement", "foo=bar"], ["and", "and"], ["statement", "bar=foo"]]]
            end

            it "should fail if expression terminates with 'and'" do
                scanner = Scanner.new("and")

                expect {
                    token = scanner.get_token
                }.to raise_error("Class name cannot be 'and', 'or', 'not'. Found 'and'")
            end

            it "should identify a '+' token" do
                scanner = Scanner.new("+foo")
                token = scanner.get_token
                token.should == ["+","foo"]
            end

            it "should identify a '-' token" do
                scanner = Scanner.new("-foo")
                token = scanner.get_token
                token.should == ["-", "foo"]
            end
        end
    end
end
