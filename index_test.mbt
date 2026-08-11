///|
fn indexed_sample() -> @sourcemap.SourceMap {
  @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 8, 0, 0, 8),
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::unmapped(1, 4),
    @sourcemap.MappingSegment::mapped(2, 2, 0, 2, 2),
  ])
}

///|
test "index sorts mappings and records line ranges" {
  let index = indexed_sample().index()
  @test.assert_eq(index.segment_count(), 4)
  @test.assert_eq(index.line_count(), 3)
  @test.assert_eq(index.generated_line_numbers(), [0, 1, 2])
  @test.assert_eq(index.segments[0].generated_column, 0)
  @test.assert_eq(index.segments[1].generated_column, 8)
}

///|
test "index returns segments for a generated line" {
  let index = indexed_sample().index()
  let line0 = index.segments_for_line(0)
  let line9 = index.segments_for_line(9)
  @test.assert_eq(line0.length(), 2)
  @test.assert_eq(line9.length(), 0)
  @test.assert_eq(index.first_segment_for_line(0).unwrap().generated_column, 0)
  @test.assert_eq(index.last_segment_for_line(0).unwrap().generated_column, 8)
}

///|
test "index can find floor and exact generated segment" {
  let index = indexed_sample().index()
  @test.assert_eq(index.find_generated_floor(0, 7).unwrap().generated_column, 0)
  @test.assert_eq(index.find_generated_floor(0, 8).unwrap().generated_column, 8)
  @test.assert_eq(index.find_generated_exact(0, 8).unwrap().generated_column, 8)
  @test.assert_eq(index.find_generated_exact(0, 7), None)
}

///|
test "index filters mapped unmapped and named segments" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::unmapped(0, 4),
      @sourcemap.MappingSegment::mapped(0, 8, 0, 0, 8),
    ],
    names=["a"],
  )
  let index = map.index()
  @test.assert_eq(index.mapped_segments().length(), 2)
  @test.assert_eq(index.unmapped_segments().length(), 1)
  @test.assert_eq(index.named_segments().length(), 1)
}

///|
test "index line_summary mirrors segment counts" {
  let summary = indexed_sample().index().line_summary(0)
  @test.assert_eq(summary.line, 0)
  @test.assert_eq(summary.segment_count, 2)
  @test.assert_eq(summary.mapped_segment_count, 2)
  @test.assert_eq(summary.first_column, Some(0))
  @test.assert_eq(summary.last_column, Some(8))
}
