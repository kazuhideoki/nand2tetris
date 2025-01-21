import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import types.{
  type Row, AInstruction, CInstruction, Comment, Comp, Jump, LInstruction,
}

// シンボルテーブル, シンボルテーブルのアドレスカウンター
pub type SimbolTable =
  #(Dict(String, Int), Int)

pub fn init_simbol_table() -> SimbolTable {
  // #("R0", 0) ~ #("R15", 15)までつくる
  let #(rs, _) =
    list.repeat(Nil, 16)
    |> list.fold(#([], 0), fn(acc, _) {
      let #(l, count) = acc
      #(
        l
          |> list.append([#("R" <> int.to_string(count), count)]),
        count + 1,
      )
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

pub fn add_entry_to_simbol_table(
  rows: List(Row),
  simbol_table: SimbolTable,
) -> SimbolTable {
  let #(table, counter) = simbol_table
  // LInstruction で対応する行番号を保持する
  let #(label_tables, _) =
    rows
    |> list.fold(#(dict.new(), 0), fn(acc, row) {
      let #(table, row_counter) = acc
      case row {
        LInstruction(label) -> {
          let new_table = dict.insert(table, label, row_counter)
          #(new_table, row_counter)
        }
        Comment(_) -> acc
        _ -> #(table, row_counter + 1)
      }
    })

  io.debug("⭐️label_tables: ")
  io.debug(label_tables)

  // LInstruction で保持した行番号を参照して、シンボルテーブルに登録する
  rows
  |> list.fold(#(table, counter), fn(acc, row) {
    let #(table, counter) = acc
    case row {
      LInstruction(label) -> {
        let address = dict.get(label_tables, label)
        case address {
          Ok(address) -> #(dict.insert(table, label, address), counter + 1)
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

fn add_entry(row: Row, simbol_table: SimbolTable) -> #(Dict(String, Int), Int) {
  let #(simbol_table, counter) = simbol_table
  case row {
    LInstruction(label) -> {
      #(dict.insert(simbol_table, label, counter), counter + 1)
    }
    _ -> #(simbol_table, counter)
  }
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
