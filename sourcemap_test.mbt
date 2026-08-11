///|
test "VLQ roundtrip covers positive negative and multi digit values" {
  let values = [-4096, -255, -64, -16, -1, 0, 1, 2, 16, 31, 32, 255, 4096]
  for value in values {
    let encoded = @sourcemap.encode_vlq(value)
    let decoded = @sourcemap.decode_vlq(encoded, 0)
    @test.assert_eq(decoded, Ok((value, encoded.length())))
  }
}

///|
test "decode_vlq_values decodes concatenated fields" {
  let encoded = @sourcemap.encode_vlq_values([0, 0, 0, 0, 2, -1, 16])
  let decoded = @sourcemap.decode_vlq_values(encoded)
  @test.assert_eq(decoded, Ok([0, 0, 0, 0, 2, -1, 16]))
}

///|
test "decode_vlq rejects invalid base64 character" {
  let decoded = @sourcemap.decode_vlq("!", 0)
  guard decoded is Err(@sourcemap.InvalidBase64(char='!', offset=0)) else {
    fail("expected invalid base64 error")
  }
}

///|
test "decode_vlq rejects truncated continuation" {
  let decoded = @sourcemap.decode_vlq("g", 0)
  guard decoded is Err(@sourcemap.TruncatedVlq(offset=0)) else {
    fail("expected truncated VLQ error")
  }
}

///|
test "mappings encode decode roundtrip with named and unmapped segments" {
  let segments = [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
    @sourcemap.MappingSegment::mapped(0, 4, 0, 0, 8),
    @sourcemap.MappingSegment::unmapped(0, 12),
    @sourcemap.MappingSegment::mapped(1, 0, 1, 3, 2, name_index=1),
    @sourcemap.MappingSegment::mapped(1, 9, 1, 3, 11),
  ]
  let encoded = @sourcemap.encode_mappings(segments)
  let decoded = @sourcemap.decode_mappings(encoded)
  @test.assert_eq(decoded, Ok(segments))
}

///|
test "decode_mappings rejects partial source segment" {
  let raw = @sourcemap.encode_vlq_values([0, 0])
  let decoded = @sourcemap.decode_mappings(raw)
  guard decoded
    is Err(@sourcemap.InvalidSegment(line=0, segment=0, values=2, ..)) else {
    fail("expected invalid segment field count")
  }
}

///|
test "source map json roundtrip keeps mappings and optional fields" {
  let original = @sourcemap.SourceMap::SourceMap(
    ["src/add.mbt", "src/main.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(1, 2, 1, 4, 6, name_index=1),
    ],
    names=["add", "main"],
    file="bundle.js",
    source_root="/workspace",
    sources_content=[Some("pub fn add"), Some("fn main")],
    ignore_list=[1],
  )
  let text = original.to_json_string()
  let parsed = @sourcemap.SourceMap::from_json_string(text)
  @test.assert_eq(parsed, Ok(original))
}

///|
test "from_json_string reports malformed json as project error" {
  let parsed = @sourcemap.SourceMap::from_json_string("{")
  guard parsed is Err(@sourcemap.JsonParse(..)) else {
    fail("expected json parse error")
  }
}

///|
test "from_json_string requires source map fields" {
  let parsed = @sourcemap.SourceMap::from_json_string("{\"version\":3}")
  guard parsed is Err(@sourcemap.MissingField(field="sources")) else {
    fail("expected missing sources field")
  }
}

///|
test "find_original returns nearest segment on same generated line" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/app.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 10, 2, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 8, 0, 11, 4, name_index=1),
      @sourcemap.MappingSegment::mapped(1, 0, 0, 20, 0),
    ],
    names=["start", "next"],
  )
  let found = map.find_original(0, 9)
  @test.assert_eq(
    found,
    Some(
      @sourcemap.OriginalPosition::OriginalPosition(
        "src/app.mbt",
        11,
        4,
        name="next",
      ),
    ),
  )
  @test.assert_eq(map.find_original(3, 0), None)
}

///|
test "find_generated returns generated position for original source" {
  let map = @sourcemap.SourceMap::SourceMap(["src/app.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 10, 2),
    @sourcemap.MappingSegment::mapped(0, 8, 0, 10, 8),
  ])
  @test.assert_eq(
    map.find_generated("src/app.mbt", 10, 9),
    Some(@sourcemap.GeneratedPosition::GeneratedPosition(0, 8)),
  )
  @test.assert_eq(map.find_generated("src/none.mbt", 10, 9), None)
}

///|
test "validate catches index and ordering errors" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/app.mbt"],
    [
      @sourcemap.MappingSegment::mapped(1, 5, 0, 0, 0),
      @sourcemap.MappingSegment::mapped(1, 3, 2, -1, 0, name_index=4),
    ],
    names=["ok"],
    ignore_list=[3],
  )
  let errors = map.errors()
  assert_true(errors.length() >= 5)
  assert_true(!map.is_valid())
}

///|
test "stats and source summaries count mapped named and ignored segments" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/b.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 8, 0, 1, 0),
      @sourcemap.MappingSegment::mapped(1, 0, 1, 5, 2, name_index=1),
      @sourcemap.MappingSegment::unmapped(1, 10),
    ],
    names=["a", "b"],
    ignore_list=[1],
  )
  let stats = map.stats()
  @test.assert_eq(stats.total_segments, 4)
  @test.assert_eq(stats.mapped_segments, 3)
  @test.assert_eq(stats.unmapped_segments, 1)
  @test.assert_eq(stats.named_segments, 2)
  let summaries = map.source_summaries()
  @test.assert_eq(summaries.length(), 2)
  @test.assert_eq(summaries[0].mapped_segments, 2)
  @test.assert_eq(summaries[1].ignored, true)
}

///|
test "report contains summary diagnostics and source rows" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  let report = map.report()
  assert_true(report.contains("SourceMap report"))
  assert_true(report.contains("source[0] src/a.mbt"))
}

///|
test "shift_generated offsets first line column and all generated lines" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 2, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(1, 4, 0, 1, 0),
  ])
  let shifted = map.shift_generated(3, 10)
  @test.assert_eq(shifted.mappings[0].generated_line, 3)
  @test.assert_eq(shifted.mappings[0].generated_column, 12)
  @test.assert_eq(shifted.mappings[1].generated_line, 4)
  @test.assert_eq(shifted.mappings[1].generated_column, 4)
}

///|
test "explain_generated is stable for mapped and unmapped positions" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 7, 1, name_index=0)],
    names=["entry"],
  )
  inspect(
    map.explain_generated(0, 2),
    content="generated 0:2 -> src/a.mbt:7:1 name=entry",
  )
  inspect(map.explain_generated(9, 0), content="generated 9:0 is unmapped")
}
