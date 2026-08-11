///|
pub struct PruneSummary {
  sources_before : Int
  sources_after : Int
  names_before : Int
  names_after : Int
  mappings_before : Int
  mappings_after : Int
} derive(Eq, Debug, ToJson)

///|
fn source_content_at(map : SourceMap, index : Int) -> String? {
  if index >= 0 && index < map.sources_content.length() {
    map.sources_content[index]
  } else {
    None
  }
}

///|
fn source_index_used(map : SourceMap, index : Int) -> Bool {
  for segment in map.mappings {
    if segment.source_index == Some(index) {
      return true
    }
  }
  map.ignore_list.contains(index)
}

///|
fn name_index_used(map : SourceMap, index : Int) -> Bool {
  for segment in map.mappings {
    if segment.name_index == Some(index) {
      return true
    }
  }
  false
}

///|
pub fn SourceMap::unused_sources(self : SourceMap) -> Array[String] {
  let unused : Array[String] = []
  for index, source in self.sources {
    if !source_index_used(self, index) {
      unused.push(source)
    }
  }
  unused
}

///|
pub fn SourceMap::unused_names(self : SourceMap) -> Array[String] {
  let unused : Array[String] = []
  for index, name in self.names {
    if !name_index_used(self, index) {
      unused.push(name)
    }
  }
  unused
}

///|
pub fn SourceMap::sorted(self : SourceMap) -> SourceMap {
  { ..self, mappings: sorted_mapping_copy(self.mappings) }
}

///|
pub fn SourceMap::prune_unused_sources(self : SourceMap) -> SourceMap {
  let remap : Array[Int?] = []
  let sources : Array[String] = []
  let sources_content : Array[String?] = []
  let keep_content = self.sources_content.length() > 0
  for index, source in self.sources {
    if source_index_used(self, index) {
      remap.push(Some(sources.length()))
      sources.push(source)
      if keep_content {
        sources_content.push(source_content_at(self, index))
      }
    } else {
      remap.push(None)
    }
  }
  let mappings = self.mappings.map(segment => {
    let source_index = match segment.source_index {
      Some(index) =>
        if index >= 0 && index < remap.length() {
          remap[index]
        } else {
          None
        }
      None => None
    }
    {
      ..segment,
      source_index,
      original_line: if source_index is Some(_) {
        segment.original_line
      } else {
        None
      },
      original_column: if source_index is Some(_) {
        segment.original_column
      } else {
        None
      },
    }
  })
  let ignore_list : Array[Int] = []
  for old_index in self.ignore_list {
    if old_index >= 0 && old_index < remap.length() {
      if remap[old_index] is Some(new_index) {
        if !ignore_list.contains(new_index) {
          ignore_list.push(new_index)
        }
      }
    }
  }
  { ..self, sources, sources_content, mappings, ignore_list }
}

///|
pub fn SourceMap::prune_unused_names(self : SourceMap) -> SourceMap {
  let remap : Array[Int?] = []
  let names : Array[String] = []
  for index, name in self.names {
    if name_index_used(self, index) {
      remap.push(Some(names.length()))
      names.push(name)
    } else {
      remap.push(None)
    }
  }
  let mappings = self.mappings.map(segment => {
    let name_index = match segment.name_index {
      Some(index) =>
        if index >= 0 && index < remap.length() {
          remap[index]
        } else {
          None
        }
      None => None
    }
    { ..segment, name_index, }
  })
  { ..self, names, mappings }
}

///|
pub fn SourceMap::prune_unused(self : SourceMap) -> SourceMap {
  self.prune_unused_sources().prune_unused_names()
}

///|
fn merge_content(left : String?, right : String?) -> String? {
  match left {
    Some(_) => left
    None => right
  }
}

///|
pub fn SourceMap::deduplicate_sources(self : SourceMap) -> SourceMap {
  let remap : Array[Int] = []
  let sources : Array[String] = []
  let sources_content : Array[String?] = []
  let keep_content = self.sources_content.length() > 0
  for index, source in self.sources {
    match find_string(sources, source) {
      Some(existing) => {
        remap.push(existing)
        if keep_content {
          sources_content[existing] = merge_content(
            sources_content[existing],
            source_content_at(self, index),
          )
        }
      }
      None => {
        let next = sources.length()
        remap.push(next)
        sources.push(source)
        if keep_content {
          sources_content.push(source_content_at(self, index))
        }
      }
    }
  }
  let mappings = self.mappings.map(segment => {
    let source_index = match segment.source_index {
      Some(index) =>
        if index >= 0 && index < remap.length() {
          Some(remap[index])
        } else {
          None
        }
      None => None
    }
    {
      ..segment,
      source_index,
      original_line: if source_index is Some(_) {
        segment.original_line
      } else {
        None
      },
      original_column: if source_index is Some(_) {
        segment.original_column
      } else {
        None
      },
    }
  })
  let ignore_list : Array[Int] = []
  for old_index in self.ignore_list {
    if old_index >= 0 && old_index < remap.length() {
      let new_index = remap[old_index]
      if !ignore_list.contains(new_index) {
        ignore_list.push(new_index)
      }
    }
  }
  { ..self, sources, sources_content, mappings, ignore_list }
}

///|
pub fn SourceMap::deduplicate_names(self : SourceMap) -> SourceMap {
  let remap : Array[Int] = []
  let names : Array[String] = []
  for name in self.names {
    match find_string(names, name) {
      Some(existing) => remap.push(existing)
      None => {
        let next = names.length()
        remap.push(next)
        names.push(name)
      }
    }
  }
  let mappings = self.mappings.map(segment => {
    let name_index = match segment.name_index {
      Some(index) =>
        if index >= 0 && index < remap.length() {
          Some(remap[index])
        } else {
          None
        }
      None => None
    }
    { ..segment, name_index, }
  })
  { ..self, names, mappings }
}

///|
pub fn SourceMap::canonical(self : SourceMap) -> SourceMap {
  self.deduplicate_sources().deduplicate_names().prune_unused().sorted()
}

///|
pub fn SourceMap::prune_summary(self : SourceMap) -> PruneSummary {
  let pruned = self.prune_unused()
  {
    sources_before: self.sources.length(),
    sources_after: pruned.sources.length(),
    names_before: self.names.length(),
    names_after: pruned.names.length(),
    mappings_before: self.mappings.length(),
    mappings_after: pruned.mappings.length(),
  }
}

///|
pub fn PruneSummary::summary(self : PruneSummary) -> String {
  "sources \{self.sources_before}->\{self.sources_after}, names \{self.names_before}->\{self.names_after}, mappings \{self.mappings_before}->\{self.mappings_after}"
}
