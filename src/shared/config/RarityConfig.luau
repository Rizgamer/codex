-- One table drives all weighted eggs and enemy tiers. New rarities only need one entry here.
local Rarities = {
	Common = { DisplayName = "Common", Color = Color3.fromRGB(190, 196, 205), Weight = 5000, Value = 1, BaseStats = { Health = 1, Damage = 1 }, Effect = "" },
	Uncommon = { DisplayName = "Uncommon", Color = Color3.fromRGB(91, 214, 122), Weight = 2500, Value = 1.35, BaseStats = { Health = 1.2, Damage = 1.2 }, Effect = "" },
	Rare = { DisplayName = "Rare", Color = Color3.fromRGB(69, 151, 255), Weight = 1200, Value = 2, BaseStats = { Health = 1.55, Damage = 1.55 }, Effect = "Sparkle" },
	Epic = { DisplayName = "Epic", Color = Color3.fromRGB(183, 91, 255), Weight = 700, Value = 3.5, BaseStats = { Health = 2.2, Damage = 2.2 }, Effect = "Aura" },
	Legendary = { DisplayName = "Legendary", Color = Color3.fromRGB(255, 185, 55), Weight = 350, Value = 7, BaseStats = { Health = 3.5, Damage = 3.5 }, Effect = "Glow" },
	Mythic = { DisplayName = "Mythic", Color = Color3.fromRGB(255, 69, 158), Weight = 180, Value = 15, BaseStats = { Health = 6, Damage = 6 }, Effect = "Pulse" },
	Secret = { DisplayName = "Secret", Color = Color3.fromRGB(255, 70, 70), Weight = 70, Value = 40, BaseStats = { Health = 12, Damage = 12 }, Effect = "Prism" },
}

function Rarities.Roll(pool: { [string]: number }, random: Random): string
	local totalWeight = 0
	for rarity, multiplier in pairs(pool) do
		local definition = Rarities[rarity]
		if definition and multiplier > 0 then
			totalWeight += definition.Weight * multiplier
		end
	end

	assert(totalWeight > 0, "A weighted rarity pool must contain at least one known rarity")
	local pickedWeight, cursor = random:NextNumber(0, totalWeight), 0
	for rarity, multiplier in pairs(pool) do
		local definition = Rarities[rarity]
		if definition and multiplier > 0 then
			cursor += definition.Weight * multiplier
			if pickedWeight <= cursor then
				return rarity
			end
		end
	end
	return "Common" -- Only satisfies Luau's total-return analysis; the loop always returns.
end

return Rarities
