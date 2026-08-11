///|
fn transform_sample() -> @sourcemap.SourceMap {
  @sourcemap.SourceMap::SourceMap(
    ["src\\a.mbt", "vendor\\b.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 8, 1, 2, 4, name_index=1),
      @sourcemap.MappingSegment::unmapped(1, 0),
    ],
    names=["a", "b"],
    file="bundle.js",
    sources_content=[Some("fn a {}"), Some("fn b {}")],
    ignore_list=[1],
  )
}

///|
test "metadata transforms set and clear file roots" {
  let map = transform_sample()
    .without_file()
    .with_file("out.js")
    .without_source_root()
    .with_source_root("/repo")
  @test.assert_eq(map.file, Some("out.js"))
  @test.assert_eq(map.source_root, Some("/repo"))
}

///|
test "source transforms rename prefix and normalize paths" {
  let map = transform_sample()
    .normalize_source_slashes()
    .replace_source_prefix("src/", "app/")
    .prefix_sources("./")
    .rename_source("./vendor/b.mbt", "./third_party/b.mbt")
  @test.assert_eq(map.sources, ["./app/a.mbt", "./third_party/b.mbt"])
}

///|
test "without_names removes name table and segment references" {
  let map = transform_sample().without_names()
  @test.assert_eq(map.names.length(), 0)
  assert_true(map.mappings.all(segment => segment.name_index is None))
}

///|
test "filter_sources remaps retained source indexes" {
  let map = transform_sample()
    .normalize_source_slashes()
    .filter_sources(source => source.contains("src/"))
  @test.assert_eq(map.sources, ["src/a.mbt"])
  @test.assert_eq(map.sources_content, [Some("fn a {}")])
  @test.assert_eq(map.ignore_list, [])
  @test.assert_eq(map.mappings.length(), 2)
  @test.assert_eq(map.mappings[0].source_index, Some(0))
}

///|
test "slice_generated_lines shifts selected line range" {
  let map = transform_sample().slice_generated_lines(1, 2)
  @test.assert_eq(map.mappings.length(), 1)
  @test.assert_eq(map.mappings[0].generated_line, 0)
}

///|
test "drop_unmapped and compact reduce optional data" {
  let dropped = transform_sample().drop_unmapped()
  @test.assert_eq(dropped.mappings.length(), 2)
  let compact = transform_sample().compact()
  @test.assert_eq(compact.names, [])
  @test.assert_eq(compact.sources_content, [])
  @test.assert_eq(compact.mappings.length(), 2)
}

///|
test "map_generated_columns and map_original_lines transform coordinates" {
  let map = transform_sample()
    .normalize_source_slashes()
    .map_generated_columns((_line, column) => column + 10)
    .map_original_lines((source, line) => {
      if source.contains("src/") {
        line + 100
      } else {
        line
      }
    })
  @test.assert_eq(map.mappings[0].generated_column, 10)
  @test.assert_eq(map.mappings[0].original_line, Some(100))
  @test.assert_eq(map.mappings[1].original_line, Some(2))
}
