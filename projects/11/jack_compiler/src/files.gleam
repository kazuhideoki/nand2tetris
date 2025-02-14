import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn get_raw_string(path: String) -> Result(String, Nil) {
  simplifile.read(path)
  |> result.map_error(fn(_) { Nil })
}

/// 指定パスがディレクトリなら、その中の .jack ファイルをすべて収集し、
/// 出力先ディレクトリ "output/<basename>" を作成して返す。
/// そうでなければ、単一ファイルとして出力先 "output" を返す。
pub fn gather_files(path: String) -> Result(#(String, List(String)), Nil) {
  case simplifile.is_directory(path) {
    Ok(True) -> {
      let assert Ok(files) = simplifile.read_directory(path)
      let jack_files =
        list.filter(files, fn(file) { string.ends_with(file, ".jack") })
      let output_dir = "output" <> "/" <> basename(path)
      let _ = simplifile.create_directory(output_dir)
      let full_paths = list.map(jack_files, fn(file) { path <> "/" <> file })
      Ok(#(output_dir, full_paths))
    }
    _ -> Ok(#("output", [path]))
  }
}

/// パス文字列の最後の "/" 以降の部分（basename）を返す。
pub fn basename(path: String) -> String {
  let parts = string.split(path, "/")
  list.last(parts)
  |> result.unwrap(path)
}

/// 拡張子 ".jack" を検出して new_ext に置換する。
pub fn replace_extension(file_path: String, new_ext: String) -> String {
  case string.ends_with(file_path, ".jack") {
    True -> {
      let base = string.slice(file_path, 0, string.length(file_path) - 5)
      base <> new_ext
    }
    False -> file_path <> new_ext
  }
}
