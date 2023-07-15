use reader.nu
use printer.nu

let repl_env = {
  "+": {|args| $args.0 + $args.1}
  "-": {|args| $args.0 - $args.1}
  "*": {|args| $args.0 * $args.1}
  "/": {|args| $args.0 / $args.1 | into int}
}

def READ [] {
  reader read_str
}

def EVAL [eval_env] {
  let ast = $in
  match $ast {
    {type: list, value: []} => $ast
    {type: list, value: $list} => {
      let el = ($ast | eval_ast $eval_env)
      if ($el | first) != null {
        do ($el | first) ($el | skip)
      }
    }
    _ => { $ast | eval_ast $eval_env }
  }
}

def PRINT [] {
 #$in | debug | print
 $in | printer pr_str --print-readably
}

def eval_ast [eval_env] {
  let it = $in
  match $it {
    {type: symbol, value: $symbol} => {
      try {
        $eval_env | get $symbol
      } catch {
        print -e $"ERROR: unknown symbol >($symbol)<"
	null
      }
    }
    {type: list, value: $list} => {
      $list | each -k {|it| $it | EVAL $eval_env}
    }
    {type: vector, value: $vector} => {
      {type: vector, value: ($vector | each -k {|it| $it | EVAL $eval_env})}
    }
    {type: hash-map, value: $hashmap} => {
      let ehm = ($hashmap | transpose key value | each {|it| {key: $it.key, value: ($it.value | EVAL $eval_env)}} | transpose -i -r -d)
      {type: hash-map, value: ($ehm)}
    }
    _ => $it
  }
}

def rep [] {
  READ | EVAL $repl_env | PRINT
}

loop {
  let user_input = (input "user> ")
  if $user_input == "" {
    break
  }
  $user_input | rep | print
}
