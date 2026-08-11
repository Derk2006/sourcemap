///|
pub struct LineIndexEntry {
  line : Int
  start : Int
  end : Int
} derive(Eq, Debug, ToJson)

///|
pub struct MappingIndex {
  segments : Array[MappingSegment]
  lines : Array[LineIndexEntry]
} derive(Eq, Debug, ToJson)

///|
pub fn SourceMap::index(self : SourceMap) -> MappingIndex {
  let ordered = sorted_mapping_copy(self.mappings)
  let lines : Array[LineIndexEntry] = []
  let mut current_line = -1
  let mut start = 0
  for i, segment in ordered {
    if segment.generated_line != current_line {
      if current_line >= 0 {
        lines.push({ line: current_line, start, end: i })
      }
      current_line = segment.generated_line
      start = i
    }
  }
  if current_line >= 0 {
    lines.push({ line: current_line, start, end: ordered.length() })
  }
  { segments: ordered, lines }
}

///|
pub fn MappingIndex::line_count(self : MappingIndex) -> Int {
  self.lines.length()
}

///|
pub fn MappingIndex::segment_count(self : MappingIndex) -> Int {
  self.segments.length()
}

///|
pub fn MappingIndex::entry_for_line(
  self : MappingIndex,
  line : Int,
) -> LineIndexEntry? {
  for entry in self.lines {
    if entry.line == line {
      return Some(entry)
    }
  }
  None
}

///|
pub fn MappingIndex::segments_for_line(
  self : MappingIndex,
  line : Int,
) -> Array[MappingSegment] {
  match self.entry_for_line(line) {
    Some(entry) => self.segments[entry.start:entry.end].to_owned()
    None => []
  }
}

///|
pub fn MappingIndex::first_segment_for_line(
  self : MappingIndex,
  line : Int,
) -> MappingSegment? {
  match self.entry_for_line(line) {
    Some(entry) =>
      if entry.start < entry.end {
        Some(self.segments[entry.start])
      } else {
        None
      }
    None => None
  }
}

///|
pub fn MappingIndex::last_segment_for_line(
  self : MappingIndex,
  line : Int,
) -> MappingSegment? {
  match self.entry_for_line(line) {
    Some(entry) =>
      if entry.start < entry.end {
        Some(self.segments[entry.end - 1])
      } else {
        None
      }
    None => None
  }
}

///|
pub fn MappingIndex::find_generated_floor(
  self : MappingIndex,
  line : Int,
  column : Int,
) -> MappingSegment? {
  match self.entry_for_line(line) {
    Some(entry) => {
      let mut best : MappingSegment? = None
      for i in entry.start..<entry.end {
        let segment = self.segments[i]
        if segment.generated_column <= column {
          best = Some(segment)
        } else {
          break
        }
      }
      best
    }
    None => None
  }
}

///|
pub fn MappingIndex::find_generated_exact(
  self : MappingIndex,
  line : Int,
  column : Int,
) -> MappingSegment? {
  match self.entry_for_line(line) {
    Some(entry) => {
      for i in entry.start..<entry.end {
        let segment = self.segments[i]
        if segment.generated_column == column {
          return Some(segment)
        }
        if segment.generated_column > column {
          return None
        }
      }
      None
    }
    None => None
  }
}

///|
pub fn MappingIndex::line_has_mappings(self : MappingIndex, line : Int) -> Bool {
  self.entry_for_line(line) is Some(_)
}

///|
pub fn MappingIndex::mapped_segments(
  self : MappingIndex,
) -> Array[MappingSegment] {
  self.segments.filter(segment => segment.is_mapped())
}

///|
pub fn MappingIndex::unmapped_segments(
  self : MappingIndex,
) -> Array[MappingSegment] {
  self.segments.filter(segment => !segment.is_mapped())
}

///|
pub fn MappingIndex::named_segments(
  self : MappingIndex,
) -> Array[MappingSegment] {
  self.segments.filter(segment => segment.has_name())
}

///|
pub fn MappingIndex::generated_line_numbers(self : MappingIndex) -> Array[Int] {
  self.lines.map(entry => entry.line)
}

///|
pub fn MappingIndex::line_summary(
  self : MappingIndex,
  line : Int,
) -> LineSummary {
  let segments = self.segments_for_line(line)
  let mapped = segments.count_if(segment => segment.is_mapped())
  let unmapped = segments.length() - mapped
  let first = match segments.get(0) {
    Some(segment) => Some(segment.generated_column)
    None => None
  }
  let last = match segments.last() {
    Some(segment) => Some(segment.generated_column)
    None => None
  }
  {
    line,
    segment_count: segments.length(),
    mapped_segment_count: mapped,
    unmapped_segment_count: unmapped,
    first_column: first,
    last_column: last,
  }
}

///|
pub fn MappingIndex::summaries(self : MappingIndex) -> Array[LineSummary] {
  self.lines.map(entry => self.line_summary(entry.line))
}
