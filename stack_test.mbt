///|
test "parse_stack_frame supports function and bare frame forms" {
  let frame = @sourcemap.parse_stack_frame("    at main (bundle.js:0:12)").unwrap()
  @test.assert_eq(frame.function_name, Some("main"))
  @test.assert_eq(frame.file, "bundle.js")
  @test.assert_eq(frame.line, 0)
  @test.assert_eq(frame.column, 12)
  let bare = @sourcemap.parse_stack_frame("bundle.js:2:4").unwrap()
  @test.assert_eq(bare.function_name, None)
  @test.assert_eq(bare.file, "bundle.js")
  @test.assert_eq(bare.line, 2)
  @test.assert_eq(bare.column, 4)
}

///|
test "parse_stack skips non frame lines" {
  let stack = "Error: boom\n    at main (bundle.js:0:12)\nnot a frame\nbundle.js:1:4"
  let frames = @sourcemap.parse_stack(stack)
  @test.assert_eq(frames.length(), 2)
  @test.assert_eq(frames[0].function_name, Some("main"))
  @test.assert_eq(frames[1].line, 1)
}

///|
test "symbolicate_stack maps generated frames to originals" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/main.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 10, 2, name_index=0),
      @sourcemap.MappingSegment::mapped(1, 0, 0, 20, 1),
    ],
    names=["main"],
    file="bundle.js",
  )
  let frames = map.symbolicate_stack(
    "at main (bundle.js:0:12)\nat run (bundle.js:1:3)",
  )
  @test.assert_eq(frames.length(), 2)
  @test.assert_eq(frames[0].original.unwrap().line, 10)
  @test.assert_eq(frames[1].original.unwrap().column, 1)
}

///|
test "symbolicated frame render includes generated origin" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/main.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 10, 2, name_index=0)],
    names=["main"],
  )
  let report = map.symbolicate_stack_report("at bundle.js:0:8")
  assert_true(report.contains("src/main.mbt:10:2"))
  assert_true(report.contains("<- bundle.js:0:8"))
}

///|
test "invalid stack frames are rejected" {
  @test.assert_eq(@sourcemap.parse_stack_frame("at main (bundle.js:x:1)"), None)
  @test.assert_eq(@sourcemap.parse_stack_frame("at main (bundle.js:1:x)"), None)
}
