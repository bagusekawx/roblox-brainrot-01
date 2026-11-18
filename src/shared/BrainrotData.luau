-- BrainrotData: the one table every script reads for the cast, the rarity ladder,
-- the mutations and the upgrade shop. Shared between server and client (it lives in
-- ReplicatedStorage), so it holds data and pure functions only -- no services, no state.

local BrainrotData = {}

-- Rarity ladder, weakest first. weight decides how often the rarity spawns on the path.
BrainrotData.Rarities = {
	Common = { order = 1, weight = 45, color = Color3.fromRGB(180, 180, 180) },
	Rare = { order = 2, weight = 28, color = Color3.fromRGB(80, 180, 255) },
	Epic = { order = 3, weight = 15, color = Color3.fromRGB(180, 90, 255) },
	Legendary = { order = 4, weight = 8, color = Color3.fromRGB(255, 170, 0) },
	Mythic = { order = 5, weight = 3, color = Color3.fromRGB(255, 80, 80) },
	BrainrotGod = { order = 6, weight = 1, color = Color3.fromRGB(255, 220, 80) },
}

-- The cast: ten absurd originals, each with its own body colour, size, accessory and joke.
-- price is what a buy costs, rate is the cash it earns every second on a base.
BrainrotData.Species = {
	{
		id = "Croaksalot", name = "Sir Croaksalot", rarity = "Common",
		price = 50, rate = 2, bodyColor = Color3.fromRGB(88, 204, 90),
		bodySize = Vector3.new(3, 2.6, 3), accessory = "TopHat",
		joke = "A frog in a top hat. He croaks in Latin.",
	},
	{
		id = "BobaBlob", name = "Boba Blob", rarity = "Common",
		price = 75, rate = 3, bodyColor = Color3.fromRGB(150, 100, 60),
		bodySize = Vector3.new(3.2, 2.4, 3.2), accessory = "BobaCup",
		joke = "90% tapioca, 10% attitude.",
	},
	{
		id = "NoodleNaga", name = "Noodle Naga", rarity = "Rare",
		price = 150, rate = 6, bodyColor = Color3.fromRGB(255, 140, 60),
		bodySize = Vector3.new(2.6, 3.4, 2.6), accessory = "Chopsticks",
		joke = "Slurps itself. Do not ask how.",
	},
	{
		id = "TurboTortoise", name = "Turbo Tortoise", rarity = "Rare",
		price = 250, rate = 10, bodyColor = Color3.fromRGB(90, 170, 90),
		bodySize = Vector3.new(3.4, 2.4, 3.4), accessory = "Helmet",
		joke = "Slow is a mindset. He has transcended it.",
	},
	{
		id = "CaptainMeowtain", name = "Captain Meowtain", rarity = "Epic",
		price = 500, rate = 22, bodyColor = Color3.fromRGB(240, 240, 240),
		bodySize = Vector3.new(3, 3, 3), accessory = "CaptainHat",
		joke = "Sails the seven litter boxes.",
	},
	{
		id = "ProfessorPickles", name = "Professor Pickles", rarity = "Epic",
		price = 750, rate = 32, bodyColor = Color3.fromRGB(100, 200, 80),
		bodySize = Vector3.new(2.6, 3.6, 2.6), accessory = "Glasses",
		joke = "PhD in brine. Tenure denied, twice.",
	},
	{
		id = "DJQuack", name = "DJ Quack", rarity = "Legendary",
		price = 1500, rate = 70, bodyColor = Color3.fromRGB(255, 220, 40),
		bodySize = Vector3.new(3.2, 3, 3.2), accessory = "Headphones",
		joke = "Drops beats. Drops bread. Never both.",
	},
	{
		id = "QueenBeestro", name = "Queen Beestro", rarity = "Legendary",
		price = 2500, rate = 110, bodyColor = Color3.fromRGB(255, 200, 30),
		bodySize = Vector3.new(3, 2.8, 3), accessory = "Crown",
		joke = "Her hive pays taxes. She does not.",
	},
	{
		id = "SirLoin", name = "Sir Loin the Steak Knight", rarity = "Mythic",
		price = 6000, rate = 300, bodyColor = Color3.fromRGB(170, 80, 60),
		bodySize = Vector3.new(3.4, 3.2, 2.6), accessory = "Sword",
		joke = "Medium rare. Fully armored. Zero regrets.",
	},
	{
		id = "BaronVonBubble", name = "Baron Von Bubble", rarity = "BrainrotGod",
		price = 15000, rate = 800, bodyColor = Color3.fromRGB(255, 150, 200),
		bodySize = Vector3.new(3.4, 3.4, 3.4), accessory = "Monocle",
		joke = "Pops for no one. Worth every penny.",
	},
}

