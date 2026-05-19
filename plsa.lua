PLSA = SMODS.current_mod

-- Loads all files in a folder...
function PLSA.LoadFolder(path)
	local files = SMODS.NFS.getDirectoryItemsInfo(PLSA.path .. "/" .. path)
	for i = 1, #files do
		local file_name = files[i].name
		if file_name:sub(-4) == ".lua" then
			assert(SMODS.load_file(path .. file_name))()
		end
	end
end

-- Object atlases
SMODS.Atlas { key = "risk", path = "consumables/risk.png", px = 71, py = 95 }
SMODS.Atlas { key = "reward", path = "consumables/reward.png", px = 71, py = 95 }

-- Various other things...
local rgs_hooks = {}
function PLSA.HookGameGlobals(func)
	rgs_hooks[#rgs_hooks + 1] = func
end

local calculate_hooks = {}
---@param func fun(self: Mod, context: CalcContext): table?
function PLSA.HookCalculate(func)
	calculate_hooks[#calculate_hooks + 1] = func
end

PLSA.reset_game_globals = function(run_start)
	for _, hook in ipairs(rgs_hooks) do
		hook(run_start)
	end
end

PLSA.calculate = function(self, context)
	local effects = {}
	for _, hook in ipairs(calculate_hooks) do
		local r = hook(self, context)
		if r and type(r) == "table" then SMODS.merge_effects(effects, r) end
	end
	if next(effects) then
		return effects
	end
end

PLSA.LoadFolder("content/consumables/")
