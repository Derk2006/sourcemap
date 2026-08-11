///|
test "base64 alphabet is stable" {
  let values : Array[Int] = []
  for i in 0..<64 {
    values.push(i)
  }
  let chars = values.map(v => base64_digit(v).to_string()).join("")
  inspect(
    chars,
    content="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
  )
}

///|
test "segment values stop before separators" {
  let raw = encode_vlq_values([0, 1, 2, 3]) + "," + encode_vlq(9)
  let decoded = decode_segment_values(raw, 0)
  guard decoded is Ok((values, next)) else {
    fail("expected decoded segment values")
  }
  inspect(values.map(v => v.to_string()).join(","), content="0,1,2,3")
  inspect(next, content=raw.find(",").unwrap().to_string())
}

///|
test "json helpers decode optional arrays" {
  let obj : Map[String, Json] = {
    "sourcesContent": [Json::string("a"), null],
    "ignoreList": [1, 2],
  }
  guard decode_optional_string_array(obj, "sourcesContent") is Ok(content) else {
    fail("expected sourcesContent array")
  }
  guard decode_int_array_optional(obj, "ignoreList") is Ok(ignore_list) else {
    fail("expected ignoreList array")
  }
  inspect(content.length(), content="2")
  inspect(content[0].unwrap(), content="a")
  guard content[1] is None else { fail("expected null sourcesContent item") }
  inspect(ignore_list.map(v => v.to_string()).join(","), content="1,2")
}
