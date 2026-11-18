-- Brainrot Bay server entrypoint: wires every system together. Players join,
-- get a state and a base plot; brainrots walk the path; income ticks once a
-- second; the tsunami rolls every few minutes; and every client request is
-- validated here, on the server, before anything changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script:WaitForChild("PlayerState"))
local PlotManager = require(script:WaitForChild("PlotManager"))
local BrainrotSpawner = require(script:WaitForChild("BrainrotSpawner"))
local Shop = require(script:WaitForChild("Shop"))
local Steal = require(script:WaitForChild("Steal"))
local Rebirth = require(script:WaitForChild("Rebirth"))
local TsunamiEvent = require(script:WaitForChild("TsunamiEvent"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shopRemote = remotes:WaitForChild("ShopRequest")
local rebirthRemote = remotes:WaitForChild("RebirthRequest")
local lockRemote = remotes:WaitForChild("LockBaseRequest")

-- One prompt, two jobs: a walker on the path is bought, a brainrot sitting on a
-- base is stolen. The prompt's mode was set when the brainrot was placed.
local function onBrainrotPrompted(player, model)
	if BrainrotSpawner.getWalkerInfo(model) then
		Shop.buyBrainrotFromPath(player, model)
	else
		Steal.tryStealBrainrot(player, model)
	end
end

-- Sets a respawning character's walk speed from the upgrades its player bought.
local function applyWalkSpeed(player, character)
	local state = PlayerState.getPlayerState(player)
	local humanoid = character:WaitForChild("Humanoid")
	if state then
		humanoid.WalkSpeed = BrainrotData.BaseWalkSpeed + 2 * state.walkSpeedLevel
	end
	-- Dying drops everything the player is carrying, back to its owners.
	humanoid.Died:Connect(function()
		Steal.dropAllCarriedBrainrots(player)
	end)
end

-- Sets a joining player up: fresh state, a base plot, and their first HUD sync.
local function onPlayerAdded(player)
	local state = PlayerState.createPlayerState(player)
	state.plot = PlotManager.assignBasePlot(player)
	player.CharacterAdded:Connect(function(character)
		applyWalkSpeed(player, character)
	end)
	PlayerState.syncPlayerState(player)
end

-- Cleans a leaving player up: their carried brainrots go home, their owned ones
-- are removed with them, and their plot opens for the next player.
local function onPlayerRemoving(player)
	Steal.dropAllCarriedBrainrots(player)
	local state = PlayerState.getPlayerState(player)
	if state then
		for _, owned in pairs(state.owned) do
			if owned.model and owned.model.Parent then
				owned.model:Destroy()
			end
		end
	end
	PlotManager.releaseBasePlot(player)
	PlayerState.removePlayerState(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Client requests, each validated by the module that owns the thing asked for.
shopRemote.OnServerEvent:Connect(function(player, upgradeId)
	if typeof(upgradeId) == "string" then
		Shop.handleShopRequest(player, upgradeId)
	end
end)
rebirthRemote.OnServerEvent:Connect(function(player)
	Rebirth.rebirthPlayer(player)
end)
lockRemote.OnServerEvent:Connect(function(player)
	Steal.lockPlayerBase(player)
end)

BrainrotSpawner.setPromptHandler(onBrainrotPrompted)
BrainrotSpawner.startSpawning()
Steal.startDeliveryWatch()
TsunamiEvent.startTsunamiCycle()

-- Rojo project files cannot express UDim2 values, so the welcome sign's label
-- has no Size in the place file; size it to fill its SurfaceGui here, before
-- any player can see the sign.
local signBoard = workspace:FindFirstChild("WelcomeSignBoard")
local signGui = signBoard and signBoard:FindFirstChild("SignGui")
local signText = signGui and signGui:FindFirstChild("SignText")
if signText then
	signText.Size = UDim2.fromScale(1, 1)
end

-- The heartbeat of the game, once a second: pay every player's income, refresh
-- the steal prompts (a lock that ran out re-enables them), and sync every HUD.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerState.tickPlayerIncome(player)
			Steal.refreshStealPrompts(player)
		end
		PlayerState.syncAllPlayerStates()
	end
end)
