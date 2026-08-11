///|
fn json_get(obj : Map[String, Json], key : String) -> Json? {
  obj.get(key)
}

///|
fn json_required(
  obj : Map[String, Json],
  key : String,
) -> Result[Json, SourceMapError] {
  match json_get(obj, key) {
    Some(value) => Ok(value)
    None => Err(MissingField(field=key))
  }
}

///|
fn decode_string_field(
  obj : Map[String, Json],
  key : String,
) -> Result[String?, SourceMapError] {
  match json_get(obj, key) {
    None | Some(Null) => Ok(None)
    Some(String(value)) => Ok(Some(value))
    Some(_) => Err(JsonDecode(path=key, expected="string or null"))
  }
}

///|
fn decode_int_field_required(
  obj : Map[String, Json],
  key : String,
) -> Result[Int, SourceMapError] {
  match json_required(obj, key) {
    Ok(Number(value, ..)) => Ok(value.to_int())
    Ok(_) => Err(JsonDecode(path=key, expected="integer"))
    Err(err) => Err(err)
  }
}

///|
fn decode_string_array_required(
  obj : Map[String, Json],
  key : String,
) -> Result[Array[String], SourceMapError] {
  match json_required(obj, key) {
    Ok(Array(items)) => {
      let out : Array[String] = []
      for i, item in items {
        match item {
          String(value) => out.push(value)
          _ => return Err(JsonDecode(path="\{key}[\{i}]", expected="string"))
        }
      }
      Ok(out)
    }
    Ok(_) => Err(JsonDecode(path=key, expected="array of strings"))
    Err(err) => Err(err)
  }
}

///|
fn decode_optional_string_array(
  obj : Map[String, Json],
  key : String,
) -> Result[Array[String?], SourceMapError] {
  match json_get(obj, key) {
    None => Ok([])
    Some(Array(items)) => {
      let out : Array[String?] = []
      for i, item in items {
        match item {
          Null => out.push(None)
          String(value) => out.push(Some(value))
          _ =>
            return Err(
              JsonDecode(path="\{key}[\{i}]", expected="string or null"),
            )
        }
      }
      Ok(out)
    }
    Some(_) => Err(JsonDecode(path=key, expected="array of strings or nulls"))
  }
}

///|
fn decode_int_array_optional(
  obj : Map[String, Json],
  key : String,
) -> Result[Array[Int], SourceMapError] {
  match json_get(obj, key) {
    None => Ok([])
    Some(Array(items)) => {
      let out : Array[Int] = []
      for i, item in items {
        match item {
          Number(value, ..) => out.push(value.to_int())
          _ => return Err(JsonDecode(path="\{key}[\{i}]", expected="integer"))
        }
      }
      Ok(out)
    }
    Some(_) => Err(JsonDecode(path=key, expected="array of integers"))
  }
}

///|
fn decode_mappings_required(
  obj : Map[String, Json],
) -> Result[Array[MappingSegment], SourceMapError] {
  match json_required(obj, "mappings") {
    Ok(String(raw)) => decode_mappings(raw)
    Ok(_) => Err(JsonDecode(path="mappings", expected="VLQ mappings string"))
    Err(err) => Err(err)
  }
}

///|
pub fn SourceMap::from_json(json : Json) -> Result[SourceMap, SourceMapError] {
  match json {
    Object(obj) => {
      let version = match decode_int_field_required(obj, "version") {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let sources = match decode_string_array_required(obj, "sources") {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let names = match decode_string_array_required(obj, "names") {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let mappings = match decode_mappings_required(obj) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let file = match decode_string_field(obj, "file") {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let source_root = match decode_string_field(obj, "sourceRoot") {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let sources_content = match
        decode_optional_string_array(obj, "sourcesContent") {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let ignore_list = match decode_int_array_optional(obj, "ignoreList") {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      Ok({
        version,
        file,
        source_root,
        sources,
        sources_content,
        names,
        mappings,
        ignore_list,
      })
    }
    _ => Err(JsonDecode(path="root", expected="object"))
  }
}

///|
pub fn SourceMap::from_json_string(
  text : StringView,
) -> Result[SourceMap, SourceMapError] {
  let json = @json.parse(text) catch {
    err => return Err(JsonParse(message=err.to_string()))
  }
  SourceMap::from_json(json)
}

///|
fn string_array_json(items : ArrayView[String]) -> Json {
  Json::array(items.map(item => Json::string(item)))
}

///|
fn optional_string_array_json(items : ArrayView[String?]) -> Json {
  Json::array(
    items.map(item => {
      match item {
        Some(value) => Json::string(value)
        None => null
      }
    }),
  )
}

///|
fn int_array_json(items : ArrayView[Int]) -> Json {
  Json::array(items.map(item => Json::number(item.to_double())))
}

///|
pub fn SourceMap::to_json(self : SourceMap) -> Json {
  let obj : Map[String, Json] = Map([])
  obj["version"] = Json::number(self.version.to_double())
  if self.file is Some(file) {
    obj["file"] = Json::string(file)
  }
  if self.source_root is Some(root) {
    obj["sourceRoot"] = Json::string(root)
  }
  obj["sources"] = string_array_json(self.sources)
  if self.sources_content.length() > 0 {
    obj["sourcesContent"] = optional_string_array_json(self.sources_content)
  }
  obj["names"] = string_array_json(self.names)
  obj["mappings"] = Json::string(self.encoded_mappings())
  if self.ignore_list.length() > 0 {
    obj["ignoreList"] = int_array_json(self.ignore_list)
  }
  Json::object(obj)
}

///|
pub fn SourceMap::to_json_string(self : SourceMap, indent? : Int = 0) -> String {
  self.to_json().stringify(indent~)
}
