import argv
import code_writer
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import parser
import segment_store
import simplifile

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

  let segment_store = segment_store.init()

  let #(assembled_lines, final_segment, _) =
    parsed
    |> list.fold(
      #(code_writer.generate_first_lines(segment_store), segment_store, 0),
      fn(acc, command_type) {
        let #(assembled_list, segment_store, label_counter) = acc
        case command_type {
          parser.CArithmetic(_) -> {
            // TODO なんらかの segment の操作？
            let #(assembled, updated_counter) =
              code_writer.write_arithmetic(command_type, label_counter)
            #(
              assembled_list
                |> list.append(assembled),
              segment_store,
              updated_counter,
            )
          }
          parser.CPush(segment, value) -> {
            let new_segment = case segment {
              parser.Constant -> segment_store.increment_sp(segment_store)
              _ -> panic
            }

            #(
              assembled_list
                |> list.append(code_writer.write_push_pop(
                  command_type,
                  segment_store,
                )),
              new_segment,
              label_counter,
            )
          }
          parser.CPop(segment, value) -> {
            let new_segment = case segment {
              // TODO まだ不完全。なんらかの segment の操作？
              parser.Constant -> segment_store.decrement_sp(segment_store)
              _ -> panic
            }

            #(
              assembled_list
                |> list.append(code_writer.write_push_pop(
                  command_type,
                  segment_store,
                )),
              new_segment,
              label_counter,
            )
          }
        }
      },
    )
  let assembled_lines =
    assembled_lines |> list.append(code_writer.generate_last_lines())

  io.debug("⭐️")
  io.debug(assembled_lines)
  io.debug("🟠")
  io.debug(final_segment)

  let raw_file =
    assembled_lines |> list.map(fn(x) { x <> "\n" }) |> string.join("")

  let _ = simplifile.write(to: "output/Output.asm", contents: raw_file)

  Ok(Nil)
}
