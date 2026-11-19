-- Compilation only; does not run the Studio installer.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local source = fs.readFile("assets/farming/import-farming.luau")
luau.load(source)
-- Exercise the actual installer's asset declarations against the export manifest.
-- No game services or installation code are run.
local declarations = assert(source:match("(local crops =.-)\nlocal wanted"))
local specs = luau.load(declarations .. "\nreturn specs")()
local manifest = serde.decode("json", fs.readFile("assets/farming/roblox/manifest.json"))
local exported = {}
for _, model in manifest.models do exported[model.id] = model end
assert(#specs == manifest.model_count)
for _, spec in specs do
	local model = assert(exported[spec.id], spec.id)
	local parts = { ["Origin"] = true }
	for _, role in spec.roles do parts[role] = true end
	assert(#model.parts == #spec.roles + 1, spec.id)
	for _, part in model.parts do assert(parts[part.role], spec.id .. ": " .. part.role) end
end
print("Farming installer: compilation passed; all 49 model declarations match exported parts")
