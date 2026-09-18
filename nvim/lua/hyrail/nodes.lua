-- Node firmware binaries, discovered rather than listed.
--
-- .vscode/launch.json hardcodes its node picker and .vscode/tasks.json
-- hardcodes one build task per node, and both have already drifted: the picker
-- offers 11 ZI nodes and there are 17 workspace members, `bolt` has no build
-- task at all. Since nodes appear and disappear with the model, anything
-- hand-listed is wrong by the next regeneration.
--
-- A node binary is a crate directly under aurora/nodes/<workspace>/ that has a
-- src/main.rs. The `*_common` members are libraries and are skipped by that
-- test on their own.

local hyrail = require("hyrail")

local M = {}

---@class hyrail.Node
---@field name string      crate name, e.g. "aci"
---@field workspace string node workspace dir name, e.g. "stm32h563zi"
---@field chip string      probe-rs chip name, e.g. "STM32H563ZI"
---@field dir string       absolute path to the crate
---@field binary string    absolute path to the built ELF

local TARGET = "thumbv8m.main-none-eabihf"

--- Every flashable node in the repository, sorted by workspace then name.
---@return hyrail.Node[]
function M.all()
  local root = hyrail.root()
  if not root then
    return {}
  end

  local nodes = {}
  local nodes_dir = root .. "/aurora/nodes"
  for ws, ws_type in vim.fs.dir(nodes_dir) do
    if ws_type == "directory" and ws:sub(1, 1) ~= "." then
      local ws_path = nodes_dir .. "/" .. ws
      for crate, crate_type in vim.fs.dir(ws_path) do
        local dir = ws_path .. "/" .. crate
        if crate_type == "directory" and vim.uv.fs_stat(dir .. "/src/main.rs") then
          table.insert(nodes, {
            name = crate,
            workspace = ws,
            -- The directory is named after the part, so the probe-rs chip
            -- name is just its uppercase form: stm32h563zi -> STM32H563ZI.
            chip = ws:upper(),
            dir = dir,
            binary = ("%s/target/%s/debug/%s"):format(ws_path, TARGET, crate),
          })
        end
      end
    end
  end

  table.sort(nodes, function(a, b)
    if a.workspace ~= b.workspace then
      return a.workspace < b.workspace
    end
    return a.name < b.name
  end)
  return nodes
end

--- The node owning `path`, if it is inside one. Used to default the picker to
--- whatever you are currently looking at.
---@param path string|nil
---@return hyrail.Node|nil
function M.containing(path)
  path = vim.fs.normalize(vim.fn.fnamemodify(path or vim.api.nvim_buf_get_name(0), ":p"))
  for _, node in ipairs(M.all()) do
    if path:sub(1, #node.dir + 1) == node.dir .. "/" then
      return node
    end
  end
  return nil
end

--- Pick a node, defaulting to the one the current buffer belongs to.
---@param prompt string
---@param on_choice fun(node: hyrail.Node|nil)
function M.select(prompt, on_choice)
  local nodes = M.all()
  if #nodes == 0 then
    vim.notify("No node binaries found under aurora/nodes/", vim.log.levels.ERROR)
    return on_choice(nil)
  end

  local current = M.containing()
  if current then
    -- Float the current node to the top so <CR> picks the obvious thing.
    for i, n in ipairs(nodes) do
      if n.dir == current.dir then
        table.remove(nodes, i)
        table.insert(nodes, 1, n)
        break
      end
    end
  end

  vim.ui.select(nodes, {
    prompt = prompt,
    format_item = function(n)
      return ("%-8s %s%s"):format(
        n.name,
        n.chip,
        n.dir == (current or {}).dir and "  (current)" or ""
      )
    end,
  }, on_choice)
end

--- `cargo build` for one node, synchronously. The node workspaces carry a
--- .cargo/config.toml with build.target, so no --target is needed here.
---@param node hyrail.Node
---@return boolean ok
function M.build(node)
  vim.notify(("cargo build: %s (%s)"):format(node.name, node.chip), vim.log.levels.INFO)
  local res = vim.system({ "cargo", "build" }, { cwd = node.dir, text = true }):wait()
  if res.code ~= 0 then
    vim.notify(
      ("cargo build failed for %s\n%s"):format(node.name, res.stderr or ""),
      vim.log.levels.ERROR
    )
    return false
  end
  if vim.uv.fs_stat(node.binary) == nil then
    vim.notify("build succeeded but no ELF at " .. node.binary, vim.log.levels.ERROR)
    return false
  end
  return true
end

return M
