use reader.nu
use printer.nu

def READ [] {
  reader read_str
}

def EVAL [] {
  $in
}

def PRINT [] {
 #$in | debug | print
 $in | printer pr_str --print-readably
}

def rep [] {
  READ | EVAL | PRINT
}

loop {
  let user_input = (input "user> ")
  if $user_input == "" {
    break
  }
  $user_input | rep | print
}
