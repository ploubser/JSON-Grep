require "parser/parser.rb"
require "parser/scanner.rb"
require "rubygems"
require "json"

module JGrep
  @verbose = false
  @flatten = false

  def self.verbose_on
    @verbose = true
  end

  def self.flatten_on
    @flatten = true
  end

  # Parse json and return documents that match the logical expression
  # Filters define output by limiting it to only returning a the listed keys.
  # Start allows you to move the pointer indicating where parsing starts.
  # Default is the first key in the document heirarchy
  def self.jgrep(json, expression, filters = nil, start = nil)
    errors = ""

    begin
      JSON.create_id = nil
      json = JSON.parse(json)
      json = [json] if json.is_a?(Hash)

      json = filter_json(json, start).flatten if start

      result = []

      if expression == ""
        result = json
      else
        call_stack = Parser.new(expression).execution_stack

        json.each do |document|
          begin
            result << document if eval_statement(document, call_stack)
          rescue Exception => e # rubocop:disable Lint/RescueException
            if @verbose
              require "pp"
              pp document
              STDERR.puts "Error - #{e} \n\n"
            else
              errors = "One or more the json documents could not be parsed. Run jgrep -v for to display documents"
            end
          end
        end
      end

      puts errors unless errors == ""

      return result unless filters

      filter_json(result, filters)
    rescue JSON::ParserError
      STDERR.puts "Error. Invalid JSON given"
    end
  end

  # Validates an expression, true when no errors are found else a string representing the issues
  def self.validate_expression(expression)
    Parser.new(expression)
    true
  rescue
    $!.message
  end

  # Strips filters from json documents and returns those values as a less bloated json document
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
    else
      documents.each do |r|
        filtered_result = dig_path(r, filters)

        unless (filtered_result == r) || filtered_result.nil?
          result << filtered_result
        end
      end
    end

    result.flatten if @flatten == true && result.size == 1

    result
  end

  # Validates if filters do not match any of the parser's logical tokens
  def self.validate_filters(filters)
    if filters.is_a? Array
      filters.each do |filter|
        if filter =~ /=|<|>|^and$|^or$|^!$|^not$/
          raise "Invalid field for -s filter : '#{filter}'"
        end
      end
    elsif filters =~ /=|<|>|^and$|^or$|^!$|^not$/
      raise "Invalid field for -s filter : '#{filters}'"
    end

    nil
  end

  # Correctly format values so we can do the correct type of comparison
  def self.format(kvalue, value)
    if kvalue.to_s =~ /^\d+$/ && value.to_s =~ /^\d+$/
      [Integer(kvalue), Integer(value)]
    elsif kvalue.to_s =~ /^\d+.\d+$/ && value.to_s =~ /^\d+.\d+$/
      [Float(kvalue), Float(value)]
    else
      [kvalue, value]
    end
  end

  # Check if the json key that is defined by statement is defined in the json document
  def self.present?(document, statement)
    statement.split(".").each do |key|
      if document.is_a? Hash
        if document.value?(nil)
          document.each do |k, _|
            document[k] = "null" if document[k].nil?
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

      return false if document.nil?
    end

    true
  end

  # Check if key=value is present in document
  def self.has_object?(document, statement)
    key, value = statement.split(/<=|>=|=|<|>/)

    if statement =~ /(<=|>=|<|>|=)/
      op = $1
    else
      op = statement
    end

    tmp = dig_path(document, key)

    tmp = tmp.first if tmp.is_a?(Array) && tmp.size == 1

    tmp, value = format(tmp, (value.gsub(/"|'/, "") unless value.nil?)) # rubocop:disable Style/FormatString

    # Deal with null comparison
    return true if tmp.nil? && value == "null"

    # Deal with booleans
    return true if tmp == true && value == "true"
    return true if tmp == false && value == "false"

    # Deal with regex matching
    if !tmp.nil? && value =~ /^\/.*\/$/
      tmp.match(Regexp.new(value.delete("/"))) ? (return true) : (return false)
    end

    # Deal with everything else
    case op
    when "="
      return tmp == value
    when "<="
      return tmp <= value
    when ">="
      return tmp >= value
    when ">"
      return tmp > value
    when "<"
      return tmp < value
    end
  end

  # Check if key=value is present in a sub array
  def self.is_object_in_array?(document, statement)
    document.each do |item|
      return true if has_object?(item, statement)
    end

    false
  end

  # Check if complex statement (defined as [key=value...]) is
  # present over an array of key value pairs
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

    field = field[1].split(/=|<|>/).first

    field.split(".").each_with_index do |item, _|
      tmp = tmp[item]

      return false if tmp.nil?

      next unless tmp.is_a?(Array)

      tmp.each do |doc|
        result = []

        compound.each do |token|
          case token[0]
          when "and"
            result << "&&"
          when "or"
            result << "||"
          when /not|\!/
            result << "!"
          when "statement"
            op = token[1].match(/.*<=|>=|=|<|>/)
            left = token[1].split(op[0]).first.split(".").last
            right = token[1].split(op[0]).last
            new_statement = left + op[0] + right
            result << has_object?(doc, new_statement)
          end
        end

        fresult << eval(result.join(" ")) # rubocop:disable Security/Eval
        (fresult << "||") unless doc == tmp.last
      end

      return eval(fresult.join(" ")) # rubocop:disable Security/Eval
    end
  end

  # Evaluates the call stack en returns true of selected document
  # matches logical expression
  def self.eval_statement(document, callstack)
    result = []

    callstack.each do |expression|
      case expression.keys.first
      when "statement"
        if expression.values.first.is_a?(Array)
          result << has_complex?(document, expression.values.first)
        else
          result << has_object?(document, expression.values.first)
        end
      when "+"
        result << present?(document, expression.values.first)
      when "-"
        result << !present?(document, expression.values.first)
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

    eval(result.join(" ")) # rubocop:disable Security/Eval
  end

  # Digs to a specific path in the json document and returns the value
  def self.dig_path(json, path)
    index = nil
    path = path.gsub(/^\./, "")

    if path =~ /(.*)\[(.*)\]/
      path = $1
      index = $2
    end

    return json if path == ""

    if json.is_a? Hash
      json.keys.each do |k|
        if path.start_with?(k) && k.include?(".")
          return dig_path(json[k], path.gsub(k, ""))
        end
      end
    end

    path_array = path.split(".")

    if path_array.first == "*"
      tmp = []

      json.each do |j|
        tmp << dig_path(j[1], path_array.drop(1).join("."))
      end

      return tmp
    end

    json = json[path_array.first] if json.is_a? Hash

    if json.is_a? Hash
      return json if path == path_array.first
      return dig_path(json, path.include?(".") ? path_array.drop(1).join(".") : path)

    elsif json.is_a? Array
      if path == path_array.first && (json.first.is_a?(Hash) && !json.first.keys.include?(path))
        return json
      end

      tmp = []

      json.each do |j|
        tmp_path = dig_path(j, (path.include?(".") ? path_array.drop(1).join(".") : path))
        tmp << tmp_path unless tmp_path.nil?
      end

      unless tmp.empty?
        return index ? tmp.flatten[index.to_i] : tmp
      end

    elsif json.nil?
      return nil

    else
      return json

    end
  end
end
