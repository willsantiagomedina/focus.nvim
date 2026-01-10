# focus.nvim

A Neovim plugin that enhances visual focus by dimming inactive windows, helping you maintain concentration without changing your workflow or window layout.

## Features

- **Visual focus without layout changes** - Keeps your window arrangement intact while clearly highlighting your active workspace
- **Zero configuration required** - Works out of the box with sensible defaults
- **Lightweight and fast** - Minimal performance impact, no delays or lag
- **Automatic window tracking** - Seamlessly updates focus as you navigate between windows
- **Customizable highlight colors** - Adjust dimming colors to match your theme and preferences
- **Neovim 0.9+ compatibility** - Built for modern Neovim with stable API support

## Installation

### Using lazy.nvim

Basic installation with default settings:

```lua
{
  'willsantiagomedina/focus.nvim',
  config = function()
    require('focus').setup()
  end
}
```

With custom configuration:

```lua
{
  'willsantiagomedina/focus.nvim',
  config = function()
    require('focus').setup({
      enable_on_startup = false,
      inactive_bg = '#1e1e1e',
      active_bg = 'NONE',
      auto_enable = false,
    })
  end
}
```

## Usage

Toggle focus mode on and off with the `:Focus` command:

```vim
:Focus
```

### Keybinding Example

Add a keybinding to quickly toggle focus mode:

```lua
vim.keymap.set('n', '<leader>f', ':Focus<CR>', { desc = 'Toggle focus mode' })
```

## Configuration

### Default Configuration

```lua
require('focus').setup({
  enable_on_startup = false,  -- Start with focus mode enabled
  inactive_bg = '#1e1e1e',    -- Background color for inactive windows
  active_bg = 'NONE',         -- Background color for active window
  auto_enable = false,        -- Automatically enable focus mode
})
```

### Custom Colors

Adjust the dimming effect to match your colorscheme:

```lua
require('focus').setup({
  inactive_bg = '#2d2d2d',  -- Lighter dim
})
```

Or use a darker dim:

```lua
require('focus').setup({
  inactive_bg = '#0d0d0d',  -- Darker dim
})
```

### Using Custom Highlight Groups

You can also define custom highlight groups instead of using color values directly:

```lua
-- Define custom highlight
vim.api.nvim_set_hl(0, 'MyInactiveBg', { bg = '#1a1a1a' })

require('focus').setup({
  inactive_bg = 'MyInactiveBg',
})
```

## Philosophy

**Invisibility until needed** - focus.nvim stays out of your way until you explicitly enable it. No automatic behavior that might surprise you or interfere with your workflow.

**Preserving user workflow** - Your window layout, splits, and navigation remain unchanged. The plugin only affects visual presentation, not functionality.

**Doing one thing well** - focus.nvim has a singular purpose: helping you visually identify your active window. It doesn't try to manage layouts, resize windows, or handle splits.

**Performance priority** - The plugin is designed to be imperceptible in terms of performance. No background processes, no polling, no delays.

## Requirements

- Neovim >= 0.9.0

## License

MIT
