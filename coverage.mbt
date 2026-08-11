///|
pub struct CoverageLine {
  line : Int
  line_length : Int
  mapped_columns : Int
  unmapped_columns : Int
  gap_count : Int
  mapped_ratio : Double
} derive(Eq, Debug, ToJson)

///|
pub struct CoverageReport {
  lines : Array[CoverageLine]
  total_columns : Int
  mapped_columns : Int
  unmapped_columns : Int
  mapped_ratio : Double
} derive(Eq, Debug, ToJson)

///|
fn ratio(part : Int, total : Int) -> Double {
  if total <= 0 {
    0.0
  } else {
    part.to_double() / total.to_double()
  }
}

///|
fn line_length_or_default(lengths : ArrayView[Int], line : Int) -> Int {
  if line >= 0 && line < lengths.length() {
    lengths[line]
  } else {
    0
  }
}

///|
pub fn SourceMap::coverage_line(
  self : SourceMap,
  line : Int,
  line_length : Int,
) -> CoverageLine {
  let spans = self.spans_for_line(line)
  let mut mapped = 0
  for span in spans {
    if span.source_index is Some(_) {
      mapped += span.width_hint(line_length)
    }
  }
  let mapped = Int::min(mapped, Int::max(line_length, 0))
  let unmapped = Int::max(0, line_length - mapped)
  let gaps = self.gaps_for_line(line, line_length)
  {
    line,
    line_length,
    mapped_columns: mapped,
    unmapped_columns: unmapped,
    gap_count: gaps.length(),
    mapped_ratio: ratio(mapped, line_length),
  }
}

///|
pub fn SourceMap::coverage_for_lengths(
  self : SourceMap,
  line_lengths : ArrayView[Int],
) -> CoverageReport {
  let max_line_count = Int::max(self.generated_lines(), line_lengths.length())
  let lines : Array[CoverageLine] = []
  let mut total = 0
  let mut mapped = 0
  for line in 0..<max_line_count {
    let length = line_length_or_default(line_lengths, line)
    let item = self.coverage_line(line, length)
    total += item.line_length
    mapped += item.mapped_columns
    lines.push(item)
  }
  let unmapped = Int::max(0, total - mapped)
  {
    lines,
    total_columns: total,
    mapped_columns: mapped,
    unmapped_columns: unmapped,
    mapped_ratio: ratio(mapped, total),
  }
}

///|
pub fn CoverageLine::summary(self : CoverageLine) -> String {
  "line=\{self.line} length=\{self.line_length} mapped=\{self.mapped_columns} unmapped=\{self.unmapped_columns} gaps=\{self.gap_count} ratio=\{self.mapped_ratio}"
}

///|
pub fn CoverageReport::summary(self : CoverageReport) -> String {
  "columns=\{self.total_columns} mapped=\{self.mapped_columns} unmapped=\{self.unmapped_columns} ratio=\{self.mapped_ratio}"
}

///|
pub fn CoverageReport::render(self : CoverageReport) -> String {
  let buf = StringBuilder()
  buf.write_string("SourceMap coverage\n")
  buf.write_string(self.summary())
  buf.write_char('\n')
  for line in self.lines {
    buf.write_string(line.summary())
    buf.write_char('\n')
  }
  buf.to_string()
}

///|
pub fn SourceMap::coverage_text_report(
  self : SourceMap,
  line_lengths : ArrayView[Int],
) -> String {
  self.coverage_for_lengths(line_lengths).render()
}
