///|
test "spans derive end column from next segment on same line" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(0, 5, 0, 0, 5),
    @sourcemap.MappingSegment::mapped(1, 1, 0, 1, 1),
  ])
  let spans = map.spans()
  @test.assert_eq(spans.length(), 3)
  @test.assert_eq(spans[0].end_column, Some(5))
  @test.assert_eq(spans[1].end_column, None)
  @test.assert_eq(spans[2].line, 1)
}

///|
test "gaps_for_line returns unmapped generated ranges" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 2, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(0, 6, 0, 1, 0),
  ])
  let gaps = map.gaps_for_line(0, 10)
  @test.assert_eq(gaps.length(), 1)
  @test.assert_eq(gaps[0].start_column, 0)
  @test.assert_eq(gaps[0].end_column, Some(2))
}

///|
test "line_summaries include empty generated lines between mappings" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::unmapped(2, 4),
  ])
  let lines = map.line_summaries()
  @test.assert_eq(lines.length(), 3)
  @test.assert_eq(lines[0].mapped_segment_count, 1)
  @test.assert_eq(lines[1].segment_count, 0)
  @test.assert_eq(lines[2].unmapped_segment_count, 1)
}

///|
test "span_at locates mapped and unmapped spans" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::unmapped(0, 8),
  ])
  let mapped = map.span_at(0, 2).unwrap()
  let unmapped = map.span_at(0, 9).unwrap()
  @test.assert_eq(mapped.source_index, Some(0))
  @test.assert_eq(unmapped.source_index, None)
  @test.assert_eq(mapped.width_hint(20), 8)
  @test.assert_eq(unmapped.width_hint(20), 12)
}

///|
test "mapped_spans and unmapped_spans split coverage" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::unmapped(0, 4),
    @sourcemap.MappingSegment::mapped(1, 0, 0, 1, 0),
  ])
  @test.assert_eq(map.mapped_spans().length(), 2)
  @test.assert_eq(map.unmapped_spans().length(), 1)
}
