Modules = {
	--	floating_island_generator = "github.com/caillef/cubzh-library/floating_island_generator:a728587",
}

local DOJO = true

blockColors = {
	Color.Transparent, -- air
	Color.Grey, -- stone
	Color.Black, -- coal
	Color.Orange, -- copper
	Color.DarkGrey, -- deepstone
	Color.White, -- iron
	Color.Yellow, -- gold
	Color.Blue, -- diamond
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
	print("Hit", x, y, z)
	if DOJO then
		dojo.actions.hit_block(x, y, z)
	end
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
	if DOJO then
		initDojo()
	end

	Fog.On = false
	generate_map()
	Player:SetParent(World)
	Player.Position = Number3(150, 5, 150)

	blocksModule:start()
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

if DOJO then
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
		local column = {
			x = rawColumn.x.value,
			y = rawColumn.y.value,
			z_layer = rawColumn.z_layer.value,
			data = tonumber(string.sub(rawColumn.data.value, 3, #rawColumn.data.value), 16),
		}

		print("check")
		for k = 0, 9 do
			local blockInfo = (column.data >> (12 * k)) & 4095
			local blockType = blockInfo >> 7
			local blockHp = blockInfo & 127
			local z = -(column.z_layer * 10 + k)
			local b = blocksModule.blockShape:GetBlock(column.x, z, column.y)
			local blockColor = blockColors[blockType + 1]
			print(blockType + 1, blockColor)
			if b and blockHp == 0 then
				print("Remove")
				b:Remove()
			elseif b and b.Color ~= blockColor then
				b:Replace(blockColor)
			elseif blockHp > 0 and not b then
				blocksModule.blockShape:AddBlock(blockColor, column.x, z, column.y)
			end
		end
	end

	function startGame(toriiClient)
		-- sync existing entities
		toriiClient:Entities('{ "limit": 100, "offset": 0 }', function(entities)
			for key, newEntity in pairs(entities) do
				local entity = getOrCreateBlocksColumn(key, newEntity)
				if entity then
					entity:update(newEntity)
				end
			end
		end)

		-- set on entity update callback
		-- match everything
		-- on 1.0.0, add [] around
		local clauseJsonStr = '{ "Keys": { "keys": [], "models": [], "pattern_matching": "VariableLen" } }'
		toriiClient:OnEntityUpdate(clauseJsonStr, function(entities)
			for key, newEntity in pairs(entities) do
				local entity = getOrCreateBlocksColumn(key, newEntity)
				if entity then
					entity:update(newEntity)
				end
			end
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
	}
end

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
		print("TREE", cachedTree)
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
