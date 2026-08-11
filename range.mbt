///|
/// Half-open generated-code range. `end_line=None` means the range has no upper
/// bound. When `end_line` is present and `end_column=None`, the range ends at
/// the start of `end_line`.
pub struct GeneratedRange {
  start_line : Int
  start_column : Int
  end_line : Int?
  end_column : Int?
} derive(Eq, Debug, ToJson)

///|
pub struct OriginalRange {
  source : String
  start_line : Int
  start_column : Int
  end_line : Int?
  end_column : Int?
} derive(Eq, Debug, ToJson)

///|
pub fn GeneratedRange::GeneratedRange(
  start_line : Int,
  start_column? : Int = 0,
  end_line? : Int,
  end_column? : Int,
) -> GeneratedRange {
  { start_line, start_column, end_line, end_column }
}

///|
pub fn OriginalRange::OriginalRange(
  source : StringView,
  start_line : Int,
  start_column? : Int = 0,
  end_line? : Int,
  end_column? : Int,
) -> OriginalRange {
  { source: source.to_owned(), start_line, start_column, end_line, end_column }
}

///|
fn before_range_start(
  line : Int,
  column : Int,
  start_line : Int,
  start_column : Int,
) -> Bool {
  line < start_line || (line == start_line && column < start_column)
}

///|
fn at_or_after_range_end(
  line : Int,
  column : Int,
  end_line : Int?,
  end_column : Int?,
) -> Bool {
  match end_line {
    None => false
    Some(limit_line) =>
      if line > limit_line {
        true
      } else if line < limit_line {
        false
      } else {
        match end_column {
          Some(limit_column) => column >= limit_column
          None => true
        }
      }
  }
}

///|
pub fn GeneratedRange::contains(
  self : GeneratedRange,
  line : Int,
  column : Int,
) -> Bool {
  !before_range_start(line, column, self.start_line, self.start_column) &&
  !at_or_after_range_end(line, column, self.end_line, self.end_column)
}

///|
pub fn OriginalRange::contains(
  self : OriginalRange,
  source : StringView,
  line : Int,
  column : Int,
) -> Bool {
  source.to_owned() == self.source &&
  !before_range_start(line, column, self.start_line, self.start_column) &&
  !at_or_after_range_end(line, column, self.end_line, self.end_column)
}

///|
pub fn GeneratedRange::is_empty(self : GeneratedRange) -> Bool {
  match self.end_line {
    Some(end_line) =>
      if end_line < self.start_line {
        true
      } else if end_line == self.start_line {
        match self.end_column {
          Some(end_column) => end_column <= self.start_column
          None => true
        }
      } else {
        false
      }
    None => false
  }
}

///|
pub fn OriginalRange::is_empty(self : OriginalRange) -> Bool {
  match self.end_line {
    Some(end_line) =>
      if end_line < self.start_line {
        true
      } else if end_line == self.start_line {
        match self.end_column {
          Some(end_column) => end_column <= self.start_column
          None => true
        }
      } else {
        false
      }
    None => false
  }
}

///|
fn rebase_generated_segment(
  segment : MappingSegment,
  range : GeneratedRange,
) -> MappingSegment {
  let line = segment.generated_line - range.start_line
  let column = if segment.generated_line == range.start_line {
    segment.generated_column - range.start_column
  } else {
    segment.generated_column
  }
  { ..segment, generated_line: line, generated_column: column }
}

///|
pub fn SourceMap::slice_generated_range(
  self : SourceMap,
  range : GeneratedRange,
  rebase? : Bool = true,
) -> SourceMap {
  if range.is_empty() {
    return { ..self, mappings: [] }.prune_unused()
  }
  let mappings : Array[MappingSegment] = []
  for segment in self.mappings {
    if range.contains(segment.generated_line, segment.generated_column) {
      if rebase {
        mappings.push(rebase_generated_segment(segment, range))
      } else {
        mappings.push(segment)
      }
    }
  }
  { ..self, mappings, }.prune_unused().sorted()
}

///|
pub fn SourceMap::drop_generated_before(
  self : SourceMap,
  line : Int,
  column? : Int = 0,
) -> SourceMap {
  self.slice_generated_range(
    GeneratedRange::GeneratedRange(line, start_column=column),
    rebase=false,
  )
}

///|
pub fn SourceMap::take_generated_before(
  self : SourceMap,
  line : Int,
  column? : Int,
) -> SourceMap {
  let range = match column {
    Some(value) =>
      GeneratedRange::GeneratedRange(0, end_line=line, end_column=value)
    None => GeneratedRange::GeneratedRange(0, end_line=line)
  }
  self.slice_generated_range(range, rebase=false)
}

///|
fn segment_original_source(
  map : SourceMap,
  segment : MappingSegment,
) -> String? {
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
fn segment_in_original_range(
  map : SourceMap,
  segment : MappingSegment,
  range : OriginalRange,
) -> Bool {
  match
    (
      segment_original_source(map, segment),
      segment.original_line,
      segment.original_column,
    ) {
    (Some(source), Some(line), Some(column)) =>
      range.contains(source, line, column)
    _ => false
  }
}

///|
pub fn SourceMap::slice_original_range(
  self : SourceMap,
  range : OriginalRange,
  keep_unmapped? : Bool = false,
) -> SourceMap {
  if range.is_empty() {
    let mappings = if keep_unmapped {
      self.mappings.filter(segment => !segment.is_mapped())
    } else {
      []
    }
    return { ..self, mappings, }.prune_unused().sorted()
  }
  let mappings : Array[MappingSegment] = []
  for segment in self.mappings {
    if segment_in_original_range(self, segment, range) ||
      (keep_unmapped && !segment.is_mapped()) {
      mappings.push(segment)
    }
  }
  { ..self, mappings, }.prune_unused().sorted()
}

///|
pub fn SourceMap::sources_in_generated_range(
  self : SourceMap,
  range : GeneratedRange,
) -> Array[String] {
  let out : Array[String] = []
  for segment in self.mappings {
    if range.contains(segment.generated_line, segment.generated_column) {
      match segment_original_source(self, segment) {
        Some(source) => if !out.contains(source) { out.push(source) }
        None => ()
      }
    }
  }
  out
}

///|
pub fn SourceMap::generated_range_summary(
  self : SourceMap,
  range : GeneratedRange,
) -> String {
  let sliced = self.slice_generated_range(range, rebase=false)
  let stats = sliced.stats()
  let sources = sliced.sources.join(", ")
  "range segments=\{stats.total_segments} mapped=\{stats.mapped_segments} sources=[\{sources}]"
}
