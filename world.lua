Modules = {
	--	floating_island_generator = "github.com/caillef/cubzh-library/floating_island_generator:a728587",
	--  ui_blocks = "github.com/caillef/cubzh-library/ui_blocks:09941d5"
}

local maxSlots = 10

idToName = {
	"Stone",
	"Coal",
	"Copper",
	"DeepStone",
	"Iron",
	"Gold",
	"Diamond",
}

blockColors = {
	nil, -- air
	Color.Grey, -- stone
	Color.Black, -- coal
	Color.Orange, -- copper
	Color.DarkGrey, -- deepstone
	Color.White, -- iron
	Color.Yellow, -- gold
	Color(112, 209, 244), -- diamond
}

generate_map = function()
	map = Object()
	map:SetParent(World)

	local leftWing = MutableShape()
	leftWing:SetParent(map)
	leftWing:AddBlock(Color(100, 200, 100), 0, 0, 0)
	leftWing.Pivot = { 0, 1, 0 }
	leftWing.Scale = { 500, 100, 200 }
	leftWing.LocalPosition = { 0, 0, 0 }

	local rightWing = MutableShape()
	rightWing:SetParent(map)
	rightWing:AddBlock(Color(100, 200, 100), 0, 0, 0)
	rightWing.Pivot = { 0, 1, 0 }
	rightWing.Scale = { 500, 100, 200 }
	rightWing.LocalPosition = { 0, 0, 400 }

	local upWing = MutableShape()
	upWing:SetParent(map)
	upWing:AddBlock(Color(100, 200, 100), 0, 0, 0)
	upWing.Pivot = { 0, 1, 0 }
	upWing.Scale = { 200, 100, 600 }
	upWing.LocalPosition = { 400, 0, 0 }

	local downWing = MutableShape()
	downWing:SetParent(map)
	downWing:AddBlock(Color(100, 200, 100), 0, 0, 0)
	downWing.Pivot = { 0, 1, 0 }
	downWing.Scale = { 200, 100, 600 }
	downWing.LocalPosition = { 0, 0, 0 }
end

blocksModule = {}
blocksModule.start = function(self)
	self.blockShape = MutableShape()
	self.blockShape.Name = "Blocks"
	self.blockShape.Physics = PhysicsMode.StaticPerBlock
	self.blockShape:SetParent(World)
	self.CollisionGroups = Map.CollisionGroups
	self.CollidesWithGroups = Map.CollidesWithGroups
	self.blockShape.Position = { 200, 0, 200 }
	self.blockShape.Scale = 20
	self.blockShape.Pivot = { 0, 1, 0 }
	self.blockShape.PrivateDrawMode = 8
	for z = 0, 49 do
		for j = 0, 9 do
			for i = 0, 9 do
				self.blockShape:AddBlock(Color.Grey, i, -z, j)
			end
		end
	end
end

blocksModule.hitBlock = function(self, block)
	local x, y, z = block.Coords.X, block.Coords.Y, block.Coords.Z
	dojo.actions.hit_block(x, y, z)
end

