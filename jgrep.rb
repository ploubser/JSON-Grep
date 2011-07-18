#! /usr/lib/env ruby

require 'parser/parser.rb'
require 'parser/scanner.rb'
require 'rubygems'
require 'json'

module JGrep

    #Method parses json and returns documents that match the logical expression
    def self.jgrep(json, expression)
        begin
            call_stack = Parser.new(expression).execution_stack
            result = []
            json = JSON.parse(json)
            json.each do |document|
                if eval_statement(document, call_stack)
                    result << document
                end
            end
            return result.to_json

        rescue NameError => e
            pp e
            var = e.to_s
            STDERR.puts "Error. #{var.match(/`.*'/)} was not found in documents"
            exit 1
        end
    end

    #Correctly format values so we can do the correct type of comparison
    def self.format(kvalue, value)
        if kvalue =~ /^\d+$/ || value =~ /^\d+$/
            return Integer(kvalue), Integer(value)
        elsif kvalue =~ /^\d+.\d+$/ || value =~ /^\d+.\d+$/
            return Float(kvalue), Float(value)
        else
            return kvalue, value
        end
    end

    #Check if key=value is present in document
    def self.has_object?(document, statement)

        key,value = statement.split(/<=|>=|=|<|>/)

        if statement =~ /(<=|>=|<|>|=)/
            op = $1
        else
            op = statement
        end

        tmp = document

        key.split(".").each_with_index do |item,i|
            tmp = tmp[item]
            result = false
            if tmp.is_a? Array
                return (is_object_in_array?(tmp, "#{key.split(".")[i+1]}#{op}#{value}"))
            end
        end

        tmp, value = format(tmp, value.gsub(/"|'/, ""))

        case op
        when "="
            (tmp == value) ? (return true) : (return false)
        when "<="
            (tmp <= value) ? (return true) : (return false)
        when ">="
            (tmp == value) ? (return true) : (return false)
        when ">"
            (tmp > value) ? (return true) : (return false)
        when "<"
            (tmp < value) ? (return true) : (return false)
        end
    end

    #Check if key=value is present in a sub array
    def self.is_object_in_array?(document, statement)

        document.each do |item|
            if has_object?(item,statement)
                return true
           end
        end

        return false
    end


    #Check if complex statement (defined as [key=value...]) is
    #present over an array of key value pairs
    def self.has_complex?(document, compound)
        field = ""
        tmp = document
        result = []
        fresult = []

        compound.each do |token|
            if token[0] == "statement"
                field = token
                break
            end
        end
        field = field[1].first.split(/=|<|>/).first

        field.split(".").each_with_index do |item, i|
            tmp = tmp[item]
            if tmp.is_a? Array
                tmp.each do |doc|
                    result = []
                    compound.each do |token|
                        case token[0]
                            when "and"
                                result << "&&"
                            when "or"
                                result << "||"
                            when  /not|\!/
                                result << "!"
                            when "statement"
                                new_statement = token[1].split(".").last
                                result << has_object?(doc, new_statement)
                        end
                    end
                    fresult << eval(result.join(" "))
                    (fresult << "||") unless doc == tmp.last
                end
                return eval(fresult.join(" "))
            end
        end
    end

    #Evaluates the call stack en returns true of selected document
    #matches logical expression
    def self.eval_statement(document, callstack)
        result = []
        callstack.each do |expression|
            case expression.keys.first
            when "statement"
                if  expression.values.first.is_a? Array
                    result << has_complex?(document, expression.values.first)
                else
                    result << has_object?(document, expression.values.first)
                end
            when "and"
                result << "&&"
            when "or"
                result << "||"
            when "("
                result << "("
            when ")"
                result << ")"
            when "not"
                result << "!"
            end
        end

        return eval(result.join(" "))
    end
end
