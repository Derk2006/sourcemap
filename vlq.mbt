///|
let vlq_base_shift : Int = 5

///|
let vlq_base : Int = 1 << vlq_base_shift

///|
let vlq_base_mask : Int = vlq_base - 1

///|
let vlq_continuation_bit : Int = vlq_base

///|
fn base64_digit(value : Int) -> Char {
  match value {
    0..<26 => (value + 'A'.to_int()).unsafe_to_char()
    26..<52 => (value - 26 + 'a'.to_int()).unsafe_to_char()
    52..<62 => (value - 52 + '0'.to_int()).unsafe_to_char()
    62 => '+'
    63 => '/'
    _ => '?'
  }
}

///|
fn base64_value(ch : Char) -> Int? {
  let code = ch.to_int()
  if code >= 'A'.to_int() && code <= 'Z'.to_int() {
    Some(code - 'A'.to_int())
  } else if code >= 'a'.to_int() && code <= 'z'.to_int() {
    Some(code - 'a'.to_int() + 26)
  } else if code >= '0'.to_int() && code <= '9'.to_int() {
    Some(code - '0'.to_int() + 52)
  } else if ch == '+' {
    Some(62)
  } else if ch == '/' {
    Some(63)
  } else {
    None
  }
}

///|
fn to_vlq_signed(value : Int) -> Int {
  if value < 0 {
    (-value << 1) + 1
  } else {
    value << 1
  }
}

///|
fn from_vlq_signed(value : Int) -> Int {
  if (value & 1) == 1 {
    -(value >> 1)
  } else {
    value >> 1
  }
}

///|
pub fn encode_vlq(value : Int) -> String {
  let buf = StringBuilder()
  let mut vlq = to_vlq_signed(value)
  for ;; {
    let digit = vlq & vlq_base_mask
    vlq = vlq >> vlq_base_shift
    let digit = if vlq > 0 { digit | vlq_continuation_bit } else { digit }
    buf.write_char(base64_digit(digit))
    if vlq == 0 {
      break
    }
  }
  buf.to_string()
}

///|
pub fn decode_vlq(
  input : StringView,
  offset : Int,
) -> Result[(Int, Int), SourceMapError] {
  let mut result = 0
  let mut shift = 0
  let mut index = offset
  for ;; {
    if index >= input.length() {
      return Err(TruncatedVlq(offset~))
    }
    let ch = input.unsafe_get(index).unsafe_to_char()
    let digit = match base64_value(ch) {
      Some(value) => value
      None => return Err(InvalidBase64(char=ch, offset=index))
    }
    let continuation = (digit & vlq_continuation_bit) != 0
    let payload = digit & vlq_base_mask
    if shift >= 30 && payload > 1 {
      return Err(VlqOverflow(offset=index))
    }
    result = result | (payload << shift)
    index += 1
    shift += vlq_base_shift
    if !continuation {
      break
    }
  }
  Ok((from_vlq_signed(result), index))
}

///|
pub fn decode_vlq_values(
  input : StringView,
) -> Result[Array[Int], SourceMapError] {
  let values : Array[Int] = []
  let mut offset = 0
  while offset < input.length() {
    match decode_vlq(input, offset) {
      Ok((value, next)) => {
        values.push(value)
        offset = next
      }
      Err(err) => return Err(err)
    }
  }
  Ok(values)
}

///|
pub fn encode_vlq_values(values : ArrayView[Int]) -> String {
  let buf = StringBuilder()
  for value in values {
    buf.write_string(encode_vlq(value))
  }
  buf.to_string()
}
