export def pr_str [--print-readably] {
  let it = $in
  let type = ($it | describe)
  if $type == 'int' {
    $it | into string
  } else if $type == 'string' {
    if ($it | str starts-with "\u{29E}") {
      $it | str replace "^\u{29E}" ":"
    } else {
      let value = if $print_readably { $it | str replace -a '\\' '\\' | str replace -a "\n" "\\n" | str replace -a "\"" "\\\"" } else { $it }
      $value | prepend '"' | append '"' | str join ''
    }
  } else if $type =~ '^record' {
    match $it.type {
      'symbol' => { $it.value }
      'list' => {
        $it.value | each { |it| $it | pr_str } | str join ' ' | str replace '^' '(' | str replace '$' ')'
      }
      'vector' => { $it.value | each { |it| $it | pr_str } | str join ' ' | str replace '^' '[' | str replace '$' ']' }
      'hash-map' => {
        let kvs = ($it.value | transpose key value | each {|it| [$it.key, $it.value]} | flatten)
        $kvs | each { |it| $it | pr_str } | str join ' ' | str replace '^' '{' | str replace '$' '}'
      }
      _ => { print -e $"ERROR: type ($it.type) unknown to pr_str" }
    }
  } else if $type == 'nothing' {
    'nil'
  } else if $type == 'bool' {
    $it | into string
  } else {
    print -e $"ERROR: type ($type) unknown to pr_str"
  }
}
