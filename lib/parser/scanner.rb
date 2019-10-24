module JGrep
  class Scanner
    attr_accessor :arguments, :token_index

    def initialize(arguments)
      @token_index = 0
      @arguments = arguments
    end

    # Scans the input string and identifies single language tokens
    def get_token
      return nil if @token_index >= @arguments.size

      begin
        case chr(@arguments[@token_index])
        when "["
          return "statement", gen_substatement

        when "]"
          return "]"

        when "("
          return "(", "("

        when ")"
          return ")", ")"

        when "n"
          if (chr(@arguments[@token_index + 1]) == "o") && (chr(@arguments[@token_index + 2]) == "t") && ((chr(@arguments[@token_index + 3]) == " ") || (chr(@arguments[@token_index + 3]) == "("))
            @token_index += 2
            return "not", "not"
          else
            gen_statement
          end

        when "!"
          return "not", "not"

        when "a"
          if (chr(@arguments[@token_index + 1]) == "n") && (chr(@arguments[@token_index + 2]) == "d") && ((chr(@arguments[@token_index + 3]) == " ") || (chr(@arguments[@token_index + 3]) == "("))
            @token_index += 2
            return "and", "and"
          else
            gen_statement
          end

        when "&"
          if chr(@arguments[@token_index + 1]) == "&"
            @token_index += 1
            return "and", "and"
          else
            gen_statement
          end

        when "o"
          if (chr(@arguments[@token_index + 1]) == "r") && ((chr(@arguments[@token_index + 2]) == " ") || (chr(@arguments[@token_index + 2]) == "("))
            @token_index += 1
            return "or", "or"
          else
            gen_statement
          end

        when "|"
          if chr(@arguments[@token_index + 1]) == "|"
            @token_index += 1
            return "or", "or"
          else
            gen_statement
          end

        when "+"
          value = ""
          i = @token_index + 1

          begin
            value += chr(@arguments[i])
            i += 1
          end until (i >= @arguments.size) || (chr(@arguments[i]) =~ /\s|\)/)

          @token_index = i - 1
          return "+", value

        when "-"
          value = ""
          i = @token_index + 1

          begin
            value += chr(@arguments[i])
            i += 1
          end until (i >= @arguments.size) || (chr(@arguments[i]) =~ /\s|\)/)

          @token_index = i - 1
          return "-", value

        when " "
          return " ", " "

        else
          gen_statement
        end
      end
    rescue NoMethodError
      raise "Error. Expression cannot be parsed."
    end

    private

    def gen_substatement
      @token_index += 1
      returnval = []

      while (val = get_token) != "]"
        @token_index += 1
        returnval << val unless val[0] == " "
      end

      returnval
    end

    def gen_statement
      current_token_value = ""
      j = @token_index

      begin
        if chr(@arguments[j]) == "/"
          begin
            current_token_value << chr(@arguments[j])
            j += 1
            if chr(@arguments[j]) == "/"
              current_token_value << "/"
              break
            end
          end until (j >= @arguments.size) || (chr(@arguments[j]) =~ /\//)
        else
          begin
            current_token_value << chr(@arguments[j])
            j += 1
            if chr(@arguments[j]) =~ /'|"/
              begin
                current_token_value << chr(@arguments[j])
                j += 1
              end until (j >= @arguments.size) || (chr(@arguments[j]) =~ /'|"/)
            end
          end until (j >= @arguments.size) || (chr(@arguments[j]) =~ /\s|\)|\]/ && chr(@arguments[j - 1]) != '\\')
        end
      rescue
        raise "Invalid token found - '#{current_token_value}'"
      end

      if current_token_value =~ /^(and|or|not|!)$/
        raise "Class name cannot be 'and', 'or', 'not'. Found '#{current_token_value}'"
      end

      @token_index += current_token_value.size - 1

      ["statement", current_token_value]
    end

    # Compatibility with 1.8.7, which returns a Fixnum from String#[]
    def chr(character)
      character.chr unless character.nil?
    end
  end
end
