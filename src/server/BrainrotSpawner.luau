-- BrainrotSpawner: keeps the spawn path busy. Brainrots appear at the west gate,
-- waddle east along the path at their own speed, and leave through the east gate.
-- Each walker carries a Buy prompt; buying one hands it to Shop, which moves it
-- onto the buyer's base.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local BrainrotSpawner = {}

local WAYPOINTS = {
	Vector3.new(-75, 2, 0),
	Vector3.new(-40, 2, 0),
	Vector3.new(0, 2, 0),
	Vector3.new(40, 2, 0),
	Vector3.new(75, 2, 0),
}
local MAX_WALKERS = 6
local SPAWN_INTERVAL_SECONDS = 4
local WALK_SPEED_STUDS = 6
local WALKER_LIFETIME_SECONDS = 90

local walkers = {} -- model -> { species, mutation, rate, waypointIndex, bornAt }
local promptHandler = nil

-- Spawns one brainrot at the west gate and sends it walking east. An optional
-- species id forces that species (the TOUR.json tour uses it for screenshots);
-- otherwise the species and mutation are rolled from BrainrotData.
function BrainrotSpawner.spawnBrainrotOnPath(speciesId)
	local species = nil
	if typeof(speciesId) == "string" and speciesId ~= "" then
		species = BrainrotData.getSpeciesById(speciesId)
	end
	if not species then
		species = BrainrotData.rollSpeciesByRarity()
	end
	local mutation = BrainrotData.rollMutation()
	local rarityColor = BrainrotData.Rarities[species.rarity].color
	local model = BrainrotFactory.buildBrainrotModel(species, mutation, rarityColor)
	model:PivotTo(CFrame.new(WAYPOINTS[1]) * CFrame.Angles(0, math.rad(90), 0))
	model.Parent = Workspace

	walkers[model] = {
		species = species,
		mutation = mutation,
		rate = BrainrotData.rateForBrainrot(species, mutation),
		waypointIndex = 2,
		bornAt = os.clock(),
	}

	local prompt = model.Body:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			if promptHandler then
				promptHandler(player, model)
			end
		end)
	end
	return model
end

-- The one prompt callback the server entrypoint registers: it buys walkers and
-- steals owned brainrots. One connection per model, for its whole life, so the
-- prompt keeps working after a buy turns it from Buy into Steal.
function BrainrotSpawner.setPromptHandler(handler)
	promptHandler = handler
end

-- The walker's species, mutation and rate, for Shop to validate a buy.
function BrainrotSpawner.getWalkerInfo(model)
	return walkers[model]
end

-- Stops tracking a walker (it was bought, or it left the map). Does not destroy it.
function BrainrotSpawner.removeWalker(model)
	walkers[model] = nil
end

-- How many brainrots are walking the path right now.
function BrainrotSpawner.walkerCount()
	local count = 0
	for _ in pairs(walkers) do
		count += 1
	end
	return count
end

-- Moves every walker one step toward its next waypoint, with a little bob.
local function stepWalkers(dt)
	local now = os.clock()
	for model, walker in pairs(walkers) do
		if not model.Parent then
			walkers[model] = nil
		else
			local target = WAYPOINTS[walker.waypointIndex]
			if not target or now - walker.bornAt > WALKER_LIFETIME_SECONDS then
				model:Destroy()
				walkers[model] = nil
			else
				local position = model:GetPivot().Position
				local toTarget = target - position
				local distance = toTarget.Magnitude
				local step = WALK_SPEED_STUDS * dt
				if distance <= step then
					walker.waypointIndex += 1
				else
					local bob = math.sin(now * 6 + model:GetPivot().Position.X) * 0.15
					local nextPosition = position + toTarget.Unit * step + Vector3.new(0, bob * dt * 6, 0)
					model:PivotTo(CFrame.new(nextPosition) * CFrame.Angles(0, math.rad(90), 0))
				end
			end
		end
	end
end

-- Starts the spawn loop and the walking loop. Called once by the server entrypoint.
function BrainrotSpawner.startSpawning()
	RunService.Heartbeat:Connect(stepWalkers)
	task.spawn(function()
		while true do
			task.wait(SPAWN_INTERVAL_SECONDS)
			if BrainrotSpawner.walkerCount() < MAX_WALKERS then
				BrainrotSpawner.spawnBrainrotOnPath(nil)
			end
		end
	end)
	-- Open with three walkers already on the path, so the first player sees the game.
	for _ = 1, 3 do
		BrainrotSpawner.spawnBrainrotOnPath(nil)
	end
end

return BrainrotSpawner
