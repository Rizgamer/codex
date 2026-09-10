-- Central weighted rarity table. Add a row here to expand every weighted roll.
local Rarities = {
 Common = {DisplayName="Common", Color=Color3.fromRGB(190,196,205), Weight=5000, Value=1, Effect=""},
 Uncommon = {DisplayName="Uncommon", Color=Color3.fromRGB(91,214,122), Weight=2500, Value=1.35, Effect=""},
 Rare = {DisplayName="Rare", Color=Color3.fromRGB(69,151,255), Weight=1200, Value=2, Effect="Sparkle"},
 Epic = {DisplayName="Epic", Color=Color3.fromRGB(183,91,255), Weight=700, Value=3.5, Effect="Aura"},
 Legendary = {DisplayName="Legendary", Color=Color3.fromRGB(255,185,55), Weight=350, Value=7, Effect="Glow"},
 Mythic = {DisplayName="Mythic", Color=Color3.fromRGB(255,69,158), Weight=180, Value=15, Effect="Pulse"},
 Secret = {DisplayName="Secret", Color=Color3.fromRGB(255,70,70), Weight=70, Value=40, Effect="Prism"},
}
function Rarities.Roll(pool, random)
 local total = 0
 for rarity, multiplier in pairs(pool) do total += (Rarities[rarity].Weight * multiplier) end
 local pick, cursor = random:NextNumber(0,total), 0
 for rarity, multiplier in pairs(pool) do cursor += Rarities[rarity].Weight * multiplier if pick <= cursor then return rarity end end
 return "Common"
end
return Rarities
