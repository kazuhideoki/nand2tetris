import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

/// 変数の属性（スコープや用途）を示す型
pub type Kind {
  Static
  Field
  Argument
  Var
  NoneKind
  // 該当なし
}

/// 識別子（シンボル）の情報。型名（symbol_type）、属性（kind）、および実行時のインデックスを保持する。
pub type Symbol =
  #(String, Kind, Int)

// シンボルテーブルは、クラススコープとサブルーチンスコープで別々に識別子を管理するので、それぞれのマップと
// 各属性ごとのカウンタを保持する。
pub type SymbolTable {
  SymbolTable(
    class_scope: Dict(String, Symbol),
    subroutine_scope: Dict(String, Symbol),
    static_count: Int,
    field_count: Int,
    argument_count: Int,
    var_count: Int,
  )
}

pub fn new_symbol_table() -> SymbolTable {
  SymbolTable(
    dict.new(),
    dict.new(),
    0,
    // static_count
    0,
    // field_count
    0,
    // argument_count
    0,
    // var_count
  )
}

pub fn start_subroutine(table: SymbolTable) -> SymbolTable {
  SymbolTable(
    table.class_scope,
    dict.new(),
    table.static_count,
    table.field_count,
    0,
    // reset argument_count
    0,
    // reset var_count
  )
}

pub fn define(
  table: SymbolTable,
  name: String,
  symbol_type: String,
  kind: Kind,
) -> SymbolTable {
  case kind {
    Static -> {
      let new_index = table.static_count
      let new_class =
        dict.insert(table.class_scope, name, #(symbol_type, kind, new_index))
      SymbolTable(
        new_class,
        table.subroutine_scope,
        new_index + 1,
        table.field_count,
        table.argument_count,
        table.var_count,
      )
    }
    Field -> {
      let new_index = table.field_count
      let new_class =
        dict.insert(table.class_scope, name, #(symbol_type, kind, new_index))
      SymbolTable(
        new_class,
        table.subroutine_scope,
        table.static_count,
        new_index + 1,
        table.argument_count,
        table.var_count,
      )
    }
    Argument -> {
      let new_index = table.argument_count
      let new_sub =
        dict.insert(table.subroutine_scope, name, #(
          symbol_type,
          kind,
          new_index,
        ))
      SymbolTable(
        table.class_scope,
        new_sub,
        table.static_count,
        table.field_count,
        new_index + 1,
        table.var_count,
      )
    }
    Var -> {
      let new_index = table.var_count
      let new_sub =
        dict.insert(table.subroutine_scope, name, #(
          symbol_type,
          kind,
          new_index,
        ))
      SymbolTable(
        table.class_scope,
        new_sub,
        table.static_count,
        table.field_count,
        table.argument_count,
        new_index + 1,
      )
    }
    NoneKind -> table
  }
}

pub fn lookup(table: SymbolTable, name: String) -> Option(Symbol) {
  case dict.get(table.subroutine_scope, name) {
    Ok(symbol) -> Some(symbol)
    Error(_) -> {
      case dict.get(table.class_scope, name) {
        Ok(symbol) -> Some(symbol)
        Error(_) -> None
      }
    }
  }
}

/// 補助：Kind 型を文字列に変換する
pub fn kind_to_string(kind: Kind) -> String {
  case kind {
    Static -> "static"
    Field -> "field"
    Argument -> "arg"
    Var -> "var"
    NoneKind -> "none"
  }
}
