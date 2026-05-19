---@class PLSA.RiskObject: Node
PLSA.RiskObject = Node:extend()
function PLSA.RiskObject:init(key)
	self.center = key and G.P_CENTERS[key] or {}
	self.ability = next(self.center) and copy_table(self.center.config) or {}
end

function PLSA.RiskObject:calculate(context)
	if self.center.risk_calculate and type(self.center.risk_calculate) == "function" and (G.GAME.blind_on_deck == 'Boss' or self.center.can_calculate_outside_of_boss) then
		return self.center:risk_calculate(self, context)
	end
end

function PLSA.RiskObject:save()
	local tbl = {
		ability = self.ability
	}
	for _, v in ipairs(G.P_CENTER_POOLS.Risk) do
		if v and v.key == self.center.key then
			tbl.config_name = v.key
		end
	end

	return tbl
end

function PLSA.RiskObject:load(tbl)
	self.center = G.P_CENTERS[tbl.config_name]
	self.ability = tbl.ability
end

SMODS.ConsumableType {
	key = 'Risk',
	collection_rows = { 5, 6 },
	primary_colour = HEX('ea7d48'),
	secondary_colour = HEX('ba3972'),
	shop_rate = 0,
	loc_txt = {},
	default = 'c_plsa_crime'
}

SMODS.UndiscoveredSprite {
	key = 'Risk',
	atlas = 'risk',
	path = 'risk.png',
	pos = { x = 0, y = 6 },
	px = 71, py = 95,
}

G.C.SET.Risk = HEX('ea7d48')
G.C.SECONDARY_SET.Risk = HEX('ba3972')

-- Add hooks to run starts and calculate
PLSA.HookGameGlobals(function(run_start)
	if not run_start then return end
	---@type PLSA.RiskObject[]
	G.GAME.plsa_risks_active = {}
end)

PLSA.HookCalculate(function(self, context)
	local effects = {}
	for _, risk in ipairs(G.GAME.plsa_risks_active) do
		local r = risk:calculate(context)
		if r and type(r) == "table" then SMODS.merge_effects(effects, r) end
	end
	if context.ante_end then
		-- TODO: Handle rewards ....
		G.GAME.plsa_risks_active = {}
	end
	if next(effects) then
		return effects
	end
end)

---@class PLSA.Risk: SMODS.Consumable
---@field risk_calculate? fun(self: PLSA.Risk|table, risk: PLSA.RiskObject|table, context: CalcContext|table): table?, boolean?  Calculates effects based on parameters in `context`. See [SMODS calculation](https://github.com/Steamodded/smods/wiki/calculate_functions) docs for details.
---@field can_calculate_outside_of_boss? boolean Determines if the Risk card's `risk_calculate` can run outside of a boss blind
---@overload fun(self: PLSA.Risk): PLSA.Risk
PLSA.Risk = SMODS.Consumable:extend {
	set = "Risk",
	config = { extra = {} },
	tier = 1,
	use = function(self, card, area, copier)
		G.GAME.plsa_risks_active[#G.GAME.plsa_risks_active + 1] = PLSA.RiskObject(self.key)

		local top_dynatext = nil
		local bot_dynatext = nil

		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 0.4,
			func = function()
				top_dynatext = DynaText({
					string = localize { type = 'name_text', set = self.set, key = self.key },
					colours = { G.C.WHITE },
					rotate = 1,
					shadow = true,
					bump = true,
					float = true,
					scale = 0.9,
					pop_in = 0.6 /
						G.SPEEDFACTOR,
					pop_in_rate = 1.5 * G.SPEEDFACTOR
				})
				bot_dynatext = DynaText({
					string = "Applied!",
					colours = { G.C.WHITE },
					rotate = 2,
					shadow = true,
					bump = true,
					float = true,
					scale = 0.9,
					pop_in = 1.4 /
						G.SPEEDFACTOR,
					pop_in_rate = 1.5 * G.SPEEDFACTOR,
					pitch_shift = 0.25
				})
				card:juice_up(0.3, 0.5)
				play_sound('card1')
				play_sound('coin1')
				card.children.top_disp = UIBox {
					definition = { n = G.UIT.ROOT, config = { align = 'tm', r = 0.15, colour = G.C.CLEAR, padding = 0.15 }, nodes = {
						{ n = G.UIT.O, config = { object = top_dynatext } }
					} },
					config = { align = "tm", offset = { x = 0, y = 0 }, parent = card }
				}
				card.children.bot_disp = UIBox {
					definition = { n = G.UIT.ROOT, config = { align = 'tm', r = 0.15, colour = G.C.CLEAR, padding = 0.15 }, nodes = {
						{ n = G.UIT.O, config = { object = bot_dynatext } }
					} },
					config = { align = "bm", offset = { x = 0, y = 0 }, parent = card }
				}
				return true
			end
		}))
		delay(0.6)

		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 2.6,
			func = function()
				top_dynatext:pop_out(4)
				bot_dynatext:pop_out(4)
				card:start_dissolve()
				return true
			end
		}))

		G.E_MANAGER:add_event(Event({
			trigger = 'after',
			delay = 0.5,
			func = function()
				card.children.top_disp:remove()
				card.children.top_disp = nil
				card.children.bot_disp:remove()
				card.children.bot_disp = nil
				return true
			end
		}))
	end,
	can_use = function(self, card)
		return G.STATE == G.STATES.BLIND_SELECT or booster_obj or G.STATE == G.STATES.SHOP
	end,
	draw = function(self, card, layer)
		card.children.center:draw_shader('booster', nil, card.ARGS.send_to_shader)
	end,
}

PLSA.Risk {
	key = "crime",
	atlas = "risk",
	pos = { x = 0, y = 1 },
	config = { extra = { hand_neg = 1 } },
	tier = 2,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			G.hand:change_size(-risk.ability.extra.hand_neg)
		end
		if context.end_of_round and context.main_eval and not context.repetition then
			G.hand:change_size(risk.ability.extra.hand_neg)
		end
	end,
	loc_vars = function(self, info_queue, card)
		return {
			vars = { card.ability.extra.hand_neg }
		}
	end
}

PLSA.Risk {
	key = 'doubledown',
	atlas = "risk",
	pos = { x = 1, y = 1 },
	tier = 2,
	risk_calculate = function(self, risk, context)
		if context.hand_drawn and not risk.ability.done then
			G.E_MANAGER:add_event(Event {
				func = function(n)
					SMODS.mod_blind_size({ mult = 2, card = G.GAME.blind, effect = {} })
					return true
				end
			})
			risk.ability.done = true
		end
	end
}
