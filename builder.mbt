///|
/// Mutable builder for producing Source Map v3 values without manually
/// maintaining source and name indexes.
pub struct SourceMapBuilder {
  mut file : String?
  mut source_root : String?
  sources : Array[String]
  sources_content : Array[String?]
  names : Array[String]
  mappings : Array[MappingSegment]
  ignore_list : Array[Int]
} derive(Debug)

///|
pub fn SourceMapBuilder::SourceMapBuilder(
  file? : String,
  source_root? : String,
) -> SourceMapBuilder {
  {
    file,
    source_root,
    sources: [],
    sources_content: [],
    names: [],
    mappings: [],
    ignore_list: [],
  }
}

///|
pub fn SourceMapBuilder::source_count(self : SourceMapBuilder) -> Int {
  self.sources.length()
}

///|
pub fn SourceMapBuilder::name_count(self : SourceMapBuilder) -> Int {
  self.names.length()
}

///|
pub fn SourceMapBuilder::mapping_count(self : SourceMapBuilder) -> Int {
  self.mappings.length()
}

///|
pub fn SourceMapBuilder::set_file(
  self : SourceMapBuilder,
  file : StringView,
) -> Unit {
  self.file = Some(file.to_owned())
}

///|
pub fn SourceMapBuilder::clear_file(self : SourceMapBuilder) -> Unit {
  self.file = None
}

///|
pub fn SourceMapBuilder::set_source_root(
  self : SourceMapBuilder,
  source_root : StringView,
) -> Unit {
  self.source_root = Some(source_root.to_owned())
}

///|
pub fn SourceMapBuilder::clear_source_root(self : SourceMapBuilder) -> Unit {
  self.source_root = None
}

///|
fn find_string(items : ArrayView[String], needle : StringView) -> Int? {
  let needle = needle.to_owned()
  for i, item in items {
    if item == needle {
      return Some(i)
    }
  }
  None
}

///|
pub fn SourceMapBuilder::add_source(
  self : SourceMapBuilder,
  source : StringView,
) -> Int {
  match find_string(self.sources, source) {
    Some(index) => index
    None => {
      let index = self.sources.length()
      self.sources.push(source.to_owned())
      self.sources_content.push(None)
      index
    }
  }
}

///|
pub fn SourceMapBuilder::add_name(
  self : SourceMapBuilder,
  name : StringView,
) -> Int {
  match find_string(self.names, name) {
    Some(index) => index
    None => {
      let index = self.names.length()
      self.names.push(name.to_owned())
      index
    }
  }
}

///|
pub fn SourceMapBuilder::set_source_content(
  self : SourceMapBuilder,
  source : StringView,
  content : StringView,
) -> Int {
  let index = self.add_source(source)
  self.sources_content[index] = Some(content.to_owned())
  index
}

///|
pub fn SourceMapBuilder::clear_source_content(
  self : SourceMapBuilder,
  source : StringView,
) -> Bool {
  match find_string(self.sources, source) {
    Some(index) => {
      self.sources_content[index] = None
      true
    }
    None => false
  }
}

///|
pub fn SourceMapBuilder::mark_ignored(
  self : SourceMapBuilder,
  source : StringView,
) -> Int {
  let index = self.add_source(source)
  if !self.ignore_list.contains(index) {
    self.ignore_list.push(index)
  }
  index
}

///|
pub fn SourceMapBuilder::unmark_ignored(
  self : SourceMapBuilder,
  source : StringView,
) -> Bool {
  match find_string(self.sources, source) {
    Some(index) => {
      let before = self.ignore_list.length()
      self.ignore_list.retain(item => item != index)
      before != self.ignore_list.length()
    }
    None => false
  }
}

///|
pub fn SourceMapBuilder::add_unmapped(
  self : SourceMapBuilder,
  generated_line : Int,
  generated_column : Int,
) -> Unit {
  self.mappings.push(MappingSegment::unmapped(generated_line, generated_column))
}

