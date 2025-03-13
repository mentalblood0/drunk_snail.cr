require "benchmark"
require "./src/drunk_snail"

module DrunkSnail
  Benchmark.ips do |x|
    table = Template.new "<table>\n    <!-- (ref)Row -->\n</table>"
    templates = {"Row" => Template.new "<tr>\n    <td><!-- (param)cell --></td>\n</tr>"}
    (1..3).each do |power|
      size = 10**power

      params = {"Row" => [] of Hash(String, Array(String))}
      (0..size).each do |y|
        columns = {"cell" => [] of String}
        (0..size).each do |x|
          columns["cell"] << "#{x + y * size}"
        end
        params["Row"] << columns
      end

      x.report("render #{size}x#{size} table") { table.render params, templates }
    end
  end
end
