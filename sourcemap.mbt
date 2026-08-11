///|
/// Position in generated code. Lines and columns are zero-based, matching the
/// Source Map v3 format.
pub struct GeneratedPosition {
  line : Int
  column : Int
} derive(Eq, Debug, ToJson)

///|
pub fn GeneratedPosition::GeneratedPosition(
  line : Int,
  column : Int,
) -> GeneratedPosition {
  { line, column }
}

///|
/// Position in an original source file. `name` is optional because most source
/// maps only attach names to identifiers and call sites.
pub struct OriginalPosition {
  source : String
  line : Int
  column : Int
  name : String?
} derive(Eq, Debug, ToJson)

///|
pub fn OriginalPosition::OriginalPosition(
  source : StringView,
  line : Int,
  column : Int,
  name? : String,
) -> OriginalPosition {
  { source: source.to_owned(), line, column, name }
}

///|
/// A decoded mapping segment. A segment with only generated fields is an
/// unmapped generated span; mapped segments carry a source index and original
/// coordinates, plus an optional name index.
pub struct MappingSegment {
  generated_line : Int
  generated_column : Int
  source_index : Int?
  original_line : Int?
  original_column : Int?
  name_index : Int?
} derive(Eq, Debug, ToJson)

///|
/// Source Map v3 data model. `mappings` is stored decoded so callers can query,
/// validate and transform it without repeatedly parsing VLQ text.
pub struct SourceMap {
  version : Int
  file : String?
  source_root : String?
  sources : Array[String]
  sources_content : Array[String?]
  names : Array[String]
  mappings : Array[MappingSegment]
  ignore_list : Array[Int]
} derive(Eq, Debug, ToJson)

///|
/// Aggregated counts that are useful in CI output and smoke tests.
pub struct MappingStats {
  generated_lines : Int
  total_segments : Int
  mapped_segments : Int
  unmapped_segments : Int
  named_segments : Int
  source_count : Int
  name_count : Int
  ignored_source_count : Int
} derive(Eq, Debug, ToJson)

///|
/// Per-source summary for dashboards and build reports.
pub struct SourceSummary {
  source : String
  index : Int
  mapped_segments : Int
  named_segments : Int
  first_original_line : Int?
  last_original_line : Int?
  ignored : Bool
} derive(Eq, Debug, ToJson)

///|
/// Validation diagnostic. `severity` is `"error"` or `"warning"`; `path`
/// points at the field or mapping segment that triggered the diagnostic.
pub struct Diagnostic {
  severity : String
  code : String
  path : String
  message : String
} derive(Eq, Debug, ToJson)

///|
/// Error type returned by parsing and encoding helpers.
pub(all) enum SourceMapError {
  InvalidBase64(char~ : Char, offset~ : Int)
  TruncatedVlq(offset~ : Int)
  VlqOverflow(offset~ : Int)
  InvalidSegment(line~ : Int, segment~ : Int, values~ : Int, reason~ : String)
  JsonParse(message~ : String)
  JsonDecode(path~ : String, expected~ : String)
  MissingField(field~ : String)
  InvalidField(field~ : String, message~ : String)
} derive(Eq, Debug, ToJson)

///|
pub fn SourceMapError::message(self : SourceMapError) -> String {
  match self {
    InvalidBase64(char~, offset~) =>
      "invalid base64 VLQ character '\{char}' at offset \{offset}"
    TruncatedVlq(offset~) =>
      "unterminated VLQ value starting before offset \{offset}"
    VlqOverflow(offset~) => "VLQ value overflows Int near offset \{offset}"
    InvalidSegment(line~, segment~, values~, reason~) =>
      "invalid mapping segment line=\{line} segment=\{segment} values=\{values}: \{reason}"
    JsonParse(message~) => "JSON parse error: \{message}"
    JsonDecode(path~, expected~) =>
      "JSON decode error at \{path}: expected \{expected}"
    MissingField(field~) => "missing required field: \{field}"
    InvalidField(field~, message~) => "invalid field \{field}: \{message}"
  }
}

///|
pub fn MappingSegment::generated_position(
  self : MappingSegment,
) -> GeneratedPosition {
  { line: self.generated_line, column: self.generated_column }
}

///|
pub fn MappingSegment::is_mapped(self : MappingSegment) -> Bool {
  self.source_index is Some(_) &&
  self.original_line is Some(_) &&
  self.original_column is Some(_)
}

///|
pub fn MappingSegment::has_name(self : MappingSegment) -> Bool {
  self.name_index is Some(_)
}

///|
pub fn MappingSegment::unmapped(
  generated_line : Int,
  generated_column : Int,
) -> MappingSegment {
  {
    generated_line,
    generated_column,
    source_index: None,
    original_line: None,
    original_column: None,
    name_index: None,
  }
}

///|
pub fn MappingSegment::mapped(
  generated_line : Int,
  generated_column : Int,
  source_index : Int,
  original_line : Int,
  original_column : Int,
  name_index? : Int,
) -> MappingSegment {
  {
    generated_line,
    generated_column,
    source_index: Some(source_index),
    original_line: Some(original_line),
    original_column: Some(original_column),
    name_index,
  }
}

///|
pub fn SourceMap::SourceMap(
  sources : ArrayView[String],
  mappings : ArrayView[MappingSegment],
  names? : ArrayView[String] = [],
  file? : String,
  source_root? : String,
  sources_content? : ArrayView[String?] = [],
  ignore_list? : ArrayView[Int] = [],
) -> SourceMap {
  {
    version: 3,
    file,
    source_root,
    sources: sources.to_owned(),
    sources_content: sources_content.to_owned(),
    names: names.to_owned(),
    mappings: mappings.to_owned(),
    ignore_list: ignore_list.to_owned(),
  }
}

///|
pub fn SourceMap::empty() -> SourceMap {
  SourceMap::SourceMap([], [])
}
