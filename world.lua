Config = {
	Items = {
		"caillef.pickaxe",
	},
}

Modules = {
	--floating_island_generator = "github.com/caillef/cubzh-library/floating_island_generator:a728587",
	ui_blocks = "github.com/caillef/cubzh-library/ui_blocks:09941d5",
}

local VERBOSE = false
local sfx = require("sfx")

worldInfo = {
	rpc_url = "https://api.cartridge.gg/x/diamond-pit/katana",
	torii_url = "https://api.cartridge.gg/x/diamond-pit/torii",
	world = "0x5c1d201209938c1ac8340c7caeec489060b04dff85399605e58ebc2cdc149f4",
	actions = "0x02c24de1c529a154eac885b0b34e8bf1b04f4ce0845b91d1a4fc9aea8c9d71ed",
	playerAddress = "0x657e5f424dc6dee0c5a305361ea21e93781fea133d83efa410b771b7f92b",
	playerSigningKey = "0xcd93de85d43988b9492bfaaff930c129fc3edbc513bb0c2b81577291848007",
}

maxSlots = 5
pickaxeStrength = 1

local PICKAXE_STRENGTHS = {
	[0] = 1,
	[1] = 2,
	[2] = 3,
	[3] = 4,
	[4] = 8,
	[5] = 12,
	[6] = 20,
}

local LEVEL_COLOR = {
	[0] = Color.Grey,
	[1] = Color.Orange,
	[2] = Color.White,
	[3] = Color.Gold,
	[4] = Color(112, 209, 244),
	[5] = Color(128, 0, 128),
	[6] = Color.Red,
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

updatePlayerStats = function(_, stats)
	if stats.player.value ~= dojo.burnerAccount.Address then
		return
	end

	if BACKPACK_MAX_SLOTS[stats.backpack_level.value] > maxSlots then
		maxSlots = BACKPACK_MAX_SLOTS[stats.backpack_level.value]
		sfx("victory_1", { Spatialized = false, Volume = 0.6 })
	end

	if PICKAXE_STRENGTHS[stats.pickaxe_level.value] > pickaxeStrength then
		pickaxeStrength = PICKAXE_STRENGTHS[stats.pickaxe_level.value]
		sfx("metal_clanging_1", { Spatialized = false, Volume = 0.6 })
		Player.pickaxe.Palette[1].Color = LEVEL_COLOR[stats.pickaxe_level.value]
		Player.pickaxe.Palette[2].Color = LEVEL_COLOR[stats.pickaxe_level.value + 1]
		Player.pickaxe.Palette[3].Color = LEVEL_COLOR[stats.pickaxe_level.value + 2]
		print(LEVEL_COLOR[stats.pickaxe_level.value])
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
		sfx("coin_1", { Spatialized = false, Volume = 0.6 })
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
			return tonumber(a.nb_coins_collected.value) > tonumber(b.nb_coins_collected.value)
		end)
		leaderboardTextCoins.Text = ""
		local hasLocalPlayer = false
		for i = 1, 10 do
			if not listCoinsCollected[i] then
				break
			end
			local name = string.sub(listCoinsCollected[i].player.value, 1, 8)
			if listCoinsCollected[i].player.value == dojo.burnerAccount.Address then
				name = " > you <"
				hasLocalPlayer = true
			end
			leaderboardTextCoins.Text = string.format(
				"%s%s: %d\n",
				leaderboardTextCoins.Text,
				name,
				listCoinsCollected[i].nb_coins_collected.value
			)
		end

		local elem = leaderboardEntries[dojo.burnerAccount.Address]
		if not hasLocalPlayer and elem then
			leaderboardTextCoins.Text =
				string.format("%s > you <: %d\n", leaderboardTextCoins.Text, elem.nb_coins_collected.value)
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
		ui:createText(string.format("💰 %d", inventory.coins.value)),
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
		safearea = 400, -- min dist of islands from 0,0,0
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
	return true -- consumed
end

Client.Action1 = function()
	-- if Player.IsOnGround then
	Player.Velocity.Y = 100
	-- end
end

Client.Action2 = function()
	mining = true
end

Client.Action2Release = function()
	mining = false
end

Client.Action3Release = function()
	Player.Position = Number3(250, 5, 150)
end

