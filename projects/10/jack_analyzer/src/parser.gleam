import gleam/list
import gleam/result
import simplifile

pub fn get_raw_string(args: List(String)) -> Result(String, Nil) {
  use path <- result.try(list.first(args))
  use file <- result.try(
    simplifile.read(path) |> result.map_error(fn(_) { Nil }),
  )

  Ok(file)
}
