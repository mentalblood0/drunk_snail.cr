class Parser
  protected def self.expression_regex(open : String, operator : String, close : String, optional : String)
    Regex.new("#{Regex.escape(open)} *(?P<optional>\\(#{Regex.escape(optional)}\\))?\\(#{Regex.escape(operator)}\\)(?P<name>\\w+) *#{Regex.escape(close)}")
  end

  def initialize(open = "<!--",
                 close = "-->",
                 param = "param",
                 ref = "ref",
                 optional = "optional")
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
  @name : String
  @optional : Bool

  def initialize(m : Regex::MatchData)
    @name = m["name"]
    @optional = m["optional"]? != nil
  end
end

alias ParamLineToken = String | Expression
alias ParamLine = Array(ParamLineToken)

struct RefLine
  def initialize(m : Regex::MatchData)
    @expression = Expression.new m
    @left = m.pre_match
    @right = m.post_match
  end
end

alias Line = String | ParamLine | RefLine

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
    puts @lines
  end

  def render
  end
end

alias Templates = Hash(String, Template)

class ParseError < Exception
end

class RenderError < Exception
end

Template.new "left<!-- (param)p1 -->middle<!-- (param)p2 -->right\nplain text\nleft<!-- (ref)r -->right"
