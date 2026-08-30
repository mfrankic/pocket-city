# Pocket City

A top-down city builder on a 64×64 grid.

## Play

Binaries are on [GitHub Releases](https://github.com/mfrankic/pocket-city/releases).

| File                               | Platform            |
| ---------------------------------- | ------------------- |
| `pocket-city-*-linux-amd64.tar.gz` | Linux x86_64        |
| `pocket-city-*-windows-amd64.zip`  | Windows x86_64      |
| `pocket-city-*-macos-arm64.zip`    | macOS Apple Silicon |
| `pocket-city-*-macos-amd64.zip`    | macOS Intel         |

macOS builds are unsigned. Right-click → Open the first time (Gatekeeper).

## Develop

Needs [Odin](https://odin-lang.org/) with `vendor:raylib`. CI builds with `dev-2026-08`.

```
odin run .
odin test city
```

Game binaries come from CI. `odin build .` writes `pocket-city` in this directory; that file, `dist/`, and `*.save` are gitignored.
