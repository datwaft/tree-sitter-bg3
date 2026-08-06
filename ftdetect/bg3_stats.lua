vim.filetype.add({
  extension = {
    lsx = "bg3_lsx",
  },
  pattern = {
    [".*/Stats/Generated/.*%.txt"] = "bg3_stats",
  },
})
