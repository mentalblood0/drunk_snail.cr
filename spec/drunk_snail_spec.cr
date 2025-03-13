require "spec"
require "../src/drunk_snail"

private struct Syntax
  getter open : String
  getter close : String
  getter optional : String
  getter param : String
  getter ref : String

  def initialize(parser : DrunkSnail::Parser)
    @open = parser.open
    @close = parser.close
    @optional = "(#{parser.optional})"
    @param = "(#{parser.param})"
    @ref = "(#{parser.ref})"
  end
end

describe DrunkSnail do
  describe "#render" do
    it "correctly renders param" do
      DrunkSnail::Template.new("one <!-- (param)p --> two").render({"p" => "lalala"}).should eq "one lalala two"
    end
    it "correctly renders multivalued param" do
      DrunkSnail::Template.new("one <!-- (param)p --> two").render({"p" => ["v1", "v2"]}).should eq "one v1 two\none v2 two"
    end
    it "correctly renders multiple params" do
      DrunkSnail::Template.new("one <!-- (param)p1 --> <!-- (param)p2 --> two").render({"p1" => "v1", "p2" => "v2"}).should eq "one v1 v2 two"
    end
    it "correctly renders optional param" do
      DrunkSnail::Template.new("one <!-- (optional)(param)p --> two").render.should eq "one  two"
    end
    it "correctly renders optional param while there is also param with more than one value" do
      DrunkSnail::Template.new("left <!-- (param)p1 --> middle <!-- (optional)(param)p2 --> right\nplain text")
        .render({"p1" => ["lalala", "lululu"], "p2" => "lololo"}).should eq "left lalala middle lololo right\nleft lululu middle  right\nplain text"
    end

    it "correctly renders ref" do
      DrunkSnail::Template.new("one <!-- (ref)r --> two").render({"r" => {"p" => "v"}}, {"r" => DrunkSnail::Template.new("three")}).should eq "one three two"
    end
    it "correctly renders 2x2 HTML table" do
      DrunkSnail::Template.new("<table>\n    <!-- (ref)Row -->\n</table>").render(
        {"Row" => [{"cell" => ["1.1", "2.1"]}, {"cell" => ["1.2", "2.2"]}]},
        {"Row" => DrunkSnail::Template.new("<tr>\n    <td><!-- (param)cell --></td>\n</tr>")}
      ).should eq "<table>\n    <tr>\n        <td>1.1</td>\n        <td>2.1</td>\n    </tr>\n    <tr>\n        <td>1.2</td>\n        <td>2.2</td>\n    </tr>\n</table>"
    end
    it "correctly renders ref with param" do
      DrunkSnail::Template.new("one <!-- (ref)r --> two").render({"r" => {"p" => "three"}}, {"r" => DrunkSnail::Template.new("<!-- (param)p -->")}).should eq "one three two"
    end
    it "correctly renders multivalued ref with param" do
      DrunkSnail::Template.new("one <!-- (ref)r --> two").render({"r" => [{"p" => "three"}, {"p" => "four"}]}, {"r" => DrunkSnail::Template.new("<!-- (param)p -->")}).should eq "one three two\none four two"
    end

    parser = DrunkSnail::Parser.new
    syntax = Syntax.new parser

    valid_other = ["", " ", "la"]
    valid_gap = ["", " ", "  "]
    valid_value = ["", "l", "la", "\n"]
    valid_ref = ["#{syntax.open}#{syntax.param}p#{syntax.close}"]

    invalid_open_tag = (1..syntax.open.size - 1).map { |cut_n| syntax.open[0, cut_n] }
    invalid_close_tag = (1..syntax.close.size - 1).map { |cut_n| syntax.close[0, cut_n] }
    invalid_name = ["1", "-"]

    valid_value.each do |value|
      (valid_other + [syntax.open]).each do |bound_left|
        valid_gap.each do |gap_left|
          valid_gap.each do |gap_right|
            (valid_other + [syntax.open]).each do |bound_right|
              line = bound_left + syntax.open + gap_left + syntax.param + "p" + gap_right + syntax.close + bound_right
              correct = bound_left + value + bound_right
              it "correctly renders line '#{line}' as '#{correct}'" do
                DrunkSnail::Template.new(line).render({"p" => value}).should eq(correct)
              end
            end
          end
        end
      end
    end

    valid_value.each do |value|
      invalid_open_tag.each do |open_tag|
        (valid_other + [syntax.open]).each do |bound_left|
          valid_gap.each do |gap_left|
            invalid_name.each do |name|
              valid_gap.each do |gap_right|
                invalid_close_tag.each do |close_tag|
                  (valid_other + [syntax.open]).each do |bound_right|
                    line = bound_left + open_tag + gap_left + syntax.param + name + gap_right + close_tag + bound_right
                    it "correctly renders line '#{line}' as just it is" do
                      DrunkSnail::Template.new(line).render({"p" => value}).should eq(line)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    valid_ref.each do |ref|
      valid_value.each do |value|
        valid_other.each do |bound_left|
          valid_gap.each do |gap_left|
            valid_gap.each do |gap_right|
              valid_other.each do |bound_right|
                line = bound_left + syntax.open + gap_left + syntax.ref + "R" + gap_right + syntax.close + bound_right
                correct = bound_left + value + bound_right
                it "correctly renders line '#{line}' as '#{correct}'" do
                  DrunkSnail::Template.new(line).render({"R" => {"p" => value}}, {"R" => DrunkSnail::Template.new ref}).should eq(correct)
                end
              end
            end
          end
        end
      end
    end
  end
end
