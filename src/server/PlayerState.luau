-- PlayerState: the single server-side store for every player's money, brainrots,
-- upgrades, rebirths and base lock. No other module keeps player state; they all
-- read and change it through here, so money can never drift between two tables.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local PlayerState = {}

local states = {}
local stateSyncRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StateSync")

-- Builds a fresh state for a joining player: starting cash, no brainrots, no rebirths.
function PlayerState.createPlayerState(player)
	local state = {
		cash = BrainrotData.StartingCash,
		rebirths = 0,
		owned = {}, -- brainrotId -> { speciesId, mutation, rate, model, slotIndex }
		walkSpeedLevel = 0,
		carryLevel = 0,
		slotLevel = 0,
		lockUntil = 0,
		lockCooldownUntil = 0,
		carrying = {}, -- brainrotId -> { model, owner (Player), speciesId, mutation, rate }
		plot = nil, -- the plot Part this player owns, set by PlotManager
	}
	states[player] = state

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = state.cash
	cashValue.Parent = leaderstats
	state.cashValue = cashValue
	return state
end

-- Drops a leaving player's state and hands their carried brainrots back (see Steal).
function PlayerState.removePlayerState(player)
	states[player] = nil
end

function PlayerState.getPlayerState(player)
	return states[player]
end

-- The income multiplier from rebirths: +25% per rebirth, stacking.
function PlayerState.rebirthMultiplier(player)
	local state = states[player]
	if not state then
		return 1
	end
	return 1 + BrainrotData.RebirthBonusPerLevel * state.rebirths
end

-- The cash per second a player's base earns right now, before the rebirth multiplier.
function PlayerState.baseIncomePerSecond(player)
	local state = states[player]
	if not state then
		return 0
	end
	local total = 0
	for _, owned in pairs(state.owned) do
		total += owned.rate
	end
	return total
end

-- The cash per second a player actually earns: base income times the rebirth multiplier.
function PlayerState.totalIncomePerSecond(player)
	return PlayerState.baseIncomePerSecond(player) * PlayerState.rebirthMultiplier(player)
end

-- Adds one second of income to a player's cash. Called once a second by the server loop.
function PlayerState.tickPlayerIncome(player)
	local state = states[player]
	if not state then
		return
	end
	local income = PlayerState.totalIncomePerSecond(player)
	if income > 0 then
		state.cash += income
		if state.cashValue then
			state.cashValue.Value = math.floor(state.cash)
		end
	end
end

-- Tries to spend cash: true and deducted when the player can afford it, false otherwise.
function PlayerState.spendCash(player, amount)
	local state = states[player]
	if not state or state.cash < amount then
		return false
	end
	state.cash -= amount
	if state.cashValue then
		state.cashValue.Value = math.floor(state.cash)
	end
	return true
end

-- How many brainrots a player may carry at once: 1, plus one per carry level.
function PlayerState.carryCapacity(player)
	local state = states[player]
	if not state then
		return BrainrotData.BaseCarryCapacity
	end
	return BrainrotData.BaseCarryCapacity + state.carryLevel
end

-- How many brainrot slots a player's base has: 4, plus two per slot level.
function PlayerState.baseSlotCount(player)
	local state = states[player]
	if not state then
		return BrainrotData.BaseSlots
	end
	return BrainrotData.BaseSlots + 2 * state.slotLevel
end

-- How many brainrots a player owns right now.
function PlayerState.ownedBrainrotCount(player)
	local state = states[player]
	if not state then
		return 0
	end
	local count = 0
	for _ in pairs(state.owned) do
		count += 1
	end
	return count
end

-- Sends one player's whole state to their client so the HUD can redraw itself.
function PlayerState.syncPlayerState(player)
	local state = states[player]
	if not state then
		return
	end
	local carryingNames = {}
	for _, carried in pairs(state.carrying) do
		local species = BrainrotData.getSpeciesById(carried.speciesId)
		table.insert(carryingNames, species and species.name or carried.speciesId)
	end
	stateSyncRemote:FireClient(player, {
		cash = math.floor(state.cash),
		incomePerSecond = math.floor(PlayerState.totalIncomePerSecond(player)),
		brainrotCount = PlayerState.ownedBrainrotCount(player),
		slotCount = PlayerState.baseSlotCount(player),
		rebirths = state.rebirths,
		multiplier = PlayerState.rebirthMultiplier(player),
		walkSpeedLevel = state.walkSpeedLevel,
		carryLevel = state.carryLevel,
		slotLevel = state.slotLevel,
		lockSecondsLeft = math.max(0, state.lockUntil - os.clock()),
		lockCooldownLeft = math.max(0, state.lockCooldownUntil - os.clock()),
		rebirthCost = BrainrotData.rebirthCostFor(state.rebirths),
		carrying = carryingNames,
		plotName = state.plot and state.plot.Name or "",
	})
end

-- Sends every connected player's state to their own client. Called once a second.
function PlayerState.syncAllPlayerStates()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerState.syncPlayerState(player)
	end
end

return PlayerState
