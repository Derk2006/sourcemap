///|
pub struct SourceMapDiff {
  same_version : Bool
  same_file : Bool
  added_sources : Array[String]
  removed_sources : Array[String]
  added_names : Array[String]
  removed_names : Array[String]
  mapping_count_before : Int
  mapping_count_after : Int
  changed_mapping_count : Int
} derive(Eq, Debug, ToJson)

///|
fn string_set_difference(
  left : ArrayView[String],
  right : ArrayView[String],
) -> Array[String] {
  let out : Array[String] = []
  for item in left {
    if !right.contains(item) {
      out.push(item)
    }
  }
  out
}

///|
fn count_mapping_changes(
  before : ArrayView[MappingSegment],
  after : ArrayView[MappingSegment],
) -> Int {
  let limit = Int::min(before.length(), after.length())
  let mut changed = 0
  for i in 0..<limit {
    if before[i] != after[i] {
      changed += 1
    }
  }
  changed + Int::abs(before.length() - after.length())
}

///|
pub fn SourceMap::diff(self : SourceMap, other : SourceMap) -> SourceMapDiff {
  {
    same_version: self.version == other.version,
    same_file: self.file == other.file,
    added_sources: string_set_difference(other.sources, self.sources),
    removed_sources: string_set_difference(self.sources, other.sources),
    added_names: string_set_difference(other.names, self.names),
    removed_names: string_set_difference(self.names, other.names),
    mapping_count_before: self.mappings.length(),
    mapping_count_after: other.mappings.length(),
    changed_mapping_count: count_mapping_changes(self.mappings, other.mappings),
  }
}

///|
pub fn SourceMapDiff::has_changes(self : SourceMapDiff) -> Bool {
  !self.same_version ||
  !self.same_file ||
  self.added_sources.length() > 0 ||
  self.removed_sources.length() > 0 ||
  self.added_names.length() > 0 ||
  self.removed_names.length() > 0 ||
  self.changed_mapping_count > 0
}

///|
pub fn SourceMapDiff::summary(self : SourceMapDiff) -> String {
  let buf = StringBuilder()
  buf.write_string("SourceMap diff\n")
  buf.write_string(
    "same_version=\{self.same_version} same_file=\{self.same_file}\n",
  )
  buf.write_string(
    "sources added=\{self.added_sources.length()} removed=\{self.removed_sources.length()}\n",
  )
  buf.write_string(
    "names added=\{self.added_names.length()} removed=\{self.removed_names.length()}\n",
  )
  buf.write_string(
    "mappings before=\{self.mapping_count_before} after=\{self.mapping_count_after} changed=\{self.changed_mapping_count}\n",
  )
  if self.added_sources.length() > 0 {
    buf.write_string("added sources: \{self.added_sources.join(", ")}\n")
  }
  if self.removed_sources.length() > 0 {
    buf.write_string("removed sources: \{self.removed_sources.join(", ")}\n")
  }
  if self.added_names.length() > 0 {
    buf.write_string("added names: \{self.added_names.join(", ")}\n")
  }
  if self.removed_names.length() > 0 {
    buf.write_string("removed names: \{self.removed_names.join(", ")}\n")
  }
  buf.to_string()
}
