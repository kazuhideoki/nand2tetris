//// シンボルテーブル, シンボルテーブルのアドレスカウンター

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import types.{type Row, Comment, LInstruction}

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

/// 第一パス: ラベル定義 ( (LABEL) ) があれば対応するROM行番を記録する
pub fn add_labels(simbol_table: SimbolTable, rows: List(Row)) -> SimbolTable {
  let #(table, var_counter) = simbol_table

  let #(label_table, _) =
    rows
    |> list.fold(#(dict.new(), 0), fn(acc, row) {
      let #(tmp_table, rom_addr) = acc
      case row {
        LInstruction(label) -> #(
          dict.insert(tmp_table, label, rom_addr),
          rom_addr,
        )
        Comment(_) -> acc
        // A命令やC命令ならROM上で1行分進む
        _ -> #(tmp_table, rom_addr + 1)
      }
    })

  // ラベルテーブルに沿ってシンボルテーブルに登録
  let new_table =
    label_table
    |> dict.fold(table, fn(acc, label, rom_addr) {
      dict.insert(acc, label, rom_addr)
    })

  #(new_table, var_counter)
}

pub fn get_address(simbol_table: SimbolTable, str: String) -> Option(String) {
  let #(dict, _) = simbol_table
  case dict.get(dict, str) {
    // base2に変換して16桁になるように0埋める
    Ok(address) -> Some(address |> int.to_base2 |> string.pad_start(16, "0"))
    Error(_) -> None
  }
}

pub fn add(str: String, simbol_table: SimbolTable) -> SimbolTable {
  let #(dict, counter) = simbol_table
  case get_address(simbol_table, str) {
    Some(_) -> simbol_table
    None -> {
      let new_dict = dict.insert(dict, str, counter)
      #(new_dict, counter + 1)
    }
  }
}
