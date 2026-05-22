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
SMODS.Atlas { key = "blinds", path = "blinders.png", px = 34, py = 34, atlas_table = 'ANIMATION_ATLAS', frames = 21 }
SMODS.Atlas { key = "risk", path = "consumables/risk.png", px = 71, py = 95 }
SMODS.Atlas { key = "reward", path = "consumables/reward.png", px = 71, py = 95 }

-- Various other things...
local rgs_hooks = {}
---@param func fun(run_start: boolean)
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

function PLSA.ShallowCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function PLSA.Filter(orig, filter)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for _, orig_value in pairs(orig) do
			if filter(orig_value) then goto continue end
			copy[#copy + 1] = orig_value
			::continue::
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

-- Blind related
function PLSA.RecreateBossBlindSelect()
	if G.blind_select_opts and G.blind_select_opts.boss then
		local par = G.blind_select_opts.boss.parent

		G.blind_select_opts.boss:remove()
		G.blind_select_opts.boss = UIBox {
			T = { par.T.x, 0, 0, 0, },
			definition =
			{ n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR }, nodes = {
				UIBox_dyn_container({ create_UIBox_blind_choice('Boss') }, false, get_blind_main_colour('Boss'), mix_colours(G.C.BLACK, get_blind_main_colour('Boss'), 0.8))
			} },
			config = { align = "bmi",
				offset = { x = 0, y = G.ROOM.T.y + 9 },
				major = par,
				xy_bond = 'Weak'
			}
		}
		par.config.object = G.blind_select_opts.boss
		par.config.object:recalculate()
		G.blind_select_opts.boss.parent = par
		G.blind_select_opts.boss.alignment.offset.y = 0
	end
end

---Changes the upcoming boss.
---@param blind string The blind key to replace the current boss.
---@param force boolean? Whether to force the blind key to be set regardless of Prelude or Cast conditions.
---@param silent boolean? Whether to change the actual blind select box or not.
function PLSA.ChangeUpcomingBoss(blind, force, silent)
	local function changeBlind()
		if not force then
			if G.GAME.round_resets.last_cast_boss then
				G.GAME.round_resets.last_cast_boss = blind
				G.GAME.plsa_merged_boss_keys[2] = G.GAME.round_resets.last_cast_boss
			elseif G.GAME.plsa_prelude_next_blind then
				G.GAME.plsa_prelude_next_blind = blind
			else
				G.GAME.round_resets.blind_choices.Boss = blind
			end
		else
			G.GAME.round_resets.blind_choices.Boss = blind
		end
	end

	if silent then
		changeBlind()
		return
	end

	-- for some reason the game restores the state of the last boss blind to current
	local old_state = G.GAME.round_resets.blind_states[G.GAME.blind_on_deck]
	G.E_MANAGER:add_event(Event {
		func = function()
			G.E_MANAGER:add_event(Event {
				trigger = 'after',
				delay = 0.2,
				func = function()
					G.GAME.round_resets.blind_states[G.GAME.blind_on_deck] = old_state
					return true
				end
			})

			changeBlind()

			PLSA.RecreateBossBlindSelect()
			return true
		end
	})
	G.GAME.plsa_cannot_reroll = true
end

PLSA.LoadFolder("content/consumables/")
PLSA.LoadFolder("content/blinds/")
PLSA.LoadFolder("content/blinds/showdown/")
