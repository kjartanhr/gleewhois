import gleam/io
import gleam_whois.{ParsingError, SocketError, UnknownError}

pub fn main() {
  let query =
    gleam_whois.query(
      "AS51019",
      server: "whois.ripe.net",
      port: 43,
      timeout_ms: 60_000,
    )
  // -> Result(String, Err)

  case query {
    Ok(result) -> io.print(result)
    Error(err) ->
      case err {
        SocketError -> io.println("Error establishing connection.")
        ParsingError -> io.println("Error parsing result data.")
        UnknownError -> io.println("An unknown error ocurred during query.")
      }
  }
}
