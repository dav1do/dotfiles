return {
    "ThePrimeagen/harpoon",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()     
      vim.keymap.set("n", "<leader>a", "<cmd>lua require('harpoon.mark').add_file()<cr>")
      vim.keymap.set("n", "<A-e>", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>")
      vim.keymap.set("n", "<leader>hn", "<cmd>lua require('harpoon.ui').nav_next()<cr>", { desc = "Go to next harpoon mark" })
      vim.keymap.set("n", "<leader>hp", "<cmd>lua require('harpoon.ui').nav_prev()<cr>", { desc = "Go to previous harpoon mark" })
      -- vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
      -- vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
      -- vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
      -- vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)
    end,
  }