import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
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
// pub fn add_entry_to_simbol_table(
//   rows: List(Row),
//   simbol_table: SimbolTable,
// ) -> SimbolTable {
//   let #(table, counter) = simbol_table
//   let #(label_tables, _) =
//     rows
//     |> list.fold(#(dict.new(), 0), fn(acc, row) {
//       let #(table, rom_addr) = acc
//       case row {
//         LInstruction(label) -> #(dict.insert(table, label, rom_addr), rom_addr)
//         Comment(_) -> acc
//         _ -> #(table, rom_addr + 1)
//       }
//     })

//   io.debug(label_tables)

//   rows
//   |> list.fold(#(table, counter), fn(acc, row) {
//     let #(table, counter) = acc
//     case row {
//       LInstruction(label) -> {
//         let address = dict.get(label_tables, label)
//         case address {
//           Ok(rom_addr) -> #(dict.insert(table, label, rom_addr), counter)
//           Error(_) -> {
//             io.debug(
//               "⭐️error occurred add_entry_to_simbol_table, label:"
//               <> label
//               <> ", counter:"
//               <> int.to_string(counter),
//             )
//             panic
//           }
//         }
//       }
//       _ -> #(table, counter)
//     }
//   })
// }
pub fn add_entry_to_simbol_table(
  rows: List(Row),
  simbol_table: SimbolTable,
) -> SimbolTable {
  let #(table, var_counter) = simbol_table

  // 1. L命令が何行目か (ROMアドレス) をラベルテーブルにまとめる
  let #(label_table, _) =
    rows
    |> list.fold(#(dict.new(), 0), fn(acc, row) {
      let #(tmp_table, rom_addr) = acc
      case row {
        // ラベルが出てきた行番(rom_addr)を記憶しておく
        LInstruction(label) -> #(
          dict.insert(tmp_table, encode_for_dict(label), rom_addr),
          rom_addr,
        )
        Comment(_) -> acc
        _ ->
          // A命令やC命令ならROM上で1行分進む
          #(tmp_table, rom_addr + 1)
      }
    })

  // 2. ラベルテーブルに沿ってシンボルテーブルに登録
  //    (ラベルを辞書に入れる時は変数カウンタは動かさない)
  let new_table =
    label_table
    |> dict.fold(table, fn(acc, label, rom_addr) {
      dict.insert(acc, label, rom_addr)
    })

  // 変数カウンタは変えない
  #(new_table, var_counter)
}

pub fn get_address(simbol_table: SimbolTable, str: String) -> Option(String) {
  let #(dict, _) = simbol_table
  case dict.get(dict, encode_for_dict(str)) {
    Ok(address) -> Some(to_binary(address))
    Error(_) -> None
  }
}

// TODO 既に入ってないか確認してから追加する
pub fn add(str: String, simbol_table: SimbolTable) -> SimbolTable {
  let #(dict, counter) = simbol_table
  case get_address(simbol_table, str) {
    Some(_) -> {
      add(str, #(dict, counter + 1))
    }
    None -> {
      let new_dict = dict.insert(dict, encode_for_dict(str), counter)
      #(new_dict, counter + 1)
    }
  }
}

fn to_binary(num: Int) -> String {
  int.to_base2(num) |> string.pad_start(16, "0")
}

pub fn encode_for_dict(str: String) -> String {
  string.replace(str, ".", "__")
}

fn parse_from_dict(str: String) -> String {
  string.replace(str, "__", ".")
}
