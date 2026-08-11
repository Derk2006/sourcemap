///|
pub struct ComposeSummary {
  input_segments : Int
  composed_segments : Int
  preserved_segments : Int
  unmapped_segments : Int
  missing_intermediate_segments : Int
} derive(Eq, Debug, ToJson)

///|
fn segment_source_name(map : SourceMap, segment : MappingSegment) -> String? {
  match segment.source_index {
    Some(index) =>
      if index >= 0 && index < map.sources.length() {
        Some(map.sources[index])
      } else {
        None
      }
    None => None
  }
}

///|
fn segment_name_value(map : SourceMap, segment : MappingSegment) -> String? {
  match segment.name_index {
    Some(index) =>
      if index >= 0 && index < map.names.length() {
        Some(map.names[index])
      } else {
        None
      }
    None => None
  }
}

///|
fn should_compose_source(source : String, selected : String?) -> Bool {
  match selected {
    Some(value) => source == value
    None => true
  }
}

///|
fn add_builder_mapping(
  builder : SourceMapBuilder,
  generated_line : Int,
  generated_column : Int,
  source : String,
  original_line : Int,
  original_column : Int,
  name : String?,
) -> Unit {
  match name {
    Some(value) =>
      builder.add_mapping(
        generated_line,
        generated_column,
        source,
        original_line,
        original_column,
        name=value,
      )
    None =>
      builder.add_mapping(
        generated_line, generated_column, source, original_line, original_column,
      )
  }
}

///|
fn best_composed_name(
  outer : SourceMap,
  segment : MappingSegment,
  original : OriginalPosition,
) -> String? {
  match original.name {
    Some(value) => Some(value)
    None => segment_name_value(outer, segment)
  }
}

///|
fn preserve_outer_segment(
  builder : SourceMapBuilder,
  outer : SourceMap,
  segment : MappingSegment,
) -> Unit {
  match
    (
      segment_source_name(outer, segment),
      segment.original_line,
      segment.original_column,
    ) {
    (Some(source), Some(line), Some(column)) =>
      add_builder_mapping(
        builder,
        segment.generated_line,
        segment.generated_column,
        source,
        line,
        column,
        segment_name_value(outer, segment),
      )
    _ => builder.add_unmapped(segment.generated_line, segment.generated_column)
  }
}

///|
pub fn SourceMap::compose_with(
  self : SourceMap,
  previous : SourceMap,
  intermediate_source? : String,
  preserve_unresolved? : Bool = true,
) -> SourceMap {
  let builder = SourceMapBuilder()
  for segment in sorted_mapping_copy(self.mappings) {
    match
      (
        segment_source_name(self, segment),
        segment.original_line,
        segment.original_column,
      ) {
      (Some(source), Some(line), Some(column)) =>
        if should_compose_source(source, intermediate_source) {
          match previous.find_original(line, column) {
            Some(original) =>
              add_builder_mapping(
                builder,
                segment.generated_line,
                segment.generated_column,
                original.source,
                original.line,
                original.column,
                best_composed_name(self, segment, original),
              )
            None =>
              if preserve_unresolved {
                preserve_outer_segment(builder, self, segment)
              } else {
                builder.add_unmapped(
                  segment.generated_line,
                  segment.generated_column,
                )
              }
          }
        } else {
          preserve_outer_segment(builder, self, segment)
        }
      _ =>
        builder.add_unmapped(segment.generated_line, segment.generated_column)
    }
  }
  let result = builder.build()
  { ..result, file: self.file, source_root: previous.source_root }.canonical()
}

///|
pub fn SourceMap::compose_summary(
  self : SourceMap,
  previous : SourceMap,
  intermediate_source? : String,
) -> ComposeSummary {
  let mut composed = 0
  let mut preserved = 0
  let mut unmapped = 0
  let mut missing = 0
  for segment in self.mappings {
    match
      (
        segment_source_name(self, segment),
        segment.original_line,
        segment.original_column,
      ) {
      (Some(source), Some(line), Some(column)) =>
        if should_compose_source(source, intermediate_source) {
          match previous.find_original(line, column) {
            Some(_) => composed += 1
            None => {
              preserved += 1
              missing += 1
            }
          }
        } else {
          preserved += 1
        }
      _ => unmapped += 1
    }
  }
  {
    input_segments: self.mappings.length(),
    composed_segments: composed,
    preserved_segments: preserved,
    unmapped_segments: unmapped,
    missing_intermediate_segments: missing,
  }
}

///|
pub fn ComposeSummary::summary(self : ComposeSummary) -> String {
  "compose input=\{self.input_segments} composed=\{self.composed_segments} preserved=\{self.preserved_segments} unmapped=\{self.unmapped_segments} missing=\{self.missing_intermediate_segments}"
}

///|
pub fn SourceMap::compose_report(
  self : SourceMap,
  previous : SourceMap,
  intermediate_source? : String,
) -> String {
  let summary = match intermediate_source {
    Some(source) => self.compose_summary(previous, intermediate_source=source)
    None => self.compose_summary(previous)
  }
  let result = match intermediate_source {
    Some(source) => self.compose_with(previous, intermediate_source=source)
    None => self.compose_with(previous)
  }
  let stats = result.stats()
  let buf = StringBuilder()
  buf.write_string("SourceMap compose\n")
  buf.write_string(summary.summary())
  buf.write_char('\n')
  buf.write_string(stats.summary())
  buf.write_char('\n')
  for source in result.sources {
    buf.write_string("source: \{source}\n")
  }
  buf.to_string()
}

///|
pub fn compose_chain(maps : ArrayView[SourceMap]) -> SourceMap {
  if maps.length() == 0 {
    return SourceMap::empty()
  }
  let mut current = maps[0]
  for i in 1..<maps.length() {
    current = current.compose_with(maps[i])
  }
  current
}
