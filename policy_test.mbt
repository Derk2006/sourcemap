///|
test "strict policy requires file and inline content" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  let diagnostics = map.validate_with(@sourcemap.ValidationPolicy::strict())
  assert_true(diagnostics.any(d => d.code == "policy.file"))
  assert_true(diagnostics.any(d => d.code == "policy.sourcesContent"))
  assert_true(!map.passes_policy(@sourcemap.ValidationPolicy::strict()))
}

///|
test "default policy accepts a minimal valid map" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
  ])
  assert_true(map.passes_policy(@sourcemap.ValidationPolicy::default()))
}

///|
test "policy can forbid unmapped segments and ignoreList" {
  let policy = @sourcemap.ValidationPolicy::default()
    .with_unmapped_segments(false)
    .with_ignore_list(false)
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
      @sourcemap.MappingSegment::unmapped(0, 4),
    ],
    ignore_list=[0],
  )
  let diagnostics = map.validate_with(policy)
  assert_true(diagnostics.any(d => d.code == "policy.unmapped"))
  assert_true(diagnostics.any(d => d.code == "policy.ignoreList"))
}

///|
test "policy limits segment and source count" {
  let policy = @sourcemap.ValidationPolicy::default().with_limits(
    max_segment_count=1,
    max_source_count=1,
  )
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt", "src/b.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::mapped(0, 4, 1, 0, 0),
  ])
  let diagnostics = map.validate_with(policy)
  assert_true(diagnostics.any(d => d.code == "policy.maxSegments"))
  assert_true(diagnostics.any(d => d.code == "policy.maxSources"))
}

///|
test "strict policy rejects empty names and unmapped segments" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::unmapped(0, 4),
    ],
    names=[""],
    file="bundle.js",
    sources_content=[Some("fn a {}")],
  )
  let diagnostics = map.validate_with(@sourcemap.ValidationPolicy::strict())
  assert_true(diagnostics.any(d => d.code == "policy.name.empty"))
  assert_true(diagnostics.any(d => d.code == "policy.unmapped"))
}
