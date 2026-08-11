///|
fn main {
  let map = @sourcemap.SourceMap::SourceMap(
    ["src/math.mbt", "src/main.mbt"],
    [
      @sourcemap.MappingSegment::mapped(0, 0, 0, 0, 0, name_index=0),
      @sourcemap.MappingSegment::mapped(0, 12, 0, 1, 4),
      @sourcemap.MappingSegment::mapped(1, 0, 1, 0, 0, name_index=1),
      @sourcemap.MappingSegment::unmapped(1, 18),
    ],
    names=["add", "main"],
    file="bundle.js",
    sources_content=[
      Some("pub fn add(a, b) { a + b }"),
      Some("fn main { println(add(1, 2)) }"),
    ],
  )
  println(map.report())
  println(map.explain_generated(0, 13))
}
