import gleam/io
import simplifile

pub fn main() {
  let file = simplifile.read("../add/Add.asm")
  case file {
    Ok(file) -> {
      io.debug(file)
      Nil
    }
    Error(err) -> {
      io.debug(err)
      Nil
    }
  }
  io.println("Hello from hack_assembler!")
}
