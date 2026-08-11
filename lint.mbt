///|
pub struct SourceMapLintOptions {
  require_file : Bool
  require_sorted_mappings : Bool
  require_no_duplicate_sources : Bool
  require_no_duplicate_names : Bool
  require_all_sources_used : Bool
  require_all_names_used : Bool
  min_mapped_ratio : Double?
  max_unmapped_segments : Int?
} derive(Eq, Debug, ToJson)

///|
pub struct LintSummary {
  errors : Int
  warnings : Int
  mapped_ratio : Double
  unused_sources : Int
  unused_names : Int
  duplicate_sources : Int
  duplicate_names : Int
} derive(Eq, Debug, ToJson)

///|
pub fn SourceMapLintOptions::SourceMapLintOptions(
  require_file? : Bool = false,
  require_sorted_mappings? : Bool = true,
  require_no_duplicate_sources? : Bool = true,
  require_no_duplicate_names? : Bool = true,
  require_all_sources_used? : Bool = false,
  require_all_names_used? : Bool = false,
  min_mapped_ratio? : Double,
  max_unmapped_segments? : Int,
) -> SourceMapLintOptions {
  {
    require_file,
    require_sorted_mappings,
    require_no_duplicate_sources,
    require_no_duplicate_names,
    require_all_sources_used,
    require_all_names_used,
    min_mapped_ratio,
    max_unmapped_segments,
  }
}

///|
pub fn SourceMapLintOptions::ci() -> SourceMapLintOptions {
  {
    require_file: true,
    require_sorted_mappings: true,
    require_no_duplicate_sources: true,
    require_no_duplicate_names: true,
    require_all_sources_used: true,
    require_all_names_used: false,
    min_mapped_ratio: Some(0.50),
    max_unmapped_segments: None,
  }
}

///|
fn mapping_order_is_sorted(segments : ArrayView[MappingSegment]) -> Bool {
  let mut previous_line = -1
  let mut previous_column = -1
  for segment in segments {
    if segment.generated_line < previous_line {
      return false
    }
    if segment.generated_line == previous_line &&
      segment.generated_column < previous_column {
      return false
    }
    previous_line = segment.generated_line
    previous_column = segment.generated_column
  }
  true
}

///|
fn duplicate_count(items : ArrayView[String]) -> Int {
  let seen : Array[String] = []
  let duplicates : Array[String] = []
  for item in items {
    if seen.contains(item) {
      if !duplicates.contains(item) {
        duplicates.push(item)
      }
    } else {
      seen.push(item)
    }
  }
  duplicates.length()
}

///|
fn push_duplicate_diagnostics(
  diagnostics : Array[Diagnostic],
  items : ArrayView[String],
  path : String,
  code : String,
) -> Unit {
  let reported : Array[String] = []
  for i, item in items {
    let start = i + 1
    for j in start..<items.length() {
      if items[j] == item && !reported.contains(item) {
        diagnostics.push(
          diag_warning(
            code,
            "\{path}[\{j}]",
            "duplicate entry '\{item}' also appears earlier",
          ),
        )
        reported.push(item)
      }
    }
  }
}

///|
fn push_unused_string_diagnostics(
  diagnostics : Array[Diagnostic],
  values : ArrayView[String],
  path : String,
  code : String,
  label : String,
) -> Unit {
  for value in values {
    diagnostics.push(
      diag_warning(code, path, "unused \{label} '\{value}' can be pruned"),
    )
  }
}

