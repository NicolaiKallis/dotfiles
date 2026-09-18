-- Detection and facts about the HyRAIL repository.
--
-- The rest of the config stays generic: anything in here only applies once a
-- buffer is recognised as living inside a HyRAIL checkout, so this same config
-- behaves like a plain Rust/TypeScript setup everywhere else.

local M = {}

-- Files that only exist together at a HyRAIL root. `aurora_model` alone is not
-- enough (a generated tree could be vendored elsewhere); the flake plus the
-- model plus the framework is.
local MARKERS = { "aurora_model", "framework", "flake.nix", "rust-toolchain.toml" }

local cache = {}

--- Repository root for `path`, or nil if it is not inside a HyRAIL checkout.
---@param path string|nil defaults to the current buffer's file, then cwd
---@return string|nil
function M.root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.uv.cwd()
  end
  -- :p first — a buffer opened as `nvim aurora/types/src/lib.rs` has a
  -- relative name, and every comparison below (and is_protected's equality
  -- test) needs both sides absolute.
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))

  local hit = cache[path]
  if hit ~= nil then
    return hit or nil
  end

  local found = vim.fs.find(MARKERS[1], { path = path, upward = true, type = "directory" })[1]
  local root = found and vim.fs.dirname(found) or nil
  if root then
    for _, marker in ipairs(MARKERS) do
      if vim.uv.fs_stat(root .. "/" .. marker) == nil then
        root = nil
        break
      end
    end
  end

  cache[path] = root or false
  return root
end

---@return boolean
function M.is_hyrail(path) return M.root(path) ~= nil end

-- Never hand-edit these (AGENTS.md section 5): they are the three-way merge
-- machinery, and an edit corrupts the next regeneration. Paths are relative to
-- the repository root.
M.PROTECTED = {
  "aurora/.hyrail/base.gz",
  "aurora/.hyrail/manifest.json",
  "aurora_model/stable-ids.json",
}

--- True if `path` is one of the generator-owned files that must not be edited.
function M.is_protected(path)
  local root = M.root(path)
  if not root then
    return false
  end
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  for _, rel in ipairs(M.PROTECTED) do
    if path == root .. "/" .. rel then
      return true
    end
  end
  return false
end

-- Directories that no picker, grep or LSP should walk into. `.direnv` is the
-- nix profile symlink farm and `framework/vendor` is a patched embassy copy —
-- both are large and neither is edited here.
M.IGNORE = {
  "%.git/",
  "%.direnv/",
  "node_modules/",
  "/target/",
  "^target/",
  "%.hyrail/",
  "dist/",
}

return M
