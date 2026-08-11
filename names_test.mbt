///|
test "name_uses returns generated and original locations" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 4, 0, 1, 0),
      @sourcemap.MappingSegment::mapped(1, 0, 0, 2, 0, name_index=0),
    ],
    names=["main"],
  )
  let uses = map.name_uses()
  @test.assert_eq(uses.length(), 2)
  @test.assert_eq(uses[0].name, "main")
  @test.assert_eq(uses[1].generated_line, 1)
}

///|
test "rename_name updates names table" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0)],
    names=["old"],
  )
  @test.assert_eq(map.rename_name("old", "new").names, ["new"])
}

///|
test "filter_names remaps kept names and clears removed references" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 4, 0, 1, 0, name_index=1),
    ],
    names=["keep", "drop"],
  )
  let filtered = map.filter_names(name => name == "keep")
  @test.assert_eq(filtered.names, ["keep"])
  @test.assert_eq(filtered.mappings[0].name_index, Some(0))
  @test.assert_eq(filtered.mappings[1].name_index, None)
}

///|
test "name_frequency and name_report sort by count" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 4, 0, 1, 0, name_index=1),
      @sourcemap.MappingSegment::mapped(0, 8, 0, 2, 0, name_index=0),
    ],
    names=["hot", "cold"],
  )
  let freq = map.name_frequency()
  @test.assert_eq(freq[0], ("hot", 2))
  @test.assert_eq(freq[1], ("cold", 1))
  assert_true(map.name_report().contains("hot: 2"))
}