local leaderboardTextBlocks
local leaderboardTextHits
local leaderboardTextCoins
initLeaderboard = function()
	local quad = Quad()
	quad.Color = Color.White
	quad.Width = 80
	quad.Height = 100
	quad:SetParent(World)
	quad.Anchor = { 0.5, 0 }

	local text = Text()
	text.Text = "Top 10 Daily\n- Blocks Mined -"
	text:SetParent(quad)
	text.FontSize = 7
	text.Type = TextType.World
	text.IsUnlit = true
	text.Color = Color.Black
	text.Anchor = { 0.5, 1 }
	text.LocalPosition = { 0, 95, -1 }

	leaderboardTextBlocks = Text()
	leaderboardTextBlocks.Text = "loading..."
	leaderboardTextBlocks:SetParent(quad)
	leaderboardTextBlocks.FontSize = 6
	leaderboardTextBlocks.Type = TextType.World
	leaderboardTextBlocks.IsUnlit = true
	leaderboardTextBlocks.Color = Color.Black
	leaderboardTextBlocks.Anchor = { 0.5, 1 }
	leaderboardTextBlocks.LocalPosition = { 0, 75, -1 }

	local quad2 = Quad()
	quad2.Color = Color.White
	quad2.Width = 80
	quad2.Height = 100
	quad2:SetParent(World)
	quad2.Anchor = { 0.5, 0 }

	local text = Text()
	text.Text = "Top 10 Daily\n- Block Hits -"
	text:SetParent(quad2)
	text.FontSize = 7
	text.Type = TextType.World
	text.IsUnlit = true
	text.Color = Color.Black
	text.Anchor = { 0.5, 1 }
	text.LocalPosition = { 0, 95, -1 }

	leaderboardTextHits = Text()
	leaderboardTextHits.Text = "loading..."
	leaderboardTextHits:SetParent(quad2)
	leaderboardTextHits.FontSize = 6
	leaderboardTextHits.Type = TextType.World
	leaderboardTextHits.IsUnlit = true
	leaderboardTextHits.Color = Color.Black
	leaderboardTextHits.Anchor = { 0.5, 1 }
	leaderboardTextHits.LocalPosition = { 0, 75, -1 }

	local quad3 = Quad()
	quad3.Color = Color.White
	quad3.Width = 80
	quad3.Height = 100
	quad3:SetParent(World)
	quad3.Anchor = { 0.5, 0 }

	local text = Text()
	text.Text = "Top 10 Daily\n- Coins Earned -"
	text:SetParent(quad3)
	text.FontSize = 7
	text.Type = TextType.World
	text.IsUnlit = true
	text.Color = Color.Black
	text.Anchor = { 0.5, 1 }
	text.LocalPosition = { 0, 95, -1 }

	leaderboardTextCoins = Text()
	leaderboardTextCoins.Text = "loading..."
	leaderboardTextCoins:SetParent(quad3)
	leaderboardTextCoins.FontSize = 6
	leaderboardTextCoins.Type = TextType.World
	leaderboardTextCoins.IsUnlit = true
	leaderboardTextCoins.Color = Color.Black
	leaderboardTextCoins.Anchor = { 0.5, 1 }
	leaderboardTextCoins.LocalPosition = { 0, 75, -1 }

	quad.Position = { 150, 0, 150 }
	quad2.Position = { 130, 0, 300 }
	quad3.Position = { 150, 0, 450 }
	quad.Rotation.Y = math.pi * 1.4
	quad2.Rotation.Y = math.pi * 1.5
	quad3.Rotation.Y = math.pi * 1.6
end

