{ inputs, pkgs, ... }:
{
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true; # sets EDITOR=nvim
    viAlias = true;
    vimAlias = true;

    globals.mapleader = " ";
    globals.maplocalleader = " ";

    # System clipboard on Wayland/niri (pulls wl-clipboard).
    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    opts = {
      number = true;
      relativenumber = true;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartindent = true;
      signcolumn = "yes";
      termguicolors = true;
      ignorecase = true;
      smartcase = true;
      undofile = true;
      scrolloff = 8;
    };

    colorschemes.tokyonight.enable = true;

    plugins = {
      # IDE feel
      telescope.enable = true; # fuzzy finder (uses ripgrep/fd from common.nix)
      neo-tree.enable = true; # file explorer
      lualine.enable = true; # statusline
      bufferline.enable = true;
      which-key.enable = true; # keybinding hints
      gitsigns.enable = true;
      web-devicons.enable = true;

      treesitter = {
        enable = true; # grammars are Nix-built — no runtime compilation
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      # Completion (LazyVim's default engine)
      blink-cmp.enable = true;

      # nvim-lspconfig provides the default server configs (filetypes/root
      # markers) that the native lsp.servers module below enables via vim.lsp.
      lspconfig.enable = true;

      # Format-on-save; dispatches to the Nix-provided formatter binaries.
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            lua = [ "stylua" ];
            nix = [ "nixfmt" ];
            python = [ "ruff_format" ];
            javascript = [ "prettierd" ];
            typescript = [ "prettierd" ];
            javascriptreact = [ "prettierd" ];
            typescriptreact = [ "prettierd" ];
            json = [ "prettierd" ];
            yaml = [ "prettierd" ];
            markdown = [ "prettierd" ];
            sh = [ "shfmt" ];
            go = [ "gofumpt" ];
            rust = [ "rustfmt" ];
            cs = [ "csharpier" ];
          };
          format_on_save = {
            lsp_format = "fallback";
            timeout_ms = 500;
          };
        };
      };

      # Rust: richer than a bare LSP; manages rust-analyzer itself, so rust is
      # deliberately NOT listed under lsp.servers below (would double-configure).
      rustaceanvim.enable = true;
    };

    # LSP via Neovim's native vim.lsp API (nvim 0.11). Each server's binary is
    # pulled from nixpkgs by the module's default package (e.g. gopls ->
    # pkgs.gopls), so the servers don't need to be in home.packages.
    lsp.servers = {
      nixd.enable = true;
      lua_ls.enable = true;
      basedpyright.enable = true; # Python types
      ruff.enable = true; # Python lint/quick-fixes as LSP diagnostics
      vtsls.enable = true;
      bashls.enable = true;
      yamlls.enable = true;
      jsonls.enable = true;
      marksman.enable = true; # markdown
      gopls.enable = true;
      roslyn_ls.enable = true; # C#
    };

    # Buffer-local LSP keymaps (registered when a server attaches).
    lsp.keymaps = [
      {
        key = "gd";
        lspBufAction = "definition";
      }
      {
        key = "gD";
        lspBufAction = "declaration";
      }
      {
        key = "gr";
        lspBufAction = "references";
      }
      {
        key = "gi";
        lspBufAction = "implementation";
      }
      {
        key = "K";
        lspBufAction = "hover";
      }
      {
        key = "<leader>rn";
        lspBufAction = "rename";
      }
      {
        key = "<leader>ca";
        lspBufAction = "code_action";
      }
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
        options.desc = "Live grep";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>Telescope buffers<cr>";
        options.desc = "Buffers";
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "File explorer";
      }
      {
        mode = "n";
        key = "<leader>cf";
        action.__raw = "function() require('conform').format({ async = true, lsp_format = 'fallback' }) end";
        options.desc = "Format buffer";
      }
    ];
  };

  # Formatters + global language toolchains needed at runtime by the servers and
  # formatters above. (LSP server binaries come from the lsp.servers modules.)
  home.packages = with pkgs; [
    # formatters / linters
    stylua
    nixfmt
    ruff
    prettierd
    shfmt
    gofumpt
    csharpier
    # language toolchains (LSPs/formatters need these on PATH)
    go
    rust-analyzer
    cargo
    rustc
    rustfmt
    dotnet-sdk
  ];
}
