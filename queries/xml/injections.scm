; extends

; LSX stores Stats-value expressions in selected LSString attributes. Keep
; this list conservative so ordinary names and UI text remain XML strings.
((EmptyElemTag
   (Name) @_element
   (Attribute
     (Name) @_id_key
     (AttValue) @_field)
   (Attribute
     (Name) @_type_key
     (AttValue) @_type)
   (Attribute
     (Name) @_value_key
     (AttValue) @injection.content))
 (#eq? @_element "attribute")
 (#eq? @_id_key "id")
 (#any-of? @_field
   "\"Boosts\""
   "\"BoostsOnEquip\""
   "\"BoostsOnUnequip\""
   "\"ContainerSpells\""
   "\"InterruptPrototype\""
   "\"Passives\""
   "\"PassivesAdded\""
   "\"PassivesOnEquip\""
   "\"PassivesRemoved\""
   "\"PersonalStatusImmunities\""
   "\"Selectors\""
   "\"Spells\""
   "\"StatusImmunities\""
   "\"StatusInInventory\""
   "\"StatusOnEquip\"")
 (#eq? @_type_key "type")
 (#eq? @_type "\"LSString\"")
 (#eq? @_value_key "value")
 (#offset! @injection.content 0 1 0 -1)
 (#set! injection.language "bg3_stats_value"))