local leaderboardEntries = {}
updateLeaderboard = function(entry)
	if entry.day.value ~= math.floor(Time.Unix() / 86400) then
		return
	end
	leaderboardEntries[entry.player.value] = entry

	local listCoinsCollected = {}
	for _, elem in pairs(leaderboardEntries) do
		if elem.nbCoinsCollected.value > 0 then
			table.insert(listCoinsCollected, elem)
		end
	end
	if #listCoinsCollected > 0 then
		table.sort(listCoinsCollected, function(a, b)
			return a.nbCoinsCollected.value - b.nbCoinsCollected.value
		end)
		leaderboardTextCoins.Text = ""
		for i = 1, 10 do
			if not listCoinsCollected[i] then
				break
			end
			local name = string.sub(listCoinsCollected[i].player.value, 1, 8)
			if listCoinsCollected[i].player.value == dojo.burnerAccount.Address then
				name = "> you <"
			end
			leaderboardTextCoins.Text = leaderboardTextCoins.Text
				.. name
				.. ": "
				.. tostring(math.floor(listCoinsCollected[i].nbCoinsCollected.value))
				.. "\n"
		end
	end

	local listBlocksHit = {}
	for _, elem in pairs(leaderboardEntries) do
		if elem.nbHits.value > 0 then
			table.insert(listBlocksHit, elem)
		end
	end
	if #listBlocksHit > 0 then
		table.sort(listBlocksHit, function(a, b)
			return a.nbHits.value - b.nbHits.value
		end)
		leaderboardTextHits.Text = ""
		for i = 1, 10 do
			if not listBlocksHit[i] then
				break
			end
			local name = string.sub(listBlocksHit[i].player.value, 1, 8)
			if listBlocksHit[i].player.value == dojo.burnerAccount.Address then
				name = "> you <"
			end
			leaderboardTextHits.Text = leaderboardTextHits.Text
				.. name
				.. ": "
				.. tostring(math.floor(listBlocksHit[i].nbHits.value))
				.. "\n"
		end
	end

	local listBlocksMined = {}
	for _, elem in pairs(leaderboardEntries) do
		if elem.nbBlocksBroken.value > 0 then
			table.insert(listBlocksMined, elem)
		end
	end
	if #listBlocksMined > 0 then
		table.sort(listBlocksMined, function(a, b)
			return a.nbBlocksBroken.value - b.nbBlocksBroken.value
		end)
		leaderboardTextBlocks.Text = ""
		for i = 1, 10 do
			if not listBlocksMined[i] then
				break
			end
			local name = string.sub(listBlocksMined[i].player.value, 1, 8)
			if listBlocksMined[i].player.value == dojo.burnerAccount.Address then
				name = "> you <"
			end
			leaderboardTextBlocks.Text = leaderboardTextBlocks.Text
				.. name
				.. ": "
				.. tostring(math.floor(listBlocksMined[i].nbBlocksBroken.value))
				.. "\n"
		end
	end
end

local inventoryNode
updateInventory = function(inventory)
	if inventory.player.value ~= dojo.burnerAccount.Address then
		return
	end
	local slots = {}
	local totalQty = 0
	for i = 1, 7 do
		local nbInSlot = ((inventory.data.value >> (8 * i)) & 255)
		if nbInSlot > 0 then
			table.insert(slots, { blockType = i, qty = nbInSlot })
			totalQty = totalQty + nbInSlot
		end
	end

	local ui = require("uikit")
	if inventoryNode then
		inventoryNode:remove()
	end
	local nodes = {
		ui:createText("Inventory"),
		ui:createText(string.format("%d/%d", totalQty, maxSlots or 10)),
	}
	for _, slot in ipairs(slots) do
		table.insert(nodes, ui:createText(string.format("%s: %d", idToName[slot.blockType], slot.qty)))
	end
	local bgInventory = ui:createFrame(Color.White)
	bgInventory.parentDidResize = function()
		bgInventory.Width = 100
		bgInventory.Height = Screen.Height / 3
		bgInventory.pos = { Screen.Width - bgInventory.Width, Screen.Height - Screen.SafeArea.Top - bgInventory.Height }
	end
	bgInventory:parentDidResize()
	inventoryNode = ui_blocks:createLineContainer({
		dir = "vertical",
		nodes = nodes,
	})
	ui_blocks:anchorNode(inventoryNode, "right", "top", 5)
end

Client.OnStart = function()
	floating_island_generator:generateIslands({
		nbIslands = 30, -- number of islands
		minSize = 4, -- min size of island
		maxSize = 7, -- max size of island
		safearea = 400, -- min dist of islands from 0,0,0
		dist = 750, -- max dist of islands
	})

	initPlayer()
	initLeaderboard()
	initDojo()

	Fog.On = false
	generate_map()
	Player:SetParent(World)
	Player.Position = Number3(250, 5, 150)

	blocksModule:start()
end

Client.OnChat = function(payload)
	if payload.message == "sell" then
		dojo.actions.sell_all()
	end
	return true -- consumed
end

Client.Action1 = function()
	-- if Player.IsOnGround then
	Player.Velocity.Y = 100
	-- end
end

Client.Action2 = function()
	local impact = Player:CastRay(nil, Player)
	if impact.Object and impact.Object.Name == "Blocks" then
		impact = Player:CastRay(impact.Object)
		if impact.Distance < 100 then
			blocksModule:hitBlock(impact.Block)
		end
	end
end