///|
pub fn SourceMap::lint(
  self : SourceMap,
  line_lengths? : ArrayView[Int] = [],
  options? : SourceMapLintOptions = SourceMapLintOptions::ci(),
) -> Array[Diagnostic] {
  let diagnostics = self.validate()
  if options.require_file && self.file is None {
    diagnostics.push(
      diag_error("lint.file", "file", "lint requires file field"),
    )
  }
  if options.require_sorted_mappings && !mapping_order_is_sorted(self.mappings) {
    diagnostics.push(
      diag_error(
        "lint.mapping.order", "mappings", "mappings must be sorted before publishing",
      ),
    )
  }
  if options.require_no_duplicate_sources {
    push_duplicate_diagnostics(
      diagnostics,
      self.sources,
      "sources",
      "lint.source.duplicate",
    )
  }
  if options.require_no_duplicate_names {
    push_duplicate_diagnostics(
      diagnostics,
      self.names,
      "names",
      "lint.name.duplicate",
    )
  }
  if options.require_all_sources_used {
    push_unused_string_diagnostics(
      diagnostics,
      self.unused_sources(),
      "sources",
      "lint.source.unused",
      "source",
    )
  }
  if options.require_all_names_used {
    push_unused_string_diagnostics(
      diagnostics,
      self.unused_names(),
      "names",
      "lint.name.unused",
      "name",
    )
  }
  if options.max_unmapped_segments is Some(limit) {
    let unmapped = self.stats().unmapped_segments
    if unmapped > limit {
      diagnostics.push(
        diag_error(
          "lint.unmapped.max",
          "mappings",
          "unmapped segment count \{unmapped} exceeds limit \{limit}",
        ),
      )
    }
  }
  if options.min_mapped_ratio is Some(limit) {
    let coverage = self.coverage_for_lengths(line_lengths)
    if coverage.total_columns > 0 && coverage.mapped_ratio < limit {
      diagnostics.push(
        diag_error(
          "lint.coverage.min",
          "mappings",
          "mapped ratio \{coverage.mapped_ratio} is below required \{limit}",
        ),
      )
    }
  }
  diagnostics
}

///|
pub fn SourceMap::lint_summary(
  self : SourceMap,
  line_lengths? : ArrayView[Int] = [],
  options? : SourceMapLintOptions = SourceMapLintOptions::ci(),
) -> LintSummary {
  let diagnostics = self.lint(line_lengths~, options~)
  let coverage = self.coverage_for_lengths(line_lengths)
  {
    errors: diagnostics.count_if(d => d.severity == "error"),
    warnings: diagnostics.count_if(d => d.severity == "warning"),
    mapped_ratio: coverage.mapped_ratio,
    unused_sources: self.unused_sources().length(),
    unused_names: self.unused_names().length(),
    duplicate_sources: duplicate_count(self.sources),
    duplicate_names: duplicate_count(self.names),
  }
}

///|
pub fn LintSummary::passes(self : LintSummary) -> Bool {
  self.errors == 0
}

///|
pub fn LintSummary::summary(self : LintSummary) -> String {
  "lint errors=\{self.errors} warnings=\{self.warnings} mapped_ratio=\{self.mapped_ratio} unused_sources=\{self.unused_sources} unused_names=\{self.unused_names} duplicate_sources=\{self.duplicate_sources} duplicate_names=\{self.duplicate_names}"
}

///|
pub fn SourceMap::lint_report(
  self : SourceMap,
  line_lengths? : ArrayView[Int] = [],
  options? : SourceMapLintOptions = SourceMapLintOptions::ci(),
) -> String {
  let summary = self.lint_summary(line_lengths~, options~)
  let diagnostics = self.lint(line_lengths~, options~)
  let buf = StringBuilder()
  buf.write_string("SourceMap lint\n")
  buf.write_string(summary.summary())
  buf.write_char('\n')
  for diagnostic in diagnostics {
    buf.write_string(
      "- [\{diagnostic.severity}] \{diagnostic.code} \{diagnostic.path}: \{diagnostic.message}\n",
    )
  }
  buf.to_string()
}

///|
pub fn SourceMap::passes_lint(
  self : SourceMap,
  line_lengths? : ArrayView[Int] = [],
  options? : SourceMapLintOptions = SourceMapLintOptions::ci(),
) -> Bool {
  self.lint_summary(line_lengths~, options~).passes()
}
