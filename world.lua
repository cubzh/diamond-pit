Modules = {
	floating_island_generator = "github.com/caillef/cubzh-library/floating_island_generator:a728587",
	ui_blocks = "github.com/caillef/cubzh-library/ui_blocks:09941d5",
}

local maxSlots = 5
local pickaxeStrength = 1

local PICKAXE_STRENGTHS = {
	[0] = 1,
	[1] = 2,
	[2] = 3,
	[3] = 4,
	[4] = 8,
	[5] = 12,
	[6] = 20,
}

local PICKAXE_UPGRADE_PRICES = {
	[0] = 0,
	[1] = 10,
	[2] = 25,
	[3] = 50,
	[4] = 100,
	[5] = 250,
	[6] = 800,
}

local BACKPACK_MAX_SLOTS = {
	[0] = 5,
	[1] = 15,
	[2] = 25,
	[3] = 40,
	[4] = 75,
	[5] = 100,
	[6] = 160,
}

local BACKPACK_UPGRADE_PRICES = {
	[0] = 0,
	[1] = 5,
	[2] = 20,
	[3] = 80,
	[4] = 135,
	[5] = 450,
	[6] = 1000,
}

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

	local leftStone = MutableShape()
	leftStone:SetParent(map)
	leftStone:AddBlock(Color.DarkGrey, 0, 0, 0)
	leftStone.Pivot = { 0, 1, 0 }
	leftStone.Scale = { 500, 2000, 200 }
	leftStone.LocalPosition = { 0, -100, 0 }

	local rightStone = MutableShape()
	rightStone:SetParent(map)
	rightStone:AddBlock(Color.DarkGrey, 0, 0, 0)
	rightStone.Pivot = { 0, 1, 0 }
	rightStone.Scale = { 500, 2000, 200 }
	rightStone.LocalPosition = { 0, -100, 400 }

	local upStone = MutableShape()
	upStone:SetParent(map)
	upStone:AddBlock(Color.DarkGrey, 0, 0, 0)
	upStone.Pivot = { 0, 1, 0 }
	upStone.Scale = { 200, 2000, 600 }
	upStone.LocalPosition = { 400, -100, 0 }

	local downStone = MutableShape()
	downStone:SetParent(map)
	downStone:AddBlock(Color.DarkGrey, 0, 0, 0)
	downStone.Pivot = { 0, 1, 0 }
	downStone.Scale = { 200, 2000, 600 }
	downStone.LocalPosition = { 0, -100, 0 }
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
	-- SFX hit block
	dojo.actions.hit_block(block.Coords.X, block.Coords.Y, block.Coords.Z)
end

updatePlayerStats = function(_, stats)
	if stats.player.value ~= dojo.burnerAccount.Account then
		return
	end

	if BACKPACK_MAX_SLOTS[stats.backpack_level] > maxSlots then
		maxSlots = BACKPACK_MAX_SLOTS[stats.backpack_level]
		print("new maxSlots is", maxSlots)
	end

	if PICKAXE_STRENGTHS[stats.pickaxe_level] > pickaxeStrength then
		pickaxeStrength = PICKAXE_STRENGTHS[stats.pickaxe_level]
		print("new pickaxe is", pickaxeStrength)
	end
end

initSellingArea = function()
	local sellAll = MutableShape()
	sellAll:AddBlock(Color(255, 0, 0, 0.5), 0, 0, 0)
	sellAll:SetParent(World)
	sellAll.Scale = { 30, 5, 30 }
	sellAll.Pivot = { 0.5, 0, 0.5 }
	sellAll.Physics = PhysicsMode.Trigger
	sellAll.OnCollisionBegin = function(_, other)
		if other ~= Player then
			return
		end
		dojo.actions.sell_all()
		-- SFX gold
	end

	sellAll.Position = { 450, 0, 300 }
end

