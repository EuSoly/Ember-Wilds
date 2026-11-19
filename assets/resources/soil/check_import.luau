local fs = require("@lune/fs")
local luau = require("@lune/luau")
luau.load(fs.readFile("assets/resources/soil/import-soil.luau"))
print("Soil installer: compilation passed")
