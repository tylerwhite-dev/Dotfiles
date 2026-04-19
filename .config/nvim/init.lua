-- options
vim.opt.number = true
vim.opt.relativenumber = true

-- plugins
vim.pack.add {
    'https://github.com/stevearc/oil.nvim',
    'https://github.com/neovim/nvim-lspconfig',
}
-- themes
vim.pack.add {
    'https://github.com/y9san9/y9nika.nvim',
    'https://github.com/vague-theme/vague.nvim'
}

-- current theme
vim.cmd.colorscheme('vague')
