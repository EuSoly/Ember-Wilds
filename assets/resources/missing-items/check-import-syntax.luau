-- Compile only: does not connect to Studio or execute the installer.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("assets/resources/missing-items/import-roblox.luau")
luau.load(source)
print("Import installer: Luau compilation passed (not executed in Studio)")
