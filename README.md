# inkscape-figures.nvim

A Neovim plugin for the Inkscape + LaTeX figure workflow.

## What it does

- **Auto-starts the watcher** the first time you open a `.tex` file in a
  session — runs `fig init` + `fig start` in a small terminal at the bottom,
  then jumps back to your editor.
- **`<leader>fe`** — place your cursor on any `\incfig{name}` line and press
  this to open that figure in Inkscape instantly.
- **`:InkscapeEdit`** — same as the keymap, usable from the command line.

## Requirements

- The `inkscape-figures` scripts installed via `install.py`
  (auto-detected from `%USERPROFILE%\inkscape-figures\fig.bat`)
- Neovim 0.8+
- Windows (the watcher uses `fig.bat`)

## Installation (lazy.nvim)

```lua
{
  "mezbah488-ops/inkscape-figures.nvim",
  ft = "tex",
  opts = {},
}
```

## Options (all optional — defaults shown)

```lua
opts = {
  keymap     = "<leader>fe",  -- open figure under cursor in Inkscape
  win_height = 5,             -- height of the watcher terminal (lines)
}
```

## How it fits into the full workflow

```
inkscape-figures/          ← global scripts (install once)
  install.py
  fig.bat
  inkscape_figures.py
  watch_figures.py

my-paper/                  ← your LaTeX project
  main.tex                 ← open this in Neovim
  figures/                 ← SVGs + exported PDFs live here
  start.bat                ← created by fig init (also called auto)
```

1. Open `main.tex` in Neovim → watcher starts automatically.
2. Write `\incfig{diagram}` and save → Inkscape opens with a blank canvas.
3. Draw. Write `$E = mc^2$` in text nodes. Press Ctrl-S.
4. Watcher exports `.pdf` + `.pdf_tex` instantly.
5. Cursor on `\incfig{diagram}`, press `<leader>fe` → Inkscape reopens that figure.
6. Compile LaTeX. Equations render perfectly.
