export def make_env [outer] {
  { outer: $outer, data: {} }
}

export def set_env [e: record, key: record<type: string, value: string>, value: any] {
  {
    outer: $e.outer
    data: ($e.data | insert $key.value $value)
  }
}

export def find_env [e, key] {
  if $key.value in $e.data {
    return $e
  } else if $e.outer != null {
    find_env $e.outer $key
  }
}

export def get_env [e, key] {
  let ee = (find_env $e $key)
  if $ee == null {
    print -e $"ERROR: symbol ($key.value) not found"
    null
  } else {
    $ee.data | get $key.value
  }
}