initPlayer = function()
	require("crosshair"):show()
	Player.Avatar:loadEquipment({ type = "hair" })
	Player.Avatar:loadEquipment({ type = "jacket" })
	Player.Avatar:loadEquipment({ type = "pants" })
	Player.Avatar:loadEquipment({ type = "boots" })
	if Player.Animations then
		-- remove view bobbing
		Player.Animations.Walk.Duration = 10000
		-- remove idle animation
		Player.Animations.Idle.Duration = 10000
	end
	Player:SetParent(World)
	Camera.FOV = 80
	require("object_skills").addStepClimbing(Player, { mapScale = 20 })
	Camera:SetModeFirstPerson()
	if Player.EyeLidRight then
		Player.EyeLidRight:RemoveFromParent()
		Player.EyeLidLeft:RemoveFromParent()
	end
end

initDojo = function()
	worldInfo.onConnect = startGame
	dojo:createToriiClient(worldInfo)
end

worldInfo = {
	rpc_url = "https://api.cartridge.gg/x/diamond-pit/katana",
	torii_url = "https://api.cartridge.gg/x/diamond-pit/torii",
	world = "0xb4079627ebab1cd3cf9fd075dda1ad2454a7a448bf659591f259efa2519b18",
	actions = "0x3610b797baec740e2fa25ae90b4a57d92b04f48a1fdbae1ae203eaf9723c1a0",
	playerAddress = "0x657e5f424dc6dee0c5a305361ea21e93781fea133d83efa410b771b7f92b",
	playerSigningKey = "0xcd93de85d43988b9492bfaaff930c129fc3edbc513bb0c2b81577291848007",
}

function getOrCreateBlocksColumn(key, entity)
	local rawColumn = dojo:getModel(entity, "BlocksColumn")
	if not rawColumn then
		return
	end
	local column = {
		x = rawColumn.x.value,
		y = rawColumn.y.value,
		z_layer = rawColumn.z_layer.value,
		data = {
			raw = string.sub(rawColumn.data.value, 3, #rawColumn.data.value),
			getBlock = function(self, index)
				return tonumber(
					string.sub(
						self.raw,
						#self.raw - math.min(#self.raw - 1, (math.floor(index) * 3 + 2)),
						#self.raw - (math.floor(index) * 3)
					),
					16
				)
			end,
		},
	}

	for k = 0, 9 do
		local blockInfo = column.data:getBlock(k)
		local blockType = blockInfo >> 7
		local blockHp = blockInfo & 127
		local z = -(column.z_layer * 10 + k)
		local b = blocksModule.blockShape:GetBlock(column.x, z, column.y)
		local blockColor = blockColors[blockType + 1]
		if b and (blockHp == 0 or blockType == 0 or blockColor == nil) then
			b:Remove()
		elseif b and b.Color ~= blockColor then
			b:Replace(blockColor)
		elseif not b and blockHp > 0 then
			blocksModule.blockShape:AddBlock(blockColor, column.x, z, column.y)
		end
	end
end

function updateEntity(entities)
	for key, newEntity in pairs(entities) do
		if getOrCreateBlocksColumn(key, newEntity) then
			getOrCreateBlocksColumn(key, newEntity):update(newEntity)
		elseif dojo:getModel(newEntity, "PlayerInventory") then
			updateInventory(dojo:getModel(newEntity, "PlayerInventory"))
		elseif dojo:getModel(newEntity, "DailyLeaderboardEntry") then
			updateLeaderboard(dojo:getModel(newEntity, "DailyLeaderboardEntry"))
		end
	end
end

function startGame(toriiClient)
	-- sync existing entities
	toriiClient:Entities('{ "limit": 100, "offset": 0 }', updateEntity)

	-- set on entity update callback
	-- match everything
	-- on 1.0.0, add [] around
	local clauseJsonStr = '{ "Keys": { "keys": [], "models": [], "pattern_matching": "VariableLen" } }'
	toriiClient:OnEntityUpdate(clauseJsonStr, updateEntity)
end

-- dojo module

dojo = {}

dojo.getOrCreateBurner = function(self, config, cb)
	self.toriiClient:CreateBurner(config.playerAddress, config.playerSigningKey, function(success, burnerAccount)
		if not success then
			error("Can't create burner")
			return
		end
		dojo.burnerAccount = burnerAccount
		cb()
	end)
end

dojo.createToriiClient = function(self, config)
	dojo.config = config
	local err
	dojo.toriiClient = Dojo:CreateToriiClient(config.torii_url, config.rpc_url, config.world)
	dojo.toriiClient.OnConnect = function(success)
		if not success then
			print("Connection failed")
			return
		end
		self:getOrCreateBurner(config, function()
			config.onConnect(dojo.toriiClient)
		end)
	end
	dojo.toriiClient:Connect()
end

dojo.getModel = function(_, entity, modelName)
	for key, model in pairs(entity) do
		if key == modelName then
			return model
		end
	end
end

function bytes_to_hex(data)
	local hex = "0x"
	for i = 1, data.Length do
		hex = hex .. string.format("%02x", data[i])
	end
	return hex
end

function number_to_hexstr(number)
	return "0x" .. string.format("%x", number)
end

-- generated contracts
dojo.actions = {
	hit_block = function(x, y, z)
		if not dojo.toriiClient then
			return
		end
		-- z is down in Dojo, y is down on Cubzh
		local calldatastr =
			string.format('["%s","%s","%s"]', number_to_hexstr(x), number_to_hexstr(z), number_to_hexstr(-y))
		print("Calling hit_block", calldatastr)
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "hit_block", calldatastr)
	end,
	sell_all = function()
		if not dojo.toriiClient then
			return
		end
		print("Calling sell_all")
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "sell_all", "[]")
	end,
}

