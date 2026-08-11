///|
pub fn SourceMap::stats(self : SourceMap) -> MappingStats {
  let mut mapped = 0
  let mut unmapped = 0
  let mut named = 0
  for segment in self.mappings {
    if segment.is_mapped() {
      mapped += 1
    } else {
      unmapped += 1
    }
    if segment.has_name() {
      named += 1
    }
  }
  {
    generated_lines: self.generated_lines(),
    total_segments: self.mappings.length(),
    mapped_segments: mapped,
    unmapped_segments: unmapped,
    named_segments: named,
    source_count: self.sources.length(),
    name_count: self.names.length(),
    ignored_source_count: self.ignore_list.length(),
  }
}

///|
pub fn MappingStats::summary(self : MappingStats) -> String {
  "lines=\{self.generated_lines} segments=\{self.total_segments} mapped=\{self.mapped_segments} unmapped=\{self.unmapped_segments} names=\{self.named_segments} sources=\{self.source_count}"
}

///|
pub fn SourceMap::source_summaries(self : SourceMap) -> Array[SourceSummary] {
  let summaries : Array[SourceSummary] = []
  for index, source in self.sources {
    let mut mapped = 0
    let mut named = 0
    let mut first_line : Int? = None
    let mut last_line : Int? = None
    for segment in self.mappings {
      match (segment.source_index, segment.original_line) {
        (Some(source_index), Some(line)) =>
          if source_index == index {
            mapped += 1
            if segment.has_name() {
              named += 1
            }
            match first_line {
              None => first_line = Some(line)
              Some(prev) => if line < prev { first_line = Some(line) }
            }
            match last_line {
              None => last_line = Some(line)
              Some(prev) => if line > prev { last_line = Some(line) }
            }
          }
        _ => ()
      }
    }
    summaries.push({
      source,
      index,
      mapped_segments: mapped,
      named_segments: named,
      first_original_line: first_line,
      last_original_line: last_line,
      ignored: self.ignore_list.contains(index),
    })
  }
  summaries
}

///|
pub fn SourceMap::report(self : SourceMap) -> String {
  let buf = StringBuilder()
  let stats = self.stats()
  buf.write_string("SourceMap report\n")
  buf.write_string(stats.summary())
  buf.write_char('\n')
  let diagnostics = self.validate()
  let error_count = diagnostics.count_if(d => d.severity == "error")
  let warning_count = diagnostics.count_if(d => d.severity == "warning")
  buf.write_string(
    "diagnostics errors=\{error_count} warnings=\{warning_count}\n",
  )
  for item in self.source_summaries() {
    let ignored = if item.ignored { " ignored" } else { "" }
    let first = match item.first_original_line {
      Some(line) => line.to_string()
      None => "-"
    }
    let last = match item.last_original_line {
      Some(line) => line.to_string()
      None => "-"
    }
    buf.write_string(
      "source[\{item.index}] \{item.source}: mapped=\{item.mapped_segments} names=\{item.named_segments} lines=\{first}..\{last}\{ignored}\n",
    )
  }
  if diagnostics.length() > 0 {
    buf.write_string("diagnostics:\n")
    for diagnostic in diagnostics {
      buf.write_string(
        "- [\{diagnostic.severity}] \{diagnostic.code} \{diagnostic.path}: \{diagnostic.message}\n",
      )
    }
  }
  buf.to_string()
}
