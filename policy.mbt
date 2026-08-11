///|
pub struct ValidationPolicy {
  require_file : Bool
  require_sources_content : Bool
  forbid_empty_sources : Bool
  forbid_empty_names : Bool
  allow_unmapped_segments : Bool
  allow_ignore_list : Bool
  max_segment_count : Int?
  max_source_count : Int?
} derive(Eq, Debug, ToJson)

///|
pub fn ValidationPolicy::ValidationPolicy(
  require_file? : Bool = false,
  require_sources_content? : Bool = false,
  forbid_empty_sources? : Bool = true,
  forbid_empty_names? : Bool = false,
  allow_unmapped_segments? : Bool = true,
  allow_ignore_list? : Bool = true,
  max_segment_count? : Int,
  max_source_count? : Int,
) -> ValidationPolicy {
  {
    require_file,
    require_sources_content,
    forbid_empty_sources,
    forbid_empty_names,
    allow_unmapped_segments,
    allow_ignore_list,
    max_segment_count,
    max_source_count,
  }
}

///|
pub fn ValidationPolicy::default() -> ValidationPolicy {
  {
    require_file: false,
    require_sources_content: false,
    forbid_empty_sources: true,
    forbid_empty_names: false,
    allow_unmapped_segments: true,
    allow_ignore_list: true,
    max_segment_count: None,
    max_source_count: None,
  }
}

///|
pub fn ValidationPolicy::strict() -> ValidationPolicy {
  {
    require_file: true,
    require_sources_content: true,
    forbid_empty_sources: true,
    forbid_empty_names: true,
    allow_unmapped_segments: false,
    allow_ignore_list: true,
    max_segment_count: None,
    max_source_count: None,
  }
}

///|
pub fn ValidationPolicy::with_unmapped_segments(
  self : ValidationPolicy,
  allow : Bool,
) -> ValidationPolicy {
  { ..self, allow_unmapped_segments: allow }
}

///|
pub fn ValidationPolicy::with_ignore_list(
  self : ValidationPolicy,
  allow : Bool,
) -> ValidationPolicy {
  { ..self, allow_ignore_list: allow }
}

///|
pub fn ValidationPolicy::with_limits(
  self : ValidationPolicy,
  max_segment_count? : Int,
  max_source_count? : Int,
) -> ValidationPolicy {
  { ..self, max_segment_count, max_source_count }
}

///|
pub fn SourceMap::validate_with(
  self : SourceMap,
  policy : ValidationPolicy,
) -> Array[Diagnostic] {
  let diagnostics = self.validate()
  if policy.require_file && self.file is None {
    diagnostics.push(
      diag_error("policy.file", "file", "policy requires file field"),
    )
  }
  if policy.require_sources_content {
    if self.sources_content.length() != self.sources.length() {
      diagnostics.push(
        diag_error(
          "policy.sourcesContent", "sourcesContent", "policy requires sourcesContent for every source",
        ),
      )
    } else {
      for i, content in self.sources_content {
        if content is None {
          diagnostics.push(
            diag_error(
              "policy.sourcesContent.item",
              "sourcesContent[\{i}]",
              "policy requires inline source content",
            ),
          )
        }
      }
    }
  }
  if policy.forbid_empty_sources {
    for i, source in self.sources {
      if source.length() == 0 {
        diagnostics.push(
          diag_error(
            "policy.source.empty",
            "sources[\{i}]",
            "empty source is forbidden",
          ),
        )
      }
    }
  }
  if policy.forbid_empty_names {
    for i, name in self.names {
      if name.length() == 0 {
        diagnostics.push(
          diag_error(
            "policy.name.empty",
            "names[\{i}]",
            "empty name is forbidden",
          ),
        )
      }
    }
  }
  if !policy.allow_unmapped_segments {
    for i, segment in self.mappings {
      if !segment.is_mapped() {
        diagnostics.push(
          diag_error(
            "policy.unmapped",
            "mappings[\{i}]",
            "unmapped segment is forbidden by policy",
          ),
        )
      }
    }
  }
  if !policy.allow_ignore_list && self.ignore_list.length() > 0 {
    diagnostics.push(
      diag_error(
        "policy.ignoreList", "ignoreList", "ignoreList is forbidden by policy",
      ),
    )
  }
  if policy.max_segment_count is Some(limit) {
    if self.mappings.length() > limit {
      diagnostics.push(
        diag_error(
          "policy.maxSegments",
          "mappings",
          "segment count \{self.mappings.length()} exceeds limit \{limit}",
        ),
      )
    }
  }
  if policy.max_source_count is Some(limit) {
    if self.sources.length() > limit {
      diagnostics.push(
        diag_error(
          "policy.maxSources",
          "sources",
          "source count \{self.sources.length()} exceeds limit \{limit}",
        ),
      )
    }
  }
  diagnostics
}

///|
pub fn SourceMap::passes_policy(
  self : SourceMap,
  policy : ValidationPolicy,
) -> Bool {
  !self.validate_with(policy).any(diagnostic => diagnostic.severity == "error")
}
