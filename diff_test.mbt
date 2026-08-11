///|
test "diff identifies source name and mapping changes" {
  let before = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0)],
    names=["a"],
    file="before.js",
  )
  let after = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/b.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(1, 0, 1, 2, 0, name_index=1),
    ],
    names=["a", "b"],
    file="after.js",
  )
  let diff = before.diff(after)
  assert_true(diff.has_changes())
  @test.assert_eq(diff.same_file, false)
  @test.assert_eq(diff.added_sources, ["src/b.mbt"])
  @test.assert_eq(diff.added_names, ["b"])
  @test.assert_eq(diff.changed_mapping_count, 1)
}

///|
test "diff reports no changes for identical maps" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  let diff = map.diff(map)
  assert_true(!diff.has_changes())
  @test.assert_eq(diff.changed_mapping_count, 0)
}

///|
test "diff summary is readable" {
  let before = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  let after = before.rename_source("src/a.mbt", "src/b.mbt")
  let summary = before.diff(after).summary()
  assert_true(summary.contains("SourceMap diff"))
  assert_true(summary.contains("added sources: src/b.mbt"))
  assert_true(summary.contains("removed sources: src/a.mbt"))
}
