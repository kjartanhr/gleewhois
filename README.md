# gleam_whois

[![Package Version](https://img.shields.io/hexpm/v/gleam_whois)](https://hex.pm/packages/gleam_whois)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleam_whois/)

WHOIS for gleam.

## Use it to query from the CLI

```sh
~/gleam_whois$ gleam run -- --server=whois.ripe.net --port=43 AS51019
```

## Or use it in your code

```sh
gleam add gleam_whois
```

```gleam
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
```

Documentation also available at <https://hexdocs.pm/gleam_whois>.

## License

MIT
