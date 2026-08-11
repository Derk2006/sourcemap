///|
test "GeneratedRange contains half open positions" {
  let range = @sourcemap.GeneratedRange::GeneratedRange(
    1,
    start_column=4,
    end_line=2,
    end_column=8,
  )
  assert_false(range.contains(1, 3))
  assert_true(range.contains(1, 4))
  assert_true(range.contains(2, 7))
  assert_false(range.contains(2, 8))
}

///|
test "slice_generated_range filters and rebases segments" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(1, 4, 0, 1, 0),
    @sourcemap.MappingSegment::mapped(1, 12, 0, 1, 8),
    @sourcemap.MappingSegment::mapped(2, 0, 0, 2, 0),
  ])
  let sliced = map.slice_generated_range(
    @sourcemap.GeneratedRange::GeneratedRange(
      1,
      start_column=4,
      end_line=2,
      end_column=0,
    ),
  )
  @test.assert_eq(sliced.mappings.length(), 2)
  @test.assert_eq(sliced.mappings[0].generated_line, 0)
  @test.assert_eq(sliced.mappings[0].generated_column, 0)
  @test.assert_eq(sliced.mappings[1].generated_column, 8)
}

///|
test "drop_generated_before keeps original coordinates" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(2, 8, 0, 2, 0),
  ])
  let dropped = map.drop_generated_before(2, column=4)
  @test.assert_eq(dropped.mappings.length(), 1)
  @test.assert_eq(dropped.mappings[0].generated_line, 2)
  @test.assert_eq(dropped.mappings[0].generated_column, 8)
}

///|
test "slice_original_range keeps only matching source positions" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt", "src/b.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(0, 8, 0, 5, 1),
    @sourcemap.MappingSegment::mapped(1, 0, 1, 0, 0),
  ])
  let sliced = map.slice_original_range(
    @sourcemap.OriginalRange::OriginalRange("src/a.mbt", 1, end_line=8),
  )
  @test.assert_eq(sliced.sources, ["src/a.mbt"])
  @test.assert_eq(sliced.mappings.length(), 1)
  @test.assert_eq(sliced.mappings[0].original_line, Some(5))
}

///|
test "sources_in_generated_range reports unique sources" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt", "src/b.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(0, 8, 0, 1, 0),
    @sourcemap.MappingSegment::mapped(1, 0, 1, 0, 0),
  ])
  let sources = map.sources_in_generated_range(
    @sourcemap.GeneratedRange::GeneratedRange(0, end_line=1),
  )
  @test.assert_eq(sources, ["src/a.mbt"])
  assert_true(
    map
    .generated_range_summary(
      @sourcemap.GeneratedRange::GeneratedRange(0, end_line=2),
    )
    .contains("segments=3"),
  )
}
