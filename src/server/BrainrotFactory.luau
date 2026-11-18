-- BrainrotFactory: builds one brainrot as a Model of plain parts -- body, eyes,
-- one accessory that makes the species recognisable, a floating name label and a
-- buy prompt. No external assets: everything is a primitive, so the place file
-- stays self-contained and the game looks the same on every machine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local nextBrainrotId = 0

local function makePart(name, size, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	if shape then
		part.Shape = shape
	end
	return part
end

local function weldTo(part, body)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = part
	weld.Parent = body
end

-- One accessory per species, built from primitives on top of (or in front of) the body.
local function buildAccessory(accessory, model, body, topY, frontZ)
	local black = Color3.fromRGB(30, 30, 30)
	if accessory == "TopHat" then
		local brim = makePart("HatBrim", Vector3.new(2.6, 0.3, 2.6), black, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		brim.CFrame = body.CFrame * CFrame.new(0, topY + 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
		brim.Parent = model
		weldTo(brim, body)
		local top = makePart("HatTop", Vector3.new(1.4, 1.6, 1.4), black, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		top.CFrame = body.CFrame * CFrame.new(0, topY + 0.9, 0) * CFrame.Angles(0, 0, math.rad(90))
		top.Parent = model
		weldTo(top, body)
	elseif accessory == "BobaCup" then
		local cup = makePart("BobaCup", Vector3.new(1.2, 1.4, 1.2), Color3.fromRGB(230, 200, 150), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		cup.CFrame = body.CFrame * CFrame.new(0, topY + 0.7, 0) * CFrame.Angles(0, 0, math.rad(90))
		cup.Parent = model
		weldTo(cup, body)
		local straw = makePart("Straw", Vector3.new(0.25, 1.6, 0.25), Color3.fromRGB(255, 80, 80))
		straw.CFrame = body.CFrame * CFrame.new(0.4, topY + 1.6, 0) * CFrame.Angles(0, 0, math.rad(-15))
		straw.Parent = model
		weldTo(straw, body)
	elseif accessory == "Chopsticks" then
		for _, side in ipairs({ -1, 1 }) do
			local stick = makePart("Chopstick", Vector3.new(0.25, 3.2, 0.25), Color3.fromRGB(200, 150, 90), Enum.Material.Wood)
			stick.CFrame = body.CFrame * CFrame.new(side * 0.5, topY + 1.2, 0) * CFrame.Angles(0, 0, math.rad(side * 20))
			stick.Parent = model
			weldTo(stick, body)
		end
	elseif accessory == "Helmet" then
		local shell = makePart("Helmet", Vector3.new(3, 1.6, 3), Color3.fromRGB(220, 60, 60), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		shell.CFrame = body.CFrame * CFrame.new(0, topY + 0.4, 0)
		shell.Parent = model
		weldTo(shell, body)
	elseif accessory == "CaptainHat" then
		local cap = makePart("CaptainCap", Vector3.new(2.8, 0.8, 2.8), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		cap.CFrame = body.CFrame * CFrame.new(0, topY + 0.4, 0) * CFrame.Angles(0, 0, math.rad(90))
		cap.Parent = model
		weldTo(cap, body)
		local band = makePart("CaptainBand", Vector3.new(2.9, 0.4, 2.9), Color3.fromRGB(40, 80, 180), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		band.CFrame = body.CFrame * CFrame.new(0, topY + 0.15, 0) * CFrame.Angles(0, 0, math.rad(90))
		band.Parent = model
		weldTo(band, body)
	elseif accessory == "Glasses" then
		for _, side in ipairs({ -1, 1 }) do
			local lens = makePart("Lens", Vector3.new(0.9, 0.9, 0.2), black, Enum.Material.Glass, Enum.PartType.Cylinder)
			lens.CFrame = body.CFrame * CFrame.new(side * 0.75, 0.5, frontZ + 0.1) * CFrame.Angles(0, math.rad(90), 0)
			lens.Parent = model
			weldTo(lens, body)
		end
	elseif accessory == "Headphones" then
		local band = makePart("Headband", Vector3.new(0.4, 1.2, 3.2), black)
		band.CFrame = body.CFrame * CFrame.new(0, topY + 0.4, 0)
		band.Parent = model
		weldTo(band, body)
		for _, side in ipairs({ -1, 1 }) do
			local cup = makePart("EarCup", Vector3.new(0.6, 1.2, 1.2), Color3.fromRGB(255, 60, 120), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			cup.CFrame = body.CFrame * CFrame.new(side * 1.7, 0.4, 0)
			cup.Parent = model
			weldTo(cup, body)
		end
	elseif accessory == "Crown" then
		local gold = Color3.fromRGB(255, 200, 40)
		local ring = makePart("CrownRing", Vector3.new(2.2, 0.7, 2.2), gold, Enum.Material.Neon, Enum.PartType.Cylinder)
		ring.CFrame = body.CFrame * CFrame.new(0, topY + 0.35, 0) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = model
		weldTo(ring, body)
		for _, x in ipairs({ -0.8, 0, 0.8 }) do
			local spike = makePart("CrownSpike", Vector3.new(0.4, 0.8, 0.4), gold, Enum.Material.Neon)
			spike.CFrame = body.CFrame * CFrame.new(x, topY + 1, 0)
			spike.Parent = model
			weldTo(spike, body)
		end
	elseif accessory == "Sword" then
		local blade = makePart("Blade", Vector3.new(0.35, 3.4, 0.15), Color3.fromRGB(220, 220, 230), Enum.Material.Metal)
		blade.CFrame = body.CFrame * CFrame.new(2.1, 0.6, 0.6) * CFrame.Angles(0, 0, math.rad(-25))
		blade.Parent = model
		weldTo(blade, body)
		local guard = makePart("SwordGuard", Vector3.new(1.2, 0.3, 0.3), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		guard.CFrame = body.CFrame * CFrame.new(1.75, -0.7, 0.6) * CFrame.Angles(0, 0, math.rad(-25))
		guard.Parent = model
		weldTo(guard, body)
	elseif accessory == "Monocle" then
		local ring = makePart("Monocle", Vector3.new(1.1, 1.1, 0.15), Color3.fromRGB(255, 200, 40), Enum.Material.Metal, Enum.PartType.Cylinder)
		ring.CFrame = body.CFrame * CFrame.new(0.75, 0.5, frontZ + 0.1) * CFrame.Angles(0, math.rad(90), 0)
		ring.Parent = model
		weldTo(ring, body)
	end
end

-- The floating label over a brainrot: name, then rarity and $/s, big enough to read at a glance.
local function attachBrainrotLabel(model, body, title, rarity, rateText, rarityColor)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.fromOffset(220, 90)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, body.Size.Y / 2 + 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = title
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0.5, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.5, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Text = rarity .. "  |  " .. rateText
	rateLabel.TextColor3 = rarityColor
	rateLabel.TextScaled = true
	rateLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	rateLabel.TextStrokeTransparency = 0.4
	rateLabel.Parent = billboard
end

-- Builds one brainrot Model for a species and mutation, anchored at the origin,
-- facing +Z, with a Buy prompt. The caller moves it (PivotTo) where it belongs.
function BrainrotFactory.buildBrainrotModel(species, mutation, rarityColor)
	nextBrainrotId += 1
	local model = Instance.new("Model")
	model.Name = species.name

	local bodyColor = species.bodyColor
	local material = Enum.Material.SmoothPlastic
	if mutation == "Golden" then
		bodyColor = Color3.fromRGB(255, 200, 40)
		material = Enum.Material.Neon
	elseif mutation == "Rainbow" then
		bodyColor = Color3.fromRGB(255, 80, 200)
		material = Enum.Material.Neon
	end

	local body = makePart("Body", species.bodySize, bodyColor, material)
	body.CFrame = CFrame.new(0, 0, 0)
	body.Parent = model
	model.PrimaryPart = body

	-- Two eyes on the front face, so the brainrot always looks where it walks.
	local frontZ = species.bodySize.Z / 2
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(0.55, 0.55, 0.3), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		eye.CFrame = CFrame.new(side * 0.7, 0.45, frontZ + 0.1)
		eye.Parent = model
		weldTo(eye, body)
	end

	buildAccessory(species.accessory, model, body, species.bodySize.Y / 2, frontZ)

	if mutation ~= "Normal" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = mutation == "Golden" and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(255, 120, 220)
		sparkles.Parent = body
	end

	local title, rarity, rateText = BrainrotData.labelForBrainrot(species, mutation)
	attachBrainrotLabel(model, body, title, rarity, rateText, rarityColor)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = species.name .. " - $" .. species.price
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	model:SetAttribute("BrainrotId", "B" .. nextBrainrotId)
	model:SetAttribute("SpeciesId", species.id)
	model:SetAttribute("Mutation", mutation)
	return model
end

-- Switches a brainrot's prompt between buying (on the path) and stealing (on a base).
function BrainrotFactory.setBrainrotPromptMode(model, mode, priceText)
	local prompt = model:FindFirstChild("Body") and model.Body:FindFirstChild("BuyPrompt")
	if not prompt then
		return
	end
	if mode == "Steal" then
		prompt.ActionText = "Steal"
		prompt.ObjectText = model.Name
	else
		prompt.ActionText = "Buy"
		prompt.ObjectText = priceText or model.Name
	end
end

return BrainrotFactory
