///|
test "trace_vlq exposes payload steps" {
  let encoded = @sourcemap.encode_vlq(123)
  let trace = @sourcemap.trace_vlq(encoded, 0).unwrap()
  assert_true(trace.length() >= 1)
  @test.assert_eq(trace.last().unwrap().continuation, false)
}

///|
test "trace_mappings reports each decoded segment" {
  let raw = @sourcemap.encode_mappings([
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
    @sourcemap.MappingSegment::unmapped(0, 4),
    @sourcemap.MappingSegment::mapped(1, 0, 0, 1, 0),
  ])
  let traces = @sourcemap.trace_mappings(raw)
  @test.assert_eq(traces.length(), 3)
  @test.assert_eq(traces[0].line, 0)
  @test.assert_eq(traces[1].decoded.unwrap().is_mapped(), false)
  @test.assert_eq(traces[2].line, 1)
}

///|
test "trace_mappings_report contains error line for invalid segment" {
  let raw = @sourcemap.encode_vlq_values([0, 1])
  let report = @sourcemap.trace_mappings_report(raw)
  assert_true(report.contains("segment must contain 1, 4 or 5 VLQ fields"))
}

///|
test "segment trace summary includes values" {
  let raw = @sourcemap.encode_mappings([
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  let traces = @sourcemap.trace_mappings(raw)
  let summary = traces[0].summary()
  assert_true(summary.contains("line=0"))
  assert_true(summary.contains("values=[0,0,0,0]"))
  assert_true(summary.contains("ok"))
}
