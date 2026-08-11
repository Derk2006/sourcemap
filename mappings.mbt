///|
fn is_mapping_separator(ch : Char) -> Bool {
  ch == ',' || ch == ';'
}

///|
fn decode_segment_values(
  input : StringView,
  offset : Int,
) -> Result[(Array[Int], Int), SourceMapError] {
  let values : Array[Int] = []
  let mut index = offset
  while index < input.length() {
    let ch = input.unsafe_get(index).unsafe_to_char()
    if is_mapping_separator(ch) {
      break
    }
    match decode_vlq(input, index) {
      Ok((value, next)) => {
        values.push(value)
        index = next
      }
      Err(err) => return Err(err)
    }
  }
  Ok((values, index))
}

///|
fn segment_error(
  line : Int,
  segment : Int,
  values : Int,
  reason : String,
) -> SourceMapError {
  InvalidSegment(line~, segment~, values~, reason~)
}

///|
pub fn decode_mappings(
  input : StringView,
) -> Result[Array[MappingSegment], SourceMapError] {
  let segments : Array[MappingSegment] = []
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
        return Err(
          segment_error(generated_line, segment_index, 0, "empty segment"),
        )
      }
      segment_index += 1
      index += 1
    } else {
      match decode_segment_values(input, index) {
        Ok((values, next)) => {
          if values.length() == 0 {
            return Err(
              segment_error(generated_line, segment_index, 0, "empty segment"),
            )
          }
          if values.length() == 1 {
            generated_column += values[0]
            segments.push(
              MappingSegment::unmapped(generated_line, generated_column),
            )
          } else if values.length() == 4 || values.length() == 5 {
            generated_column += values[0]
            source_index += values[1]
            original_line += values[2]
            original_column += values[3]
            if values.length() == 5 {
              name_index += values[4]
              segments.push(
                MappingSegment::mapped(
                  generated_line,
                  generated_column,
                  source_index,
                  original_line,
                  original_column,
                  name_index~,
                ),
              )
            } else {
              segments.push(
                MappingSegment::mapped(
                  generated_line, generated_column, source_index, original_line,
                  original_column,
                ),
              )
            }
          } else {
            return Err(
              segment_error(
                generated_line,
                segment_index,
                values.length(),
                "segment must contain 1, 4 or 5 VLQ fields",
              ),
            )
          }
          line_has_segment = true
          index = next
        }
        Err(err) => return Err(err)
      }
    }
  }
  Ok(segments)
}

///|
fn sorted_mapping_copy(
  segments : ArrayView[MappingSegment],
) -> Array[MappingSegment] {
  let copy = segments.to_owned()
  copy.sort_by((a, b) => {
    let by_line = a.generated_line.compare(b.generated_line)
    if by_line != 0 {
      by_line
    } else {
      a.generated_column.compare(b.generated_column)
    }
  })
  copy
}

///|
fn encode_segment_values(values : ArrayView[Int]) -> String {
  encode_vlq_values(values)
}

///|
pub fn encode_mappings(segments : ArrayView[MappingSegment]) -> String {
  let ordered = sorted_mapping_copy(segments)
  let buf = StringBuilder()
  let mut current_line = 0
  let mut previous_generated_column = 0
  let mut previous_source_index = 0
  let mut previous_original_line = 0
  let mut previous_original_column = 0
  let mut previous_name_index = 0
  let mut first_in_line = true
  for segment in ordered {
    while current_line < segment.generated_line {
      buf.write_char(';')
      current_line += 1
      previous_generated_column = 0
      first_in_line = true
    }
    if !first_in_line {
      buf.write_char(',')
    }
    let fields : Array[Int] = []
    fields.push(segment.generated_column - previous_generated_column)
    previous_generated_column = segment.generated_column
    match
      (segment.source_index, segment.original_line, segment.original_column) {
      (Some(source), Some(original_line), Some(original_column)) => {
        fields.push(source - previous_source_index)
        fields.push(original_line - previous_original_line)
        fields.push(original_column - previous_original_column)
        previous_source_index = source
        previous_original_line = original_line
        previous_original_column = original_column
        if segment.name_index is Some(name) {
          fields.push(name - previous_name_index)
          previous_name_index = name
        }
      }
      _ => ()
    }
    buf.write_string(encode_segment_values(fields))
    first_in_line = false
  }
  buf.to_string()
}

///|
pub fn SourceMap::encoded_mappings(self : SourceMap) -> String {
  encode_mappings(self.mappings)
}