-- Module to create floating island

--[[
USAGE
Modules = {
    floating_island_generator = "github.com/caillef/cubzh-library/floating_island_generator:82d22a5"
}

Client.OnStart = function()
    floating_island_generator:generateIslands({
		nbIslands = 20, -- number of islands
		minSize = 4, -- min size of island
		maxSize = 7, -- max size of island
		safearea = 200, -- min dist of islands from 0,0,0
		dist = 750, -- max dist of islands
	})
end
--]]

floating_island_generator = {}

local cachedTree

local COLORS = {
	GRASS = Color(19, 133, 16),
	DIRT = Color(107, 84, 40),
	STONE = Color.Grey,
}

local function islandHeight(x, z, radius)
	local distance = math.sqrt(x * x + z * z)
	local normalizedDistance = distance / radius
	local maxy = -((1 + radius) * 2 - (normalizedDistance ^ 4) * distance)
	return maxy
end

local function onReady(callback)
	Object:Load("knosvoxel.oak_tree", function(obj)
		cachedTree = obj
		callback()
	end)
end

local function create(radius)
	local shape = MutableShape()
	shape.Pivot = { 0.5, 0.5, 0.5 }
	for z = -radius, radius do
		for x = -radius, radius do
			local maxy = islandHeight(x, z, radius)
			shape:AddBlock(COLORS.DIRT, x, -2, z)
			shape:AddBlock(COLORS.GRASS, x, -1, z)
			shape:AddBlock(COLORS.GRASS, x, 0, z)
			if maxy <= -3 then
				shape:AddBlock(COLORS.DIRT, x, -3, z)
			end
			for y = maxy, -3 do
				shape:AddBlock(COLORS.STONE, x, y, z)
			end
		end
	end

	local xShift = math.random(-radius, radius)
	local zShift = math.random(-radius, radius)
	for z = -radius, radius do
		for x = -radius, radius do
			local maxy = islandHeight(x, z, radius) - 2
			shape:AddBlock(COLORS.DIRT, x + xShift, -2 + 2, z + zShift)
			shape:AddBlock(COLORS.GRASS, x + xShift, -1 + 2, z + zShift)
			shape:AddBlock(COLORS.GRASS, x + xShift, 0 + 2, z + zShift)
			if maxy <= -3 + 2 then
				shape:AddBlock(COLORS.DIRT, x + xShift, -3 + 2, z + zShift)
			end
			for y = maxy, -3 + 2 do
				shape:AddBlock(COLORS.STONE, x + xShift, y, z + zShift)
			end
		end
	end

	for _ = 1, math.random(1, 2) do
		local obj = Shape(cachedTree, { includeChildren = true })
		obj.Position = { 0, 0, 0 }
		local box = Box()
		box:Fit(obj, true)
		obj.Pivot = Number3(obj.Width / 2, box.Min.Y + obj.Pivot.Y + 4, obj.Depth / 2)
		obj:SetParent(shape)
		require("hierarchyactions"):applyToDescendants(obj, { includeRoot = true }, function(o)
			o.Physics = PhysicsMode.Disabled
		end)
		local coords = Number3(math.random(-radius + 1, radius - 1), 0, math.random(-radius + 1, radius - 1))
		while shape:GetBlock(coords) do
			coords.Y = coords.Y + 1
		end
		obj.Scale = math.random(70, 150) / 1000
		obj.Rotation.Y = math.random(1, 4) * math.pi * 0.25
		obj.LocalPosition = coords
	end

	return shape
