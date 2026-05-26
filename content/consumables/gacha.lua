SMODS.Atlas { key = "tickezo", path = "consumables/tickezo.png", px = 71, py = 95 }

SMODS.Consumable {
	key = "gacha",
	atlas = "tickezo",
	set = "Spectral",
	pos = { x = 0, y = 0 },
	in_pool = function(self, args)
		return false
	end,
	use = function(self, card, area, copier)
		G.FUNCS.plsa_open_gacha_banners({ config = { ref_table = card } })
	end,
	can_use = function(self, card)
		return true
	end
}

-- Gacha now summons a custom shop
-- This stupid spectral needs more effort than what it deserves
PLSA.GachaBanners = {}

SMODS.Attribute {
	key = 'gacha_banner'
}

---@class PLSA.GachaBanner: SMODS.GameObject
---@field target_center string|nil Target center to increase weights of. Set to nil for no center.
---@overload fun(self: PLSA.GachaBanner): PLSA.GachaBanner
PLSA.GachaBanner = SMODS.GameObject:extend({
	class_prefix = "gacha",
	set = "GachaBanner",
	obj_buffer = {},
	obj_table = PLSA.GachaBanners,
	required_params = {
		'key',
		'target_center',
	},
	target_center = 'j_joker',
	attributes = {
		'gacha_banner'
	},
	weight = 0.4,
	inject = function(self, i)
		for _, attr in ipairs(self.attributes) do
			SMODS.add_attribute(attr, { self.key })
		end
	end,
})

-- Default banner. Not in the pool by default, this is chosen as the very last one. All the time.
PLSA.GachaBanner { key = 'default', target_center = 'c_base', in_pool = function(self)
	return false
end }

-- Various other banners
PLSA.GachaBanner {
	key = 'baron_pickup',
	target_center = 'j_baron',
}
PLSA.GachaBanner {
	key = 'mime_pickup',
	target_center = 'j_mime',
}
PLSA.GachaBanner {
	key = 'blueprint_pickup',
	target_center = 'j_blueprint',
	weight = 0.2
}
PLSA.GachaBanner {
	key = 'brainstorm_pickup',
	target_center = 'j_brainstorm',
	weight = 0.2
}

G.PLSA_BANNERS = PLSA.GachaBanners
SMODS.game_table_from_type['gacha_banner'] = 'PLSA_BANNERS'

PLSA.HookGameGlobals(function(run_start)
	if not run_start then return end
	G.GAME.plsa_ante_banners = {}
	G.GAME.plsa_pity = 0
end)

PLSA.MAX_GACHA_BANNERS = 3

G.FUNCS.plsa_open_gacha_banners = function(e)
	---@type Card
	local card = e.config.ref_table
	card:highlight(false)

	local pool = G.GAME.plsa_ante_banners[G.GAME.round_resets.ante] or {}
	if #pool == 0 then
		for i = 1, PLSA.MAX_GACHA_BANNERS do
			local key = i == PLSA.MAX_GACHA_BANNERS and 'gacha_plsa_default' or
				SMODS.poll_object { attributes = { 'gacha_banner' }, pool = SMODS.get_attribute_pool('gacha_banner'), guaranteed = true }
			if not key or key == 'UNAVAILABLE' then
				key = 'gacha_plsa_default'
			end
			local dummy = copy_table(G.P_CENTERS.c_base)
			dummy.plsa_gacha_key = PLSA.GachaBanners[key].target_center
			dummy.plsa_gacha = key
			pool[#pool + 1] = dummy
		end
		G.GAME.plsa_ante_banners[G.GAME.round_resets.ante] = pool
	end

	G.GAME.plsa_pity = G.GAME.plsa_pity + 100

	delay(0.2)

	G.E_MANAGER:add_event(Event {
		func = function(n)
			G.SETTINGS.paused = true
			PLSA.gacha_menu = true
			G.FUNCS.overlay_menu {
				definition = SMODS.card_collection_UIBox(pool, { PLSA.MAX_GACHA_BANNERS }, {
					no_materialize = true,
					back_func = 'exit_overlay_menu',
					modify_card = function(c, center, i, j)
						c:set_sprites(G.P_CENTERS[center.plsa_gacha_key])
						local old_click = c.click
						c.click = function(self)
							PLSA.gacha_menu = false
							G.FUNCS.exit_overlay_menu()
							old_click(self)
						end
					end,
					plsa_misc_elements = function()
						return {
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{
									n = G.UIT.C,
									config = { align = "cm" },
									nodes = {
										{
											n = G.UIT.R,
											config = { align = "cm" },
											nodes = {
												{ n = G.UIT.O, config = { object = DynaText({ string = { localize('ph_plsa_gacha_banner') }, colours = { G.C.EDITION }, shadow = true, float = true, spacing = 7, rotate = true, scale = 1.5, maxw = 6.5 }) } },
											}
										},
										{
											n = G.UIT.R,
											config = { align = "cm" },
											nodes = {
												{
													n = G.UIT.T,
													config = {
														text = localize { type = "variable", key = "ph_plsa_gacha_pity", vars = { G.GAME.plsa_pity } },
														shadow = true,
														scale = 0.3,
														colour = G.C.WHITE,
													}
												}
											}
										}
									}
								}
							}
						}
					end
				}),
				config = {
					plsa_gacha = true,
					pity = G.GAME.plsa_pity
				}
			}
			return true
		end
	})

	-- Exit out when selecting a card
	G.E_MANAGER:add_event(Event({
		func = function()
			if G.OVERLAY_MENU and PLSA.gacha_menu then
				return false
			end
			G.SETTINGS.paused = false
			return true
		end
	}))

	delay(0.2)
end