local nextMineHit = 0
local t = 0
Client.Tick = function(dt)
	if Player.Position.Y < -2050 then
		Player.Position = Number3(250, 5, 150)
	end
	t = t + dt
	if mining then
		if t >= nextMineHit then
			nextMineHit = t + 0.8
			local impact = Player:CastRay(nil, Player)
			if impact.Object and impact.Object.Name == "Blocks" then
				impact = Player:CastRay(impact.Object)
				if impact.Distance < 40 then
					local block = impact.Block
					Player:SwingRight()
					local impactPos = Camera.Position + Camera.Forward * impact.Distance
					emitter.Position = impactPos
					emitter:spawn(15)
					sfx(string.format("wood_impact_%d", math.random(1, 5)), { Spatialized = false, Volume = 0.6 })
					dojo.actions.hit_block(block.Coords.X, block.Coords.Y, block.Coords.Z)

					local text = Text()
					text.Text = string.format("-%d", pickaxeStrength)
					text:SetParent(World)
					text.FontSize = 40
					text.Type = TextType.Screen
					text.IsUnlit = true
					text.Color = Color.Black
					text.Anchor = { 0.5, 0.4 }
					text.LocalPosition = impactPos
					local dir = Player.Right * (math.random(-10, 10) / 50) + Number3(0, 0.3, 0)
					local listener = LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
						text.LocalPosition = text.LocalPosition + dir
						dir.Y = dir.Y - 0.01
					end)
					Timer(2, function()
						text:RemoveFromParent()
						listener:Remove()
					end)
					local textParent = text
					local text = Text()
					text.Text = string.format("-%d", pickaxeStrength)
					text:SetParent(textParent)
					text.FontSize = 40
					text.Type = TextType.Screen
					text.IsUnlit = true
					text.Color = Color.Black
					text.Anchor = { 0.5, 0.6 }
					local text = Text()
					text.Text = string.format("-%d", pickaxeStrength)
					text:SetParent(textParent)
					text.FontSize = 40
					text.Type = TextType.Screen
					text.IsUnlit = true
					text.Color = Color.Black
					text.Anchor = { 0.6, 0.5 }
					local text = Text()
					text.Text = string.format("-%d", pickaxeStrength)
					text:SetParent(textParent)
					text.FontSize = 40
					text.Type = TextType.Screen
					text.IsUnlit = true
					text.Color = Color.Black
					text.Anchor = { 0.4, 0.5 }

					local text = Text()
					text.Text = string.format("-%d", pickaxeStrength)
					text:SetParent(textParent)
					text.FontSize = 40
					text.Type = TextType.Screen
					text.IsUnlit = true
					text.Color = Color.White
					text.Anchor = { 0.5, 0.5 }
				end
			end
		end
	end
end

initPlayer = function()
	emitter = require("particles"):newEmitter({
		velocity = function()
			local v = Number3(0, 0, math.random(20, 30))
			v:Rotate(math.random() * math.pi * 2, math.random() * math.pi * 2, 0)
			return v
		end,
		physics = true,
		life = 3.0,
		scale = function()
			return 0.7 + math.random() * 1.0
		end,
		color = function()
			return Color.Black
		end,
	})
	Player.pickaxe = Shape(Items.caillef.pickaxe)
	Player:EquipRightHand(Player.pickaxe)
	print("palette size", #Player.pickaxe.Palette)
	Player.pickaxe.Palette[1].Color = LEVEL_COLOR[2]
	-- Player.pickaxe.Palette[2].Color = LEVEL_COLOR[3]
	-- Player.pickaxe.Palette[3].Color = LEVEL_COLOR[4]
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

function updateBlocksColumn(key, rawColumn)
	if not blocksModule.blockShape.GetBlock then
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

local onEntityUpdateCallbacks = {
	-- all = function(key, entity)
	-- 	print("Any update", key)
	-- end,
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

	print("Private Key", dojo.burnerAccountPrivateKey)
end

-- dojo module

dojo = {}

dojo.getOrCreateBurner = function(self, config, cb)
	self.toriiClient:CreateBurner(
		config.playerAddress,
		config.playerSigningKey,
		function(success, burnerAccount, privateKey)
			if not success then
				error("Can't create burner")
				return
			end
			dojo.burnerAccount = burnerAccount
			print(dojo.burnerAccount.Address, privateKey)
			dojo.burnerAccountPrivateKey = privateKey
			cb()
		end
	)

	-- self.toriiClient:CreateAccount(
	-- 	"0x61061baa37cf56f3cd139dd19d74e344d6522369416f7de585c9324ab58dc24",
	-- 	"0x5594932d50a0b34d94336b1746df194343db6fa650078176dd1fb4600f1c74a",
	-- 	function(success, burnerAccount)
	-- 		if not success then
	-- 			error("Can't create burner")
	-- 			return
	-- 		end
	-- 		dojo.burnerAccount = burnerAccount
	-- 		print(dojo.burnerAccount.Address, "0x5594932d50a0b34d94336b1746df194343db6fa650078176dd1fb4600f1c74a")
	-- 		dojo.burnerAccountPrivateKey = "0x5594932d50a0b34d94336b1746df194343db6fa650078176dd1fb4600f1c74a"
	-- 		cb()
	-- 	end
	-- )
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

dojo.setOnEntityUpdateCallbacks = function(self, callbacks)
	local clauseJsonStr = '[{ "Keys": { "keys": [], "models": [], "pattern_matching": "VariableLen" } }]'
	self.toriiClient:OnEntityUpdate(clauseJsonStr, function(entityKey, entity)
		for modelName, callback in pairs(callbacks) do
			local model = self:getModel(entity, modelName)
			if modelName == "all" or model then
				callback(entityKey, model, entity)
			end
		end
	end)
end

dojo.syncEntities = function(self, callbacks)
	self.toriiClient:Entities('{ "limit": 1000, "offset": 0 }', function(entities)
		if not entities then
			return
		end
		for entityKey, entity in pairs(entities) do
			for modelName, callback in pairs(callbacks) do
				local model = self:getModel(entity, modelName)
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
		if VERBOSE then
			print("Calling hit_block", calldatastr)
		end
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "hit_block", calldatastr)
	end,
	sell_all = function()
		if not dojo.toriiClient then
			return
		end
		if VERBOSE then
			print("Calling sell_all")
		end
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "sell_all", "[]")
	end,
	upgrade_backpack = function()
		if not dojo.toriiClient then
			return
		end
		if VERBOSE then
			print("Calling upgrade_backpack")
		end
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "upgrade_backpack", "[]")
	end,
	upgrade_pickaxe = function()
		if not dojo.toriiClient then
			return
		end
		if VERBOSE then
			print("Calling upgrade_pickaxe")
		end
		dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "upgrade_pickaxe", "[]")
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
