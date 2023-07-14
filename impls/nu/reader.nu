export def read_str [] {
  (tokenize | read_form).0
}

def tokenize [] {
  parse -r "[\\s,]*(~@|[\\[\\]{}()'`~^@]|\"(?:\\\\.|[^\\\\\"])*\"?|;.*|[^\\s\\[\\]{}('\"`,;)]*)" | get capture0 | where {|x| not ($x | str starts-with ';')}
}

def read_form [] {
  let it = $in
  if ($it | is-empty) {
    return [null, []]
  }
  match ($it | first) {
    '(' => { $it | read_list '(' ')' }
    '[' => { $it | read_list '[' ']' }
    '{' => { $it | read_list '{' '}' }

    "'" => {
      let f = ($it | skip | read_form)
      let result = {type: list, value: [{type: symbol, value: quote}, $f.0]}
      [$result, $f.1]
    }
    "`" => {
      let f = ($it | skip | read_form)
      let result = {type: list, value: [{type: symbol, value: quasiquote}, $f.0]}
      [$result, $f.1]
    }
    "~" => {
      let f = ($it | skip | read_form)
      let result = {type: list, value: [{type: symbol, value: unquote}, $f.0]}
      [$result, $f.1]
    }
    "~@" => {
      let f = ($it | skip | read_form)
      let result = {type: list, value: [{type: symbol, value: splice-unquote}, $f.0]}
      [$result, $f.1]
    }
    "@" => {
      let f = ($it | skip | read_form)
      let result = {type: list, value: [{type: symbol, value: deref}, $f.0]}
      [$result, $f.1]
    }
    "^" => {
      let m = ($it | skip | read_form)
      let f = ($m.1 | read_form)
      let result = {type: list, value: [{type: symbol, value: with-meta}, $f.0, $m.0]}
      [$result, $f.1]
    }

    _ => { $it | read_atom }
  }
}

def read_list [start: string, end: string] {
  # TODO: it would be more memory efficient if streams were an actual nu data
  # type and we could keep writing to the same stream instead of having to
  # append result lists (sort of like named pipes for structured data)
  let it = $in
  mut result = []
  mut rest = ($it | skip)
  loop {
    if ($rest | is-empty) {
      print -e $"ERROR: unbalanced ($start)"
      return [[], []]
    }
    if ($rest | first) == $end {
      match $start {
        '(' => { return [{type: list, value: $result}, ($rest | skip)] }
	'[' => { return [{type: vector, value: $result}, ($rest | skip)] }
	'{' => {
	  if ($result | length) mod 2 != 0 {
	    print -e "ERROR: odd number of hash-map arguments"
	    return [[], []]
	  }
	  if ($result | is-empty) {
	    return [{type: hash-map, value: {}}, ($rest | skip)]
	  }
	  let hm = ($result | group 2 | each { |it| {key: $it.0, value: $it.1} } | transpose -i -r).0
	  return [{type: hash-map, value: $hm}, ($rest | skip)]
	  }
      }
    }
    let f = ($rest | read_form)
    $result = ($result | append [$f.0])
    $rest = $f.1
  }
}

def read_atom [] {
  let it = $in
  let atom = ($it | first)
  let rest = ($it | skip)
  if $atom =~ '^-?[0-9]+$' {
    return [($atom | into int), $rest]
  }
  if ($atom | str starts-with '"') {
    return [($atom | read_string), $rest]
  }
  if ($atom | str starts-with ':') {
    let parsed = ($atom | str replace '^:' "\u{29E}")
    return [$parsed, $rest]
  }
  match $atom {
    'nil' => [null, $rest]
    'true' => [true, $rest]
    'false' => [false, $rest]
    _ => [{type: symbol, value: $atom}, $rest]
  }
}

def read_string [] {
  let tokens = (parse -r '(\\.|.)' | get capture0 | skip)
  if ($tokens | last) != '"' {
    print -e "ERROR: unbalanced \""
    return null
  }
  $tokens | drop | each {|it|
    match $it {
      '\"' => { '"' }
      '\n' => { "\n" }
      '\\' => { '\' }
      '\' => { print -e "ERROR: unbalanced \\"; return null }
      _ => { $it }
    }
  } | str join ''
}
