return {
  "echasnovski/mini.surround",
  event = "VeryLazy",
  opts = {
    -- Use gs* prefix to match the "+surround" group already in which-key
    mappings = {
      add = "gsa", -- gsa{motion}{char}  e.g. gsaiw" to surround word with "
      delete = "gsd", -- gsd{char}          e.g. gsd" to delete " surrounds
      replace = "gsr", -- gsr{old}{new}      e.g. gsr"' to change " to '
      find = "gsf", -- find surrounding to the right
      find_left = "gsF", -- find surrounding to the left
      highlight = "gsh", -- highlight surrounding
      update_n_lines = "gsn", -- update search range for surrounding
    },
  },
}
