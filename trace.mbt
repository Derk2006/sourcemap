///|
pub struct VlqTraceStep {
  offset : Int
  char : String
  digit : Int
  payload : Int
  continuation : Bool
  shift : Int
  partial : Int
} derive(Eq, Debug, ToJson)

///|
pub struct SegmentTrace {
  line : Int
  segment : Int
  start_offset : Int
  end_offset : Int
  raw : String
  values : Array[Int]
  decoded : MappingSegment?
  error : String?
} derive(Eq, Debug, ToJson)

///|
pub fn trace_vlq(
  input : StringView,
  offset : Int,
) -> Result[Array[VlqTraceStep], SourceMapError] {
  let steps : Array[VlqTraceStep] = []
  let mut result = 0
  let mut shift = 0
  let mut index = offset
  for ;; {
    if index >= input.length() {
      return Err(TruncatedVlq(offset~))
    }
    let ch = input.unsafe_get(index).unsafe_to_char()
    let digit = match base64_value(ch) {
      Some(value) => value
      None => return Err(InvalidBase64(char=ch, offset=index))
    }
    let continuation = (digit & vlq_continuation_bit) != 0
    let payload = digit & vlq_base_mask
    if shift >= 30 && payload > 1 {
      return Err(VlqOverflow(offset=index))
    }
    result = result | (payload << shift)
    steps.push({
      offset: index,
      char: ch.to_string(),
      digit,
      payload,
      continuation,
      shift,
      partial: result,
    })
    index += 1
    shift += vlq_base_shift
    if !continuation {
      break
    }
  }
  Ok(steps)
}

///|
fn segment_raw(input : StringView, start : Int, end : Int) -> String {
  input[start:end].to_owned()
}

///|
pub fn trace_mappings(input : StringView) -> Array[SegmentTrace] {
  let traces : Array[SegmentTrace] = []
  let mut generated_line = 0
  let mut generated_column = 0
  let mut source_index = 0
  let mut original_line = 0
  let mut original_column = 0
  let mut name_index = 0
  let mut index = 0
  let mut segment_index = 0
  let mut line_has_segment = false
  while index < input.length() {
    let ch = input.unsafe_get(index).unsafe_to_char()
    if ch == ';' {
      generated_line += 1
      generated_column = 0
      segment_index = 0
      line_has_segment = false
      index += 1
    } else if ch == ',' {
      if !line_has_segment {
        traces.push({
          line: generated_line,
          segment: segment_index,
          start_offset: index,
          end_offset: index + 1,
          raw: ",",
          values: [],
          decoded: None,
          error: Some("empty segment"),
        })
      }
      segment_index += 1
      index += 1
    } else {
      let start = index
      match decode_segment_values(input, index) {
        Ok((values, next)) => {
          let raw = segment_raw(input, start, next)
          if values.length() == 1 {
            generated_column += values[0]
            let decoded = MappingSegment::unmapped(
              generated_line, generated_column,
            )
            traces.push({
              line: generated_line,
              segment: segment_index,
              start_offset: start,
              end_offset: next,
              raw,
              values,
              decoded: Some(decoded),
              error: None,
            })
          } else if values.length() == 4 || values.length() == 5 {
            generated_column += values[0]
            source_index += values[1]
            original_line += values[2]
            original_column += values[3]
            let decoded = if values.length() == 5 {
              name_index += values[4]
              MappingSegment::mapped(
                generated_line,
                generated_column,
                source_index,
                original_line,
                original_column,
                name_index~,
              )
            } else {
              MappingSegment::mapped(
                generated_line, generated_column, source_index, original_line, original_column,
              )
            }
            traces.push({
              line: generated_line,
              segment: segment_index,
              start_offset: start,
              end_offset: next,
              raw,
              values,
              decoded: Some(decoded),
              error: None,
            })
          } else {
            traces.push({
              line: generated_line,
              segment: segment_index,
              start_offset: start,
              end_offset: next,
              raw,
              values,
              decoded: None,
              error: Some("segment must contain 1, 4 or 5 VLQ fields"),
            })
          }
          line_has_segment = true
          index = next
        }
        Err(err) => {
          traces.push({
            line: generated_line,
            segment: segment_index,
            start_offset: start,
            end_offset: input.length(),
            raw: input[start:].to_owned(),
            values: [],
            decoded: None,
            error: Some(err.message()),
          })
          break
        }
      }
    }
  }
  traces
}

///|
pub fn SegmentTrace::summary(self : SegmentTrace) -> String {
  let values = self.values.map(value => value.to_string()).join(",")
  match self.error {
    Some(error) =>
      "line=\{self.line} segment=\{self.segment} raw=\{self.raw} values=[\{values}] error=\{error}"
    None =>
      "line=\{self.line} segment=\{self.segment} raw=\{self.raw} values=[\{values}] ok"
  }
}

///|
pub fn trace_mappings_report(input : StringView) -> String {
  let buf = StringBuilder()
  for trace in trace_mappings(input) {
    buf.write_string(trace.summary())
    buf.write_char('\n')
  }
  buf.to_string()
}