end

floating_island_generator.generateIslands = function(_, config)
	config = config or {}
	local nbIslands = config.nbIslands or 20
	local minSize = config.minSize or 4
	local maxSize = config.maxSize or 7
	local dist = config.dist or 750
	local safearea = config.safearea or 200
	onReady(function()
		for i = 1, nbIslands do
			local island = create(math.random(minSize, maxSize))
			island:SetParent(World)
			island.Scale = Map.Scale
			island.Physics = PhysicsMode.Disabled
			local x = math.random(-dist, dist)
			local z = math.random(-dist, dist)
			while (x >= -safearea and x <= safearea) and (z >= -safearea and z <= safearea) do
				x = math.random(-dist, dist)
				z = math.random(-dist, dist)
			end
			island.Position = {
				x + 250,
				150 + math.random(300) - 150,
				z + 250,
			}
			local t = x + z
			LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
				t = t + dt
				island.Position.Y = island.Position.Y + math.sin(t) * 0.02
			end)
		end
	end)
end

ui_blocks = {}

ui_blocks.createTriptych = function(_, config)
	local ui = require("uikit")

	local node = ui:createFrame(config.color)

	local dir = config.dir or "horizontal"

	local left = config.left or config.top
	local center = config.center
	local right = config.right or config.bottom

	if left then
		left:setParent(node)
	end
	if center then
		center:setParent(node)
	end
	if right then
		right:setParent(node)
	end

	node.parentDidResize = function()
		if not node.parent then
			return
		end
		node.Width = node.parent.Width
		node.Height = node.parent.Height

		if center then
			center.pos = { node.Width * 0.5 - center.Width * 0.5, node.Height * 0.5 - center.Height * 0.5 }
		end

		if dir == "horizontal" then
			if left then
				left.pos = { 0, node.Height * 0.5 - left.Height * 0.5 }
			end
			if right then
				right.pos = { node.Width - right.Width, node.Height * 0.5 - right.Height * 0.5 }
			end
		end
		if dir == "vertical" then
			if left then
				left.pos = { node.Width * 0.5 - left.Width * 0.5, node.Height - left.Height }
			end
			if right then
				right.pos = { node.Width * 0.5 - right.Width * 0.5, 0 }
			end
		end
	end

	return node
end

ui_blocks.createColumns = function(_, config)
	local ui = require("uikit")

	local node = ui:createFrame()

	local nodes = config.nodes

	local nbColumns = #nodes
	if not nbColumns or nbColumns < 1 then
		error("config.nodes must have at least two nodes")
		return
	end

	local columns = {}
	for i = 1, nbColumns do
		local column = ui:createFrame()
		nodes[i]:setParent(column)
		column:setParent(node)
		table.insert(columns, column)
	end
	node.columns = columns

	node.parentDidResize = function()
		if not node.parent then
			return
		end
		node.Width = node.parent.Width
		node.Height = node.parent.Height
		local columnWidth = math.floor(node.Width / nbColumns)
		for k, column in ipairs(columns) do
			column.Width = columnWidth
			column.Height = node.Height
			column.pos = { (k - 1) * columnWidth, 0 }
		end
	end

	return node
