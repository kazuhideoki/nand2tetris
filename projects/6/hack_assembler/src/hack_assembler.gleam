import argv
import gleam/io
import gleam/list
import gleam/result
import simplifile

pub fn main() {
  let args = argv.load().arguments
  use path <- result.try(list.first(args))
  use file <- result.try(
    simplifile.read(path) |> result.map_error(fn(_) { Nil }),
  )

  io.debug(file)

  Ok(Nil)
}
