-- PlotManager: hands each player one of the six base plots around the spawn path
-- and works out where each owned brainrot stands on it. Plots are the coloured
-- platforms in default.project.json, grouped under Workspace.BasePlots.

local Workspace = game:GetService("Workspace")

local PlotManager = {}

-- Twelve slot offsets on a plot, in the order brainrots fill them (3 columns, 4 rows).
local SLOT_OFFSETS = {
	Vector3.new(-7, 0, -6), Vector3.new(0, 0, -6), Vector3.new(7, 0, -6),
	Vector3.new(-7, 0, -2), Vector3.new(0, 0, -2), Vector3.new(7, 0, -2),
	Vector3.new(-7, 0, 2), Vector3.new(0, 0, 2), Vector3.new(7, 0, 2),
	Vector3.new(-7, 0, 6), Vector3.new(0, 0, 6), Vector3.new(7, 0, 6),
}

local owners = {} -- plot Part -> Player

local function plotParts()
	local folder = Workspace:WaitForChild("BasePlots")
	local plots = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 4) == "Plot" and #child.Name == 5 then
			table.insert(plots, child)
		end
	end
	table.sort(plots, function(a, b)
		return a.Name < b.Name
	end)
	return plots
end

-- Gives a joining player the first free plot, or nil when all six are taken.
function PlotManager.assignBasePlot(player)
	for _, plot in ipairs(plotParts()) do
		if owners[plot] == nil then
			owners[plot] = player
			return plot
		end
	end
	return nil
end

-- Frees a leaving player's plot for the next player.
function PlotManager.releaseBasePlot(player)
	for plot, owner in pairs(owners) do
		if owner == player then
			owners[plot] = nil
		end
	end
end

-- The plot a player owns, or nil when they have none.
function PlotManager.getPlayerPlot(player)
	for plot, owner in pairs(owners) do
		if owner == player then
			return plot
		end
	end
	return nil
end

-- The centre of a player's plot, used to tell when a thief has made it home.
function PlotManager.getPlotCenter(player)
	local plot = PlotManager.getPlayerPlot(player)
	if not plot then
		return nil
	end
	return plot.Position
end

-- Where a brainrot stands on a plot: its slot offset above the platform's top.
function PlotManager.slotPositionFor(player, slotIndex)
	local plot = PlotManager.getPlayerPlot(player)
	if not plot then
		return nil
	end
	local offset = SLOT_OFFSETS[slotIndex]
	if not offset then
		return nil
	end
	-- Platform top is 1 stud above its centre; a brainrot's body centre sits 1.5 above that.
	return plot.Position + Vector3.new(offset.X, 2.5, offset.Z)
end

-- The first empty slot index on a player's base, or nil when the base is full.
function PlotManager.firstFreeSlotIndex(player, owned)
	local taken = {}
	for _, brainrot in pairs(owned) do
		taken[brainrot.slotIndex] = true
	end
	for index = 1, #SLOT_OFFSETS do
		if not taken[index] then
			return index
		end
	end
	return nil
end

return PlotManager