///|
pub fn SourceMapBuilder::add_mapping(
  self : SourceMapBuilder,
  generated_line : Int,
  generated_column : Int,
  source : StringView,
  original_line : Int,
  original_column : Int,
  name? : StringView,
) -> Unit {
  let source_index = self.add_source(source)
  let name_index = match name {
    Some(value) => Some(self.add_name(value))
    None => None
  }
  match name_index {
    Some(index) =>
      self.mappings.push(
        MappingSegment::mapped(
          generated_line,
          generated_column,
          source_index,
          original_line,
          original_column,
          name_index=index,
        ),
      )
    None =>
      self.mappings.push(
        MappingSegment::mapped(
          generated_line, generated_column, source_index, original_line, original_column,
        ),
      )
  }
}

///|
pub fn SourceMapBuilder::add_line_start(
  self : SourceMapBuilder,
  generated_line : Int,
  source : StringView,
  original_line : Int,
) -> Unit {
  self.add_mapping(generated_line, 0, source, original_line, 0)
}

///|
pub fn SourceMapBuilder::append_segments(
  self : SourceMapBuilder,
  segments : ArrayView[MappingSegment],
) -> Unit {
  self.mappings.append(segments)
}

///|
pub fn SourceMapBuilder::sort_mappings(self : SourceMapBuilder) -> Unit {
  self.mappings.sort_by((a, b) => {
    let line_cmp = a.generated_line.compare(b.generated_line)
    if line_cmp != 0 {
      line_cmp
    } else {
      a.generated_column.compare(b.generated_column)
    }
  })
}

///|
pub fn SourceMapBuilder::build(self : SourceMapBuilder) -> SourceMap {
  self.sort_mappings()
  {
    version: 3,
    file: self.file,
    source_root: self.source_root,
    sources: self.sources.copy(),
    sources_content: self.sources_content.copy(),
    names: self.names.copy(),
    mappings: self.mappings.copy(),
    ignore_list: self.ignore_list.copy(),
  }
}

///|
pub fn SourceMapBuilder::reset_mappings(self : SourceMapBuilder) -> Unit {
  self.mappings.clear()
}

///|
pub fn SourceMapBuilder::reset_all(self : SourceMapBuilder) -> Unit {
  self.file = None
  self.source_root = None
  self.sources.clear()
  self.sources_content.clear()
  self.names.clear()
  self.mappings.clear()
  self.ignore_list.clear()
}

///|
pub fn SourceMap::to_builder(self : SourceMap) -> SourceMapBuilder {
  {
    file: self.file,
    source_root: self.source_root,
    sources: self.sources.copy(),
    sources_content: self.sources_content.copy(),
    names: self.names.copy(),
    mappings: self.mappings.copy(),
    ignore_list: self.ignore_list.copy(),
  }
}

///|
pub fn SourceMapBuilder::merge_from(
  self : SourceMapBuilder,
  other : SourceMap,
  generated_line_offset? : Int = 0,
  generated_column_offset? : Int = 0,
) -> Unit {
  let source_remap : Array[Int] = []
  for source in other.sources {
    source_remap.push(self.add_source(source))
  }
  let name_remap : Array[Int] = []
  for name in other.names {
    name_remap.push(self.add_name(name))
  }
  for i, content in other.sources_content {
    if i < other.sources.length() {
      match content {
        Some(text) => ignore(self.set_source_content(other.sources[i], text))
        None => ()
      }
    }
  }
  for index in other.ignore_list {
    if index >= 0 && index < other.sources.length() {
      ignore(self.mark_ignored(other.sources[index]))
    }
  }
  for segment in other.mappings {
    let remapped_source = match segment.source_index {
      Some(index) =>
        if index >= 0 && index < source_remap.length() {
          Some(source_remap[index])
        } else {
          None
        }
      None => None
    }
    let remapped_name = match segment.name_index {
      Some(index) =>
        if index >= 0 && index < name_remap.length() {
          Some(name_remap[index])
        } else {
          None
        }
      None => None
    }
    self.mappings.push({
      ..segment,
      generated_line: segment.generated_line + generated_line_offset,
      generated_column: segment.generated_column + generated_column_offset,
      source_index: remapped_source,
      name_index: remapped_name,
    })
  }
}
