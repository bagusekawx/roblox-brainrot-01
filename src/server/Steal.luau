-- Steal: the threat that makes the game tense. A player can grab a brainrot off
-- another player's base and carry it home -- but the owner can lock their base,
-- the tsunami knocks carried brainrots loose, and the carrier has to make it all
-- the way back to their own plot before the steal counts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local PlotManager = require(script.Parent:WaitForChild("PlotManager"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local Steal = {}

local DELIVERY_RADIUS_STUDS = 13

-- Locks a player's own base for 30 seconds, so nobody can steal from it. The
-- lock then needs a 2-minute cooldown before it can be used again.
function Steal.lockPlayerBase(player)
	local state = PlayerState.getPlayerState(player)
	if not state then
		return false
	end
	local now = os.clock()
	if now < state.lockCooldownUntil then
		return false
	end
	state.lockUntil = now + BrainrotData.LockDurationSeconds
	state.lockCooldownUntil = now + BrainrotData.LockCooldownSeconds
	Steal.refreshStealPrompts(player)
	PlayerState.syncPlayerState(player)
	return true
end

-- Whether a player's base is locked right now (its lock time has not run out).
function Steal.isBaseLocked(player)
	local state = PlayerState.getPlayerState(player)
	if not state then
		return false
	end
	return os.clock() < state.lockUntil
end

-- Enables or disables every steal prompt on one player's base, to match the lock.
function Steal.refreshStealPrompts(player)
	local state = PlayerState.getPlayerState(player)
	if not state then
		return
	end
	local locked = Steal.isBaseLocked(player)
	for _, owned in pairs(state.owned) do
		local prompt = owned.model:FindFirstChild("Body") and owned.model.Body:FindFirstChild("BuyPrompt")
		if prompt then
			prompt.Enabled = not locked
		end
	end
end

-- Picks a brainrot up off another player's base and welds it above the thief's
-- head. Refused when the base is locked, the brainrot is the thief's own, or the
-- thief is already carrying all they can.
function Steal.tryStealBrainrot(thief, model)
	local thiefState = PlayerState.getPlayerState(thief)
	if not thiefState then
		return false
	end
	local brainrotId = model:GetAttribute("BrainrotId")
	local owner, owned = nil, nil
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local state = PlayerState.getPlayerState(player)
		if state and state.owned[brainrotId] then
			owner = player
			owned = state.owned[brainrotId]
			break
		end
	end
	if not owner or not owned or owner == thief then
		return false
	end
	if Steal.isBaseLocked(owner) then
		return false
	end
	local carryingCount = 0
	for _ in pairs(thiefState.carrying) do
		carryingCount += 1
	end
	if carryingCount >= PlayerState.carryCapacity(thief) then
		return false
	end
	local character = thief.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") or nil
	if not rootPart then
		return false
	end
	-- Take it off the owner's base, unanchor it, and weld it over the thief's head.
	local ownerState = PlayerState.getPlayerState(owner)
	ownerState.owned[brainrotId] = nil
	local body = model.PrimaryPart
	body.Anchored = false
	model:PivotTo(rootPart.CFrame * CFrame.new(0, 4.5, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = body
	weld.Part1 = rootPart
	weld.Parent = body
	thiefState.carrying[brainrotId] = {
		model = model,
		owner = owner,
		speciesId = owned.speciesId,
		mutation = owned.mutation,
		rate = owned.rate,
	}
	BrainrotFactory.setBrainrotPromptMode(model, "Steal")
	local prompt = body:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.Enabled = false
	end
	PlayerState.syncPlayerState(thief)
	PlayerState.syncPlayerState(owner)
	return true
end

-- Hands a carried brainrot back to its owner's base, at the first free slot.
-- Used when the carrier is hit by the tsunami, dies, or leaves.
function Steal.dropCarriedBrainrot(carrier, brainrotId)
	local carrierState = PlayerState.getPlayerState(carrier)
	if not carrierState then
		return
	end
	local carried = carrierState.carrying[brainrotId]
	if not carried then
		return
	end
	carrierState.carrying[brainrotId] = nil
	local ownerState = PlayerState.getPlayerState(carried.owner)
	local model = carried.model
	local weld = model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	model.PrimaryPart.Anchored = true
	if ownerState then
		local slotIndex = PlotManager.firstFreeSlotIndex(carried.owner, ownerState.owned)
		local slotPosition = slotIndex and PlotManager.slotPositionFor(carried.owner, slotIndex) or nil
		if slotPosition then
			ownerState.owned[brainrotId] = {
				speciesId = carried.speciesId,
				mutation = carried.mutation,
				rate = carried.rate,
				model = model,
				slotIndex = slotIndex,
			}
			model:PivotTo(CFrame.new(slotPosition))
			local prompt = model.PrimaryPart:FindFirstChild("BuyPrompt")
			if prompt then
				prompt.Enabled = not Steal.isBaseLocked(carried.owner)
			end
			PlayerState.syncPlayerState(carried.owner)
		else
			model:Destroy()
		end
	else
		model:Destroy()
	end
	PlayerState.syncPlayerState(carrier)
end

-- Drops everything one player is carrying (tsunami, death, or leaving).
function Steal.dropAllCarriedBrainrots(carrier)
	local carrierState = PlayerState.getPlayerState(carrier)
	if not carrierState then
		return
	end
	local ids = {}
	for brainrotId in pairs(carrierState.carrying) do
		table.insert(ids, brainrotId)
	end
	for _, brainrotId in ipairs(ids) do
		Steal.dropCarriedBrainrot(carrier, brainrotId)
	end
end

-- Delivers a carried brainrot onto the thief's own base: the steal is complete
-- and the brainrot starts earning for its new owner.
function Steal.deliverStolenBrainrot(thief, brainrotId)
	local thiefState = PlayerState.getPlayerState(thief)
	if not thiefState then
		return false
	end
	local carried = thiefState.carrying[brainrotId]
	if not carried then
		return false
	end
	if PlayerState.ownedBrainrotCount(thief) >= PlayerState.baseSlotCount(thief) then
		Steal.dropCarriedBrainrot(thief, brainrotId)
		return false
	end
	local slotIndex = PlotManager.firstFreeSlotIndex(thief, thiefState.owned)
	local slotPosition = slotIndex and PlotManager.slotPositionFor(thief, slotIndex) or nil
	if not slotPosition then
		Steal.dropCarriedBrainrot(thief, brainrotId)
		return false
	end
	thiefState.carrying[brainrotId] = nil
	local model = carried.model
	local weld = model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	model.PrimaryPart.Anchored = true
	thiefState.owned[brainrotId] = {
		speciesId = carried.speciesId,
		mutation = carried.mutation,
		rate = carried.rate,
		model = model,
		slotIndex = slotIndex,
	}
	model:PivotTo(CFrame.new(slotPosition))
	local prompt = model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.Enabled = not Steal.isBaseLocked(thief)
	end
	PlayerState.syncPlayerState(thief)
	return true
end

-- Watches every carrying player: the moment one stands on their own plot, the
-- steal completes. Called every heartbeat by the server entrypoint.
function Steal.checkStealDeliveries()
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local state = PlayerState.getPlayerState(player)
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart") or nil
		local plotCenter = PlotManager.getPlotCenter(player)
		if state and rootPart and plotCenter then
			local distance = (rootPart.Position - plotCenter).Magnitude
			if distance <= DELIVERY_RADIUS_STUDS then
				local ids = {}
				for brainrotId in pairs(state.carrying) do
					table.insert(ids, brainrotId)
				end
				for _, brainrotId in ipairs(ids) do
					Steal.deliverStolenBrainrot(player, brainrotId)
				end
			end
		end
	end
end

-- Starts the delivery watch. Called once by the server entrypoint.
function Steal.startDeliveryWatch()
	RunService.Heartbeat:Connect(Steal.checkStealDeliveries)
end

return Steal