-- Mutations roll on spawn and multiply the earning rate (never the price).
BrainrotData.Mutations = {
	Normal = { multiplier = 1, chance = 0.88, label = "" },
	Golden = { multiplier = 2, chance = 0.10, label = "GOLDEN" },
	Rainbow = { multiplier = 5, chance = 0.02, label = "RAINBOW" },
}

-- Upgrade shop: each row is one row of the HUD shop, bought with cash.
BrainrotData.Upgrades = {
	WalkSpeed = { label = "Walk Speed", desc = "+2 speed per level", baseCost = 100, costGrowth = 2, maxLevel = 5 },
	Carry = { label = "Carry Capacity", desc = "+1 brainrot carried", baseCost = 300, costGrowth = 2.5, maxLevel = 2 },
	Slots = { label = "Base Slots", desc = "+2 brainrots on your base", baseCost = 200, costGrowth = 2, maxLevel = 4 },
}

BrainrotData.StartingCash = 100
BrainrotData.BaseSlots = 4
BrainrotData.BaseWalkSpeed = 16
BrainrotData.BaseCarryCapacity = 1
BrainrotData.RebirthBaseCost = 1000
BrainrotData.RebirthCostGrowth = 10
BrainrotData.RebirthBonusPerLevel = 0.25
BrainrotData.LockDurationSeconds = 30
BrainrotData.LockCooldownSeconds = 120

local byId = {}
for _, species in ipairs(BrainrotData.Species) do
	byId[species.id] = species
end

-- Rolls one species, weighted by its rarity's weight, so Commons walk by most often.
function BrainrotData.rollSpeciesByRarity()
	local total = 0
	for _, rarity in pairs(BrainrotData.Rarities) do
		total += rarity.weight
	end
	local roll = math.random() * total
	for _, species in ipairs(BrainrotData.Species) do
		roll -= BrainrotData.Rarities[species.rarity].weight
		if roll <= 0 then
			return species
		end
	end
	return BrainrotData.Species[1]
end

-- Rolls one mutation: mostly Normal, sometimes Golden, rarely Rainbow.
function BrainrotData.rollMutation()
	local roll = math.random()
	if roll < BrainrotData.Mutations.Rainbow.chance then
		return "Rainbow"
	elseif roll < BrainrotData.Mutations.Rainbow.chance + BrainrotData.Mutations.Golden.chance then
		return "Golden"
	else
		return "Normal"
	end
end

-- The cash a brainrot earns per second: its species rate times its mutation multiplier.
function BrainrotData.rateForBrainrot(species, mutation)
	return species.rate * BrainrotData.Mutations[mutation].multiplier
end

-- The label over a brainrot: name, mutation tag, rarity and $/s, each on its own line.
function BrainrotData.labelForBrainrot(species, mutation)
	local tag = BrainrotData.Mutations[mutation].label
	local title = species.name
	if tag ~= "" then
		title = tag .. " " .. title
	end
	return title, species.rarity, "$" .. BrainrotData.rateForBrainrot(species, mutation) .. "/s"
end

function BrainrotData.getSpeciesById(id)
	return byId[id]
end

-- What the next level of an upgrade costs at the level the player already has.
function BrainrotData.upgradeCostFor(upgradeId, currentLevel)
	local upgrade = BrainrotData.Upgrades[upgradeId]
	return math.floor(upgrade.baseCost * (upgrade.costGrowth ^ currentLevel) + 0.5)
end

-- What the next rebirth costs at the rebirth count the player already has.
function BrainrotData.rebirthCostFor(rebirthCount)
	return BrainrotData.RebirthBaseCost * (BrainrotData.RebirthCostGrowth ^ rebirthCount)
end

return BrainrotData
