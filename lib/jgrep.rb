#! /usr/lib/env ruby

require 'parser/parser.rb'
require 'parser/scanner.rb'
require 'rubygems'
require 'json'

module JGrep
    @verbose = false
    @flatten = false

    def self.verbose_on
        @verbose = true
    end

    def self.flatten_on
        @flatten = true
    end

    #Method parses json and returns documents that match the logical expression
    def self.jgrep(json, expression, filters = nil, start = nil)
        errors = ""
        begin
            JSON.create_id = nil
            json = JSON.parse(json)
            if json.is_a? Hash
                json = [json]
            end

            json = filter_json(json, start).flatten if start

            result = []
            unless expression == ""
                call_stack = Parser.new(expression).execution_stack

                json.each do |document|
                    begin
                        if eval_statement(document, call_stack)
                            result << document
                        end
                    rescue Exception => e
                        if @verbose
                            require 'pp'
                            pp document
                            STDERR.puts "Error - #{e} \n\n"
                        else
                            errors = "One or more the json documents could not be parsed. Run jgrep -v for to display documents"
                        end
                    end
                end
            else
                result = json
            end

            unless errors == ""
                puts errors
            end

            unless filters
                return result
            else
                filter_json(result, filters)
            end

        rescue JSON::ParserError => e
            STDERR.puts "Error. Invalid JSON given"
            exit 1
        end

    end

    #Strips filters from json documents and returns those values as a less bloated json document
    def self.filter_json(documents, filters)
        result = []

        if filters.is_a? Array
            documents.each do |doc|
                tmp_json = {}
                filters.each do |filter|
                    filtered_result = dig_path(doc, filter)
                    unless (filtered_result == doc) || filtered_result.nil?
                        tmp_json[filter] = filtered_result
                    end
                end
                result << tmp_json
            end

            result = result.flatten if (result.size == 1 && @flatten == true)
            return result

        else
            documents.each do |r|
                filtered_result = dig_path(r, filters)
                unless (filtered_result == r) || filtered_result.nil?
                    result << filtered_result
                end
            end

            result = result.flatten if (result.size == 1 && @flatten == true)
            return result
        end
    end

    #Validates if filters do not match any of the parser's logical tokens
    def self.validate_filters(filters)
        if filters.is_a? Array
            filters.each do |filter|
                if filter =~ /=|<|>|^and$|^or$|^!$|^not$/
                    raise "Invalid field for -s filter : '#{filter}'"
                end
            end
        else
            if filters =~ /=|<|>|^and$|^or$|^!$|^not$/
                raise "Invalid field for -s filter : '#{filters}'"
            end
        end
        return
    end

    #Correctly format values so we can do the correct type of comparison
    def self.format(kvalue, value)
        if kvalue.to_s =~ /^\d+$/ && value.to_s =~ /^\d+$/
            return Integer(kvalue), Integer(value)
        elsif kvalue.to_s =~ /^\d+.\d+$/ && value.to_s =~ /^\d+.\d+$/
            return Float(kvalue), Float(value)
        else
            return kvalue, value
        end
    end

    def self.present?(document, statement)
        statement.split(".").each do |key|
            if document.is_a? Hash
                if document.has_value? nil
                    document.each do |k, v|
                        if document[k] == nil
                            document[k] = "null"
                        end
                    end
                end
            end

            if document.is_a? Array
                rval = false
                document.each do |doc|
                    rval ||= present?(doc, key)
                end
                return rval
            end

            document = document[key]
            if document.nil?
                return false
            end
        end
        return true
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
            if tmp.nil?
                if item == key.split(".").last
                    tmp = "null"
                else
                    return false
                end
            end
            result = false
            if tmp.is_a? Array
                return (is_object_in_array?(tmp, "#{key.split(".")[i+1]}#{op}#{value}"))
            end
        end

        tmp, value = format(tmp, (value.gsub(/"|'/, "") unless value.nil?))

        if value.match(/^\/.*\/$/)
            if tmp.match(Regexp.new(value.gsub("/", "")))
                return true
            else
                return false
            end
        end

        case op
            when "="
                (tmp == value) ? (return true) : (return false)
            when "<="
                (tmp <= value) ? (return true) : (return false)
            when ">="
                (tmp >= value) ? (return true) : (return false)
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
            if tmp.nil?
                return false
            end
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
                                op = token[1].match(/.*<=|>=|=|<|>/)
                                left = token[1].split(op[0]).first.split(".").last
                                right = token[1].split(op[0]).last
                                new_statement = left + op[0] + right
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
            when "+"
                result << present?(document, expression.values.first)
            when "-"
                result << !(present?(document, expression.values.first))
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

    def self.dig_path(json, path)

        puts path
        exit!

        json = json[path.split(".").first] if json.is_a? Hash

        if json.is_a?(Hash)
            if path == path.split(".").first
                return json
            else
                return dig_path(json, (path.match(/\./) ? path.split(".").drop(1).join(".") : path))
            end

        elsif json.is_a? Array
            if path == path.split(".").first && (json.first.is_a?(Hash) && !(json.first.keys.include?(path)))
                return json
            else
                tmp = []
                json.each do |j|
                    tmp_path = dig_path(j, (path.match(/\./) ? path.split(".").drop(1).join(".") : path))
                    unless tmp_path.nil?
                        tmp << tmp_path
                    end
                end
                unless tmp.empty?
                    return tmp
                end
            end

        elsif json.nil?
            return nil

        else
            return json

        end

    end
end
