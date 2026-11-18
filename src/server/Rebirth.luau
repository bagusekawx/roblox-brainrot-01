-- Rebirth: the long climb. A player trades everything -- cash and every brainrot
-- on their base -- for a permanent +25% income multiplier. Each rebirth costs ten
-- times the last, so the climb never ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))

local Rebirth = {}

-- Rebirths a player: destroys their brainrots, resets their cash to the starting
-- amount, and adds one permanent income multiplier level. Refused when they
-- cannot afford the rebirth cost.
function Rebirth.rebirthPlayer(player)
	local state = PlayerState.getPlayerState(player)
	if not state then
		return false
	end
	local cost = BrainrotData.rebirthCostFor(state.rebirths)
	if state.cash < cost then
		return false
	end
	for _, owned in pairs(state.owned) do
		if owned.model and owned.model.Parent then
			owned.model:Destroy()
		end
	end
	state.owned = {}
	state.cash = BrainrotData.StartingCash
	state.rebirths += 1
	if state.cashValue then
		state.cashValue.Value = state.cash
	end
	PlayerState.syncPlayerState(player)
	return true
end

return Rebirth
