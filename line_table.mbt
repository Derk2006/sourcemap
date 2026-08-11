///|
pub struct GeneratedLineInfo {
  line : Int
  start_offset : Int
  end_offset : Int
  length : Int
  has_line_break : Bool
} derive(Eq, Debug, ToJson)

///|
fn is_line_break(ch : Char) -> Bool {
  ch == '\n' || ch == '\r'
}

///|
fn line_break_width(input : StringView, index : Int) -> Int {
  let ch = input.unsafe_get(index).unsafe_to_char()
  if ch == '\r' && index + 1 < input.length() {
    let next = input.unsafe_get(index + 1).unsafe_to_char()
    if next == '\n' {
      2
    } else {
      1
    }
  } else {
    1
  }
}

///|
pub fn line_table(input : StringView) -> Array[GeneratedLineInfo] {
  let lines : Array[GeneratedLineInfo] = []
  let mut line = 0
  let mut start_offset = 0
  let mut column = 0
  let mut index = 0
  while index < input.length() {
    let ch = input.unsafe_get(index).unsafe_to_char()
    if is_line_break(ch) {
      lines.push({
        line,
        start_offset,
        end_offset: index,
        length: column,
        has_line_break: true,
      })
      let width = line_break_width(input, index)
      index += width
      start_offset = index
      column = 0
      line += 1
    } else {
      column += 1
      index += 1
    }
  }
  lines.push({
    line,
    start_offset,
    end_offset: input.length(),
    length: column,
    has_line_break: false,
  })
  lines
}

///|
pub fn generated_line_lengths(input : StringView) -> Array[Int] {
  line_table(input).map(item => item.length)
}

///|
pub fn generated_line_count(input : StringView) -> Int {
  line_table(input).length()
}

///|
pub fn generated_offset_to_position(
  input : StringView,
  offset : Int,
) -> GeneratedPosition? {
  if offset < 0 || offset > input.length() {
    return None
  }
  for line in line_table(input) {
    if offset >= line.start_offset && offset <= line.end_offset {
      return Some({ line: line.line, column: offset - line.start_offset })
    }
  }
  None
}

///|
pub fn generated_position_to_offset(
  input : StringView,
  line : Int,
  column : Int,
) -> Int? {
  if column < 0 {
    return None
  }
  for item in line_table(input) {
    if item.line == line && column <= item.length {
      return Some(item.start_offset + column)
    }
  }
  None
}

///|
pub fn SourceMap::coverage_for_text(
  self : SourceMap,
  generated : StringView,
) -> CoverageReport {
  self.coverage_for_lengths(generated_line_lengths(generated))
}

///|
pub fn SourceMap::coverage_text_report_for_text(
  self : SourceMap,
  generated : StringView,
) -> String {
  self.coverage_for_text(generated).render()
}

///|
pub fn GeneratedLineInfo::summary(self : GeneratedLineInfo) -> String {
  let suffix = if self.has_line_break { " break" } else { "" }
  "line=\{self.line} offsets=\{self.start_offset}..\{self.end_offset} length=\{self.length}\{suffix}"
}

///|
pub fn line_table_report(input : StringView) -> String {
  let buf = StringBuilder()
  buf.write_string("Generated line table\n")
  for item in line_table(input) {
    buf.write_string(item.summary())
    buf.write_char('\n')
  }
  buf.to_string()
}
