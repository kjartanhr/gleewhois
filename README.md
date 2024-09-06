# gleewhois

[![Package Version](https://img.shields.io/hexpm/v/gleewhois)](https://hex.pm/packages/gleewhois)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleewhois/)

WHOIS client for Gleam.

## Use it to query from the CLI

```sh
~/gleewhois$ gleam run -- --server=whois.ripe.net --port=43 AS51019
```

## Or use it in your code

```sh
gleam add gleewhois
```

```gleam
import gleam/io
import gleewhois.{ParsingError, SocketError, UnknownError}

pub fn main() {
  let query =
    gleewhois.query(
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
```

Documentation also available at <https://hexdocs.pm/gleewhois>.

## License

MIT
