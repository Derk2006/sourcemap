///|
pub struct NameUse {
  name : String
  name_index : Int
  generated_line : Int
  generated_column : Int
  source : String?
  original_line : Int?
  original_column : Int?
} derive(Eq, Debug, ToJson)

///|
pub fn SourceMap::name_uses(self : SourceMap) -> Array[NameUse] {
  let uses : Array[NameUse] = []
  for segment in self.mappings {
    if segment.name_index is Some(name_index) {
      if name_index >= 0 && name_index < self.names.length() {
        let source = match segment.source_index {
          Some(source_index) =>
            if source_index >= 0 && source_index < self.sources.length() {
              Some(self.sources[source_index])
            } else {
              None
            }
          None => None
        }
        uses.push({
          name: self.names[name_index],
          name_index,
          generated_line: segment.generated_line,
          generated_column: segment.generated_column,
          source,
          original_line: segment.original_line,
          original_column: segment.original_column,
        })
      }
    }
  }
  uses
}

///|
pub fn SourceMap::rename_name(
  self : SourceMap,
  old_name : StringView,
  new_name : StringView,
) -> SourceMap {
  let old_name = old_name.to_owned()
  let new_name = new_name.to_owned()
  let names = self.names.map(name => {
    if name == old_name {
      new_name
    } else {
      name
    }
  })
  { ..self, names, }
}

///|
pub fn SourceMap::filter_names(
  self : SourceMap,
  keep : (String) -> Bool,
) -> SourceMap {
  let remap : Array[Int?] = []
  let names : Array[String] = []
  for name in self.names {
    if keep(name) {
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
pub fn SourceMap::name_frequency(self : SourceMap) -> Array[(String, Int)] {
  let counts : Map[String, Int] = Map([])
  for name_use in self.name_uses() {
    counts.update_or_default(name_use.name, 1, value => value + 1)
  }
  let out = counts.to_array()
  out.sort_by((a, b) => {
    let count_cmp = b.1.compare(a.1)
    if count_cmp != 0 {
      count_cmp
    } else {
      a.0.compare(b.0)
    }
  })
  out
}

///|
pub fn SourceMap::name_report(self : SourceMap) -> String {
  let buf = StringBuilder()
  buf.write_string("SourceMap names\n")
  for pair in self.name_frequency() {
    buf.write_string("\{pair.0}: \{pair.1}\n")
  }
  buf.to_string()
}
