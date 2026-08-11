///|
test "lint passes clean canonical map" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 4, 0, 1, 0, name_index=0),
    ],
    names=["main"],
    file="bundle.js",
  )
  let options = @sourcemap.SourceMapLintOptions::SourceMapLintOptions(
    require_all_names_used=true,
    min_mapped_ratio=0.50,
  )
  let summary = map.lint_summary(line_lengths=[8], options~)
  @test.assert_eq(summary.errors, 0)
  @test.assert_eq(summary.warnings, 0)
  assert_true(summary.passes())
  assert_true(map.passes_lint(line_lengths=[8], options~))
}

///|
test "lint reports missing file and low coverage" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0),
    @sourcemap.MappingSegment::unmapped(0, 2),
  ])
  let options = @sourcemap.SourceMapLintOptions::SourceMapLintOptions(
    require_file=true,
    min_mapped_ratio=0.90,
  )
  let diagnostics = map.lint(line_lengths=[10], options~)
  assert_true(diagnostics.any(d => d.code == "lint.file"))
  assert_true(diagnostics.any(d => d.code == "lint.coverage.min"))
}

///|
test "lint reports duplicate sources and names" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/a.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0)],
    names=["main", "main"],
    file="bundle.js",
  )
  let diagnostics = map.lint(line_lengths=[4])
  assert_true(diagnostics.any(d => d.code == "lint.source.duplicate"))
  assert_true(diagnostics.any(d => d.code == "lint.name.duplicate"))
}

///|
test "lint reports unused sources and names when required" {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/a.mbt", "src/unused.mbt"],
    [@sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0)],
    names=["main", "unused"],
    file="bundle.js",
  )
  let options = @sourcemap.SourceMapLintOptions::SourceMapLintOptions(
    require_all_sources_used=true,
    require_all_names_used=true,
  )
  let diagnostics = map.lint(line_lengths=[4], options~)
  assert_true(diagnostics.any(d => d.code == "lint.source.unused"))
  assert_true(diagnostics.any(d => d.code == "lint.name.unused"))
}

///|
test "lint_report renders summary and diagnostics" {
  let map = @sourcemap.SourceMap::SourceMap(["src/a.mbt"], [
    @sourcemap.MappingSegment::unmapped(0, 0),
  ])
  let options = @sourcemap.SourceMapLintOptions::SourceMapLintOptions(
    require_file=true,
    max_unmapped_segments=0,
  )
  let report = map.lint_report(line_lengths=[4], options~)
  assert_true(report.contains("SourceMap lint"))
  assert_true(report.contains("lint.unmapped.max"))
}
