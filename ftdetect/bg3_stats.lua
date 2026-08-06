vim.filetype.add({
  extension = {
    khn = "bg3_thoth",
    lsx = "bg3_lsx",
  },
  pattern = {
    [".*/Stats/Generated/.*%.txt"] = "bg3_stats",
  },
})
