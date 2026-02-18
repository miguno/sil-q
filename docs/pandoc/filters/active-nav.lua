-- Builds the sidebar nav HTML and exposes it as the `sidebar` template variable.
-- Reads the current page's slug from metadata (passed via `-M slug=...`)
-- and the chapter list (if it exists) from the splitter's output.

local nav_items = {
  { title = "Home",       href = "index.html",        slug = "index" },
  { title = "Download",   href = "download.html",     slug = "download" },
  { title = "Manual",     href = "manual/index.html", slug = "manual",
    expand_prefix = "manual" },
  { title = "Changes",    href = "changes.html",      slug = "changes" },
  { title = "Community",  href = "community.html",    slug = "community" },
  { title = "Credits",    href = "credits.html",      slug = "credits" },
  { title = "Sources",    href = "sources.html",      slug = "sources" },
}

local function stringify(v)
  if v == nil then return nil end
  return pandoc.utils.stringify(v)
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function load_chapters()
  local path = "dist/_intermediate/manual/nav-chapters.lua"
  if not file_exists(path) then return {} end
  local ok, result = pcall(dofile, path)
  if not ok or type(result) ~= "table" then return {} end
  return result
end

local function html_escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

function Meta(meta)
  local current_slug = stringify(meta.slug) or ""
  local root = stringify(meta.root) or ""
  local chapters = load_chapters()

  local out = { '<nav class="sidebar-nav" aria-label="Site navigation"><ul>' }
  for _, item in ipairs(nav_items) do
    local is_active = item.slug == current_slug
    local should_expand = item.expand_prefix and
      (current_slug == item.expand_prefix or
       current_slug:sub(1, #item.expand_prefix + 1) == item.expand_prefix .. "/")
    local cls = is_active and ' class="active"' or ''
    out[#out + 1] = string.format('<li%s><a href="%s%s">%s</a>',
      cls, root, item.href, html_escape(item.title))
    if should_expand and #chapters > 0 then
      out[#out + 1] = '<ul>'
      for _, ch in ipairs(chapters) do
        local ch_slug = "manual/" .. ch.slug
        local ch_active = ch_slug == current_slug
        local ch_cls = ch_active and ' class="active"' or ''
        out[#out + 1] = string.format('<li%s><a href="%smanual/%s.html">%s</a></li>',
          ch_cls, root, ch.slug, html_escape(ch.title))
      end
      out[#out + 1] = '</ul>'
    end
    out[#out + 1] = '</li>'
  end
  out[#out + 1] = '</ul></nav>'

  meta.sidebar = pandoc.MetaBlocks({pandoc.RawBlock("html", table.concat(out, "\n"))})

  -- Prev/next links for manual pages. The walk treats the manual landing
  -- page (slug = "manual") as the entry before the first chapter.
  if #chapters > 0 then
    local manual_pages = { { slug = "manual", title = "Manual", href = "manual/index.html" } }
    for _, ch in ipairs(chapters) do
      manual_pages[#manual_pages + 1] = {
        slug = "manual/" .. ch.slug,
        title = ch.title,
        href = "manual/" .. ch.slug .. ".html",
      }
    end

    local current_idx
    for i, p in ipairs(manual_pages) do
      if p.slug == current_slug then current_idx = i; break end
    end

    if current_idx then
      local prev = manual_pages[current_idx - 1]
      local next_ = manual_pages[current_idx + 1]
      if prev then
        meta.prev_url = pandoc.MetaString(root .. prev.href)
        meta.prev_title = pandoc.MetaString(prev.title)
      end
      if next_ then
        meta.next_url = pandoc.MetaString(root .. next_.href)
        meta.next_title = pandoc.MetaString(next_.title)
      end
    end
  end

  return meta
end
