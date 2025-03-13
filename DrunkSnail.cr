module DrunkSnail
  class Parser
    getter open : String
    getter close : String
    getter param : String
    getter ref : String
    getter optional : String

    protected def self.expression_regex(open : String, operator : String, close : String, optional : String)
      Regex.new("#{Regex.escape(open)} *(?P<optional>\\(#{Regex.escape(optional)}\\))?\\(#{Regex.escape(operator)}\\)(?P<name>\\w+) *#{Regex.escape(close)}")
    end

    def initialize(@open = "<!--", @close = "-->", @param = "param", @ref = "ref", @optional = "optional")
      @param_regex = Parser.expression_regex(open, param, close, optional)
      @ref_regex = Parser.expression_regex(open, ref, close, optional)
    end

    def parse_refs(line)
      line.scan @ref_regex
    end

    def parse_params(line)
      line.scan @param_regex
    end
  end

  struct Expression
    getter name : String
    getter? optional : Bool

    def initialize(m : Regex::MatchData)
      @name = m["name"]
      @optional = m["optional"]? != nil
    end
  end

  alias ParamLineToken = String | Expression
  alias ParamLine = Array(ParamLineToken)

  struct Bounds
    getter left : String
    getter right : String

    def initialize(@left = "", @right = "")
    end

    def initialize(m : Regex::MatchData)
      @left = m.pre_match
      @right = m.post_match
    end

    def +(other : Bounds)
      Bounds.new other.left + left, right + other.right
    end
  end

  struct RefLine
    getter expression : Expression
    getter bounds : Bounds

    def initialize(m : Regex::MatchData)
      @expression = Expression.new m
      @bounds = Bounds.new m
    end
  end

  alias Line = String | ParamLine | RefLine
  alias TemplateParams = Hash(String, String | Array(String) | TemplateParams | Array(TemplateParams))

  class ParseError < Exception
  end

  class RenderError < Exception
  end

  class Template
    @lines = [] of Line

    def initialize(text : String, parser : Parser = Parser.new)
      text.each_line do |line|
        refs = parser.parse_refs line
        raise ParseError.new "Line `#{line}` contain more then one reference expressions" if refs.size > 1
        params = parser.parse_params line
        raise ParseError.new "Line `#{line}` mixes parameters and references expressions" if refs.size > 0 && params.size > 0
        if refs.size > 0
          @lines << RefLine.new refs[0]
        elsif params.size > 0
          result = ParamLine.new
          last_param_end = 0
          params.each do |param|
            plain = line[last_param_end, param.begin - last_param_end]
            result << plain if plain.size > 0
            result << Expression.new param
            last_param_end = param.end
          end
          plain = line[last_param_end, line.size]
          result << plain if plain.size > 0
          @lines << result
        else
          @lines << line
        end
      end
    end

    def render(params : TemplateParams = {} of String => String, templates : Templates = Templates.new, external : Bounds = Bounds.new)
      String.build do |result|
        @lines.each_with_index do |line, i|
          result << "\n" if i > 0
          if line.is_a? String
            result << external.left << line << external.right
          elsif line.is_a? ParamLine
            all_optional = line.all? { |token| !token.is_a?(Expression) || token.optional? }
            i = 0
            loop do
              result << "\n" if i > 0
              new_i = i + 1
              result << external.left
              line.each do |token|
                if token.is_a? String
                  result << token
                elsif token.is_a? Expression
                  if params.has_key? token.name
                    value = params[token.name]
                    if value.is_a? String
                      result << value if i == 0
                      new_i = -1 if !token.optional? || all_optional
                    elsif value.is_a? Array
                      new_i = -1 if value.size == i + 1
                      v = value[i]
                      raise RenderError.new "Expected String for param '#{token.name}'" if !v.is_a? String
                      result << v
                    end
                  else
                    raise RenderError.new "Expected key for param '#{token.name}'" if !token.optional?
                    new_i = -1
                  end
                end
              end
              result << external.right
              i = new_i
              break if i == -1
            end
          elsif line.is_a? RefLine
            name = line.expression.name
            if params.has_key?(name)
              param = params[name]
              param = [param] if !param.is_a? Array
              raise RenderError.new "Expected TemplateParams or Array(TemplateParams) for template '#{name}'" if !param.is_a? Array
              param.each_with_index do |subparams, j|
                raise RenderError.new "Expected TemplateParams for subtemplate '#{name}'" if !subparams.is_a? Hash
                result << "\n" if j > 0
                if !(line.expression.optional? && !templates.has_key?(name))
                  result << templates[name].render(subparams, templates, line.bounds + external)
                end
              end
            elsif !line.expression.optional?
              raise RenderError.new "Expected params for non-optional subtemplate '#{name}'"
            end
          end
        end
      end
    end
  end

  alias Templates = Hash(String, Template)
end
