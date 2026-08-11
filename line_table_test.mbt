///|
test "line_table handles lf and trailing line" {
  let table = @sourcemap.line_table("abc\ndef")
  @test.assert_eq(table.length(), 2)
  @test.assert_eq(table[0].length, 3)
  @test.assert_eq(table[0].has_line_break, true)
  @test.assert_eq(table[1].start_offset, 4)
  @test.assert_eq(table[1].length, 3)
}

///|
test "line_table handles crlf as one line break" {
  let table = @sourcemap.line_table("a\r\nbb")
  @test.assert_eq(table.length(), 2)
  @test.assert_eq(table[0].end_offset, 1)
  @test.assert_eq(table[1].start_offset, 3)
  @test.assert_eq(table[1].length, 2)
}

///|
test "line_table reports empty final line after newline" {
  let table = @sourcemap.line_table("a\n")
  @test.assert_eq(table.length(), 2)
  @test.assert_eq(table[1].length, 0)
  @test.assert_eq(@sourcemap.generated_line_lengths("a\n"), [1, 0])
}

///|
test "generated offset and position conversion" {
  let text = "abc\ndef"
  @test.assert_eq(
    @sourcemap.generated_offset_to_position(text, 5),
    Some(@sourcemap.GeneratedPosition::GeneratedPosition(1, 1)),
  )
  @test.assert_eq(@sourcemap.generated_position_to_offset(text, 1, 2), Some(6))
  @test.assert_eq(@sourcemap.generated_position_to_offset(text, 3, 0), None)
}

///|
test "coverage_for_text uses generated line lengths" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(1, 0, 0, 1, 0),
  ])
  let report = map.coverage_for_text("abcd\nxy")
  @test.assert_eq(report.total_columns, 6)
  @test.assert_eq(report.mapped_columns, 6)
  assert_true(
    @sourcemap.line_table_report("x").contains("Generated line table"),
  )
}
