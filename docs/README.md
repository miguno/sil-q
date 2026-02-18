# Sil-Q documentation

Source for the Sil website and the user-manual PDF. Both are produced from the
same Markdown files via [pandoc](https://pandoc.org/).

## Layout

- `user/` contains the Markdown sources. They are rendered to HTML for the
    website, and [manual.md](user/manual.md) is also rendered to PDF.
- `developer/` is the developer documentation (see below). This is not rendered
    to HTML or PDF right now.
- `pandoc/` contains the build pipeline: templates, Lua filters, defaults files,
    and assets (e.g., CSS/JS for the website, title image for the PDF).

## Developer documentation

Each topic is documented in one file only. Other files link to it instead of
repeating it. The exception is `world_model.md`, which collects facts from the
other files for a possible database.

| File                                             | Topic                                                              |
| ------------------------------------------------ | ------------------------------------------------------------------ |
| [code_base.md](developer/code_base.md)           | Game systems in the C code, especially hardcoded behavior          |
| [data_files.md](developer/data_files.md)         | The format of all data files (`lib/edit/*.txt`, `lib/pref/*.prf`)  |
| [rendering.md](developer/rendering.md)           | ASCII and tile rendering, overlays, rage visual effects            |
| [visibility.md](developer/visibility.md)         | Line of sight, view algorithm, `distance()`                        |
| [world_model.md](developer/world_model.md)       | Entity-relationship model for a possible database of game entities |
| [developer_mode.md](developer/developer_mode.md) | Debug commands for testing                                         |
| [game_design.md](developer/game_design.md)       | Design intent and history                                          |

The docs are written for human developers and for AI agents. They refer to code
by function name (e.g., `min_depth()` in `src/cmd2.c`), not by line number.

## Build

[pandoc](https://pandoc.org) (version 3.6+) is the only required tool. The PDF
build additionally needs XeLaTeX (e.g. via TeX Live).

```sh
just html    # build the website into dist/
just pdf     # build dist/Sil-Q-Manual.pdf
just build   # both
just serve   # serve dist/ at http://localhost:8000
just clean   # remove dist/
```

On macOS you can install pandoc via `just install` (uses `Brewfile`). On other
systems, install pandoc and a TeX distribution with your package manager.

## How it works

- Top-level pages (e.g., [index.md](user/index.md),
    [download.md](user/download.md)) are rendered one-to-one to HTML.
- The manual ([manual.md](user/manual.md)) is pre-split on `##` headings into
    per-chapter files by
    [pandoc/filters/split-manual.lua](pandoc/filters/split-manual.lua). Inside
    each chapter, headings are promoted one level so chapter pages have a clean
    `<h1>` from the title. Cross-chapter and same-page `#anchor` links are
    rewritten by the splitter.
- The same [pandoc/templates/site.html](pandoc/templates/site.html) template is
    used for every HTML page. The sidebar is built by
    [pandoc/filters/active-nav.lua](pandoc/filters/active-nav.lua).
- The PDF build consumes `manual.md` as-is via the Eisvogel LaTeX template in
    [pandoc/templates/eisvogel/](pandoc/templates/eisvogel/).
