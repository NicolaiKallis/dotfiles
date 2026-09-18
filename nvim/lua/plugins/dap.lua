-- probe-rs debugging for the node firmware.
--
-- A port of .vscode/launch.json: same adapter, same chips, same SVD, same
-- defmt-over-RTT channel. Two differences, both deliberate:
--
--   * The node list is discovered (lua/hyrail/nodes.lua), not hardcoded, so it
--     cannot drift the way launch.json's picker has.
--   * Launching asks for confirmation first. This writes to a board on a rocket
--     test stand (AGENTS.md section 7); it should never happen because a key
--     was fat-fingered. `<leader>da` attaches read-only and does not ask,
--     because it flashes nothing.

local function hyrail_only(fn)
  return function()
    if not require("hyrail").is_hyrail() then
      return vim.notify("Not inside a HyRAIL checkout", vim.log.levels.WARN)
    end
    fn()
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      -- Session control
      { "<leader>dd", desc = "Flash + debug a node" },
      { "<leader>da", desc = "Attach (RTT only, no flash)" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dR", function() require("dap").restart() end, desc = "Restart" },

      -- Breakpoints
      {
        "<leader>db",
        function() require("dap").toggle_breakpoint() end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
            if cond and cond ~= "" then
              require("dap").set_breakpoint(cond)
            end
          end)
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dx",
        function() require("dap").clear_breakpoints() end,
        desc = "Clear breakpoints",
      },

      -- Stepping
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "Step over (next)" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },

      -- Inspection
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      {
        "<leader>dk",
        function() require("dapui").eval(nil, { enter = true }) end,
        mode = { "n", "v" },
        desc = "Evaluate expression",
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local hyrail = require("hyrail")
      local nodes = require("hyrail.nodes")

      dapui.setup({})
      require("nvim-dap-virtual-text").setup({})

      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn" })
      vim.fn.sign_define(
        "DapStopped",
        { text = "", texthl = "DiagnosticInfo", linehl = "CursorLine" }
      )

      dap.listeners.after.event_initialized.dapui = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui = function() dapui.close() end
      dap.listeners.before.event_exited.dapui = function() dapui.close() end

      -- `--single-session` matters: without it probe-rs keeps listening after a
      -- disconnect and nvim-dap leaves an orphan process holding the probe.
      dap.adapters["probe-rs"] = {
        type = "server",
        port = "${port}",
        executable = {
          command = "probe-rs",
          args = { "dap-server", "--port", "${port}", "--single-session" },
        },
      }

      --- The launch payload, mirroring .vscode/launch.json field for field.
      ---@param node hyrail.Node
      local function launch_config(node)
        local root = hyrail.root()
        return {
          name = ("%s (%s)"):format(node.name, node.chip),
          type = "probe-rs",
          request = "launch",
          cwd = root,
          chip = node.chip,
          wireProtocol = "Swd",
          speed = 4000,
          flashingConfig = {
            flashingEnabled = true,
            -- Boot logs are dropped, not queued: defmt-rtt runs non-blocking,
            -- so anything written before the RTT terminal opens is gone.
            -- Halting at reset holds the core until it is.
            haltAfterReset = true,
          },
          coreConfigs = {
            {
              programBinary = node.binary,
              svdFile = root .. "/.vscode/STM32H563.svd",
              rttEnabled = true,
              rttChannelFormats = {
                { channelNumber = 0, dataFormat = "Defmt", showTimestamps = true },
              },
            },
          },
        }
      end

      -- Registered so `:DapContinue` with no session offers the node list too.
      dap.configurations.rust = {}

      local function flash_and_debug()
        nodes.select("Flash and debug which node?", function(node)
          if not node then
            return
          end

          local answer = vim.fn.confirm(
            ("Flash %s to a %s over SWD?\n\nThis writes to hardware."):format(node.name, node.chip),
            "&No\n&Yes",
            1,
            "Question"
          )
          if answer ~= 2 then
            return vim.notify("Cancelled — nothing was written", vim.log.levels.INFO)
          end

          -- launch.json does this with preLaunchTask; nvim-dap has no
          -- equivalent, so build here and abort before touching the probe.
          if not nodes.build(node) then
            return
          end
          dap.run(launch_config(node))
        end)
      end

      --- RTT only: reads the defmt stream off a board that is already running.
      --- No flashing, no reset, no actuation, so no confirmation.
      local function attach_rtt()
        nodes.select("Stream defmt logs from which node?", function(node)
          if not node then
            return
          end
          if vim.uv.fs_stat(node.binary) == nil then
            return vim.notify(
              ("No ELF at %s — build it first (defmt needs it to decode)"):format(node.binary),
              vim.log.levels.ERROR
            )
          end
          vim.cmd("botright split | resize 15")
          vim.fn.termopen({ "probe-rs", "attach", "--chip", node.chip, node.binary }, {
            cwd = node.dir,
          })
          vim.cmd("startinsert")
        end)
      end

      vim.keymap.set(
        "n",
        "<leader>dd",
        hyrail_only(flash_and_debug),
        { desc = "Flash + debug a node" }
      )
      vim.keymap.set(
        "n",
        "<leader>da",
        hyrail_only(attach_rtt),
        { desc = "Attach (RTT only, no flash)" }
      )

      vim.api.nvim_create_user_command("HyRailFlash", hyrail_only(flash_and_debug), {
        desc = "Pick a node, cargo build, flash and start a debug session",
      })
      vim.api.nvim_create_user_command("HyRailRtt", hyrail_only(attach_rtt), {
        desc = "Pick a node and stream its defmt log over RTT (read-only)",
      })
      vim.api.nvim_create_user_command("HyRailNodes", function()
        local lines = {}
        for _, n in ipairs(nodes.all()) do
          table.insert(
            lines,
            ("%-8s %-14s %s"):format(
              n.name,
              n.chip,
              vim.uv.fs_stat(n.binary) and "built" or "not built"
            )
          )
        end
        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end, { desc = "List the discovered node firmware binaries" })
    end,
  },
}
