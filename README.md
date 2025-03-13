# drunk_snail

Pure [crystal](https://crystal-lang.org/) implementation of template language originally presented in [drunk snail](https://github.com/mentalblood0/drunk_snail)

Uses standard library only

## Why this language?

- Easy syntax
- Separates logic and data

## Why better then C / Python / Nim implementations?

- Compiled and statically typed yet memory safe
- Small codebase
- Allow for parser configuration
- Significantly (~x2) faster than Nim implementation

## Example

Row:

```html
<tr>
  <td><!-- (param)cell --></td>
</tr>
```

Table:

```html
<table>
  <!-- (ref)Row -->
</table>
```

Arguments:

```json
{
  "Row": [
    {
      "cell": ["1", "2"]
    },
    {
      "cell": ["3", "4"]
    }
  ]
}
```

Result:

```html
<table>
  <tr>
    <td>1</td>
    <td>2</td>
  </tr>
  <tr>
    <td>3</td>
    <td>4</td>
  </tr>
</table>
```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     drunk_snail:
       github: mentalblood0/drunk_snail
   ```

2. Run `shards install`

## Usage

```crystal
require "drunk_snail"

template = DrunkSnail::Template.new(
  "<table>\n" \
  "    <!-- (ref)Row -->\n" \
  "</table>"
)
params = {"Row" => [{"cell" => ["1", "2"]}, {"cell" => ["3", "4"]}]}
deps = {"Row" => DrunkSnail::Template.new(
  "<tr>\n" \
  "    <td><!-- (param)cell --></td>\n" \
  "</tr>\n"
)}
puts template.render params, deps
```

## Testing

Inside cloned repository execute:

```bash
crystal spec
```

## Benchmarking

Inside cloned repository execute:

```bash
crystal build drunk_snail_benchmark.cr --release
./drunk_snail_benchmark
```
