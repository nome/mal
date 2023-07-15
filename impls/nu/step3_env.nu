use reader.nu
use printer.nu
use env.nu

def sym [name] {
  {type: symbol, value: $name}
}

let repl_env = (env make_env null)

let repl_env = (env set_env $repl_env (sym "+") {|args: list<int>| $args.0 + $args.1})
let repl_env = (env set_env $repl_env (sym "-") {|args: list<int>| $args.0 - $args.1})
let repl_env = (env set_env $repl_env (sym "*") {|args: list<int>| $args.0 * $args.1})
let repl_env = (env set_env $repl_env (sym "/") {|args: list<int>| $args.0 / $args.1 | into int})

def READ [] {
  reader read_str
}

def EVAL [eval_env] {
  let ast = $in
  match $ast {
    {type: list, value: []} => [$ast, $eval_env]
    {type: list, value: $list} => {
      match ($list | first) {
        {type: symbol, value: "def!"} => {
	  let val = ($list.2 | eval_ast $eval_env)
	  [$val, (env set_env $eval_env $list.1 $val)]
	}
	{type: symbol, value: "let*"} => {
	  let let_env = ($list.1 | group 2 | reduce -f (env make_env $eval_env) { |it, e|
	    env set_env $e $it.0 ($it.1 | EVAL $e).0
	  })
	  $list.2 | EVAL $let_env
	}
        _ => {
          let el = ($ast | eval_ast $eval_env)
          if ($el.0 | first) != null {
            let result = (do ($el.0 | first) ($el | skip))
	    [$result, $el.1]
          }
	}
      }
    }
    _ => [{ $ast | eval_ast $eval_env }, $eval_env]
  }
}

def PRINT [] {
 #$in | debug | print
 $in.0 | printer pr_str --print-readably
}

def eval_ast [eval_env] {
  let it = $in
  match $it {
    {type: symbol, value: $symbol} => { env get_env $eval_env $it }
    {type: list, value: $list} => {
      $list | each -k {|it| ($it | EVAL $eval_env).0}
    }
    {type: vector, value: $vector} => {
      {type: vector, value: ($vector | each -k {|it| ($it | EVAL $eval_env).0})}
    }
    {type: hash-map, value: $hashmap} => {
      let ehm = ($hashmap | transpose key value | each {|it| {key: $it.key, value: ($it.value | EVAL $eval_env).0}} | transpose -i -r -d)
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
