class Parser
  getter param_regex : Regex
  getter ref_regex : Regex

  protected def self.expression_regex(open : String, operator : String, close : String, optional : String) : Regex
    return Regex.new("#{Regex.escape(open)} *(?P<optional>\\(#{Regex.escape(optional)}\\))?\\(#{Regex.escape(operator)}\\)(?P<name>\\w+) *#{Regex.escape(close)}")
  end

  def initialize(@open = "<!--",
                 @close = "-->",
                 @param = "param",
                 @ref = "ref",
                 @optional = "optional")
    @param_regex = Parser.expression_regex(open, param, close, optional)
    @ref_regex = Parser.expression_regex(open, ref, close, optional)
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

struct Bounds
  def initialize(@left : String,
                 @right : String)
  end
end

alias ParamLineToken = String | Expression
alias ParamLine = Array(ParamLineToken)

class RefLine
  def initialize(m : Regex::MatchData)
    @expression = Expression.new m
    @bounds = Bounds.new m.pre_match, m.post_match
  end
end

alias Line = String | ParamLine | RefLine

class Template
  @lines = [] of Line

  def initialize(text : String, parser : Parser = Parser.new)
    text.each_line do |line|
      refs = line.scan parser.ref_regex
      if refs.size > 1
        raise ParseError.new "Line `#{line}` contain more then one reference expressions"
      end
      params = line.scan parser.param_regex
      if refs.size > 0 && params.size > 0
        raise ParseError.new "Line `#{line}` mixes parameters and references expressions"
      end
      if refs.size > 0
        @lines << RefLine.new refs[0]
      elsif params.size > 0
        result = ParamLine.new
        last_param_end = 0
        params.each do |p|
          plain = line[last_param_end, p.begin - last_param_end]
          if plain.size > 0
            result << plain
          end
          result << Expression.new p
          last_param_end = p.end
        end
        plain = line[last_param_end, line.size]
        if plain.size > 0
          result << plain
        end
        @lines << result
      else
        @lines << line
      end
    end
  end

  def render
  end
end

alias Templates = Hash(String, Template)

class ParseError < Exception
end

class RenderError < Exception
end

t = Template.new "left<!-- (param)p1 -->middle<!-- (param)p2 -->right\nplain text\nleft<!-- (ref)r -->right"
