{
  config,
  pkgs,
  vars,
  ...
}:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;

    initLua = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      vim.opt.number = true
      vim.opt.completeopt = { "menu", "menuone", "noselect" }
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2

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

          local msg = "🔒 MANAGED BY HOME-MANAGER — edit source at ${vars.repoPath}/home/"
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
    '';
  };
}
