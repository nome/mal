def READ [] {
  $in
}

def EVAL [] {
  $in
}

def PRINT [] {
  $in
}

def rep [] {
  READ | EVAL | PRINT
}

loop {
  # TODO: it would be nice if "input" could use reedline to read user input
  let user_input = (input "user> ")
  if $user_input == "" {
    break
  }
  $user_input | rep | print
}
