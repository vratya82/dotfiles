-- Rounded borders around the panes
require("full-border"):setup()

-- Bookmarks: persist across sessions; '' jumps to previous folder
require("bookmarks"):setup({
  last_directory = { enable = true, persist = true, mode = "dir" },
  persist        = "all",
  desc_format    = "full",
  file_pick_mode = "hover",
  show_keys      = true,
  notify         = { enable = true, timeout = 1 },
})
