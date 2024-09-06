//// Library to query WHOIS servers from Gleam, using the `mug` Gleam TCP client.

import argv
import gleam/bit_array
import gleam/io
import glint
import mug.{type Error, type Socket}

pub type Err {
  SocketError
  ParsingError
  UnknownError
}

fn whois() -> glint.Command(Nil) {
  use <- glint.command_help("Queries a WHOIS server.")
  use query_string <- glint.named_arg("query")
  use server <- glint.flag(server_flag())
  use port <- glint.flag(port_flag())
  use timeout_ms <- glint.flag(timeout_flag())

  use named, _args, flags <- glint.command()

  let assert Ok(server) = server(flags)
  let assert Ok(port) = port(flags)
  let assert Ok(timeout_ms) = timeout_ms(flags)
  let query_string = query_string(named)

  case query(query_string, server, port, timeout_ms) {
    Ok(result) -> io.print(result)
    Error(err) ->
      case err {
        SocketError ->
          io.println("Error establishing connection (socket error).")
        ParsingError -> io.println("Error parsing result data (parsing error).")
        UnknownError ->
          io.println("Unknown error ocurred when querying (unknown error).")
      }
  }
}

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

fn timeout_flag() -> glint.Flag(Int) {
  glint.int_flag("timeout")
  |> glint.flag_default(60_000)
  |> glint.flag_help(
    "Max time to wait for responses from the WHOIS server (in ms).",
  )
}

pub fn main() {
  glint.new()
  |> glint.with_name("whois")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: whois())
  |> glint.run(argv.load().arguments)
}

/// Query a WHOIS server, e.g.
/// ```gleam
/// query("AS51019", server: "whois.ripe.net", port: 43, timeout_ms: 60_000)
/// ```
/// 
/// or for a domain name:
/// ```gleam
/// query("ospf.se", server: "whois.iis.se", port: 43, timeout_ms: 60_000)
/// ```
/// 
/// You can find the WHOIS server for any TLD from `whois.iana.org`, you could even do it with this library:
/// ```gleam
/// query("se", server: "whois.iana.org", port: 43, timeout_ms: 60_000)
/// ```
/// and programmatically obtain the WHOIS server for any TLD, to query for any domain name.
pub fn query(
  query: String,
  server server: String,
  port port: Int,
  timeout_ms timeout_ms: Int,
) -> Result(String, Err) {
  let socket =
    mug.new(server, port)
    |> mug.timeout(timeout_ms)
    |> mug.connect()

  case socket {
    Ok(socket) -> {
      let suffixed_query = query <> "\n"
      let assert Ok(Nil) = mug.send(socket, <<suffixed_query:utf8>>)

      receive_all(socket, timeout_ms, base_str: "", base_iteration: 0)
    }
    _ -> Error(SocketError)
  }
}

fn receive_all(
  socket: Socket,
  timeout_ms: Int,
  base_str res: String,
  base_iteration iteration: Int,
) -> Result(String, Err) {
  let string = {
    case receive_packet(socket, timeout_ms) {
      Ok(bits) -> bits_to_string(bits)
      Error(_) -> Error(ParsingError)
    }
  }

  case string {
    Ok(str) -> {
      receive_all(
        socket,
        timeout_ms,
        base_str: res <> str,
        base_iteration: iteration + 1,
      )
    }
    Error(err) -> {
      case iteration {
        0 -> Error(err)
        _ -> Ok(res)
      }
    }
  }
}

fn receive_packet(socket: Socket, timeout_ms: Int) -> Result(BitArray, Err) {
  case mug.receive(socket, timeout_ms) {
    Ok(bits) -> Ok(bits)
    Error(_) -> Error(SocketError)
  }
}

fn bits_to_string(bits: BitArray) -> Result(String, Err) {
  case bit_array.to_string(bits) {
    Ok(str) -> Ok(str)
    Error(_) -> Error(ParsingError)
  }
}
