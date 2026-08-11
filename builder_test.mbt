///|
test "builder deduplicates sources and names" {
  let builder = @sourcemap.SourceMapBuilder(file="bundle.js")
  builder.add_mapping(0, 0, "src/a.mbt", 0, 0, name="main")
  builder.add_mapping(0, 8, "src/a.mbt", 1, 2, name="main")
  builder.add_unmapped(0, 16)
  let map = builder.build()
  @test.assert_eq(map.sources, ["src/a.mbt"])
  @test.assert_eq(map.names, ["main"])
  @test.assert_eq(map.mappings.length(), 3)
  @test.assert_eq(map.mappings[0].source_index, Some(0))
  @test.assert_eq(map.mappings[1].name_index, Some(0))
}

///|
test "builder manages source content and ignore list" {
  let builder = @sourcemap.SourceMapBuilder()
  let index = builder.set_source_content("src/a.mbt", "fn a {}")
  @test.assert_eq(index, 0)
  ignore(builder.mark_ignored("src/a.mbt"))
  ignore(builder.mark_ignored("src/a.mbt"))
  let map = builder.build()
  @test.assert_eq(map.sources_content, [Some("fn a {}")])
  @test.assert_eq(map.ignore_list, [0])
  assert_true(map.is_source_ignored("src/a.mbt"))
  assert_true(builder.clear_source_content("src/a.mbt"))
  assert_true(builder.unmark_ignored("src/a.mbt"))
  let next = builder.build()
  @test.assert_eq(next.sources_content, [None])
  @test.assert_eq(next.ignore_list, [])
}

///|
test "builder merge remaps source and name indexes" {
  let left = @sourcemap.SourceMapBuilder()
  left.add_mapping(0, 0, "src/left.mbt", 0, 0, name="left")
  let right = @sourcemap.SourceMapBuilder()
  right.add_mapping(0, 0, "src/right.mbt", 2, 4, name="right")
  right.add_unmapped(0, 10)
  left.merge_from(right.build(), generated_line_offset=3)
  let map = left.build()
  @test.assert_eq(map.sources, ["src/left.mbt", "src/right.mbt"])
  @test.assert_eq(map.names, ["left", "right"])
  @test.assert_eq(map.mappings[1].generated_line, 3)
  @test.assert_eq(map.mappings[1].source_index, Some(1))
  @test.assert_eq(map.mappings[1].name_index, Some(1))
}

///|
test "to_builder preserves existing map and allows edits" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0)],
    file="bundle.js",
  )
  let builder = map.to_builder()
  builder.add_mapping(1, 0, "src/b.mbt", 0, 0, name="b")
  let edited = builder.build()
  @test.assert_eq(edited.file, Some("bundle.js"))
  @test.assert_eq(edited.sources, ["src/a.mbt", "src/b.mbt"])
  @test.assert_eq(edited.names, ["b"])
  @test.assert_eq(edited.mappings.length(), 2)
}

///|
test "builder reset methods clear expected state" {
  let builder = @sourcemap.SourceMapBuilder(
    file="bundle.js",
    source_root="/root",
  )
  builder.add_mapping(0, 0, "src/a.mbt", 0, 0, name="a")
  builder.reset_mappings()
  @test.assert_eq(builder.mapping_count(), 0)
  @test.assert_eq(builder.source_count(), 1)
  builder.reset_all()
  @test.assert_eq(builder.source_count(), 0)
  @test.assert_eq(builder.name_count(), 0)
  @test.assert_eq(builder.mapping_count(), 0)
  @test.assert_eq(builder.build().file, None)
}
