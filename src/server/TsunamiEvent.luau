-- TsunamiEvent: the wave that punishes slow thieves. Every few minutes a warning
-- banner goes out, then a wall of water sweeps the island from west to east and
-- knocks every carried brainrot loose, back to its owner's base. A thief who has
-- not made it home by the time the wave rolls loses the catch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Steal = require(script.Parent:WaitForChild("Steal"))

local TsunamiEvent = {}

local WARNING_SECONDS = 10
local WAVE_CROSS_SECONDS = 8
local CYCLE_MIN_SECONDS = 150
local CYCLE_MAX_SECONDS = 210

local eventBannerRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EventBanner")

local function broadcastBanner(text, seconds)
	eventBannerRemote:FireAllClients(text, seconds)
end

-- Sweeps one tsunami across the island: builds the wave wall, tweens it from the
-- west gate to the east gate, drops every carried brainrot, then clears it away.
-- A TOUR.json tour calls this with any argument to stage the wave for a screenshot.
function TsunamiEvent.triggerTsunamiWave(_arg)
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(4, 14, 220)
	wave.Color = Color3.fromRGB(60, 140, 255)
	wave.Material = Enum.Material.SmoothPlastic
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = CFrame.new(-120, 7, 0)
	wave.Parent = Workspace

	broadcastBanner("TSUNAMI! Hold on tight!", WAVE_CROSS_SECONDS)

	-- The wave knocks every carried brainrot loose the moment it starts moving.
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		Steal.dropAllCarriedBrainrots(player)
	end

	local tween = TweenService:Create(wave, TweenInfo.new(WAVE_CROSS_SECONDS, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(120, 7, 0),
	})
	tween:Play()
	tween.Completed:Wait()
	wave:Destroy()
end

-- Starts the tsunami cycle: wait, warn for 10 seconds, sweep the wave, repeat.
function TsunamiEvent.startTsunamiCycle()
	task.spawn(function()
		while true do
			task.wait(math.random(CYCLE_MIN_SECONDS, CYCLE_MAX_SECONDS))
			broadcastBanner("TSUNAMI INCOMING - GET HOME!", WARNING_SECONDS)
			task.wait(WARNING_SECONDS)
			TsunamiEvent.triggerTsunamiWave(0)
		end
	end)
end

return TsunamiEvent
