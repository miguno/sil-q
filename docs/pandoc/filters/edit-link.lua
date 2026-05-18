-- Computes a default `edit_url` from `source_path` metadata if the page
-- does not already define one in its frontmatter.

local REPO_PREFIX = "https://github.com/sil-quirk/sil-q/blob/master/docs/"

function Meta(meta)
  if meta.edit_url then return nil end
  local source_path = meta.source_path
  if not source_path then return nil end
  local sp = pandoc.utils.stringify(source_path)
  if sp == "" then return nil end
  meta.edit_url = pandoc.MetaString(REPO_PREFIX .. sp)
  return meta
end
