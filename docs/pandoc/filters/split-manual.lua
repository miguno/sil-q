-- Splits manual.md into chapter files at H2 boundaries.
--
-- Outputs (under OUT_DIR):
--   index.md             prelude + auto-generated chapter list
--   <slug>.md            one per H2 chapter; H3+ headings promoted by 1 level
--   nav-chapters.lua     Lua table: { {slug=..., title=...}, ... }
--   heading-index.lua    Lua table: heading-id -> chapter slug (step 6)
--
-- Invoked as a Lua filter on manual.md; output target is /dev/null since
-- the side effect (writing files) is the point.

local OUT_DIR = "dist/_intermediate/manual"

-- Pandoc auto-id for a heading, matching its default slugify (gfm/auto_identifiers).
-- Used when a heading lacks an explicit identifier.
local function slugify(text)
  local s = text:lower()
  -- strip everything that isn't alnum, space, hyphen, or underscore
  s = s:gsub("[^%w%s%-_]", "")
  s = s:gsub("%s+", "-")
  return s
end

local function yaml_quote(s)
  return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

local function lua_quote(s)
  return string.format("%q", s)
end

local function write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then error("split-manual: cannot write " .. path .. ": " .. tostring(err)) end
  f:write(content)
  f:close()
end

local function ensure_dir(path)
  os.execute("mkdir -p " .. path)
end

-- Promote H3→H2, H4→H3, etc., within a chapter's block list. Headings
-- are always top-level blocks in markdown, so a flat pass suffices.
local function promote_headings(blocks)
  local out = pandoc.List({})
  for _, b in ipairs(blocks) do
    if b.t == "Header" and b.level > 1 then
      b.level = b.level - 1
    end
    out:insert(b)
  end
  return out
end

