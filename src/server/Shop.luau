-- Shop: everything a player spends cash on. Buying a brainrot off the path moves
-- it onto the buyer's base and starts its income; the upgrade shop sells walk
-- speed, carry capacity and extra base slots. Every purchase is validated on the
-- server -- the client only ever asks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local PlotManager = require(script.Parent:WaitForChild("PlotManager"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local Shop = {}

-- Buys the brainrot a player prompted on the path: checks cash and a free base
-- slot, deducts the price, then parks the model on the buyer's base as theirs.
function Shop.buyBrainrotFromPath(player, model)
	local state = PlayerState.getPlayerState(player)
	local walker = BrainrotSpawner.getWalkerInfo(model)
	if not state or not walker then
		return false
	end
	if PlayerState.ownedBrainrotCount(player) >= PlayerState.baseSlotCount(player) then
		return false
	end
	local slotIndex = PlotManager.firstFreeSlotIndex(player, state.owned)
	local slotPosition = slotIndex and PlotManager.slotPositionFor(player, slotIndex) or nil
	if not slotPosition then
		return false
	end
	if not PlayerState.spendCash(player, walker.species.price) then
		return false
	end
	BrainrotSpawner.removeWalker(model)
	local brainrotId = model:GetAttribute("BrainrotId")
	state.owned[brainrotId] = {
		speciesId = walker.species.id,
		mutation = walker.mutation,
		rate = walker.rate,
		model = model,
		slotIndex = slotIndex,
	}
	-- Face the path: north plots look south, south plots look north.
	local plotCenter = PlotManager.getPlotCenter(player)
	local facing = CFrame.Angles(0, 0, 0)
	if plotCenter and plotCenter.Z > 0 then
		facing = CFrame.Angles(0, math.rad(180), 0)
	end
	model:PivotTo(CFrame.new(slotPosition) * facing)
	BrainrotFactory.setBrainrotPromptMode(model, "Steal")
	PlayerState.syncPlayerState(player)
	return true
end

-- Buys one walk-speed level: +2 studs/s, applied to the character at once.
function Shop.buyWalkSpeedUpgrade(player)
	local state = PlayerState.getPlayerState(player)
	if not state then
		return false
	end
	local upgrade = BrainrotData.Upgrades.WalkSpeed
	if state.walkSpeedLevel >= upgrade.maxLevel then
		return false
	end
	local cost = BrainrotData.upgradeCostFor("WalkSpeed", state.walkSpeedLevel)
	if not PlayerState.spendCash(player, cost) then
		return false
	end
	state.walkSpeedLevel += 1
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
	if humanoid then
		humanoid.WalkSpeed = BrainrotData.BaseWalkSpeed + 2 * state.walkSpeedLevel
	end
	PlayerState.syncPlayerState(player)
	return true
end

-- Buys one carry-capacity level: one more brainrot carried at a time.
function Shop.buyCarryCapacityUpgrade(player)
	local state = PlayerState.getPlayerState(player)
	if not state then
		return false
	end
	local upgrade = BrainrotData.Upgrades.Carry
	if state.carryLevel >= upgrade.maxLevel then
		return false
	end
	local cost = BrainrotData.upgradeCostFor("Carry", state.carryLevel)
	if not PlayerState.spendCash(player, cost) then
		return false
	end
	state.carryLevel += 1
	PlayerState.syncPlayerState(player)
	return true
end

-- Buys one base-slot level: two more brainrots fit on the player's base.
function Shop.buyBaseSlotUpgrade(player)
	local state = PlayerState.getPlayerState(player)
	if not state then
		return false
	end
	local upgrade = BrainrotData.Upgrades.Slots
	if state.slotLevel >= upgrade.maxLevel then
		return false
	end
	local cost = BrainrotData.upgradeCostFor("Slots", state.slotLevel)
	if not PlayerState.spendCash(player, cost) then
		return false
	end
	state.slotLevel += 1
	PlayerState.syncPlayerState(player)
	return true
end

-- Routes one shop button press from the client to the upgrade it names.
function Shop.handleShopRequest(player, upgradeId)
	if upgradeId == "WalkSpeed" then
		return Shop.buyWalkSpeedUpgrade(player)
	elseif upgradeId == "Carry" then
		return Shop.buyCarryCapacityUpgrade(player)
	elseif upgradeId == "Slots" then
		return Shop.buyBaseSlotUpgrade(player)
	end
	return false
end

return Shop
