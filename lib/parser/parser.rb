module JGrep
  class Parser
    attr_reader :scanner, :execution_stack

    def initialize(args)
      @scanner = Scanner.new(args)
      @execution_stack = []

      parse
    end

    # Parse the input string, one token at a time a contruct the call stack
    def parse(substatement = nil, token_index = 0)
      p_token = nil

      if substatement
        c_token, c_token_value = substatement[token_index]
      else
        c_token, c_token_value = @scanner.get_token
      end

      parenth = 0

      until c_token.nil?
        if substatement
          token_index += 1
          n_token, n_token_value = substatement[token_index]
        else
          @scanner.token_index += 1
          n_token, n_token_value = @scanner.get_token
        end

        next if n_token == " "
        case c_token

        when "and"
          unless (n_token =~ /not|statement|\(|\+|-/) || (scanner.token_index == scanner.arguments.size)
            raise "Error at column #{scanner.token_index}. \nExpected 'not', 'statement' or '('. Found '#{n_token_value}'"
          end

          raise "Error at column #{scanner.token_index}. \n Expression cannot start with 'and'" if p_token.nil?
          raise "Error at column #{scanner.token_index}. \n #{p_token} cannot be followed by 'and'" if %w[and or].include?(p_token)

        when "or"
          unless (n_token =~ /not|statement|\(|\+|-/) || (scanner.token_index == scanner.arguments.size)
            raise "Error at column #{scanner.token_index}. \nExpected 'not', 'statement', '('. Found '#{n_token_value}'"
          end

          raise "Error at column #{scanner.token_index}. \n Expression cannot start with 'or'" if p_token.nil?
          raise "Error at column #{scanner.token_index}. \n #{p_token} cannot be followed by 'or'" if %w[and or].include?(p_token)

        when "not"
          unless n_token =~ /statement|\(|not|\+|-/
            raise "Error at column #{scanner.token_index}. \nExpected 'statement' or '('. Found '#{n_token_value}'"
          end

        when "statement"
          if c_token_value.is_a? Array
            raise "Error at column #{scanner.token_index}\nError, cannot define '[' in a '[...]' block." if substatement

            parse(c_token_value, 0)
          end

          if c_token_value =~ /!=/
            c_token_value = c_token_value.gsub("!=", "=")
            @execution_stack << {"not" => "not"}
          end

          if !n_token.nil? && !n_token.match(/and|or|\)/)
            raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', ')'. Found '#{n_token_value}'"
          end

        when "+"
          if !n_token.nil? && !n_token.match(/and|or|\)/)
            raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', ')'. Found '#{n_token_value}'"
          end

        when "-"
          if !n_token.nil? && !n_token.match(/and|or|\)/)
            raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', ')'. Found '#{n_token_value}'"
          end

        when ")"
          if !n_token.nil? && !n_token =~ /|and|or|not|\(/
            raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', 'not' or '('. Found '#{n_token_value}'"
          end

          parenth += 1

        when "("
          unless n_token =~ /statement|not|\(|\+|-/
            raise "Error at column #{scanner.token_index}. \nExpected 'statement', '(',  not. Found '#{n_token_value}'"
          end

          parenth -= 1

        else
          raise "Unexpected token found at column #{scanner.token_index}. '#{c_token_value}'"
        end

        unless n_token == " " || substatement
          @execution_stack << {c_token => c_token_value}
        end

        p_token = c_token
        c_token = n_token
        c_token_value = n_token_value
      end

      return if substatement

      raise "Error. Missing parentheses ')'." if parenth < 0
      raise "Error. Missing parentheses '('." if parenth > 0
    end
  end
end
