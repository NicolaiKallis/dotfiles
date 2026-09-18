# Debugging HyRAIL firmware from Neovim

Personal notes. Nothing here is in the HyRAIL repo, and nothing here is shared.

## The short version

| Key | Command | What it does |
| --- | --- | --- |
| `<leader>dd` | `:HyRailFlash` | pick node → confirm → `cargo build` → **flash** → debug session |
| `<leader>da` | `:HyRailRtt` | pick node → stream defmt logs. **Reads only.** |
| — | `:HyRailNodes` | list the 20 discovered nodes and whether each is built |

`<leader>dd` is the only thing in this config that writes to hardware, and it
asks first. `<leader>da` attaches to a board that is already running and never
resets, flashes or actuates anything, so it does not ask.

## Why the node list is not hardcoded

`.vscode/launch.json` has a `pickString` input listing the nodes, and
`.vscode/tasks.json` has one `cargo build` task per node. Both were written by
hand and both have drifted:

- `launch.json` offers 11 `stm32h563zi` nodes; the workspace has **17** members.
- `tasks.json` has 13 build tasks; `bolt` has none.
- Neither knows about `gnsu1-4`, `pcdu1-2`.

Nodes appear and disappear when `aurora_model/` is regenerated, so any
hand-written list is wrong by the next generation.

`lua/hyrail/nodes.lua` discovers them instead: a node is any crate directly
under `aurora/nodes/<workspace>/` that has a `src/main.rs`. That test excludes
the `*_common` library crates on its own. **20 found** today. The probe-rs chip
name is the workspace directory uppercased — `stm32h563zi` → `STM32H563ZI`.

## What a launch actually does

1. **Pick** — `vim.ui.select`, with the node owning the current buffer floated
   to the top, so `<CR>` usually picks the right thing.
2. **Confirm** — `Flash <node> to a <chip> over SWD?`, defaulting to **No**.
3. **Build** — `cargo build` in the node's crate directory. No `--target` is
   passed: each node workspace has a `.cargo/config.toml` with
   `build.target = "thumbv8m.main-none-eabihf"`.
   **A failed build aborts here.** The probe is never touched.
4. **Launch** — `probe-rs dap-server --port <port> --single-session`, handed a
   config that mirrors `launch.json` field for field.

`--single-session` matters. Without it probe-rs survives the disconnect, keeps
listening, and leaves an orphan process holding the probe — the next launch then
fails with the probe already in use.

## The launch payload

Ported from `.vscode/launch.json`:

| Field | Value |
| --- | --- |
| `chip` | `STM32H563ZI` / `STM32H563RG`, from the workspace dir |
| `wireProtocol` | `Swd` |
| `speed` | `4000` |
| `flashingConfig.haltAfterReset` | `true` |
| `coreConfigs[0].programBinary` | `aurora/nodes/<ws>/target/thumbv8m.main-none-eabihf/debug/<node>` |
| `coreConfigs[0].svdFile` | `.vscode/STM32H563.svd` |
| `coreConfigs[0].rttChannelFormats[0]` | channel 0, `Defmt`, timestamps on |

`haltAfterReset` is not cosmetic. defmt-rtt is non-blocking, so anything the
firmware logs before the RTT terminal attaches is **dropped, not queued**.
Halting at reset holds the core until the terminal is up. (This is the same
reasoning as the comment in `launch.json`.)

## Debug session keys

| Key | Action |
| --- | --- |
| `<leader>dc` | continue |
| `<leader>di` | step into |
| `<leader>dn` | step over (next) |
| `<leader>dO` | step out |
| `<leader>db` | toggle breakpoint |
| `<leader>dB` | conditional breakpoint |
| `<leader>dx` | clear all breakpoints |
| `<leader>du` | toggle the DAP UI |
| `<leader>dr` | toggle the REPL |
| `<leader>dk` | evaluate expression (works on a visual selection) |
| `<leader>dt` | terminate |
| `<leader>dR` | restart |

The UI opens on `event_initialized` and closes on terminate/exit, so there is
nothing to tidy up by hand.

## Reading logs without flashing

`<leader>da` runs `probe-rs attach --chip <CHIP> <elf>` in a split terminal. It
still needs the ELF, because defmt log strings live in the binary, not in the
RTT stream — the board sends indices, the host resolves them. If the ELF does
not match what is actually flashed you get garbage, so rebuild before attaching
after changing any log line.

## defmt log level

`aurora/nodes/*/.cargo/config.toml` sets a **floor**, not a ceiling:

```toml
[env]
DEFMT_LOG = "trace,embassy_stm32=warn"
```

An already-set environment variable wins, so to quieten a session:

```bash
DEFMT_LOG=info cargo build
```

Rebuild is required — defmt filtering happens at compile time.

## Safety

AGENTS.md §7: hardware is physical, shared, and part of a rocket test stand.

- Nothing here runs on a timer, on save, or on startup.
- `<leader>dd` confirms, and defaults to No.
- A failed `cargo build` aborts before the probe is opened.
- `<leader>da` and `:HyRailNodes` never write to a device.

## When it breaks

**"probe not found"** — `probe-rs list`. On WSL the probe has to be attached to
the WSL VM with `usbipd` first; it is not visible just because Windows sees it.

**"probe already in use"** — an orphaned `dap-server`. `pkill -f 'probe-rs dap-server'`.

**Breakpoints do not bind** — check the ELF is current. `:HyRailNodes` shows
built/not built, but not staleness; when in doubt `<leader>dd` again, it rebuilds.

**No log output at all** — the RTT terminal attached after the firmware logged.
`haltAfterReset` should prevent this on `<leader>dd`; on `<leader>da` it is
expected for anything logged during boot.

**Wrong workspace in the statusline** — the right-hand side shows which cargo
workspace rust-analyzer resolved for the buffer. If it says `aurora` while you
are editing a node, the file is not where you think it is.
