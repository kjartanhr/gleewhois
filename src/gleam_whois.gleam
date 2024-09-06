import argv
import gleam/bit_array
import gleam/io
import gleam/result
import glint
import mug.{type Socket, Enotsup}

const timeout_ms = 60_000

fn server_flag() -> glint.Flag(String) {
  glint.string_flag("server")
  |> glint.flag_default("whois.ripe.net")
  |> glint.flag_help("WHOIS server to query")
}

fn port_flag() -> glint.Flag(Int) {
  glint.int_flag("port")
  |> glint.flag_default(43)
  |> glint.flag_help("Port of WHOIS server to query")
}

pub fn main() {
  glint.new()
  |> glint.with_name("whois")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: whois())
  |> glint.run(argv.load().arguments)
}

fn whois() -> glint.Command(Nil) {
  use <- glint.command_help("Queries a WHOIS server.")
  use query <- glint.named_arg("query")
  use server <- glint.flag(server_flag())
  use port <- glint.flag(port_flag())

  use named, _args, flags <- glint.command()

  let assert Ok(server) = server(flags)
  let assert Ok(port) = port(flags)
  let query = query(named)

  let assert Ok(socket) =
    mug.new(server, port)
    |> mug.timeout(timeout_ms)
    |> mug.connect()

  let suffixed_query = query <> "\n"
  let assert Ok(Nil) = mug.send(socket, <<suffixed_query:utf8>>)

  let result = receive(socket, "")
  io.print(result)
}

fn receive(socket: Socket, res: String) -> String {
  let packet = mug.receive(socket, timeout_ms)
  let string =
    result.then(packet, fn(bits) {
      case bit_array.to_string(bits) {
        Ok(str) -> Ok(str)
        _ -> Error(result.unwrap_error(packet, Enotsup))
      }
    })

  case string {
    Ok(str) -> {
      receive(socket, res <> str)
    }
    _ -> res
  }
}
