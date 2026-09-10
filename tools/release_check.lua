-- Starfall Vengeance release smoke checklist (documentation-only Lua file).
-- Native LÖVE execution remains a required final gate outside CI.
return {
    engine = "LÖVE 11.5",
    native_archive = "Starfall-Vengeance.love",
    web_entry = "web/index.html",
    modes = {"campaign", "endless", "gauntlet"}
}
