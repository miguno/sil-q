-- Rewrites local `[label](file.md)` and `[label](file.md#anchor)` to .html.
-- Special case: `manual.md` and `manual.md#anchor` resolve into the split
-- manual landing page (the per-chapter anchor resolution happens later in
-- the split-manual pipeline via a heading-id → chapter-slug index).

local function is_external(target)
  return target:match("^https?://")
      or target:match("^//")
      or target:match("^mailto:")
      or target:match("^#")
end

local function load_heading_index()
  local path = "dist/_intermediate/manual/heading-index.lua"
  local f = io.open(path, "r")
  if not f then return {} end
  f:close()
  local ok, result = pcall(dofile, path)
  if not ok or type(result) ~= "table" then return {} end
  return result
end

local heading_index = load_heading_index()

local function rewrite_manual(target)
  -- manual.md#anchor → manual/<chapter>.html#anchor (or fall back to landing)
  local anchor = target:match("^manual%.md#(.+)$")
  if anchor then
    local slug = heading_index[anchor]
    if slug then return "manual/" .. slug .. ".html#" .. anchor end
    return "manual/index.html#" .. anchor
  end
  if target == "manual.md" then return "manual/index.html" end
  return nil
end

function Link(el)
  local target = el.target
  if is_external(target) then return nil end

  local manual = rewrite_manual(target)
  if manual then
    el.target = manual
    return el
  end

  -- generic: file.md[#anchor] → file.html[#anchor]
  local new, n = target:gsub("%.md(#[^#]*)$", ".html%1")
  if n == 0 then
    new = target:gsub("%.md$", ".html")
  end
  if new ~= target then
    el.target = new
    return el
  end
end