initUpgradeAreas = function()
	local upgradePickaxe = MutableShape()
	upgradePickaxe:AddBlock(Color(255, 255, 0, 0.5), 0, 0, 0)
	upgradePickaxe:SetParent(World)
	upgradePickaxe.Scale = { 30, 5, 30 }
	upgradePickaxe.Pivot = { 0.5, 0, 0.5 }
	upgradePickaxe.Physics = PhysicsMode.Trigger
	upgradePickaxe.OnCollisionBegin = function(_, other)
		if other ~= Player then
			return
		end
		dojo.actions.upgrade_pickaxe()
		-- SFX unlock
	end

	local upgradeBackpack = MutableShape()
	upgradeBackpack:AddBlock(Color(0, 0, 255, 0.5), 0, 0, 0)
	upgradeBackpack:SetParent(World)
	upgradeBackpack.Scale = { 30, 5, 30 }
	upgradeBackpack.Pivot = { 0.5, 0, 0.5 }
	upgradeBackpack.Physics = PhysicsMode.Trigger
	upgradeBackpack.OnCollisionBegin = function(_, other)
		if other ~= Player then
			return
		end
		dojo.actions.upgrade_backpack()
		-- SFX unlock
	end

	upgradePickaxe.Position = { 450, 0, 150 }
	upgradeBackpack.Position = { 450, 0, 450 }
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
updateLeaderboard = function(_, entry)
	if entry.day.value ~= math.floor(Time.Unix() / 86400) then
		return
	end
	leaderboardEntries[entry.player.value] = entry

	local listCoinsCollected = {}
	for _, elem in pairs(leaderboardEntries) do
		table.insert(listCoinsCollected, elem)
	end
	if #listCoinsCollected > 0 then
		table.sort(listCoinsCollected, function(a, b)
			return a.nb_coins_collected.value > b.nb_coins_collected.value
		end)
		leaderboardTextCoins.Text = ""
		local hasLocalPlayer = false
		for i = 1, 10 do
			if not listCoinsCollected[i] then
				break
			end
			local name = string.sub(listCoinsCollected[i].player.value, 1, 8)
			if listCoinsCollected[i].player.value == dojo.burnerAccount.Address then
				name = "> you <"
				hasLocalPlayer = true
			end
			leaderboardTextCoins.Text = leaderboardTextCoins.Text
				.. name
				.. ": "
				.. tostring(math.floor(listCoinsCollected[i].nb_coins_collected.value))
				.. "\n"
		end

		local elem = leaderboardEntries[dojo.burnerAccount.Address]
		if not hasLocalPlayer and elem then
			leaderboardTextCoins.Text = leaderboardTextCoins.Text
				.. "> you <"
				.. ": "
				.. tostring(math.floor(elem.nb_coins_collected.value))
				.. "\n"
		end
	end

	local listBlocksHit = {}
	for _, elem in pairs(leaderboardEntries) do
		table.insert(listBlocksHit, elem)
	end
	if #listBlocksHit > 0 then
		table.sort(listBlocksHit, function(a, b)
			return a.nb_hits.value > b.nb_hits.value
		end)
		leaderboardTextHits.Text = ""
		local hasLocalPlayer = false
		for i = 1, 10 do
			if not listBlocksHit[i] then
				break
			end
			local name = string.sub(listBlocksHit[i].player.value, 1, 8)
			if listBlocksHit[i].player.value == dojo.burnerAccount.Address then
				name = "> you <"
				hasLocalPlayer = true
			end
			leaderboardTextHits.Text = leaderboardTextHits.Text
				.. name
				.. ": "
				.. tostring(math.floor(listBlocksHit[i].nb_hits.value))
				.. "\n"
		end

		local elem = leaderboardEntries[dojo.burnerAccount.Address]
		if not hasLocalPlayer and elem then
			leaderboardTextHits.Text = leaderboardTextHits.Text
				.. "> you <"
				.. ": "
				.. tostring(math.floor(elem.nb_hits.value))
				.. "\n"
		end
	end

	local listBlocksMined = {}
	for _, elem in pairs(leaderboardEntries) do
		table.insert(listBlocksMined, elem)
	end
	if #listBlocksMined > 0 then
		table.sort(listBlocksMined, function(a, b)
			return a.nb_blocks_broken.value > b.nb_blocks_broken.value
		end)
		leaderboardTextBlocks.Text = ""
		local hasLocalPlayer = false
		for i = 1, 10 do
			if not listBlocksMined[i] then
				break
			end
			local name = string.sub(listBlocksMined[i].player.value, 1, 8)
			if listBlocksMined[i].player.value == dojo.burnerAccount.Address then
				name = "> you <"
				hasLocalPlayer = true
			end
			leaderboardTextBlocks.Text = leaderboardTextBlocks.Text
				.. name
				.. ": "
				.. tostring(math.floor(listBlocksMined[i].nb_blocks_broken.value))
				.. "\n"
		end
		local elem = leaderboardEntries[dojo.burnerAccount.Address]
		if not hasLocalPlayer and elem then
			leaderboardTextBlocks.Text = leaderboardTextBlocks.Text
				.. "> you <"
				.. ": "
				.. tostring(math.floor(elem.nb_blocks_broken.value))
				.. "\n"
		end
	end
