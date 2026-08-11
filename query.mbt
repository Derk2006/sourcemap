///|
fn source_name_at(map : SourceMap, index : Int) -> String? {
  if index >= 0 && index < map.sources.length() {
    Some(map.sources[index])
  } else {
    None
  }
}

///|
fn name_at(map : SourceMap, index : Int?) -> String? {
  match index {
    Some(i) =>
      if i >= 0 && i < map.names.length() {
        Some(map.names[i])
      } else {
        None
      }
    None => None
  }
}

///|
fn segment_to_original(
  map : SourceMap,
  segment : MappingSegment,
) -> OriginalPosition? {
  match (segment.source_index, segment.original_line, segment.original_column) {
    (Some(source_index), Some(line), Some(column)) =>
      match source_name_at(map, source_index) {
        Some(source) =>
          Some({ source, line, column, name: name_at(map, segment.name_index) })
        None => None
      }
    _ => None
  }
}

///|
pub fn SourceMap::find_original(
  self : SourceMap,
  generated_line : Int,
  generated_column : Int,
) -> OriginalPosition? {
  let mut best : MappingSegment? = None
  for segment in self.mappings {
    if segment.generated_line == generated_line &&
      segment.generated_column <= generated_column &&
      segment.is_mapped() {
      match best {
        None => best = Some(segment)
        Some(prev) =>
          if segment.generated_column >= prev.generated_column {
            best = Some(segment)
          }
      }
    }
  }
  match best {
    Some(segment) => segment_to_original(self, segment)
    None => None
  }
}

///|
pub fn SourceMap::find_generated(
  self : SourceMap,
  source : StringView,
  original_line : Int,
  original_column : Int,
) -> GeneratedPosition? {
  let mut best : MappingSegment? = None
  let source = source.to_owned()
  for segment in self.mappings {
    match
      (segment.source_index, segment.original_line, segment.original_column) {
      (Some(source_index), Some(line), Some(column)) =>
        if source_index >= 0 &&
          source_index < self.sources.length() &&
          self.sources[source_index] == source &&
          line == original_line &&
          column <= original_column {
          match best {
            None => best = Some(segment)
            Some(prev) =>
              if column >= prev.original_column.unwrap_or(-1) {
                best = Some(segment)
              }
          }
        }
      _ => ()
    }
  }
  match best {
    Some(segment) => Some(segment.generated_position())
    None => None
  }
}

///|
pub fn SourceMap::segments_for_source(
  self : SourceMap,
  source : StringView,
) -> Array[MappingSegment] {
  let out : Array[MappingSegment] = []
  let source = source.to_owned()
  for segment in self.mappings {
    if segment.source_index is Some(index) {
      if index >= 0 &&
        index < self.sources.length() &&
        self.sources[index] == source {
        out.push(segment)
      }
    }
  }
  out
}

///|
pub fn SourceMap::generated_lines(self : SourceMap) -> Int {
  let mut max_line = -1
  for segment in self.mappings {
    if segment.generated_line > max_line {
      max_line = segment.generated_line
    }
  }
  max_line + 1
}

///|
pub fn SourceMap::explain_generated(
  self : SourceMap,
  generated_line : Int,
  generated_column : Int,
) -> String {
  match self.find_original(generated_line, generated_column) {
    Some(original) => {
      let name_part = match original.name {
        Some(name) => " name=\{name}"
        None => ""
      }
      "generated \{generated_line}:\{generated_column} -> \{original.source}:\{original.line}:\{original.column}\{name_part}"
    }
    None => "generated \{generated_line}:\{generated_column} is unmapped"
  }
}

///|
pub fn SourceMap::shift_generated(
  self : SourceMap,
  line_delta : Int,
  column_delta_for_first_line : Int,
) -> SourceMap {
  let shifted = self.mappings.map(segment => {
    let column_delta = if segment.generated_line == 0 {
      column_delta_for_first_line
    } else {
      0
    }
    {
      ..segment,
      generated_line: segment.generated_line + line_delta,
      generated_column: segment.generated_column + column_delta,
    }
  })
  { ..self, mappings: shifted }
}
