///|
test "prune_unused_sources removes unreferenced entries" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/b.mbt", "src/c.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 1, 2, 4)],
    sources_content=[Some("a"), Some("b"), Some("c")],
  )
  let pruned = map.prune_unused_sources()
  @test.assert_eq(pruned.sources, ["src/b.mbt"])
  @test.assert_eq(pruned.sources_content, [Some("b")])
  @test.assert_eq(pruned.mappings[0].source_index, Some(0))
}

///|
test "prune_unused_names removes names without references" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=2)],
    names=["unused_a", "unused_b", "kept"],
  )
  let pruned = map.prune_unused_names()
  @test.assert_eq(pruned.names, ["kept"])
  @test.assert_eq(pruned.mappings[0].name_index, Some(0))
}

///|
test "deduplicate_sources remaps mappings and ignore list" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/a.mbt", "src/b.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 1, 0, 0),
      @sourcemap.MappingSegment::mapped(0, 8, 2, 1, 0),
    ],
    ignore_list=[1, 2],
  )
  let deduped = map.deduplicate_sources()
  @test.assert_eq(deduped.sources, ["src/a.mbt", "src/b.mbt"])
  @test.assert_eq(deduped.mappings[0].source_index, Some(0))
  @test.assert_eq(deduped.mappings[1].source_index, Some(1))
  @test.assert_eq(deduped.ignore_list, [0, 1])
}

///|
test "deduplicate_names remaps name indexes" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=1),
      @sourcemap.MappingSegment::mapped(0, 4, 0, 1, 0, name_index=2),
    ],
    names=["main", "main", "helper"],
  )
  let deduped = map.deduplicate_names()
  @test.assert_eq(deduped.names, ["main", "helper"])
  @test.assert_eq(deduped.mappings[0].name_index, Some(0))
  @test.assert_eq(deduped.mappings[1].name_index, Some(1))
}

///|
test "canonical sorts and removes duplicate unused data" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/a.mbt", "src/unused.mbt"],
    [
      @sourcemap.MappingSegment::mapped(1, 0, 1, 3, 0, name_index=1),
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
    ],
    names=["main", "main", "unused"],
  )
  let canonical = map.canonical()
  @test.assert_eq(canonical.sources, ["src/a.mbt"])
  @test.assert_eq(canonical.names, ["main"])
  @test.assert_eq(canonical.mappings[0].generated_line, 0)
  @test.assert_eq(canonical.mappings[1].source_index, Some(0))
}

///|
test "prune_summary reports before and after counts" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/unused.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0)],
    names=["used", "unused"],
  )
  let summary = map.prune_summary()
  @test.assert_eq(summary.sources_before, 2)
  @test.assert_eq(summary.sources_after, 1)
  assert_true(summary.summary().contains("sources 2->1"))
}