end

local inventoryNode
updateInventory = function(_, inventory)
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
		ui:createText(string.format("%d/%d", totalQty, maxSlots or 5)),
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
		safearea = 700, -- min dist of islands from 0,0,0
		dist = 750, -- max dist of islands
	})

	initPlayer()
	initLeaderboard()
	initDojo()
	initSellingArea()
	initUpgradeAreas()

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
	world = "0x5c1d201209938c1ac8340c7caeec489060b04dff85399605e58ebc2cdc149f4",
	actions = "0x02c24de1c529a154eac885b0b34e8bf1b04f4ce0845b91d1a4fc9aea8c9d71ed",
	playerAddress = "0x657e5f424dc6dee0c5a305361ea21e93781fea133d83efa410b771b7f92b",
	playerSigningKey = "0xcd93de85d43988b9492bfaaff930c129fc3edbc513bb0c2b81577291848007",
}

function getOrCreateBlocksColumn(key, entity)
	local rawColumn = dojo:getModel(entity, "diamond_pit-BlocksColumn")
	if not rawColumn or not blocksModule.blockShape.GetBlock then
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

function updateBlocksColumn(key, entity)
	getOrCreateBlocksColumn(key, entity):update(entity)
end

local onEntityUpdateCallbacks = {
	["diamond_pit-BlocksColumn"] = updateBlocksColumn,
	["diamond_pit-PlayerInventory"] = updateInventory,
	["diamond_pit-DailyLeaderboardEntry"] = updateLeaderboard,
	["diamond_pit-PlayerStats"] = updatePlayerStats,
}

function startGame(toriiClient)
	-- sync previous entities
	dojo:syncEntities(onEntityUpdateCallbacks)

	-- add callbacks when an entity is updated
	dojo:setOnEntityUpdateCallbacks(onEntityUpdateCallbacks)

	-- listen to any update
	dojo:setOnAnyEntityUpdateCallback(function(key, entity)
		print("Any update", key)
	end)
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

dojo.setOnEntityUpdateCallbacks = function(_, callbacks)
	for modelName, callback in pairs(callbacks) do
		local clauseJsonStr = string.format(
			'[{ "Keys": { "keys": [], "models": ["%s"], "pattern_matching": "VariableLen" } }]',
			modelName
		)
		dojo.toriiClient:OnEntityUpdate(clauseJsonStr, function(entityKey, entity)
			local model = dojo:getModel(entity, modelName)
			if model then
				callback(entityKey, model, entity)
			end
		end)
	end
end

dojo.setOnAnyEntityUpdateCallback = function(_, callback)
	local clauseJsonStr = '[{ "Keys": { "keys": [], "models": [], "pattern_matching": "VariableLen" } }]'
	dojo.toriiClient:OnEntityUpdate(clauseJsonStr, callback)
end

dojo.syncEntities = function(_, callbacks)
	dojo.toriiClient:Entities('{ "limit": 100, "offset": 0 }', function(entities)
		if not entities then
			return
		end
		for entityKey, entity in pairs(entities) do
			for modelName, callback in pairs(callbacks) do
				local model = dojo:getModel(entity, modelName)
				if model then
					callback(entityKey, model, entity)
				end
			end
		end
	end)
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
	upgrade_backpack = function()
		if not dojo.toriiClient then
			return
		end
		print("Calling upgrade_backpack")
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "upgrade_backpack", "[]")
	end,
	upgrade_pickaxe = function()
		if not dojo.toriiClient then
			return
		end
		print("Calling upgrade_pickaxe")
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "upgrade_pickaxe", "[]")
	end,
}
