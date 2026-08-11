///|
fn diag_error(code : String, path : String, message : String) -> Diagnostic {
  { severity: "error", code, path, message }
}

///|
fn diag_warning(code : String, path : String, message : String) -> Diagnostic {
  { severity: "warning", code, path, message }
}

///|
fn is_ignored(map : SourceMap, index : Int) -> Bool {
  map.ignore_list.contains(index)
}

///|
pub fn SourceMap::validate(self : SourceMap) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  if self.version != 3 {
    diagnostics.push(
      diag_error(
        "version",
        "version",
        "Source Map v3 requires version=3, found \{self.version}",
      ),
    )
  }
  if self.sources.is_empty() &&
    self.mappings.any(segment => segment.is_mapped()) {
    diagnostics.push(
      diag_error(
        "sources.empty", "sources", "mapped segments require at least one source",
      ),
    )
  }
  if self.sources_content.length() > 0 &&
    self.sources_content.length() != self.sources.length() {
    diagnostics.push(
      diag_warning(
        "sourcesContent.length", "sourcesContent", "sourcesContent should be absent or have the same length as sources",
      ),
    )
  }
  for i, source in self.sources {
    if source.length() == 0 {
      diagnostics.push(
        diag_warning("source.empty", "sources[\{i}]", "source path is empty"),
      )
    }
  }
  for i, name in self.names {
    if name.length() == 0 {
      diagnostics.push(
        diag_warning("name.empty", "names[\{i}]", "name entry is empty"),
      )
    }
  }
  for i, ignored in self.ignore_list {
    if ignored < 0 || ignored >= self.sources.length() {
      diagnostics.push(
        diag_error(
          "ignoreList.index",
          "ignoreList[\{i}]",
          "ignoreList index \{ignored} is outside sources range",
        ),
      )
    }
  }
  let mut previous_line = -1
  let mut previous_column = -1
  for i, segment in self.mappings {
    let path = "mappings[\{i}]"
    if segment.generated_line < 0 {
      diagnostics.push(
        diag_error("generated.line", path, "generated line is negative"),
      )
    }
    if segment.generated_column < 0 {
      diagnostics.push(
        diag_error("generated.column", path, "generated column is negative"),
      )
    }
    if segment.generated_line < previous_line {
      diagnostics.push(
        diag_error("mapping.order", path, "mapping lines must be nondecreasing"),
      )
    } else if segment.generated_line == previous_line &&
      segment.generated_column < previous_column {
      diagnostics.push(
        diag_error(
          "mapping.order", path, "mapping columns must be nondecreasing within a generated line",
        ),
      )
    }
    previous_line = segment.generated_line
    previous_column = segment.generated_column
    match
      (segment.source_index, segment.original_line, segment.original_column) {
      (None, None, None) => ()
      (Some(source), Some(line), Some(column)) => {
        if source < 0 || source >= self.sources.length() {
          diagnostics.push(
            diag_error(
              "source.index",
              path,
              "source index \{source} is outside sources range",
            ),
          )
        }
        if line < 0 {
          diagnostics.push(
            diag_error("original.line", path, "original line is negative"),
          )
        }
        if column < 0 {
          diagnostics.push(
            diag_error("original.column", path, "original column is negative"),
          )
        }
      }
      _ =>
        diagnostics.push(
          diag_error(
            "segment.partial", path, "mapped segments must carry source, original line and original column together",
          ),
        )
    }
    if segment.name_index is Some(name_index) {
      if name_index < 0 || name_index >= self.names.length() {
        diagnostics.push(
          diag_error(
            "name.index",
            path,
            "name index \{name_index} is outside names range",
          ),
        )
      }
    }
  }
  diagnostics
}

///|
pub fn SourceMap::is_valid(self : SourceMap) -> Bool {
  !self.validate().any(d => d.severity == "error")
}

///|
pub fn SourceMap::warnings(self : SourceMap) -> Array[Diagnostic] {
  self.validate().filter(d => d.severity == "warning")
}

///|
pub fn SourceMap::errors(self : SourceMap) -> Array[Diagnostic] {
  self.validate().filter(d => d.severity == "error")
}

///|
pub fn SourceMap::is_source_ignored(
  self : SourceMap,
  source : StringView,
) -> Bool {
  let source = source.to_owned()
  for i, item in self.sources {
    if item == source {
      return is_ignored(self, i)
    }
  }
  false
}
