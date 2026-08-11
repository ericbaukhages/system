vim.g.mapleader = " "
vim.g.maplocalleader = [[\]]

vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.undofile = true

vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.expandtab = false
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.mouse = "a"

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.opt.scrolloff = 2

vim.opt.completeopt = { "menu", "menuone", "fuzzy" }
vim.opt.shortmess:append("c")
vim.opt.pumheight = 10

-- vim-flagship
vim.opt.laststatus = 2
vim.opt.showtabline = 2

vim.lsp.config("nixd", {
	cmd = { "nixd" },
	filetypes = { "nix" },
	settings = {
		nixd = {
			formatting = {
				command = { "nixfmt" },
			},
		},
	},
})

vim.lsp.enable("nixd")

vim.lsp.config("ts_ls", {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
	},
	root_markers = { "package.json", "tsconfig.json", ".git" },
})

vim.lsp.enable("ts_ls")

vim.lsp.config("html", {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = { "html" },
})

vim.lsp.enable("html")

vim.lsp.config("cssls", {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
})

vim.lsp.enable("cssls")

vim.lsp.config("jsonls", {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
})

vim.lsp.enable("jsonls")

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = false })
		end
	end,
})

vim.diagnostic.config({
	virtual_text = true,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = os.getenv("HOME") .. "/*",
	callback = function(args)
		local real = vim.fn.resolve(args.file)
		if not real:match("^/nix/store/") then
			return
		end

		local msg = "🔒 MANAGED BY HOME-MANAGER — edit source at @repoPath@/home/"
		local lines = vim.api.nvim_buf_get_lines(0, 0, 1, false)
		if lines[1] == msg then
			return
		end

		vim.bo.modifiable = true
		vim.api.nvim_buf_set_lines(0, 0, 0, false, { msg, "" })
		vim.bo.modifiable = false
		vim.bo.readonly = true
	end,
})

vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Only use <C-a>; <C-e> already works as <End>
vim.keymap.set("c", "<C-a>", "<Home>", {})
