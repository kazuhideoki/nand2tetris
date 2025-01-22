import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, Some}
import gleam/string
import types.{type Row, Comment, LInstruction}

// シンボルテーブル, シンボルテーブルのアドレスカウンター
pub type SimbolTable =
  #(Dict(String, Int), Int)

pub fn init_simbol_table() -> SimbolTable {
  let #(rs, _) =
    list.repeat(Nil, 16)
    |> list.fold(#([], 0), fn(acc, _) {
      let #(l, count) = acc
      #(l |> list.append([#("R" <> int.to_string(count), count)]), count + 1)
    })

  #(
    dict.from_list([
      #("SP", 0),
      #("LCL", 1),
      #("ARG", 2),
      #("THIS", 3),
      #("THAT", 4),
      #("SCREEN", 16_384),
      #("KBD", 24_576),
      ..rs
    ]),
    16,
  )
}

// 第一パス: ラベル定義 ( (LABEL) ) があれば対応するROM行番を記録する
pub fn add_entry_to_simbol_table(
  rows: List(Row),
  simbol_table: SimbolTable,
) -> SimbolTable {
  let #(table, counter) = simbol_table
  let #(label_tables, _) =
    rows
    |> list.fold(#(dict.new(), 0), fn(acc, row) {
      let #(table, rom_addr) = acc
      case row {
        LInstruction(label) -> #(dict.insert(table, label, rom_addr), rom_addr)
        Comment(_) -> acc
        _ -> #(table, rom_addr + 1)
      }
    })

  rows
  |> list.fold(#(table, counter), fn(acc, row) {
    let #(table, counter) = acc
    case row {
      LInstruction(label) -> {
        let address = dict.get(label_tables, label)
        case address {
          Ok(rom_addr) -> #(dict.insert(table, label, rom_addr), counter)
          Error(_) -> {
            io.debug(
              "⭐️error occurred add_entry_to_simbol_table, label:"
              <> label
              <> ", counter:"
              <> int.to_string(counter),
            )
            panic
          }
        }
      }
      _ -> #(table, counter)
    }
  })
}

// TODO dict で登録する時 `{str}.0` の形式はうまくいかない -> encode_for_dict, parse_from_dict で対応
pub fn add_variable_to_simbol_table(
  str: String,
  simbol_table: SimbolTable,
) -> SimbolTable {
  io.debug("⭐️add_variable_to_simbol_table")
  io.debug(str)
  let #(dict, counter) = simbol_table
  let new_dict = dict.insert(dict, str, counter)
  #(new_dict, counter + 1)
}

pub fn get_address_from_symbol_table(
  str: String,
  simbol_table: SimbolTable,
) -> #(Option(String), SimbolTable) {
  let #(dict, counter) = simbol_table
  case dict.get(dict, str) {
    Ok(address) -> #(Some(to_binary(address)), simbol_table)
    Error(_) -> {
      let counter = counter + 1
      let new_dict = dict.insert(dict, str, counter)
      #(Some(to_binary(counter)), #(new_dict, counter))
    }
  }
}

fn to_binary(num: Int) -> String {
  int.to_base2(num) |> string.pad_start(16, "0")
}

fn encode_for_dict() {
  todo
}

fn parse_from_dict() {
  todo
}