end

ui_blocks.createRows = function(_, config)
	local ui = require("uikit")

	local node = ui:createFrame()

	local nodes = config.nodes

	local nbRows = #nodes
	if not nbRows or nbRows < 1 then
		error("config.nodes must have at least two nodes")
		return
	end

	local rows = {}
	for i = 1, nbRows do
		local row = ui:createFrame()
		nodes[i]:setParent(row)
		row:setParent(node)
		table.insert(rows, row)
	end
	node.rows = rows

	node.parentDidResize = function()
		if not node.parent then
			return
		end
		node.Width = node.parent.Width
		node.Height = node.parent.Height
		local rowHeight = math.floor(node.Height / nbRows)
		for k, row in ipairs(rows) do
			row.Width = node.Width
			row.Height = rowHeight
			row.pos = { 0, node.Height - k * rowHeight }
		end
	end

	return node
end

ui_blocks.createLineContainer = function(_, config)
	local uiContainer = require("ui_container")

	local node
	if config.dir == "vertical" then
		node = uiContainer:createVerticalContainer()
	else
		node = uiContainer:createHorizontalContainer()
	end

	for _, info in ipairs(config.nodes) do
		if info.type == "separator" then
			node:pushSeparator()
		elseif info.type == "gap" then
			node:pushGap()
		elseif info.type == "node" then
			node:pushElement(info.node)
		else
			node:pushElement(info)
		end
	end

	return node
end

ui_blocks.setNodePos = function(_, node, horizontalAnchor, verticalAnchor, margins)
	margins = margins or 0
	if type(margins) ~= "table" then
		-- left, bottom, right, top
		margins = { margins, margins, margins, margins }
	end

	local x = 0
	local y = 0

	local parentWidth = node.parent and node.parent.Width or Screen.Width
	local parentHeight = node.parent and node.parent.Height or (Screen.Height - Screen.SafeArea.Top)

	if horizontalAnchor == "left" then
		x = margins[3]
	elseif horizontalAnchor == "center" then
		x = parentWidth * 0.5 - node.Width * 0.5
	elseif horizontalAnchor == "right" then
		x = parentWidth - margins[1] - node.Width
	end

	if verticalAnchor == "bottom" then
		y = margins[2]
	elseif verticalAnchor == "center" then
		y = parentHeight * 0.5 - node.Height * 0.5
	elseif verticalAnchor == "top" then
		y = parentHeight - margins[4] - node.Height
	end

	node.pos = { x, y }
end

-- Only works on node that are not resized // where parentDidResize is not set
-- If you need to define parentDidResize, use setNodePos
ui_blocks.anchorNode = function(_, node, horizontalAnchor, verticalAnchor, margins)
	node.parentDidResize = function()
		ui_blocks:setNodePos(node, horizontalAnchor, verticalAnchor, margins)
	end
	node:parentDidResize()
	return node
end

ui_blocks.createBlock = function(_, config)
	local ui = require("uikit")

	local node = ui:createFrame()

	local subnode
	if config.triptych then
		subnode = ui_blocks:createTriptych(config.triptych)
	elseif config.columns then
		subnode = ui_blocks:createColumns({ nodes = config.columns })
	elseif config.rows then
		subnode = ui_blocks:createRows({ nodes = config.rows })
	end
	subnode:setParent(node)

	node.parentDidResize = function()
		if config.parentDidResize then
			config.parentDidResize(node)
		end
		node.Width = config.width and config.width(node) or (node.parent and node.parent.Width or Screen.Width)
		node.Height = config.height and config.height(node)
			or (node.parent and node.parent.Height or Screen.Height - Screen.SafeArea.Top)
		node.pos = config.pos and config.pos(node) or { 0, 0 }
	end
	node:parentDidResize()

	return node
end
