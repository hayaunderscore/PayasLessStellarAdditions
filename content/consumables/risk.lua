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
	-- Reset counters for stuff like Shrink
	G.GAME.plsa_shrink_count = 0
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
---@field tier 1|2|3|nil The tier of this Risk card, from 1 to 3.
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
	key = "hinder",
	atlas = "risk",
	pos = { x = 0, y = 0 },
	config = { extra = { debuff = 10 } },
	tier = 1,
	loc_vars = function(self, info_queue, card)
		return {
			vars = { card.ability.extra.debuff }
		}
	end,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			-- Initial setup...
			local hinderable_cards = PLSA.ShallowCopy(G.deck.cards)
			hinderable_cards = PLSA.Filter(hinderable_cards,
				function(v) return v.ability.plsa_hindered end)
			local hindered_cards = {}
			local count = math.min(risk.ability.extra.debuff, #hinderable_cards)
			while count > 0 do
				---@type Card
				local c = table.remove(hinderable_cards,
					pseudorandom('plsa_hinder_' .. G.GAME.round_resets.ante, 1, #hinderable_cards))
				if c then hindered_cards[#hindered_cards + 1] = c end
				if c.ability.debuff_sources and c.ability.debuff_sources["plsa_risk_hinder"] then goto continue end
				count = count - 1
				::continue::
			end

			for i = 1, #hindered_cards do
				---@type Card
				local c = hindered_cards[i]
				draw_card(G.deck, G.hand, i * 100 / #hindered_cards, 'up', false, c, nil, nil)
			end
			delay(0.4)
			for i = 1, #hindered_cards do
				---@type Card
				local c = hindered_cards[i]
				c.ability.plsa_hindered = true
				G.E_MANAGER:add_event(Event {
					trigger = 'after',
					delay = 0.15,
					func = function()
						c:juice_up()
						play_sound('timpani')
						c.ability.plsa_hindered = false
						SMODS.debuff_card(c, true, 'plsa_risk_hinder')
						return true
					end
				})
			end
			delay(0.4)
			for i = 1, #hindered_cards do
				---@type Card
				local c = hindered_cards[i]
				draw_card(G.hand, G.deck, i * 100 / #hindered_cards, 'down', true, c, nil, nil)
			end
		end
	end
}

PLSA.Risk {
	key = "hollow",
	atlas = "risk",
	pos = { x = 1, y = 0 },
	tier = 1,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			for _, card in ipairs(G.consumeables) do
				SMODS.debuff_card(card, true, "plsa_hollow")
			end
		end
		if context.end_of_round and context.main_eval then
			for _, card in ipairs(G.consumeables) do
				SMODS.debuff_card(card, false, "plsa_hollow")
			end
		end
	end,
}

PLSA.Risk {
	key = "leak",
	atlas = "risk",
	pos = { x = 2, y = 0 },
	tier = 1,
	config = { extra = { money = 1 } },
	risk_calculate = function(self, risk, context)
		if context.before then
			for _, card in ipairs(context.scoring_hand) do
				G.E_MANAGER:add_event(Event {
					trigger = 'after',
					delay = 0.15,
					func = function()
						card:juice_up()
						ease_dollars(-risk.ability.extra.money, true)
						return true
					end
				})
			end
		end
	end,
	loc_vars = function(self, info_queue, card)
		return {
			vars = { card.ability.extra.money }
		}
	end
}

PLSA.Risk {
	key = "shrink",
	atlas = "risk",
	pos = { x = 3, y = 0 },
	tier = 1,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			-- Yes, this means it stacks now...
			G.GAME.plsa_shrink_count = G.GAME.plsa_shrink_count + 1
		end
		if context.end_of_round and context.main_eval then
			G.GAME.plsa_shrink_count = G.GAME.plsa_shrink_count - 1
			if G.GAME.plsa_shrink_count < 0 then G.GAME.plsa_shrink_count = 0 end
		end
	end
}

-- Hook to get_chip_bonus
local oldgcb = Card.get_chip_bonus
function Card:get_chip_bonus()
	if self.ability.plsa_stunted then
		return (self.base.nominal + (self.ability.perma_bonus or 0)) / (2 ^ (G.GAME.plsa_shrink_count or 0))
	end
	return (oldgcb(self) or 0) / (2 ^ (G.GAME.plsa_shrink_count or 0))
end

PLSA.Risk {
	key = "genesis",
	atlas = "risk",
	pos = { x = 4, y = 0 },
	config = { extra = { cards = 7 } },
	tier = 1,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			for _ = 1, risk.ability.extra.cards do
				---@type Card
				local c = SMODS.add_card { area = G.hand, set = 'Base', skip_materialize = true }
				c.states.visible = false
				G.E_MANAGER:add_event(Event {
					trigger = 'after',
					delay = 0.2,
					func = function()
						c.states.visible = true
						c:start_materialize({ G.C.SET.Risk })
						SMODS.recalc_debuff(c)
						return true
					end
				})
			end
			delay(0.6)
			for i = 1, risk.ability.extra.cards do
				---@type Card
				local c = G.hand[i]
				draw_card(G.hand, G.deck, i * 100 / risk.ability.extra.cards, 'down', true, c, nil, nil)
			end
		end
	end,
	loc_vars = function(self, info_queue, card)
		return {
			vars = { card.ability.extra.cards }
		}
	end
}

PLSA.Risk {
	key = "burden",
	atlas = "risk",
	pos = { x = 5, y = 0 },
	tier = 1,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			---@type Card|nil
			local joker = pseudorandom_element(G.jokers.cards, pseudoseed('plsa_burden_' .. G.GAME.round_resets.ante))
			if joker then
				joker:set_eternal(true)
				joker:juice_up()
			end
		end
	end
}

PLSA.Risk {
	key = "ethereal",
	atlas = "risk",
	pos = { x = 6, y = 0 },
	tier = 1,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			---@type Card|nil
			local joker = pseudorandom_element(G.jokers.cards, pseudoseed('plsa_burden_' .. G.GAME.round_resets.ante))
			if joker then
				joker:set_perishable(true)
				joker:juice_up()
			end
		end
	end
}

PLSA.Risk {
	key = "cyclone",
	atlas = "risk",
	pos = { x = 7, y = 0 },
	tier = 1,
	risk_calculate = function(self, risk, context)
		if context.after then
			G.E_MANAGER:add_event(Event {
				func = function()
					G.FUNCS.draw_from_hand_to_deck(nil)
					return true
				end
			})
		end
	end
}

PLSA.Risk {
	key = "perpetuate",
	atlas = "risk",
	pos = { x = 8, y = 0 },
	tier = 1,
	risk_calculate = function(self, risk, context)
		if context.setting_blind then
			G.GAME.plsa_perpetuate = true
		end
		if context.end_of_round and context.main_eval then
			G.GAME.plsa_perpetuate = nil
		end
	end
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

PLSA.Risk {
	key = 'decay',
	atlas = "risk",
	pos = { x = 2, y = 1 },
	tier = 2,
	config = { extra = { level = 2 } },
	risk_calculate = function(self, risk, context)
		if context.before then
			risk.ability.last_hand_name = nil
			if G.GAME.hands[context.scoring_name].level > 1 then
				risk.ability.last_hand_name = context.scoring_name
				risk.ability.last_hand_level = G.GAME.hands[context.scoring_name].level
				local level = -math.max(1,
					risk.ability.last_hand_level - (risk.ability.last_hand_level / risk.ability.extra.level))
				SMODS.upgrade_poker_hands { hands = { context.scoring_name }, level_up = level }
			end
		end
		if context.after and risk.ability.last_hand_name then
			G.E_MANAGER:add_event(Event {
				func = function()
					local hand = G.GAME.hands[risk.ability.last_hand_name]
					hand.level = risk.ability.last_hand_level
					hand.mult = math.max(hand.s_mult + hand.l_mult * (hand.level - 1), 1)
					hand.chips = math.max(hand.s_chips + hand.l_chips * (hand.level - 1), 0)
					return true
				end
			})
		end
	end,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.level } }
	end
}

PLSA.Risk {
	key = "stunted",
	atlas = "risk",
	pos = { x = 3, y = 1 },
	tier = 2,
	config = { extra = { chance = 2 } },
	risk_calculate = function(self, risk, context)
		if context.before then
			for _, card in ipairs(G.play.cards) do
				if SMODS.pseudorandom_probability(card, "plsa_stunted" .. G.GAME.round_resets.ante, 1, risk.ability.extra.chance)
					and card.ability.set == 'Enhanced' then
					card.ability.set = 'Default'
					card.ability.plsa_old_effect = card.ability.effect
					card.ability.plsa_old_extra = card.ability.extra_enhancement
					card.ability.effect = nil
					card.ability.extra_enhancement = false
					card.ability.plsa_stunted = true
					SMODS.calculate_effect({ message = "Stunted!" }, card)
				end
			end
		end
		if context.after then
			for _, card in ipairs(G.play.cards) do
				if card.ability.plsa_stunted then
					card.ability.set = 'Enhanced'
					card.ability.effect = card.ability.plsa_old_effect
					card.ability.extra_enhancement = card.ability.plsa_old_extra
					card.ability.plsa_old_effect = nil
					card.ability.plsa_old_extra = nil
					card.ability.plsa_stunted = false
					SMODS.calculate_effect({ message = "Reverted!" }, card)
				end
			end
		end
	end,
	loc_vars = function(self, info_queue, card)
		local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.chance)
		return { vars = { num, den } }
	end
}

-- Handle hooks for stunted
local stunted_function_addresses = {
	get_chip_mult = "perma_mult",
	get_chip_x_mult = "perma_x_mult",
	get_chip_h_mult = "perma_h_mult",
	get_chip_h_x_mult = "perma_h_x_mult",
	-- get_chip_bonus = "perma_mult",
	get_chip_x_bonus = "perma_x_chips",
	get_chip_h_bonus = "perma_h_chips",
	get_chip_h_x_bonus = "perma_h_x_chips",
	get_h_dollars = "perma_h_dollars",
}

for addr, var in pairs(stunted_function_addresses) do
	local old = Card[addr]
	Card[addr] = function(self, context)
		if self.ability.plsa_stunted then return self.ability[var] or 0 end
		return old(self, context)
	end
end

local oldce = Card.calculate_enhancement
function Card:calculate_enhancement(context)
	if self.ability.plsa_stunted then return nil end
	return oldce(self, context)
end

PLSA.Risk {
	key = "backfire",
	atlas = "risk",
	pos = { x = 3, y = 1 },
	tier = 2,
	config = { extra = { chance = 2 } },
	loc_vars = function(self, info_queue, card)
		local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.chance)
		return { vars = { num, den } }
	end,
	risk_calculate = function(self, risk, context)
		if context.press_play and SMODS.pseudorandom_probability(risk, 'plsa_backfire' .. G.GAME.round_resets.ante, 1, risk.ability.extra.chance) then
			table.sort(G.jokers.cards, function(x, y) return x.sort_id > y.sort_id end)
			G.jokers:set_ranks()
		end
	end,
}

PLSA.Risk {
	key = "elusive",
	atlas = "risk",
	pos = { x = 5, y = 1 },
	tier = 2,
	risk_calculate = function(self, risk, context)
		if context.press_play then
			for _, card in ipairs(G.hand.cards) do
				if not card.highlighted then card:flip() end
			end
		end
		if context.setting_blind then
			G.GAME.plsa_elusive_cards = (G.GAME.plsa_elusive_cards or 0) + 1
		end
		if context.end_of_round and context.main_eval then
			G.GAME.plsa_elusive_cards = 0
		end
	end
}

-- TODO
PLSA.Risk {
	key = "cast",
	atlas = "risk",
	pos = { x = 0, y = 2 },
	tier = 3,
	can_calculate_outside_of_boss = true,
	use = function(self, card, area, copier)
		if not G.GAME.plsa_prelude_next_blind and G.GAME.round_resets.blind_choices.Boss ~= "bl_plsa_question" then
			G.GAME.round_resets.last_cast_boss = G.GAME.round_resets.blind_choices.Boss
			PLSA.ChangeUpcomingBoss('bl_plsa_question', true)
		else
			if G.GAME.plsa_prelude_next_blind ~= "bl_plsa_question" then
				G.GAME.round_resets.last_cast_boss = G.GAME.plsa_prelude_next_blind
				G.GAME.plsa_prelude_next_blind = "bl_plsa_question"
			end
		end
		G.GAME.plsa_cannot_reroll = true

		-- determine bosses for the cast
		G.GAME.banned_keys['bl_plsa_question'] = true -- Prevent get_new_boss from selecting The Cast itself!
		local current_boss = G.GAME.round_resets.last_cast_boss or get_new_boss()
		G.GAME.plsa_merged_boss_keys = G.GAME.plsa_merged_boss_keys or {}
		if not next(G.GAME.plsa_merged_boss_keys) then
			-- first entry is the current boss
			table.insert(G.GAME.plsa_merged_boss_keys, current_boss)
		end
		-- Get a random boss blind to append
		table.insert(G.GAME.plsa_merged_boss_keys, get_new_boss())
		G.GAME.banned_keys['bl_plsa_question'] = nil

		-- get biggest chips multiplier
		for i = 1, #G.GAME.plsa_merged_boss_keys do
			local blind = G.P_BLINDS[G.GAME.plsa_merged_boss_keys[i]]
			G.P_BLINDS['bl_plsa_question'].mult = math.max(G.P_BLINDS['bl_plsa_question'].mult, blind.mult)
		end

		PLSA.Risk.use(self, card, area, copier)
	end,
	risk_calculate = function(self, risk, context)
		if (context.end_of_round and context.main_eval) and (not risk.ability.persist) and G.GAME.blind_on_deck == 'Boss' then
			G.GAME.plsa_cannot_reroll = nil
			G.GAME.round_resets.last_cast_boss = nil
			G.GAME.plsa_merged_boss_keys = {}
			G.GAME.plsa_casted = nil
		end
		if context.ending_shop and not G.GAME.plsa_casted then
			if not G.GAME.plsa_prelude_next_blind then
				G.GAME.plsa_prelude_next_blind = "bl_plsa_question"
				PLSA.ChangeUpcomingBoss('bl_plsa_prelude', true, true)
			else
				PLSA.ChangeUpcomingBoss('bl_plsa_question', true, true)
			end
			G.GAME.plsa_casted = true
		end
	end
}

PLSA.Risk {
	key = "elysium",
	atlas = "risk",
	pos = { x = 1, y = 2 },
	tier = 3,
	risk_calculate = function(self, risk, context)
		if context.plsa_risk_joker_moved and next(G.jokers.cards) then
			for _, joker in ipairs(G.jokers.cards) do
				SMODS.debuff_card(joker, false, "plsa_risk_elysium")
			end
			SMODS.debuff_card(G.jokers.cards[1], true, "plsa_risk_elysium")
			SMODS.debuff_card(G.jokers.cards[#G.jokers.cards], true, "plsa_risk_elysium")
		end
		if context.ante_end or (context.end_of_round and context.main_eval) then
			for _, joker in ipairs(G.jokers.cards) do
				SMODS.debuff_card(joker, false, "plsa_risk_elysium")
			end
		end
	end
}

-- TODO
PLSA.Risk {
	key = "prelude",
	atlas = "risk",
	pos = { x = 2, y = 2 },
	tier = 3,
	can_calculate_outside_of_boss = true,
	risk_calculate = function(self, risk, context)
		if (context.end_of_round and context.main_eval) and (not risk.ability.persist) and G.GAME.blind_on_deck == 'Boss' then
			G.GAME.plsa_cannot_reroll = nil
		end
		if context.ending_shop and not G.GAME.plsa_prelude_next_blind then
			G.GAME.plsa_prelude_next_blind = G.GAME.round_resets.blind_choices.Boss
			PLSA.ChangeUpcomingBoss('bl_plsa_prelude', true, true)
		end
	end,
	use = function(self, card, area, copier)
		G.GAME.plsa_prelude_next_blind = G.GAME.round_resets.blind_choices.Boss
		PLSA.ChangeUpcomingBoss('bl_plsa_prelude', true)
		G.GAME.plsa_cannot_reroll = true
		PLSA.Risk.use(self, card, area, copier)
	end
}
