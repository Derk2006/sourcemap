///|
test "coverage_for_lengths counts mapped columns and gaps" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::unmapped(0, 4),
    @sourcemap.MappingSegment::mapped(0, 8, 0, 1, 0),
  ])
  let report = map.coverage_for_lengths([12])
  @test.assert_eq(report.total_columns, 12)
  @test.assert_eq(report.mapped_columns, 8)
  @test.assert_eq(report.unmapped_columns, 4)
  @test.assert_eq(report.lines[0].gap_count, 0)
}

///|
test "coverage_text_report renders per line details" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 2, 0, 0, 0),
  ])
  let report = map.coverage_text_report([8])
  assert_true(report.contains("SourceMap coverage"))
  assert_true(report.contains("line=0"))
  assert_true(report.contains("gaps=1"))
}

///|
test "coverage handles lines without length input" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(2, 0, 0, 2, 0),
  ])
  let report = map.coverage_for_lengths([])
  @test.assert_eq(report.lines.length(), 3)
  @test.assert_eq(report.total_columns, 0)
  @test.assert_eq(report.mapped_columns, 0)
}
