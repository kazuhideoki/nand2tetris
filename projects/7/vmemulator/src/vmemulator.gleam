import argv
import code_writer
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import parser
import simplifile
import state

pub fn main() {
  use parsed <- result.try(
    argv.load().arguments
    |> parser.get_raw_string
    |> result.map(fn(raw_string) {
      raw_string
      |> parser.parse_lines
      |> list.map(parser.parse_line)
    }),
  )
  io.debug(parsed)

  let state = state.init()

  let #(assembled_lines, final_state) =
    parsed
    |> list.fold(
      #(code_writer.generate_first_lines(state), state),
      fn(acc, command_type) {
        let #(assembled, state) = acc
        case command_type {
          parser.CArithmetic(_) -> {
            let new_state = state.add(state)
            #(
              assembled
                |> list.append(code_writer.write_arithmetic(command_type)),
              new_state,
            )
          }
          parser.CPush(_, value) -> {
            let new_state = state.push(state, state.SInt(value))
            #(
              assembled |> list.append(code_writer.write_push_pop(command_type)),
              new_state,
            )
          }
          parser.CPop(_, value) -> {
            let new_state = state.push(state, state.SInt(value))
            #(
              assembled |> list.append(code_writer.write_push_pop(command_type)),
              new_state,
            )
          }
        }
      },
    )
  io.debug("⭐️")
  io.debug(assembled_lines)
  io.debug("🟠")
  io.debug(final_state)

  let raw_file =
    assembled_lines |> list.map(fn(x) { x <> "\n" }) |> string.join("")

  let _ = simplifile.write(to: "output/Output.asm", contents: raw_file)

  Ok(Nil)
}
