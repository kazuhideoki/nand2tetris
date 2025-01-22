//// Hackのシンボルとニーモニックをバイナリコードに変換する ためのサービスを提供する

import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import simbol.{type SimbolTable}
import types.{
  type Row, AInstruction, CInstruction, Comment, CompAndJump, DestAndComp,
  LInstruction,
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
        // 数値リテラル @23
        Ok(num) -> #(Some(to_binary(num)), simbol_table)
        // シンボル @something
        Error(_) -> {
          case simbol.get_address(simbol_table, str_val) {
            Some(address) ->
              // 既に辞書にあればそれを使う
              #(Some(address), simbol_table)
            None -> {
              // 辞書になければ変数として登録
              let new_table = simbol.add(str_val, simbol_table)
              let new_addr = simbol.get_address(new_table, str_val)
              case new_addr {
                Some(addr) -> #(Some(addr), new_table)
                None -> panic
              }
            }
          }
        }
      }
    }
    CInstruction(dettail) -> {
      case dettail {
        DestAndComp(dest, comp) -> #(
          Some("111" <> encode_comp(comp) <> encode_dest(dest) <> "000"),
          simbol_table,
        )
        CompAndJump(comp, jump) -> #(
          Some("111" <> encode_comp(comp) <> "000" <> encode_jump(jump)),
          simbol_table,
        )
      }
    }
    LInstruction(str) -> {
      case simbol.get_address(simbol_table, str) {
        Some(_) -> #(None, simbol_table)
        None -> {
          let new_table = simbol.add(str, simbol_table)
          #(None, new_table)
        }
      }
    }
    Comment(_) -> #(None, simbol_table)
  }
}

pub fn encode_dest(str: String) {
  case str {
    "0" -> "000"
    "M" -> "001"
    "D" -> "010"
    "DM" -> "011"
    "MD" -> "011"
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
