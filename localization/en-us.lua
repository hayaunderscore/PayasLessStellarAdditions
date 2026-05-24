return {
	descriptions = {
		Blind = {
			bl_plsa_prelude = {
				name = 'Prelude Blind',
				text = {
					"The calm before",
					"the storm..."
				}
			},
			bl_plsa_question = {
				name = 'The Cast', text = { "Fusion of the blinds", "#1#" }
			},
			bl_plsa_question_alt = { name = 'The Cast', text = { "Fuses 2 showdown", "boss blinds" } },
		},
		Risk = {
			c_plsa_hinder = {
				name = "Hinder",
				text = {
					"{C:attention}Debuff{} {C:attention}#1#{} random",
					"cards in your deck",
				}
			},
			c_plsa_hollow = {
				name = "Hollow",
				text = {
					"{C:attention}Debuff{} all consumables",
				}
			},
			c_plsa_leak = {
				name = "Leak",
				text = {
					"Lose {C:money}$#1#{} per",
					"{C:attention}scored{} card"
				}
			},
			c_plsa_shrink = {
				name = "Shrink",
				text = {
					"Scored cards give",
					"{C:attention}half{} its chip value",
				},
			},
			c_plsa_genesis = {
				name = "Genesis",
				text = {
					"Adds {C:attention}#1#{} random basic",
					"cards to your deck",
				},
			},
			c_plsa_burden = {
				name = "Burden",
				text = {
					"Adds {C:purple}Eternal{} to",
					"a random Joker",
				},
			},
			c_plsa_ethereal = {
				name = "Ethereal",
				text = {
					"Adds {C:purple}Perishable{} to",
					"a random Joker",
				},
			},
			c_plsa_cyclone = {
				name = "Cyclone",
				text = {
					"Held cards are {C:attention}shuffled",
					"back into the deck",
				},
			},
			c_plsa_perpetuate = {
				name = "Perpetuate",
				text = {
					"Discarded cards {C:attention}return",
					"back into the deck",
				},
			},
			c_plsa_doubledown = {
				name = "Double Down",
				text = {
					"{C:attention}Doubles{} the boss",
					"blind's {C:attention}requirement",
				}
			},
			c_plsa_crime = {
				name = "Crime",
				text = {
					"{C:red}-#1#{} hand size",
				}
			},
			c_plsa_decay = {
				name = "Eclipse",
				text = {
					"{X:attention,C:white}÷#1#{} poker",
					"hand levels",
				}
			},
			c_plsa_stunted = {
				name = "Stunted",
				text = {
					"Played {C:attention}Enhanced{} cards have a",
					"{C:green}#1# in #2#{} chance of not {C:attention}activating",
				}
			},
			c_plsa_backfire = {
				name = "Backfire",
				text = {
					"{C:green}#1# in #2#{} chance of",
					"reversing Joker order",
					"when hand is played",
				},
			},
			c_plsa_elusive = {
				name = "Elusive",
				text = {
					"{C:attention}First{} drawn card",
					"is faced down",
					"Held cards are",
					"flipped after playing"
				}
			},
			c_plsa_cast = {
				name = "Cast",
				text = {
					"{C:attention}Applies{} a {C:attention}random{}",
					"boss blind's {C:attention}ability",
					"to current boss blind",
				}
			},
			c_plsa_elysium = {
				name = "Elysium",
				text = {
					"{C:attention}Debuff{} the {C:attention}rightmost",
					"and {C:attention}leftmost{} Joker",
					"during the round",
				}
			},
			c_plsa_prelude = {
				name = "Prelude",
				text = {
					"{C:attention}Encounter{} a",
					"{C:attention}Prelude Blind"
				}
			},
			c_plsa_flow = {
				name = "Flow",
				text = {
					"Held cards are {C:attention}debuffed",
					"after playing a hand",
				},
			},
		},
		Spectral = {
			c_plsa_showdown = {
				name = "Showdown",
				text = {
					"{C:attention}Transforms{} the boss",
					"blind to a {C:attention}showdown",
					"boss blind",
				}
			},
		},
		Other = {
			plsa_risk_card_hint = {
				name = "Risk Card",
				text = {
					"Effects apply only",
					"during the Boss Blind"
				}
			}
		}
	},
	misc = {
		dictionary = {
			k_risk = "Risk",
			b_risk_cards = "Risk Cards",
			k_reward = "Reward",
			b_reward_cards = "Reward Cards",
		}
	}
}
