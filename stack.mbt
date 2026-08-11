///|
pub struct StackFrame {
  function_name : String?
  file : String
  line : Int
  column : Int
} derive(Eq, Debug, ToJson)

///|
pub struct SymbolicatedFrame {
  generated : StackFrame
  original : OriginalPosition?
} derive(Eq, Debug, ToJson)

///|
fn parse_decimal(text : StringView) -> Int? {
  if text.length() == 0 {
    return None
  }
  let mut value = 0
  for ch in text {
    if ch < '0' || ch > '9' {
      return None
    }
    value = value * 10 + (ch.to_int() - '0'.to_int())
  }
  Some(value)
}

///|
fn strip_wrapping_parens(text : StringView) -> StringView {
  let trimmed = text.trim()
  if trimmed.has_prefix("(") && trimmed.has_suffix(")") && trimmed.length() >= 2 {
    trimmed[1:trimmed.length() - 1]
  } else if trimmed.has_suffix(")") && trimmed.length() >= 1 {
    trimmed[:trimmed.length() - 1]
  } else {
    trimmed
  }
}

///|
fn parse_location(text : StringView) -> StackFrame? {
  let location = strip_wrapping_parens(text)
  match location.rev_split_once(":") {
    Some((file_and_line, column_text)) =>
      match file_and_line.rev_split_once(":") {
        Some((file, line_text)) =>
          match (parse_decimal(line_text), parse_decimal(column_text)) {
            (Some(line), Some(column)) =>
              Some({ function_name: None, file: file.to_owned(), line, column })
            _ => None
          }
        None => None
      }
    None => None
  }
}

///|
pub fn parse_stack_frame(line : StringView) -> StackFrame? {
  let trimmed = line.trim()
  let frame_text = match trimmed.strip_prefix("at ") {
    Some(rest) => rest.trim()
    None => trimmed
  }
  match frame_text.split_once(" (") {
    Some((name, loc)) =>
      match parse_location(loc) {
        Some(frame) =>
          Some({ ..frame, function_name: Some(name.trim().to_owned()) })
        None => None
      }
    None => parse_location(frame_text)
  }
}

///|
pub fn parse_stack(text : StringView) -> Array[StackFrame] {
  let frames : Array[StackFrame] = []
  for line in text.split("\n") {
    match parse_stack_frame(line) {
      Some(frame) => frames.push(frame)
      None => ()
    }
  }
  frames
}

///|
pub fn SourceMap::symbolicate_frame(
  self : SourceMap,
  frame : StackFrame,
) -> SymbolicatedFrame {
  { generated: frame, original: self.find_original(frame.line, frame.column) }
}

///|
pub fn SourceMap::symbolicate_stack(
  self : SourceMap,
  stack : StringView,
) -> Array[SymbolicatedFrame] {
  parse_stack(stack).map(frame => self.symbolicate_frame(frame))
}

///|
pub fn StackFrame::render(self : StackFrame) -> String {
  match self.function_name {
    Some(name) => "at \{name} (\{self.file}:\{self.line}:\{self.column})"
    None => "at \{self.file}:\{self.line}:\{self.column}"
  }
}

///|
pub fn SymbolicatedFrame::render(self : SymbolicatedFrame) -> String {
  match self.original {
    Some(original) => {
      let name = match original.name {
        Some(value) => value
        None =>
          match self.generated.function_name {
            Some(value) => value
            None => "<anonymous>"
          }
      }
      "at \{name} (\{original.source}:\{original.line}:\{original.column}) <- \{self.generated.file}:\{self.generated.line}:\{self.generated.column}"
    }
    None => self.generated.render()
  }
}

///|
pub fn render_symbolicated_stack(
  frames : ArrayView[SymbolicatedFrame],
) -> String {
  frames.map(frame => frame.render()).join("\n")
}

///|
pub fn SourceMap::symbolicate_stack_report(
  self : SourceMap,
  stack : StringView,
) -> String {
  render_symbolicated_stack(self.symbolicate_stack(stack))
}
