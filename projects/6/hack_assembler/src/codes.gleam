//// Hackのシンボルとニーモニックをバイナリコードに変換する ためのサービスを提供する

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import types.{
  type Row, AInstruction, CInstruction, Comment, Comp, Jump, LInstruction,
}

// シンボルテーブル, シンボルテーブルのアドレスカウンター
type SimbolTable =
  #(Dict(String, Int), Int)

// TODO for Max
// 1 シンボルテーブルつくる -> 定数、ラベル、変数。一覧 -> p136
// - Mapつかう
// - 変数を登録するためのカウンターみたいなもの必要 RAM[16] から始まる
// - AInstruction, LInstruction の時に登録することがある

// 2 jump に対応するために ラベルの保持
// - 第1パスで ラベルだけを登録する -> 先に登録しないとjump 時に参照できない
// - 第2パスで ラベルを参照する

pub fn add_entry_to_simbol_table(rows: List(Row)) -> SimbolTable {
  let simbol_table = dict.new()
  let counter = 16
  rows
  |> list.fold(#(simbol_table, counter), fn(acc, row) { add_entry(row, acc) })
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

fn get_address_from_symbol_table(
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

pub fn encode_rows(rows: List(Row), simbol_table: SimbolTable) -> List(String) {
  let #(encoded_rows, _) =
    rows
    |> list.fold(#([], simbol_table), fn(acc, row) {
      let #(acc_rows, acc_table) = acc
      case encode_row(row, acc_table) {
        #(Some(binary), new_table) -> #(
          list.append(acc_rows, [binary]),
          new_table,
        )
        #(None, new_table) -> #(acc_rows, new_table)
      }
    })

  encoded_rows
}

fn encode_row(
  row: Row,
  simbol_table: SimbolTable,
) -> #(Option(String), SimbolTable) {
  case row {
    // 2進数に変換する
    AInstruction(str_val) -> {
      // シンボルの時、参照 or 登録する
      case int.parse(str_val) {
        Ok(num) -> {
          #(Some(to_binary(num)), simbol_table)
        }
        Error(_) -> {
          // TODO 数字以外はラベルとして扱う。登録する
          #(None, simbol_table)
        }
      }
    }
    CInstruction(comp_or_jump) -> {
      case comp_or_jump {
        Comp(dest, comp) -> #(
          Some("111" <> encode_comp(comp) <> encode_dest(dest) <> "000"),
          simbol_table,
        )
        Jump(dest, jump) -> #(
          Some("111" <> "0000000" <> encode_dest(dest) <> encode_jump(jump)),
          simbol_table,
        )
      }
    }
    LInstruction(str) -> get_address_from_symbol_table(str, simbol_table)
    Comment(_) -> #(None, simbol_table)
  }
}

pub fn encode_dest(str: String) {
  case str {
    "0" -> "000"
    "M" -> "001"
    "D" -> "010"
    "DM" -> "011"
    "A" -> "100"
    "AM" -> "101"
    "AD" -> "110"
    "ADM" -> "111"
    _ -> panic
  }
}

pub fn encode_comp(str: String) {
  case str {
    "0" -> "0101010"
    "1" -> "0111111"
    "-1" -> "0111010"
    "D" -> "0001100"
    "A" -> "0110000"
    "!D" -> "0001101"
    "!A" -> "0110001"
    "-D" -> "0001111"
    "-A" -> "0110011"
    "D+1" -> "0011111"
    "A+1" -> "0110111"
    "D-1" -> "0001110"
    "A-1" -> "0110010"
    "D+A" -> "0000010"
    "D-A" -> "0010011"
    "A-D" -> "0000111"
    "D&A" -> "0000000"
    "D|A" -> "0010101"
    "M" -> "1110000"
    "!M" -> "1110001"
    "-M" -> "1110011"
    "M+1" -> "1110111"
    "M-1" -> "1110010"
    "D+M" -> "1000010"
    "D-M" -> "1010011"
    "M-D" -> "1000111"
    "D&M" -> "1000000"
    "D|M" -> "1010101"
    _ -> panic
  }
}

pub fn encode_jump(str: String) {
  case str {
    "JGT" -> "001"
    "JEQ" -> "010"
    "JGE" -> "011"
    "JLT" -> "100"
    "JNE" -> "101"
    "JLE" -> "110"
    "JMP" -> "111"
    _ -> panic
  }
}

fn to_binary(num: Int) -> String {
  int.to_base2(num) |> string.pad_start(16, "0")
}
