vim.filetype.add({
  extension = {
    khn = "bg3_thoth",
    lsx = "bg3_lsx",
  },
  pattern = {
    [".*/Localization/[^/]+/[^/]+%.xml"] = "bg3_localization",
    [".*/Stats/Generated/.*%.txt"] = "bg3_stats",
    [".*/Story/RawFiles/Goals/.*%.txt"] = "bg3_osiris",
  },
})
