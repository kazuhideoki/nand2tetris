import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

/// 変数の属性（スコープや用途）を示す型
pub type Kind {
  Static
  Field
  Argument
  Var
  NoneKind
}

/// 識別子（シンボル）の情報。型名（symbol_type）、属性（kind）、および実行時のインデックスを保持する。
pub type Symbol =
  #(String, Kind, Int)

pub type SymbolTable {
  SymbolTable(
    /// クラススコープのシンボルを保持するマップ
    class_scope: Dict(String, Symbol),
    /// サブルーチンスコープのシンボルを保持するマップ
    subroutine_scope: Dict(String, Symbol),
    /// 静的変数のカウンタ
    static_count: Int,
    /// フィールド変数のカウンタ
    field_count: Int,
    /// 引数のカウンタ
    argument_count: Int,
    /// ローカル変数のカウンタ
    var_count: Int,
  )
}

pub fn new_symbol_table() -> SymbolTable {
  SymbolTable(
    class_scope: dict.new(),
    subroutine_scope: dict.new(),
    static_count: 0,
    field_count: 0,
    argument_count: 0,
    var_count: 0,
  )
}

pub fn start_subroutine(table: SymbolTable) -> SymbolTable {
  SymbolTable(
    class_scope: table.class_scope,
    subroutine_scope: dict.new(),
    static_count: table.static_count,
    field_count: table.field_count,
    argument_count: 0,
    var_count: 0,
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
        class_scope: new_class,
        subroutine_scope: table.subroutine_scope,
        static_count: new_index + 1,
        field_count: table.field_count,
        argument_count: table.argument_count,
        var_count: table.var_count,
      )
    }
    Field -> {
      let new_index = table.field_count
      let new_class =
        dict.insert(table.class_scope, name, #(symbol_type, kind, new_index))
      SymbolTable(
        class_scope: new_class,
        subroutine_scope: table.subroutine_scope,
        static_count: table.static_count,
        field_count: new_index + 1,
        argument_count: table.argument_count,
        var_count: table.var_count,
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
        class_scope: table.class_scope,
        subroutine_scope: new_sub,
        static_count: table.static_count,
        field_count: table.field_count,
        argument_count: new_index + 1,
        var_count: table.var_count,
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
        class_scope: table.class_scope,
        subroutine_scope: new_sub,
        static_count: table.static_count,
        field_count: table.field_count,
        argument_count: table.argument_count,
        var_count: new_index + 1,
      )
    }
    NoneKind -> table
  }
}

/// シンボルテーブルから識別子を検索する
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
