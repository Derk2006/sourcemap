///|
test "compose_with rewrites intermediate source to original source" {
  let previous = @sourcemap.SourceMap::SourceMap(
    ["src/main.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 10, 2, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 8, 0, 11, 4, name_index=1),
    ],
    file="tmp/main.js",
    names=["main", "helper"],
  )
  let outer = @sourcemap.SourceMap::SourceMap(
    ["tmp/main.js"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 1),
      @sourcemap.MappingSegment::mapped(0, 12, 0, 0, 8),
    ],
    file="bundle.js",
  )
  let composed = outer.compose_with(previous, intermediate_source="tmp/main.js")
  @test.assert_eq(composed.file, Some("bundle.js"))
  @test.assert_eq(composed.sources, ["src/main.mbt"])
  @test.assert_eq(composed.names, ["main", "helper"])
  @test.assert_eq(composed.mappings[0].original_line, Some(10))
  @test.assert_eq(composed.mappings[1].original_column, Some(4))
}

///|
test "compose_with preserves unrelated sources" {
  let previous = @sourcemap.SourceMap::SourceMap(["src/main.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 1, 0),
  ])
  let outer = @sourcemap.SourceMap::SourceMap(["tmp/main.js", "vendor.js"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(0, 10, 1, 5, 0),
  ])
  let composed = outer.compose_with(previous, intermediate_source="tmp/main.js")
  @test.assert_eq(composed.sources, ["src/main.mbt", "vendor.js"])
  @test.assert_eq(composed.mappings[1].source_index, Some(1))
  @test.assert_eq(composed.mappings[1].original_line, Some(5))
}

///|
test "compose_with can turn unresolved mappings into unmapped segments" {
  let previous = @sourcemap.SourceMap::SourceMap(["src/main.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 1, 0),
  ])
  let outer = @sourcemap.SourceMap::SourceMap(["tmp/main.js"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 99, 0),
  ])
  let composed = outer.compose_with(
    previous,
    intermediate_source="tmp/main.js",
    preserve_unresolved=false,
  )
  @test.assert_eq(composed.mappings[0].is_mapped(), false)
  @test.assert_eq(composed.sources, [])
}

///|
test "compose_summary counts composed and missing segments" {
  let previous = @sourcemap.SourceMap::SourceMap(["src/main.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 1, 0),
  ])
  let outer = @sourcemap.SourceMap::SourceMap(["tmp/main.js"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(0, 8, 0, 9, 0),
    @sourcemap.MappingSegment::unmapped(0, 12),
  ])
  let summary = outer.compose_summary(
    previous,
    intermediate_source="tmp/main.js",
  )
  @test.assert_eq(summary.input_segments, 3)
  @test.assert_eq(summary.composed_segments, 1)
  @test.assert_eq(summary.missing_intermediate_segments, 1)
  @test.assert_eq(summary.unmapped_segments, 1)
  assert_true(summary.summary().contains("composed=1"))
}

///|
test "compose_report renders composed output sources" {
  let previous = @sourcemap.SourceMap::SourceMap(["src/main.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 1, 0),
  ])
  let outer = @sourcemap.SourceMap::SourceMap(["tmp/main.js"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  let report = outer.compose_report(previous, intermediate_source="tmp/main.js")
  assert_true(report.contains("SourceMap compose"))
  assert_true(report.contains("src/main.mbt"))
}

///|
test "compose_chain composes maps in order" {
  let first = @sourcemap.SourceMap::SourceMap(["tmp/a.js"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  let second = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 7, 3),
  ])
  let chained = @sourcemap.compose_chain([first, second])
  @test.assert_eq(chained.sources, ["src/a.mbt"])
  @test.assert_eq(chained.mappings[0].original_line, Some(7))
}
