local M = {}

-- ── Default config ────────────────────────────────────────────────────────────
M.config = {
	keymap = "<leader>fe", -- keymap to open figure under cursor
	win_height = 5, -- height of the watcher terminal (lines)
}

-- ── Internal state ────────────────────────────────────────────────────────────
local watcher_started = false -- only start once per Neovim session

-- ── Resolve fig.bat path ──────────────────────────────────────────────────────
local function fig_path()
	local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
	return home .. "\\inkscape-figures\\fig.bat"
end

-- ── Extract \incfig{name} from current line ───────────────────────────────────
local function get_incfig_name()
	local line = vim.api.nvim_get_current_line()
	-- Match \incfig[optional width]{name} or \incfig{name}
	-- Try with optional [...] arg first, then plain
	return line:match("\\incfig%[.-%]%{(.-)%}") or line:match("\\incfig%{(.-)%}")
end

-- ── Open figure under cursor in Inkscape ─────────────────────────────────────
local function edit_figure()
	local name = get_incfig_name()
	if not name or name == "" then
		vim.notify("inkscape-figures: no \\incfig{} on this line.", vim.log.levels.WARN)
		return
	end
	local fig = fig_path()

	-- Use jobstart for reliable non-blocking process spawning on Windows.
	-- We call fig.bat via cmd /c so the batch file runs and exits cleanly.
	local job = vim.fn.jobstart(
		{ "cmd", "/c", "call", fig, "edit", name },
		{ detach = true } -- detach so Inkscape outlives the job handle
	)

	if job > 0 then
		vim.notify(string.format("inkscape-figures: opened '%s'", name), vim.log.levels.INFO)
	else
		vim.notify("inkscape-figures: failed — is fig.bat at " .. fig .. "?", vim.log.levels.ERROR)
	end
end

-- ── Start watcher terminal (once per session) ─────────────────────────────────
local function start_watcher()
	if watcher_started then
		return
	end
	watcher_started = true

	local fig = fig_path()
	local dir = vim.fn.expand("%:p:h")

	if vim.fn.filereadable(fig) == 0 then
		return
	end

	os.execute(
		string.format("start powershell -Command \"cd '%s'; fig init; fig start; Start-Sleep -Milliseconds 300\"", dir)
	)
end

-- ── Buffer-local setup (keymaps) ─────────────────────────────────────────────
local function setup_buf()
	vim.keymap.set("n", M.config.keymap, edit_figure, {
		buffer = true,
		desc = "inkscape-figures: edit \\incfig{} under cursor in Inkscape",
		silent = true,
	})
end

-- ── Public setup() ────────────────────────────────────────────────────────────
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	local augroup = vim.api.nvim_create_augroup("InkscapeFigures", { clear = true })

	-- On opening any .tex file:
	--   1. Start the watcher terminal (once per session)
	--   2. Set up buffer-local keymap
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = "*.tex",
		callback = function()
			start_watcher()
			setup_buf()
		end,
	})

	-- Also apply keymap when filetype is set (handles new/unnamed buffers)
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = "tex",
		callback = setup_buf,
	})

	-- User command — works from cmdline regardless of filetype
	vim.api.nvim_create_user_command("InkscapeEdit", edit_figure, {
		desc = "Edit the \\incfig{} figure on the current line in Inkscape",
	})
	-- Closing the watchers silently
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		once = true,
		callback = function()
			os.execute('start powershell -Command "fig stop"')
		end,
	})
end

return M
