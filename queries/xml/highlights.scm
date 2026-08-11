; extends

; Localization text escapes inline LSTag delimiters as XML entities. Limit
; concealment to content values so unrelated XML keeps its literal source view.
((element
   (STag (Name) @_content_list)
   (content
     (element
       (STag (Name) @_content)
       (content (EntityRef) @conceal))))
 (#eq? @_content_list "contentList")
 (#eq? @_content "content")
 (#eq? @conceal "&lt;")
 (#set! conceal "<"))

((element
   (STag (Name) @_content_list)
   (content
     (element
       (STag (Name) @_content)
       (content (EntityRef) @conceal))))
 (#eq? @_content_list "contentList")
 (#eq? @_content "content")
 (#eq? @conceal "&gt;")
 (#set! conceal ">"))
