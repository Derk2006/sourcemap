///|
pub fn SourceMap::with_file(self : SourceMap, file : StringView) -> SourceMap {
  { ..self, file: Some(file.to_owned()) }
}

///|
pub fn SourceMap::without_file(self : SourceMap) -> SourceMap {
  { ..self, file: None }
}

///|
pub fn SourceMap::with_source_root(
  self : SourceMap,
  source_root : StringView,
) -> SourceMap {
  { ..self, source_root: Some(source_root.to_owned()) }
}

///|
pub fn SourceMap::without_source_root(self : SourceMap) -> SourceMap {
  { ..self, source_root: None }
}

///|
pub fn SourceMap::without_names(self : SourceMap) -> SourceMap {
  let stripped = self.mappings.map(segment => { ..segment, name_index: None })
  { ..self, names: [], mappings: stripped }
}

///|
pub fn SourceMap::without_sources_content(self : SourceMap) -> SourceMap {
  { ..self, sources_content: [] }
}

///|
pub fn SourceMap::with_sources_content(
  self : SourceMap,
  contents : ArrayView[String?],
) -> SourceMap {
  { ..self, sources_content: contents.to_owned() }
}

///|
pub fn SourceMap::rename_source(
  self : SourceMap,
  old_source : StringView,
  new_source : StringView,
) -> SourceMap {
  let old_source = old_source.to_owned()
  let new_source = new_source.to_owned()
  let sources = self.sources.map(source => {
    if source == old_source {
      new_source
    } else {
      source
    }
  })
  { ..self, sources, }
}

///|
pub fn SourceMap::prefix_sources(
  self : SourceMap,
  prefix : StringView,
) -> SourceMap {
  let prefix = prefix.to_owned()
  { ..self, sources: self.sources.map(source => prefix + source) }
}

///|
pub fn SourceMap::replace_source_prefix(
  self : SourceMap,
  old_prefix : StringView,
  new_prefix : StringView,
) -> SourceMap {
  let sources = self.sources.map(source => {
    match source.strip_prefix(old_prefix) {
      Some(rest) => new_prefix.to_owned() + rest.to_owned()
      None => source
    }
  })
  { ..self, sources, }
}

///|
pub fn SourceMap::normalize_source_slashes(self : SourceMap) -> SourceMap {
  {
    ..self,
    sources: self.sources.map(source => source.replace_all(old="\\", new="/")),
  }
}

///|
pub fn SourceMap::filter_sources(
  self : SourceMap,
  keep : (String) -> Bool,
) -> SourceMap {
  let remap : Array[Int?] = []
  let sources : Array[String] = []
  let sources_content : Array[String?] = []
  for i, source in self.sources {
    if keep(source) {
      remap.push(Some(sources.length()))
      sources.push(source)
      if i < self.sources_content.length() {
        sources_content.push(self.sources_content[i])
      }
    } else {
      remap.push(None)
    }
  }
  let mappings : Array[MappingSegment] = []
  for segment in self.mappings {
    match segment.source_index {
      Some(index) =>
        if index >= 0 && index < remap.length() {
          match remap[index] {
            Some(new_index) =>
              mappings.push({ ..segment, source_index: Some(new_index) })
            None => ()
          }
        }
      None => mappings.push(segment)
    }
  }
  let ignore_list : Array[Int] = []
  for index in self.ignore_list {
    if index >= 0 && index < remap.length() {
      if remap[index] is Some(new_index) {
        ignore_list.push(new_index)
      }
    }
  }
  { ..self, sources, sources_content, mappings, ignore_list }
}

///|
pub fn SourceMap::slice_generated_lines(
  self : SourceMap,
  start_line : Int,
  end_line : Int,
) -> SourceMap {
  let mappings = self.mappings.filter(segment => {
    segment.generated_line >= start_line && segment.generated_line < end_line
  })
  let shifted = mappings.map(segment => {
    ..segment,
    generated_line: segment.generated_line - start_line,
  })
  { ..self, mappings: shifted }
}

///|
pub fn SourceMap::drop_unmapped(self : SourceMap) -> SourceMap {
  { ..self, mappings: self.mappings.filter(segment => segment.is_mapped()) }
}

///|
pub fn SourceMap::compact(self : SourceMap) -> SourceMap {
  self.drop_unmapped().without_names().without_sources_content()
}

///|
pub fn SourceMap::map_generated_columns(
  self : SourceMap,
  f : (Int, Int) -> Int,
) -> SourceMap {
  let mappings = self.mappings.map(segment => {
    ..segment,
    generated_column: f(segment.generated_line, segment.generated_column),
  })
  { ..self, mappings, }
}

///|
pub fn SourceMap::map_original_lines(
  self : SourceMap,
  f : (String, Int) -> Int,
) -> SourceMap {
  let mappings = self.mappings.map(segment => {
    let next_line = match (segment.source_index, segment.original_line) {
      (Some(index), Some(line)) =>
        if index >= 0 && index < self.sources.length() {
          Some(f(self.sources[index], line))
        } else {
          Some(line)
        }
      _ => segment.original_line
    }
    { ..segment, original_line: next_line }
  })
  { ..self, mappings, }
}
