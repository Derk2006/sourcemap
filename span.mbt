///|
/// A generated-code span derived from adjacent mapping segments on the same
/// generated line. `end_column=None` means the span extends to the end of line.
pub struct GeneratedSpan {
  line : Int
  start_column : Int
  end_column : Int?
  source_index : Int?
  original_line : Int?
  original_column : Int?
  name_index : Int?
} derive(Eq, Debug, ToJson)

///|
pub struct GeneratedGap {
  line : Int
  start_column : Int
  end_column : Int?
} derive(Eq, Debug, ToJson)

///|
pub struct LineSummary {
  line : Int
  segment_count : Int
  mapped_segment_count : Int
  unmapped_segment_count : Int
  first_column : Int?
  last_column : Int?
} derive(Eq, Debug, ToJson)

///|
fn span_from_segment(
  segment : MappingSegment,
  end_column : Int?,
) -> GeneratedSpan {
  {
    line: segment.generated_line,
    start_column: segment.generated_column,
    end_column,
    source_index: segment.source_index,
    original_line: segment.original_line,
    original_column: segment.original_column,
    name_index: segment.name_index,
  }
}

///|
pub fn SourceMap::spans(self : SourceMap) -> Array[GeneratedSpan] {
  let ordered = sorted_mapping_copy(self.mappings)
  let spans : Array[GeneratedSpan] = []
  for i, segment in ordered {
    let end_column = if i + 1 < ordered.length() &&
      ordered[i + 1].generated_line == segment.generated_line {
      Some(ordered[i + 1].generated_column)
    } else {
      None
    }
    spans.push(span_from_segment(segment, end_column))
  }
  spans
}

///|
pub fn SourceMap::spans_for_line(
  self : SourceMap,
  line : Int,
) -> Array[GeneratedSpan] {
  self.spans().filter(span => span.line == line)
}

///|
pub fn SourceMap::gaps_for_line(
  self : SourceMap,
  line : Int,
  line_length : Int,
) -> Array[GeneratedGap] {
  let gaps : Array[GeneratedGap] = []
  let spans = self.spans_for_line(line)
  let mut cursor = 0
  for span in spans {
    if span.start_column > cursor {
      gaps.push({
        line,
        start_column: cursor,
        end_column: Some(span.start_column),
      })
    }
    cursor = match span.end_column {
      Some(end_column) => Int::max(cursor, end_column)
      None => line_length
    }
  }
  if cursor < line_length {
    gaps.push({ line, start_column: cursor, end_column: Some(line_length) })
  }
  gaps
}

///|
pub fn SourceMap::line_summaries(self : SourceMap) -> Array[LineSummary] {
  let summaries : Array[LineSummary] = []
  let line_count = self.generated_lines()
  for line in 0..<line_count {
    let segments = self.mappings.filter(segment => {
      segment.generated_line == line
    })
    let mapped = segments.count_if(segment => segment.is_mapped())
    let unmapped = segments.length() - mapped
    let mut first : Int? = None
    let mut last : Int? = None
    for segment in segments {
      match first {
        None => first = Some(segment.generated_column)
        Some(value) =>
          if segment.generated_column < value {
            first = Some(segment.generated_column)
          }
      }
      match last {
        None => last = Some(segment.generated_column)
        Some(value) =>
          if segment.generated_column > value {
            last = Some(segment.generated_column)
          }
      }
    }
    summaries.push({
      line,
      segment_count: segments.length(),
      mapped_segment_count: mapped,
      unmapped_segment_count: unmapped,
      first_column: first,
      last_column: last,
    })
  }
  summaries
}

///|
pub fn SourceMap::unmapped_spans(self : SourceMap) -> Array[GeneratedSpan] {
  self.spans().filter(span => span.source_index is None)
}

///|
pub fn SourceMap::mapped_spans(self : SourceMap) -> Array[GeneratedSpan] {
  self.spans().filter(span => span.source_index is Some(_))
}

///|
pub fn GeneratedSpan::contains(
  self : GeneratedSpan,
  line : Int,
  column : Int,
) -> Bool {
  if self.line != line || column < self.start_column {
    return false
  }
  match self.end_column {
    Some(end_column) => column < end_column
    None => true
  }
}

///|
pub fn SourceMap::span_at(
  self : SourceMap,
  line : Int,
  column : Int,
) -> GeneratedSpan? {
  for span in self.spans() {
    if span.contains(line, column) {
      return Some(span)
    }
  }
  None
}

///|
pub fn GeneratedSpan::width_hint(
  self : GeneratedSpan,
  fallback_end : Int,
) -> Int {
  let end_column = match self.end_column {
    Some(value) => value
    None => fallback_end
  }
  Int::max(0, end_column - self.start_column)
}
