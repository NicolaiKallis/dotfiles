-- nvim-treesitter `master` on Neovim 0.12.
--
-- Neovim 0.11 changed query predicate and directive handlers so that a match
-- maps a capture id to a *list* of nodes (`table<integer, TSNode[]>`) rather
-- than a single `TSNode`. Core offered `opts.all = false` as a shim, and
-- nvim-treesitter master still asks for it:
--
--     local opts = vim.fn.has "nvim-0.10" == 1 and { force = true, all = false } or true
--
-- Neovim 0.12 dropped that shim, so every one of these handlers now receives a
-- list where it expects a node. The visible symptom is opening any Markdown
-- file with a fenced code block:
--
--     ...treesitter.lua:196: attempt to call method 'range' (a nil value)
--
-- because `get_node_text` is handed a table. Six handlers are affected:
-- `nth?`, `is?`, `kind-eq?`, `set-lang-from-mimetype!`,
-- `set-lang-from-info-string!` and `downcase!`.
--
-- Re-registering them here with `force = true` is a workaround, not a fix.
-- master is frozen for Neovim 0.11 by upstream's own support policy; the real
-- answer is the `main` branch, which needs `tree-sitter-cli` on PATH.
--
-- Must be required AFTER nvim-treesitter has registered its own versions.

local query = require("vim.treesitter.query")

--- First node of a capture, whichever API shape the match uses.
local function first(match, id)
  local v = match[id]
  if v == nil then
    return nil
  end
  if type(v) == "table" and v[1] ~= nil and getmetatable(v) == nil then
    return v[1]
  end
  return v
end

local force = { force = true }

-- Mirrors nvim-treesitter's tables; kept local so this file does not depend on
-- the plugin's internals staying importable.
local SCRIPT_TYPE_LANGUAGES = {
  ["importmap"] = "json",
  ["module"] = "javascript",
  ["application/ecmascript"] = "javascript",
  ["text/ecmascript"] = "javascript",
}

local ALIASES = {
  ex = "elixir",
  pl = "perl",
  sh = "bash",
  uxn = "uxntal",
  ts = "typescript",
}

local function parser_from_info_string(alias)
  if ALIASES[alias] then
    return ALIASES[alias]
  end
  local m = vim.filetype.match({ filename = "a." .. alias })
  return m or alias
end

query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
  local node = first(match, pred[2])
  if not node then
    return
  end
  local alias = vim.treesitter.get_node_text(node, bufnr):lower()
  metadata["injection.language"] = parser_from_info_string(alias)
end, force)

query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
  local node = first(match, pred[2])
  if not node then
    return
  end
  local value = vim.treesitter.get_node_text(node, bufnr)
  local configured = SCRIPT_TYPE_LANGUAGES[value]
  if configured then
    metadata["injection.language"] = configured
  else
    local parts = vim.split(value, "/", {})
    metadata["injection.language"] = parts[#parts]
  end
end, force)

query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
  local id = pred[2]
  local node = first(match, id)
  if not node then
    return
  end
  local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
  metadata[id] = metadata[id] or {}
  metadata[id].text = text:lower()
end, force)

query.add_predicate("nth?", function(match, _, _, pred)
  local node = first(match, pred[2])
  local n = tonumber(pred[3])
  if not (node and n) then
    return false
  end
  local parent = node:parent()
  if not parent then
    return false
  end
  for i = 0, parent:named_child_count() - 1 do
    if parent:named_child(i) == node then
      return i == n
    end
  end
  return false
end, force)

query.add_predicate("is?", function(match, _, bufnr, pred)
  local node = first(match, pred[2])
  if not node then
    return false
  end
  local types = { unpack(pred, 3) }
  local _ = bufnr
  return vim.tbl_contains(types, node:type())
end, force)

query.add_predicate("kind-eq?", function(match, _, _, pred)
  local node = first(match, pred[2])
  if not node then
    return false
  end
  local types = { unpack(pred, 3) }
  return vim.tbl_contains(types, node:type())
end, force)