local function collect_heading_ids(blocks)
  local ids = {}
  for _, b in ipairs(blocks) do
    if b.t == "Header" and b.identifier ~= "" then
      ids[#ids + 1] = b.identifier
    end
  end
  return ids
end

-- Rewrite a link target inside chapter content. The chapter HTML lives one
-- directory below the site root.
local function rewrite_link_target(target, heading_index, current_slug, warn)
  if target:match("^https?://")
      or target:match("^//")
      or target:match("^mailto:") then
    return target
  end

  -- Bare anchor `#foo` — local to this chapter, or another chapter?
  local anchor = target:match("^#(.+)$")
  if anchor then
    local owner = heading_index[anchor]
    if owner and owner ~= current_slug then
      return owner .. ".html#" .. anchor
    end
    if not owner then warn(target) end
    return target  -- same chapter, or unknown (warning emitted)
  end

  -- `manual.md` or `manual.md#anchor` — should never appear inside manual
  -- content, but handle it for robustness.
  local manual_anchor = target:match("^manual%.md#(.+)$")
  if manual_anchor then
    local owner = heading_index[manual_anchor]
    if owner then return owner .. ".html#" .. manual_anchor end
    warn(target)
    return "index.html#" .. manual_anchor
  end
  if target == "manual.md" then return "index.html" end

  -- Any other `*.md[#...]` — a top-level page reference. Chapter files live
  -- under manual/, so prepend `../`. md-links.lua will convert .md→.html.
  if target:match("%.md$") or target:match("%.md#") then
    return "../" .. target
  end

  return target
end

local function is_external_url(target)
  return target:match("^https?://") or target:match("^//") or target:match("^data:")
end

local function rewrite_chapter_links(blocks, heading_index, current_slug, warn)
  local doc = pandoc.Pandoc(blocks, pandoc.Meta({}))
  local walked = doc:walk({
    Link = function(l)
      l.target = rewrite_link_target(l.target, heading_index, current_slug, warn)
      return l
    end,
    Image = function(img)
      -- Images use src paths relative to docs/user/. Chapter HTML lives
      -- one dir below the site root, so local image paths need `../`.
      if not is_external_url(img.src) then
        img.src = "../" .. img.src
      end
      return img
    end,
  })
  return walked.blocks
end

-- Render a list of blocks as markdown using pandoc.write.
local function blocks_to_markdown(blocks)
  local doc = pandoc.Pandoc(blocks, pandoc.Meta({}))
  return pandoc.write(doc, "markdown")
end

function Pandoc(doc)
  ensure_dir(OUT_DIR)

  local prelude = pandoc.List({})
  local chapters = {}
  local current

  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 2 then
      local title = pandoc.utils.stringify(block.content)
      -- Slug is derived from the title rather than pandoc's auto-id so that
      -- chapters don't inherit document-wide disambiguation suffixes like
      -- "stealth-1" caused by a same-named H3 elsewhere in the source.
      local slug = slugify(title)
      current = {
        title = title,
        slug = slug,
        anchor = block.identifier,  -- original H2 id, used by heading-index
        blocks = pandoc.List({}),
      }
      table.insert(chapters, current)
    elseif current then
      current.blocks:insert(block)
    else
      prelude:insert(block)
    end
  end

  -- Build heading-index FIRST (before link rewriting needs it).
  -- Maps every heading id in the source to the chapter it ended up in.
  local heading_index = {}
  for _, ch in ipairs(chapters) do
    if ch.anchor and ch.anchor ~= "" then
      heading_index[ch.anchor] = ch.slug
    end
    heading_index[ch.slug] = ch.slug
    for _, id in ipairs(collect_heading_ids(ch.blocks)) do
      heading_index[id] = ch.slug
    end
  end

  -- Rewrite cross-chapter links inside each chapter's content.
  local function warn(target)
    io.stderr:write("split-manual: unresolved link target: " .. target .. "\n")
  end
  for _, ch in ipairs(chapters) do
    ch.blocks = rewrite_chapter_links(ch.blocks, heading_index, ch.slug, warn)
  end

  -- Write chapter files
  for _, ch in ipairs(chapters) do
    local promoted = promote_headings(ch.blocks)
    local body = blocks_to_markdown(promoted)
    local md = "---\ntitle: " .. yaml_quote(ch.title) .. "\n---\n\n" .. body
    write_file(OUT_DIR .. "/" .. ch.slug .. ".md", md)
  end

  -- Write nav-chapters.lua
  local nav = { "return {" }
  for _, ch in ipairs(chapters) do
    nav[#nav + 1] = string.format("  { slug = %s, title = %s },",
      lua_quote(ch.slug), lua_quote(ch.title))
  end
  nav[#nav + 1] = "}"
  write_file(OUT_DIR .. "/nav-chapters.lua", table.concat(nav, "\n") .. "\n")

  -- Write heading-index.lua for md-links.lua to resolve external
  -- `manual.md#anchor` references from top-level pages.
  local idx = { "return {" }
  for id, slug in pairs(heading_index) do
    idx[#idx + 1] = string.format("  [%s] = %s,", lua_quote(id), lua_quote(slug))
  end
  idx[#idx + 1] = "}"
  write_file(OUT_DIR .. "/heading-index.lua", table.concat(idx, "\n") .. "\n")

  -- Write manual/index.md (prelude + chapter list)
  local landing = pandoc.List({})
  for _, b in ipairs(prelude) do landing:insert(b) end
  if #chapters > 0 then
    landing:insert(pandoc.Header(2, { pandoc.Str("Chapters") }))
    local items = pandoc.List({})
    for _, ch in ipairs(chapters) do
      items:insert({ pandoc.Plain({
        pandoc.Link({ pandoc.Str(ch.title) }, ch.slug .. ".html"),
      }) })
    end
    landing:insert(pandoc.BulletList(items))
  end
  local landing_md = blocks_to_markdown(landing)
  write_file(OUT_DIR .. "/index.md",
    "---\ntitle: Manual\n---\n\n" .. landing_md)

  return doc
end
