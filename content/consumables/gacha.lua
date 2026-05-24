SMODS.Atlas { key = "tickezo", path = "consumables/tickezo.png", px = 71, py = 95 }

SMODS.Consumable {
	key = "gacha",
	atlas = "tickezo",
	set = "Spectral",
	pos = { x = 0, y = 0 },
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
	inject = function(self, i)

	end
})

-- Default banner.
PLSA.GachaBanner { key = 'default', target_center = nil }

-- Various other banners
PLSA.GachaBanner {
	key = 'baron_pickup',
	target_center = 'j_baron',
}
PLSA.GachaBanner {
	key = 'mime_pickup',
	target_center = 'j_mime',
}
