# Sil-Q documentation

Source for the Sil website and the user-manual PDF. Both are produced from the
same Markdown files via [pandoc](https://pandoc.org/).

## Layout

- `user/` contains the Markdown sources. They are rendered to HTML for the
    website, and [manual.md](user/manual.md) is also rendered to PDF.
- `developer/` is the developer documentation. This is not rendered to HTML or
    PDF right now.
- `pandoc/` contains the build pipeline: templates, Lua filters, defaults files,
    and assets (e.g., CSS/JS for the website, title image for the PDF).

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
