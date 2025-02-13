import gleam/result
import simplifile

pub fn get_raw_string(path: String) -> Result(String, Nil) {
  simplifile.read(path)
  |> result.map_error(fn(_) { Nil })
}
