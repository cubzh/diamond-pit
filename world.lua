Config = {
    Items = {
        "caillef.pickaxe",
        "caillef.backpackmine",
        "caillef.shop2",
        "caillef.coin",
    },
}

Modules = {
    ui_blocks = "github.com/caillef/cubzh-library/ui_blocks:09941d5",
}

local cachedTree, cachedBush

local playersStats = {}
local resourcesById = {}
local resourcesByKey = {}
local resources = {
    {
        id = 1,
        key = "stone",
        name = "Stone",
        type = "block",
        block = { color = Color.Grey },
    },
    {
        id = 2,
        key = "coal",
        name = "Coal",
        type = "block",
        block = { color = Color.Black },
    },
    {
        id = 3,
        key = "copper",
        name = "Copper",
        type = "block",
        block = { color = Color.Orange },
    },
    {
        id = 4,
        key = "deepstone",
        name = "DeepStone",
        type = "block",
        block = { color = Color.DarkGrey },
    },
    {
        id = 5,
        key = "iron",
        name = "Iron",
        type = "block",
        block = { color = Color.White },
    },
    {
        id = 6,
        key = "gold",
        name = "Gold",
        type = "block",
        block = { color = Color.Yellow },
    },
    {
        id = 7,
        key = "diamond",
        name = "Diamond",
        type = "block",
        block = { color = Color(112, 209, 244) },
    },
}

for _, v in ipairs(resources) do
    resourcesByKey[v.key] = v
    resourcesById[v.id] = v
end

local VERBOSE = false
local inventoryIsFull = false
local inventoryTotalQty = 0
local sfx = require("sfx")

tickSinceSync = 0
otherPlayers = {}

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
    [3] = Color.Yellow,
    [4] = Color(112, 209, 244),
    [5] = Color(128, 0, 128),
    [6] = Color.Red,
}

local PICKAXE_UPGRADE_PRICES = {
    [0] = 0,
    [1] = 10,
    [2] = 25,
    [3] = 100,
    [4] = 300,
    [5] = 750,
    [6] = 3000,
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
    [4] = 350,
    [5] = 1250,
    [6] = 2500,
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

local BLOCK_COLORS = {
    Color.Grey,           -- stone [1]
    Color.Black,          -- coal
    Color.Orange,         -- copper
    Color.DarkGrey,       -- deepstone
    Color.White,          -- iron
    Color.Yellow,         -- gold
    Color(112, 209, 244), -- diamond
}

local NUGGETS_COLOR = {
    nil,                  -- stone [1]
    Color.DarkGrey,       -- coal
    Color(195, 90, 19),   -- copper
    nil,                  -- deepstone
    Color(206, 206, 206), -- iron
    Color(246, 206, 46),  -- gold
    Color(54, 142, 244),  -- diamond
}

local BLOCKS_MAX_HP = { 4, 10, 25, 10, 40, 80, 125 }

blocksModule = {
    chips = {}
}

blocksModule.checkNeighborsAndAddChips = function(self, x, y, z)
    local directions = {
        { 1, 0, 0 }, { -1, 0, 0 },
        { 0, 1, 0 }, { 0, -1, 0 },
        { 0, 0, 1 }, { 0, 0, -1 }
    }

    for _, dir in ipairs(directions) do
        local nx, ny, nz = x + dir[1], y + dir[2], z + dir[3]
        local neighborBlock = self.blockShape:GetBlock(nx, ny, nz)

        if neighborBlock then
            local neighborColor = neighborBlock.Color
            if neighborColor ~= BLOCK_COLORS[1] and neighborColor ~= BLOCK_COLORS[4] then
                for _, color in pairs(BLOCK_COLORS) do
                    if neighborColor == color then
                        self:addChips(neighborBlock, color)
                    end
                end
            end
        end
    end
end
blocksModule.addChips = function(self, block, color)
    if self.chips[block.Coords.Z] and
        self.chips[block.Coords.Z][block.Coords.Y] and
        self.chips[block.Coords.Z][block.Coords.Y][block.Coords.X] then
        return
    end
    local blockType
    for k, v in pairs(BLOCK_COLORS) do
        if v == color then
            blockType = k
            break
        end
    end

    if not self.cachedChips then
        self.cachedChips = {}
    end

    if not self.cachedChips[blockType] then
        local chips = MutableShape()

        local function randomFacePosition()
            return math.random(-4, 4), math.random(-4, 4)
        end

        -- Front face (3 chips)
        for i = 1, 10 do
            local x, y = randomFacePosition()
            chips:AddBlock(NUGGETS_COLOR[blockType], x, y, -5)
        end

        -- Back face (3 chips)
        for i = 1, 10 do
            local x, y = randomFacePosition()
            chips:AddBlock(NUGGETS_COLOR[blockType], x, y, 5)
        end

        -- Left face (3 chips)
        for i = 1, 10 do
            local y, z = randomFacePosition()
            chips:AddBlock(NUGGETS_COLOR[blockType], -5, y, z)
        end

        -- Right face (3 chips)
        for i = 1, 10 do
            local y, z = randomFacePosition()
            chips:AddBlock(NUGGETS_COLOR[blockType], 5, y, z)
        end

        -- Top face (3 chips)
        for i = 1, 10 do
            local x, z = randomFacePosition()
            chips:AddBlock(NUGGETS_COLOR[blockType], x, 5, z)
        end

        -- Bottom face (3 chips)
        for i = 1, 10 do
            local x, z = randomFacePosition()
            chips:AddBlock(NUGGETS_COLOR[blockType], x, -5, z)
        end

        self.cachedChips[blockType] = chips
    end

    local chips = Shape(self.cachedChips[blockType])
    chips:SetParent(World)
    chips.Position = block.Position + Number3(10, 10, 10)
    chips.Physics = PhysicsMode.Disabled
    chips.Pivot = Number3(0.5, 0.5, 0.5)
    chips.Scale = 1.75

    self.chips[block.Coords.Z] = self.chips[block.Coords.Z] or {}
    self.chips[block.Coords.Z][block.Coords.Y] = self.chips[block.Coords.Z][block.Coords.Y] or {}
    self.chips[block.Coords.Z][block.Coords.Y][block.Coords.X] = chips
end

blocksModule.setBlockHP = function(self, block, hp, maxHP)
    if not self.chips[block.Coords.Z] or not self.chips[block.Coords.Z][block.Coords.Y] or not self.chips[block.Coords.Z][block.Coords.Y][block.Coords.X] then return end

    local chips = self.chips[block.Coords.Z][block.Coords.Y][block.Coords.X]
    if hp <= 0 then
        chips:RemoveFromParent()
        self.chips[block.Coords.Z][block.Coords.Y][block.Coords.X] = nil
        return
    end

    local percentage = 1 - (hp / maxHP)
    chips.Scale = 1.75 + percentage * 0.3
end

blocksModule.start = function(self)
    self.blockShape = MutableShape()
    self.blockShape.Name = "Blocks"
    self.blockShape.Physics = PhysicsMode.StaticPerBlock
    self.blockShape:SetParent(World)
    self.CollisionGroups = Map.CollisionGroups
    self.CollidesWithGroups = Map.CollidesWithGroups
    self.blockShape.Position = { 200, 0, 200 }
    self.blockShape.Scale = 20
    self.blockShape.Friction = { top = 0.2, other = 0 }
    self.blockShape.Pivot = { 0, 1, 0 }
    self.blockShape.Shadow = true
    -- self.blockShape.PrivateDrawMode = 8
    for z = 0, 49 do
        for j = 0, 9 do
            for i = 0, 9 do
                self.blockShape:AddBlock(Color.Grey, i, -z, j)
            end
        end
    end
end

createNewPlayer = function(key, position)
    local player = {}
    local model = require("avatar"):get("caillef")
    model:SetParent(World)
    model.Scale = 0.5
    model.Rotation.Y = math.random() * 2 * math.pi
    model.Position = position
    player.model = model
    LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
        if not player.targetPosition then
            return
        end
        if player.checkRefresh then
            player.checkRefresh:Cancel()
            player.checkRefresh = nil
        end
        if (player.model.Position - player.targetPosition).SquaredLength <= 3 then
            player.checkRefresh = Timer(61, function()
                player.model:RemoveFromParent()
                otherPlayers[key] = nil
            end)
            player.targetPosition = nil
            return
        end
        local dir = player.targetPosition - player.model.Position
        dir:Normalize()
        player.model.Position = player.model.Position + dir * dt * 30

        player.model.Forward = dir
        player.model.Rotation.X = 0
        player.model.Rotation.Z = 0
    end)
    otherPlayers[key] = player
    return player
end

updatePlayerPosition = function(key, position)
    if position.player.value == dojo.burnerAccount.Address then
        return
    end

    local worldPos = Number3(
        math.floor(position.x.value - 1000000),
        math.floor(position.y.value - 1000000),
        math.floor(position.z.value - 1000000)
    )

    if position.time.value + 60 < Time.Unix() then
        return
    end

    local player = otherPlayers[key] or createNewPlayer(key, worldPos)
    if not player then
        return
    end
    player.targetPosition = worldPos
end

updatePlayerStats = function(key, stats)
    playersStats[stats.player.value] = stats
    if stats.player.value ~= dojo.burnerAccount.Address then
        return
    end

    if textInputUsername then
        textInputUsername.Text = hex_to_string(stats.name.value)
    end

    local backpackLevel = stats.backpack_level.value
    if BACKPACK_MAX_SLOTS[backpackLevel] > maxSlots then
        maxSlots = BACKPACK_MAX_SLOTS[backpackLevel]
        sfx("victory_1", { Spatialized = false, Volume = 0.6 })
        local nextLevel = backpackLevel + 1
        if LEVEL_COLOR[nextLevel] then
            floatingBackpack.Palette[1].Color = LEVEL_COLOR[nextLevel]
            backpackNextText.Text = string.format("%d 💰", BACKPACK_UPGRADE_PRICES[nextLevel])
        else
            floatingBackpack.IsHidden = true
            backpackNextText.IsHidden = true
        end
    end

    local pickaxeLevel = stats.pickaxe_level.value
    if Player.pickaxe and PICKAXE_STRENGTHS[pickaxeLevel] > pickaxeStrength then
        pickaxeStrength = PICKAXE_STRENGTHS[pickaxeLevel]
        sfx("metal_clanging_1", { Spatialized = false, Volume = 0.6 })
        Player.pickaxe.Palette[8].Color = LEVEL_COLOR[pickaxeLevel]
        local nextLevel = pickaxeLevel + 1
        if LEVEL_COLOR[nextLevel] then
            floatingPickaxe.Palette[8].Color = LEVEL_COLOR[nextLevel]
            pickaxeNextText.Text = string.format("%d 💰", PICKAXE_UPGRADE_PRICES[nextLevel])
        else
            floatingPickaxe.IsHidden = true
            pickaxeNextText.IsHidden = true
        end
    end
end

initSellingArea = function()
    local sellAll = MutableShape()
    sellAll:AddBlock(Color(0, 0, 0, 0), 0, 0, 0)
    sellAll:SetParent(World)
    sellAll.Scale = { 30, 5, 30 }
    sellAll.Pivot = { 0.5, 0, 0.5 }
    sellAll.Physics = PhysicsMode.Trigger
    sellAll.Position = { 450, 0, 300 }
    sellAll.OnCollisionBegin = function(_, other)
        if other ~= Player then
            return
        end
        if inventoryTotalQty == 0 then
            local text = Text()
            text.Text = "Nothing to sell, mine blocks in the pit"
            text:SetParent(World)
            text.FontSize = 20
            text.Type = TextType.Screen
            text.IsUnlit = true
            text.Color = Color.Black
            text.Anchor = { 0.5, 0.4 }
            text.Position = Number3(450, 10, 300)
            Timer(5, function()
                text:RemoveFromParent()
            end)
            return
        end
        dojo.actions.sell_all()
        sfx("coin_1", { Spatialized = false, Volume = 0.6 })
    end

    local shop = Shape(Items.caillef.shop2)
    shop:SetParent(World)
    shop.Scale = 1.6
    shop.Physics = PhysicsMode.Static
    shop.Position = sellAll.Position
    shop.Pivot = { 0, 0.5, shop.Depth * 0.5 }

    local text = Text()
    text.Text = "Sell"
    text:SetParent(World)
    text.FontSize = 7
    text.Type = TextType.World
    text.IsUnlit = true
    text.Color = Color.Black
    text.Anchor = { 0.5, 0 }
    text.Position = shop.Position + Number3(0, 25, 0)
    LocalEvent:Listen(LocalEvent.Name.Tick, function()
        text.Forward = Player.Forward
    end)
end

initMenu = function(callbackOnStart)
    local ui = require("uikit")
    local bg = ui:createFrame(Color(0, 0, 0, 0.8))
    bg.parentDidResize = function()
        bg.Width = 400
        bg.Height = Screen.Height * 0.2
        bg.pos = { Screen.Width * 0.5 - bg.Width * 0.5, Screen.Height * 0.5 - bg.Height * 0.5 }
    end
    bg:parentDidResize()

    local bgBlock = ui:createFrame(Color(0, 0, 0, 0))
    bgBlock.parentDidResize = function()
        bgBlock.Width = bg.Width - 16
        bgBlock.Height = bg.Height - 16
        bgBlock.pos = { 8, 8 }
    end
    bgBlock:setParent(bg)
    bgBlock:parentDidResize()

    textInputUsername = ui:createTextInput("")
    textInputUsername.onFocus = function()
        textInputUsername.Text = ""
    end
    textInputUsername.onSubmit = function()
        local name = textInputUsername.Text
        if #name > 11 then
            name = string.sub(name, 1, 11)
        end
        if #name > 0 then
            dojo.actions.set_username(name)
        end
    end
    local setUsernameBlock = ui_blocks:createLineContainer({
        dir = "horizontal",
        nodes = {
            ui:createText("Username: ", Color.White),
            { type = "gap" },
            textInputUsername,
        }
    })

    local playBtn = ui:createButton("Play")
    playBtn.onRelease = function()
        local name = textInputUsername.Text
        if #name > 11 then
            name = string.sub(name, 1, 11)
        end
        if #name < 0 then return end
        dojo.actions.set_username(name)
        bg:remove()
        Pointer:Hide()
        textInputUsername = nil
        callbackOnStart()
    end

    local titleScreen = ui_blocks:createBlock({
        triptych = {
            dir = "vertical",
            color = Color(0, 0, 0, 0), -- background color
            top = ui:createText("Diamond Pit", Color.White, "big"),
            center = setUsernameBlock,
            bottom = playBtn,
        },
    })
    titleScreen:setParent(bgBlock)

    Pointer:Show()
end

initUpgradeAreas = function()
    local function createUpgradeArea(position, upgradeAction, itemShape, priceTable)
        local area = MutableShape()
        area:AddBlock(Color(127, 127, 127, 0.5), 0, 0, 0)
        area:SetParent(World)
        area.Scale = { 30, 2, 30 }
        area.Pivot = { 0.5, 0, 0.5 }
        area.Physics = PhysicsMode.Trigger
        area.Position = position
        area.OnCollisionBegin = function(_, other)
            if other == Player then
                dojo.actions[upgradeAction]()
            end
        end

        local floatingItem = Shape(itemShape)
        floatingItem:SetParent(World)
        floatingItem.Scale = 1.5
        floatingItem.Position = area.Position + Number3(0, 12, 0)
        floatingItem.Physics = PhysicsMode.Disabled
        floatingItem.Palette[upgradeAction == "upgrade_pickaxe" and 8 or 1].Color = LEVEL_COLOR[1]

        local t = 0
        LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
            t = t + dt
            floatingItem.Position.Y = 12 + math.sin(t * 3) * 2
            floatingItem.Rotation.Y = floatingItem.Rotation.Y + dt * 0.5
        end)

        local text = Text()
        text.Text = string.format("%d 💰", priceTable[1])
        text:SetParent(floatingItem)
        text.FontSize = 5
        text.Type = TextType.World
        text.IsUnlit = true
        text.Color = Color.Black
        text.Anchor = { 0.5, 0 }
        text.LocalPosition = { 0, 7, 0 }
        LocalEvent:Listen(LocalEvent.Name.Tick, function()
            text.Forward = Player.Forward
        end)

        return floatingItem, text
    end

    floatingPickaxe, pickaxeNextText = createUpgradeArea({ 450, 0, 200 }, "upgrade_pickaxe", Items.caillef.pickaxe,
        PICKAXE_UPGRADE_PRICES)
    floatingBackpack, backpackNextText = createUpgradeArea({ 450, 0, 400 }, "upgrade_backpack",
        Items.caillef.backpackmine, BACKPACK_UPGRADE_PRICES)

    -- rebirth area
    local rebirthArea = MutableShape()
    rebirthArea:AddBlock(Color(127, 127, 127, 0.5), 0, 0, 0)
    rebirthArea:SetParent(World)
    rebirthArea.Scale = { 30, 2, 30 }
    rebirthArea.Pivot = { 0.5, 0, 0.5 }
    rebirthArea.Physics = PhysicsMode.Trigger
    rebirthArea.Position = { 350, 0, 450 }
    rebirthArea.OnCollisionBegin = function(_, other)
        if other == Player then
            dojo.actions.rebirth(1)
        end
    end

    local rebirthText = Text()
    rebirthText.Text = "Rebirth (3000 💰)"
    rebirthText:SetParent(World)
    rebirthText.FontSize = 5
    rebirthText.Type = TextType.World
    rebirthText.IsUnlit = true
    rebirthText.Color = Color.Black
    rebirthText.Anchor = { 0.5, 0 }
    rebirthText.Position = Number3(350, 12, 450)
    rebirthText.LocalPosition = { 0, 7, 0 }
    LocalEvent:Listen(LocalEvent.Name.Tick, function()
        rebirthText.Forward = Player.Forward
    end)
end

local leaderboardTextBlocks, leaderboardTextHits, leaderboardTextCoins
local leaderboardTextBlocksScore, leaderboardTextHitsScore, leaderboardTextCoinsScore

local function createLeaderboardQuad(position, rotation, title)
    local quad = Quad()
    quad.Color = Color.White
    quad.Width = 30
    quad.Height = 50
    quad:SetParent(World)
    quad.IsUnlit = true
    quad.Anchor = { 0.5, 0 }
    quad.Position = position
    quad.Rotation.Y = rotation

    local titleText = Text()
    titleText.Text = title
    titleText:SetParent(quad)
    titleText.FontSize = 3
    titleText.Type = TextType.World
    titleText.IsUnlit = true
    titleText.Color = Color.Black
    titleText.Anchor = { 0.5, 1 }
    titleText.LocalPosition = { 0, 47, -0.1 }

    local contentText = Text()
    contentText.Text = "become the first\nentry today"
    contentText:SetParent(quad)
    contentText.FontSize = 2.5
    contentText.Type = TextType.World
    contentText.IsUnlit = true
    contentText.Color = Color.Black
    contentText.Anchor = { 0, 1 }
    contentText.LocalPosition = { -13, 35, -0.1 }

    local contentTextScore = Text()
    contentTextScore.Text = ""
    contentTextScore:SetParent(quad)
    contentTextScore.FontSize = 2.5
    contentTextScore.Type = TextType.World
    contentTextScore.IsUnlit = true
    contentTextScore.Color = Color.Black
    contentTextScore.Anchor = { 1, 1 }
    contentTextScore.LocalPosition = { 13, 35, -0.1 }

    return contentText, contentTextScore
end

function initLeaderboard()
    leaderboardTextBlocks, leaderboardTextBlocksScore = createLeaderboardQuad({ 150, 0, 100 }, math.pi * 1.3,
        "Daily Leaderboard\n- Blocks Mined -")
    leaderboardTextHits, leaderboardTextHitsScore = createLeaderboardQuad({ 130, 0, 150 }, math.pi * 1.5,
        "Daily Leaderboard\n- Pickaxe Hits -")
    leaderboardTextCoins, leaderboardTextCoinsScore = createLeaderboardQuad({ 150, 0, 200 }, math.pi * 1.7,
        "Daily Leaderboard\n- Coins Earned -")
end

local leaderboardEntries = {}
local function updateIndividualLeaderboard(entries, textObject, textScoreObject, valueField)
    local list = {}
    for _, elem in pairs(entries) do
        table.insert(list, elem)
    end
    if #list == 0 then return end

    table.sort(list, function(a, b)
        return tonumber(a[valueField].value) > tonumber(b[valueField].value)
    end)

    local text = ""
    local textScore = ""
    local hasLocalPlayer = false

    for i = 1, 10 do
        local entry = list[i]
        if not entry then break end

        local name = playersStats[entry.player.value]
            and hex_to_string(playersStats[entry.player.value].name.value)
            or string.sub(entry.player.value, 1, 8)
        if entry.player.value == dojo.burnerAccount.Address then
            name = string.format("> %s",
                playersStats[entry.player.value] and hex_to_string(playersStats[entry.player.value].name.value) or "you")
            hasLocalPlayer = true
        end
        text = text .. string.format("%s\n", name)
        textScore = textScore .. string.format("%d\n", entry[valueField].value)
    end

    if not hasLocalPlayer then
        local localEntry = entries[dojo.burnerAccount.Address]
        if localEntry then
            local name = playersStats[localEntry.player.value]
                and hex_to_string(playersStats[localEntry.player.value].name.value)
                or "you"
            text = text .. string.format("%s\n", name)
            textScore = textScore .. string.format("%d\n", localEntry[valueField].value)
        end
    end

    textObject.Text = text
    textScoreObject.Text = textScore
end

-- Then in your updateLeaderboard function:
updateLeaderboard = function(_, entry)
    if entry.day.value ~= math.floor(Time.Unix() / 86400) then
        return
    end
    leaderboardEntries[entry.player.value] = entry

    updateIndividualLeaderboard(leaderboardEntries, leaderboardTextCoins, leaderboardTextCoinsScore, "nb_coins_collected")
    updateIndividualLeaderboard(leaderboardEntries, leaderboardTextHits, leaderboardTextHitsScore, "nb_hits")
    updateIndividualLeaderboard(leaderboardEntries, leaderboardTextBlocks, leaderboardTextBlocksScore, "nb_blocks_broken")
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

    coinText.Text = string.format("%d", inventory.coins.value)
    creditsText.Text = string.format("%d", inventory.rebirth_credits.value)

    inventoryTotalQty = totalQty
    inventoryIsFull = totalQty == (maxSlots or 5)
    nbSlotsLeftText.Text = string.format("%d/%d", totalQty, maxSlots or 5)

    local ui = require("uikit")
    LocalEvent:Send("InvClearAll", { key = "hotbar" })
    for _, slot in ipairs(slots) do
        LocalEvent:Send("InvAdd", {
            key = "hotbar",
            rKey = resourcesById[slot.blockType].key,
            amount = slot.qty,
            callback = function(success)
                if success then
                    return
                end
            end,
        })
    end

    -- if inventoryNode then
    -- 	inventoryNode:remove()
    -- end
    -- local nodes = {
    -- 	ui:createText("Inventory"),
    -- 	ui:createText(string.format("%d/%d", totalQty, maxSlots or 5)),
    -- }
    -- for _, slot in ipairs(slots) do
    -- 	table.insert(nodes, ui:createText(string.format("%s: %d", idToName[slot.blockType], slot.qty)))
    -- end
    -- local bgInventory = ui:createFrame(Color.White)
    -- bgInventory.parentDidResize = function()
    -- 	bgInventory.Width = 100
    -- 	bgInventory.Height = Screen.Height / 3
    -- 	bgInventory.pos = { Screen.Width - bgInventory.Width, Screen.Height - Screen.SafeArea.Top - bgInventory.Height }
    -- end
    -- bgInventory:parentDidResize()
    -- inventoryNode = ui_blocks:createLineContainer({
    -- 	dir = "vertical",
    -- 	nodes = nodes,
    -- })
    -- ui_blocks:anchorNode(inventoryNode, "right", "top", 5)
end

Client.OnWorldObjectLoad = function(obj)
    obj.Position = obj.Position + Number3(40, -20 * Map.Height, 40)

    if obj.Name == "pratamacam.grass_01" then
        for i = 1, 5 do
            local copy = Shape(obj, { includeChildren = true })
            copy:SetParent(World)
            copy.Position = obj.Position + Number3(math.random(-10, 10), 0, math.random(-10, 10))
            copy.Rotation.Y = math.random() * math.pi
            copy.Scale = math.random() * 0.4 + 0.8
            require("hierarchyactions"):applyToDescendants(copy, { includeRoot = true }, function(obj)
                obj.Physics = PhysicsMode.Disabled
            end)
        end
    end
end

Client.OnStart = function()
    -- floating_island_generator:generateIslands({
    --     nbIslands = 30, -- number of islands
    --     minSize = 4,    -- min size of island
    --     maxSize = 7,    -- max size of island
    --     safearea = 400, -- min dist of islands from 0,0,0
    --     dist = 750,     -- max dist of islands
    -- })

    blocksModule:start()
    initLeaderboard()
    initDojo()
    initSellingArea()
    initUpgradeAreas()

    local ui = require("uikit")
    nbSlotsLeftText = ui:createText("0/5", Color.White, "big")

    inventory_module:setResources(resourcesByKey, resourcesById)
    inventory_module:create("hotbar", {
        width = 7,
        height = 1,
        alwaysVisible = true,
        selector = false,
        uiPos = function(node)
            local padding = require("uitheme").current.padding
            nbSlotsLeftText.pos = {
                Screen.Width * 0.5 - node.Width * 0.5 - padding * 3 - nbSlotsLeftText.Width * 2,
                padding + node.Height * 0.5 - nbSlotsLeftText.Height * 0.5,
            }
            return { Screen.Width * 0.5 - node.Width * 0.5, padding }
        end,
    })
    initUI()
    Player.pickaxe = Shape(Items.caillef.pickaxe)
    Map.Position = { 40, -Map.Height * 20, 40 }

    Camera:SetModeFree()
    Camera.Position = { 20 * 15, 300, 20 * 15 }
    Camera.Rotation.X = math.pi * 0.5
    Fog.On = false

    initMenu(function()
        require("ambience"):set(require("ambience").default)
        initPlayer()
        Player:SetParent(World)
        Player.Position = Number3(250 + math.random(-25, 25), 5, 150 + math.random(-25, 25))
    end)
end

Client.OnChat = function(payload)
    print("Set new username:", payload.message)
    dojo.actions.set_username(payload.message)
    return true -- consumed
end

local isOnGroundBox = Box()
local pts = {}
local minN3 = Number3.Zero
local maxN3 = Number3.Zero
local bMax
local bMin
function isOnGround(object)
    if object.CollisionBox == nil then
        return false
    end

    bMax = object.CollisionBox.Max
    bMin = object.CollisionBox.Min

    -- TMP, waiting for object:BoxLocalToWorld
    pts[1] = object:PositionLocalToWorld(bMin)
    pts[2] = object:PositionLocalToWorld({ bMax.X, bMin.Y, bMin.Z })
    pts[3] = object:PositionLocalToWorld({ bMin.X, bMax.Y, bMin.Z })
    pts[4] = object:PositionLocalToWorld({ bMin.X, bMin.Y, bMax.Z })
    pts[5] = object:PositionLocalToWorld({ bMax.X, bMax.Y, bMin.Z })
    pts[6] = object:PositionLocalToWorld({ bMax.X, bMin.Y, bMax.Z })
    pts[7] = object:PositionLocalToWorld({ bMin.X, bMax.Y, bMax.Z })
    pts[8] = object:PositionLocalToWorld(bMax)

    minN3:Set(pts[1])
    minN3.X = math.min(minN3.X, pts[2].X, pts[3].X, pts[4].X, pts[5].X, pts[6].X, pts[7].X, pts[8].X)
    minN3.Y = math.min(minN3.Y, pts[2].Y, pts[3].Y, pts[4].Y, pts[5].Y, pts[6].Y, pts[7].Y, pts[8].Y)
    minN3.Z = math.min(minN3.Z, pts[2].Z, pts[3].Z, pts[4].Z, pts[5].Z, pts[6].Z, pts[7].Z, pts[8].Z)
    maxN3:Set(pts[1])
    maxN3.X = math.max(maxN3.X, pts[2].X, pts[3].X, pts[4].X, pts[5].X, pts[6].X, pts[7].X, pts[8].X)
    maxN3.Y = math.max(maxN3.Y, pts[2].Y, pts[3].Y, pts[4].Y, pts[5].Y, pts[6].Y, pts[7].Y, pts[8].Y)
    maxN3.Z = math.max(maxN3.Z, pts[2].Z, pts[3].Z, pts[4].Z, pts[5].Z, pts[6].Z, pts[7].Z, pts[8].Z)

    isOnGroundBox.Min = minN3 + Number3(1, 0, 1)
    isOnGroundBox.Max = maxN3 - Number3(1, 0, 1)

    local impact = isOnGroundBox:Cast(Number3.Down, 5, object.CollidesWithGroups)
    return (impact ~= nil and impact.FaceTouched == Face.Top)
end

Client.Action1 = function()
    if isOnGround(Player) then
        Player.Velocity.Y = 100
    end
end

Client.Action2 = function()
    mining = true
end

Client.Action2Release = function()
    mining = false
end

Client.Action3Release = function()
    Player.Position = Number3(410, 5, 300)
    Player.Rotation = Number3(0, math.pi * 0.5, 0)
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
                    if inventoryIsFull then
                        local text = Text()
                        text.Text = "Inventory full, right click to leave the pit"
                        text:SetParent(World)
                        text.FontSize = 20
                        text.Type = TextType.Screen
                        text.IsUnlit = true
                        text.Color = Color.Black
                        text.Anchor = { 0.5, 0.4 }
                        local impactPos = Camera.Position + Camera.Forward * impact.Distance
                        text.LocalPosition = impactPos
                        Timer(4, function()
                            text:RemoveFromParent()
                        end)
                        return
                    end
                    local block = impact.Block
                    Player:SwingRight()
                    local impactPos = Camera.Position + Camera.Forward * impact.Distance
                    emitter.Position = impactPos
                    emitter:spawn(15)
                    sfx(string.format("wood_impact_%d", math.random(1, 5)), { Spatialized = false, Volume = 0.6 })

                    local playerPos = Player.Position + Number3(1, 1, 1) * 1000000
                    tickSinceSync = 0
                    dojo.actions.hit_block(
                        math.floor(block.Coords.X),
                        math.floor(block.Coords.Y),
                        math.floor(block.Coords.Z),
                        math.floor(playerPos.X),
                        math.floor(playerPos.Y),
                        math.floor(playerPos.Z)
                    )

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
                end
            end
        end
    end
end

initUI = function()
    local ui = require("uikit")

    coinIcon = ui:createShape(Shape(Items.caillef.coin), { spherized = true })
    LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
        coinIcon.pivot.Rotation.Y = coinIcon.pivot.Rotation.Y + dt
    end)
    coinIcon.Size = 80
    coinText = ui:createText("0", Color.White, "big")
    coinText.object.FontSize = 30
    coinText.parentDidResize = function()
        coinIcon.pos = { 10, Screen.Height - Screen.SafeArea.Top - 10 - coinIcon.Height }
        coinText.pos =
        { coinIcon.pos.X + coinIcon.Width + 5, coinIcon.pos.Y + coinIcon.Height * 0.5 - coinText.Height * 0.5 }
    end
    coinText:parentDidResize()

    creditsIcon = ui:createShape(Shape(Items.caillef.coin), { spherized = true })
    creditsIcon.shape.Palette[1].Color = Color.Red
    creditsIcon.shape.Palette[2].Color = Color(math.floor(Color.Red.R * 0.8), math.floor(Color.Red.G * 0.8),
        math.floor(Color.Red.B * 0.8))
    LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
        creditsIcon.pivot.Rotation.Y = creditsIcon.pivot.Rotation.Y + dt
    end)
    creditsIcon.Size = 80
    creditsText = ui:createText("0", Color.White, "big")
    creditsText.object.FontSize = 30
    creditsText.parentDidResize = function()
        creditsIcon.pos = { 10, coinIcon.pos.Y - 5 - creditsIcon.Height }
        creditsText.pos =
        { creditsIcon.pos.X + creditsIcon.Width + 5, creditsIcon.pos.Y + creditsIcon.Height * 0.5 -
        creditsText.Height * 0.5 }
    end
    creditsText:parentDidResize()

    local help = ui:createText("Right Click: Teleport to Sell Area", Color.White, "small")
    help.parentDidResize = function()
        help.pos = { Screen.Width - help.Width - 4, 4 }
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
            return 0.3 + math.random() * 0.5
        end,
        color = function()
            return Color.Black
        end,
    })
    Player:EquipRightHand(Player.pickaxe)
    require("crosshair"):show()
    Player.Avatar:loadEquipment({ type = "hair" })
    Player.Avatar:loadEquipment({ type = "jacket" })
    Player.Avatar:loadEquipment({ type = "pants" })
    Player.Avatar:loadEquipment({ type = "boots" })
    Player:SetParent(World)
    Camera.FOV = 80
    -- require("object_skills").addStepClimbing(Player, { mapScale = 20 })
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
        blocksModule:setBlockHP(b, blockHp, BLOCKS_MAX_HP[blockType])
        local blockColor = BLOCK_COLORS[blockType]
        if b and (blockHp == 0 or blockType == 0 or blockColor == nil) then
            blocksModule:checkNeighborsAndAddChips(column.x, z, column.y)
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
    ["diamond_pit-PlayerPosition"] = updatePlayerPosition,
}

function startGame(toriiClient)
    textInputUsername.Text = string.sub(dojo.burnerAccount.Address, 1, 8)

    -- sync previous entities
    dojo:syncEntities(onEntityUpdateCallbacks)

    -- add callbacks when an entity is updated
    dojo:setOnEntityUpdateCallbacks(onEntityUpdateCallbacks)

    Timer(1, true, function()
        tickSinceSync = tickSinceSync + 1
        if tickSinceSync >= 5 then
            local playerPos = Player.Position + Number3(1, 1, 1) * 1000000
            dojo.actions.sync_position(math.floor(playerPos.X), math.floor(playerPos.Y), math.floor(playerPos.Z))
            tickSinceSync = 0
        end
    end)
end

-- dojo module

dojo = {}

dojo.createBurner = function(self, config, cb)
    self.toriiClient:CreateBurner(
        config.playerAddress,
        config.playerSigningKey,
        function(success, burnerAccount, privateKey)
            if not success then
                error("Can't create burner")
                return
            end
            dojo.burnerAccount = burnerAccount
            cb()
        end
    )
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
        local json = dojo.toriiClient:GetBurners()
        local burners = json.burners
        -- if not burners then
        self:createBurner(config, function()
            config.onConnect(dojo.toriiClient)
        end)
        -- else
        --     local lastBurner = burners[1]
        --     self.toriiClient:CreateAccount(lastBurner.publicKey, lastBurner.privateKey, function(success, burnerAccount)
        --         if not success then
        --             error("Can't create burner")
        --             return
        --         end
        --         dojo.burnerAccount = burnerAccount
        --         config.onConnect(dojo.toriiClient)
        --     end)
        -- end
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

function hex_to_string(hex)
    hex = hex:gsub("^0x", "") -- Remove "0x" prefix if present
    return (hex:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

function string_to_hex(input)
    -- Ensure the input is no longer than 11 characters
    input = string.sub(input, 1, 11)
    local result = "0x"
    for i = 1, #input do
        result = result .. string.format("%02X", string.byte(input:sub(i, i)))
    end
    return result
end

function number_to_hexstr(number)
    return "0x" .. string.format("%x", number)
end

-- generated contracts
dojo.actions = {
    hit_block = function(x, y, z, px, py, pz)
        if not dojo.toriiClient then
            return
        end
        -- z is down in Dojo, y is down on Cubzh
        local calldatastr = string.format(
            '["%s","%s","%s","%s","%s","%s"]',
            number_to_hexstr(x),
            number_to_hexstr(z),
            number_to_hexstr(-y),
            number_to_hexstr(px),
            number_to_hexstr(py),
            number_to_hexstr(pz)
        )
        if VERBOSE then
            print("Calling hit_block", calldatastr)
        end
        dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "hit_block", calldatastr)
    end,
    sync_position = function(px, py, pz)
        if not dojo.toriiClient then
            return
        end
        -- z is down in Dojo, y is down on Cubzh
        local calldatastr =
            string.format('["%s","%s","%s"]', number_to_hexstr(px), number_to_hexstr(py), number_to_hexstr(pz))
        if VERBOSE then
            print("Calling sync_position", calldatastr)
        end
        dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "sync_position", calldatastr)
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
    set_username = function(username)
        if not dojo.toriiClient then
            return
        end
        if VERBOSE then
            print("Calling set_username")
        end
        dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "set_username",
            string.format("[\"%s\"]", string_to_hex(username)))
    end,
    rebirth = function(nb)
        if not dojo.toriiClient then
            return
        end
        if VERBOSE then
            print("Calling rebirth")
        end
        dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "rebirth",
            string.format("[\"%s\"]", number_to_hexstr(nb)))
    end,
    open_egg = function(egg_type)
        if not dojo.toriiClient then
            return
        end
        if VERBOSE then
            print("Calling open_egg")
        end
        dojo.toriiClient:Execute(dojo.burnerAccount, dojo.config.actions, "open_egg",
            string.format("[\"%s\"]", number_to_hexstr(egg_type)))
    end
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
    end)
end

local cachedIslands = {}
local function create(radius)
    if cachedIslands[radius] then
        return Shape(cachedIslands[radius], { includeChildren = true })
    end
    local shape = MutableShape()
    cachedIslands[radius] = shape
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
            island.Scale = 5
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

-- Inventory

inventory_module = {
    inventories = {},
    uiOpened = false,
    nbUIOpen = 0,
    listUIOpened = {},

    -- private
    nbAlwaysVisible = 0,
}

local resourcesByKey = {}
local resourcesById = {}

inventory_module.setResources = function(_, _resourcesByKey, _resourcesById)
    resourcesByKey = _resourcesByKey
    resourcesById = _resourcesById
end

local isClient = type(Client.IsMobile) == "boolean"

if isClient then
    function getSlotIndexFromVisibleInventories(x, y)
        for key, inventory in pairs(inventory_module.listUIOpened) do
            if inventory and key ~= "cursor" then
                local inventoryUi = inventory.ui
                if
                    inventoryUi.pos.X <= x
                    and x <= inventoryUi.pos.X + inventoryUi.Width
                    and inventoryUi.pos.Y <= y
                    and y <= inventoryUi.pos.Y + inventoryUi.Height
                then
                    return key, inventoryUi:getSlotIndex(x - inventoryUi.pos.X, y - inventoryUi.pos.Y)
                end
            end
        end
    end

    LocalEvent:Listen(LocalEvent.Name.PointerUp, function(pe)
        local cursorSlot = inventory_module.inventories.cursor.slots[1]
        if not cursorSlot.key then
            return
        end
        local inventoryKey, slotIndex = getSlotIndexFromVisibleInventories(pe.X * Screen.Width, pe.Y * Screen.Height)
        if not inventoryKey or not slotIndex or slotIndex < 1 then
            return
        end
        local inventory = inventory_module.inventories[inventoryKey]
        if Client.IsMobile then
            inventory:selectSlot(slotIndex)
        else
            LocalEvent:Send("InvClearSlot", {
                key = "cursor",
                slotIndex = 1,
                callback = function()
                    inventory:tryAddElement(cursorSlot.key, cursorSlot.amount, slotIndex)
                end,
            })
        end
    end, { topPriority = true })

    local saveInventoriesRequests = {}
    function saveInventory(iKey)
        if iKey == "cursor" then
            return
        end
    end
end -- end is client

inventory_module.serialize = function(self, iKey)
    local inventory = self.inventories[iKey]
    if inventory == nil then
        return
    end
    local data = Data()
    data:WriteUInt8(1)                  -- version
    data:WriteUInt16(inventory.nbSlots) -- nbSlots
    for i = 1, inventory.nbSlots do
        local slot = inventory.slots[i]
        local id = slot.key and resourcesByKey[slot.key].id or 0
        data:WriteUInt16(math.floor(id))
        data:WriteUInt16(slot and slot.amount or 0)
    end
    return data
end

inventory_module.deserialize = function(_, iKey, data)
    if not data or iKey == "cursor" then
        return
    end
    local version = data:ReadUInt8()
    if version ~= 1 then
        return
    end
    local inventory = inventory_module.inventories[iKey]
    if not inventory then
        error("Inventory: can't find " .. iKey, 2)
    end
    local nbSlots = data:ReadUInt16()
    for slotIndex = 1, nbSlots do
        local id = data:ReadUInt16()
        local amount = data:ReadUInt16()
        if id > 0 then
            inventory:tryAddElement(resourcesById[id].key, amount, slotIndex)
        end
    end
end

inventory_module.create = function(_, iKey, config)
    if not config.width or not config.height then
        return error("inventory: missing width or height in config", 2)
    end
    local nbSlots = config.width * config.height
    local alwaysVisible = config.alwaysVisible
    local selector = config.selector
    local toSave = true
    if config.toSave == false then
        toSave = false
    end

    local inventory = {}
    inventory_module.inventories[iKey] = inventory

    inventory.onOpen = config.onOpen

    local slots = {}
    for i = 1, nbSlots do
        slots[i] = { index = i }
    end
    inventory.slots = slots
    inventory.nbSlots = nbSlots

    local function inventoryGetSlotIndexMatchingKey(key)
        for i = 1, nbSlots do
            if slots[i] and slots[i].key == key then
                return i
            end
        end
    end

    inventory.tryAddElement = function(_, rKey, amount, optionalSlot)
        if rKey == nil or amount == nil then
            return
        end
        local slotIndex = optionalSlot
        if slotIndex then
            if slots[slotIndex].key and slots[slotIndex].key ~= rKey then
                LocalEvent:Send("InvAdd", {
                    key = "cursor",
                    rKey = slots[slotIndex].key,
                    amount = slots[slotIndex].amount,
                    callback = function()
                        slots[slotIndex].key = nil
                        slots[slotIndex].amount = nil
                        inventory:tryAddElement(rKey, amount, optionalSlot)
                    end,
                })
                return
            end
        else
            slotIndex = inventoryGetSlotIndexMatchingKey(rKey)
        end
        if not slotIndex then
            -- try add to first empty slot
            for i = 1, nbSlots do
                if slots[i].key == nil then
                    slotIndex = i
                    break
                end
            end
        end
        if not slotIndex then
            LocalEvent:Send("invFailAdd(" .. iKey .. ")", { key = rKey, amount = amount })
            return false
        end

        slots[slotIndex] = { index = slotIndex, key = rKey, amount = (slots[slotIndex].amount or 0) + amount }
        LocalEvent:Send("invUpdateSlot(" .. iKey .. ")", slots[slotIndex])

        return true
    end

    inventory.getQuantity = function(_, rKey)
        local quantity = 0
        for i = 1, nbSlots do
            if slots[i].key == rKey and slots[i].amount and slots[i].amount > 0 then
                quantity = quantity + slots[i].amount
            end
        end
        return quantity
    end

    inventory.tryRemoveElement = function(_, rKey, amount, optionalSlot)
        if rKey == nil or amount == nil then
            return
        end

        local slotIndex = optionalSlot
        if not slotIndex then
            slotIndex = inventoryGetSlotIndexMatchingKey(rKey)
        end
        if not slotIndex or amount > slots[slotIndex].amount then
            LocalEvent:Send("invFailRemove(" .. iKey .. ")", { key = rKey, amount = amount })
            return false
        end

        if amount > slots[slotIndex].amount then
            amount = amount - slots[slotIndex].amount
            slots[slotIndex] = { index = slotIndex }
            LocalEvent:Send("invUpdateSlot(" .. iKey .. ")", slots[slotIndex])
            return inventory:tryRemoveElement(rKey, amount, optionalSlot)
        end
        slots[slotIndex].amount = slots[slotIndex].amount - amount
        if slots[slotIndex].amount == 0 then
            slots[slotIndex] = { index = slotIndex }
        end
        LocalEvent:Send("invUpdateSlot(" .. iKey .. ")", slots[slotIndex])

        return true
    end

    inventory.clearSlotContent = function(_, slotIndex)
        if slotIndex == nil then
            return
        end
        local contentToClear = slots[slotIndex]
        slots[slotIndex] = { index = slotIndex }
        LocalEvent:Send("invUpdateSlot(" .. iKey .. ")", slots[slotIndex])
        return contentToClear
    end

    local bg
    local uiSlots = {}

    if iKey == "cursor" then
        local latestPointerPos
        LocalEvent:Listen(LocalEvent.Name.Tick, function()
            if not latestPointerPos or not inventory.slots[1].key then
                return
            end
            local pe = latestPointerPos
            inventory.ui.pos = { pe.X * Screen.Width - 20, pe.Y * Screen.Height - 20 }
            inventory.ui.pos.Z = -300
        end, { topPriority = true })
        LocalEvent:Listen(LocalEvent.Name.PointerMove, function(pe)
            latestPointerPos = pe
        end, { topPriority = true })
        LocalEvent:Listen(LocalEvent.Name.PointerDrag, function(pe)
            latestPointerPos = pe
        end, { topPriority = true })
    end

    inventory.show = function(_)
        local ui = require("uikit")
        local padding = require("uitheme").current.padding

        bg = ui:createFrame(iKey == "cursor" and Color(0, 0, 0, 0) or Color(198, 198, 198))
        inventory.ui = bg

        local nbRows = config.height
        local nbColumns = config.width

        local cellSize = Screen.Width < 1000 and 40 or 60

        inventory.isVisible = true

        for j = 1, nbRows do
            for i = 1, nbColumns do
                local slotBg = ui:createFrame(iKey == "cursor" and Color(0, 0, 0, 0) or Color(85, 85, 85))
                local slot = ui:createFrame(iKey == "cursor" and Color(0, 0, 0, 0) or Color(139, 139, 139))
                slot:setParent(slotBg)
                local slotIndex = (j - 1) * nbColumns + i
                uiSlots[slotIndex] = slotBg
                slotBg.slot = slot
                slotBg.parentDidResize = function()
                    slotBg.Size = cellSize
                    slot.Size = slotBg.Size - padding
                    slotBg.pos = { padding + (i - 1) * cellSize, padding + (nbRows - j) * cellSize }
                    slot.pos = { padding * 0.5, padding * 0.5 }
                end
                slotBg:setParent(bg)
                if iKey ~= "cursor" then
                    local cursorSlotOnPress
                    if not Client.IsMobile then
                        slotBg.onPress = function()
                            local content = slots[slotIndex]
                            cursorSlotOnPress = inventory_module.inventories.cursor.slots[1]
                            if not content.key then
                                return
                            end
                            if sneak then
                                LocalEvent:Send("InvAdd", {
                                    key = iKey == "hotbar" and "mainInventory" or "hotbar",
                                    rKey = content.key,
                                    amount = content.amount,
                                    callback = function()
                                        inventory:clearSlotContent(slotIndex)
                                    end,
                                })
                                return
                            end
                        end
                        slotBg.onDrag = function()
                            local cursorSlot = inventory_module.inventories.cursor.slots[1]
                            if cursorSlot.key then
                                return
                            end
                            local content = slots[slotIndex]
                            if not content.key then
                                return
                            end
                            LocalEvent:Send("InvAdd", {
                                key = "cursor",
                                rKey = content.key,
                                amount = content.amount,
                                callback = function()
                                    inventory:clearSlotContent(slotIndex)
                                end,
                            })
                        end
                        slotBg.onRelease = function()
                            local cursorSlot = inventory_module.inventories.cursor.slots[1]
                            if not cursorSlot.key and slots[slotIndex].key then
                                local content = slots[slotIndex]
                                LocalEvent:Send("InvAdd", {
                                    key = "cursor",
                                    rKey = content.key,
                                    amount = content.amount,
                                    callback = function()
                                        inventory:clearSlotContent(slotIndex)
                                    end,
                                })
                                return
                            end
                            if not cursorSlotOnPress.key then
                                return
                            end
                            local key, amount = cursorSlot.key, cursorSlot.amount
                            LocalEvent:Send("InvClearSlot", {
                                key = "cursor",
                                slotIndex = 1,
                                callback = function()
                                    inventory:tryAddElement(key, amount, slotIndex)
                                end,
                            })
                        end
                    else
                        -- mobile
                        slotBg.onRelease = function()
                            inventory:selectSlot(slotIndex)
                        end
                    end
                end
                LocalEvent:Send("invUpdateSlot(" .. iKey .. ")", slots[slotIndex])
            end
        end

        bg.getSlotIndex = function(_, x, y)
            x = x - padding + cellSize * 0.5
            y = y - padding + cellSize * 0.5
            return math.floor(x / (cellSize + padding))
                + 1
                + (nbRows - 1 - (math.floor(y / (cellSize + padding)))) * nbColumns
        end

        bg.parentDidResize = function()
            bg.Width = nbColumns * cellSize + 2 * padding
            bg.Height = nbRows * cellSize + 2 * padding

            bg.pos = config.uiPos and config.uiPos(bg)
                or { Screen.Width * 0.5 - bg.Width * 0.5, Screen.Height * 0.5 - bg.Height * 0.5 }
        end
        bg:parentDidResize()

        if not alwaysVisible then
            require("crosshair"):hide()
            Pointer:Show()
            require("controls"):turnOff()
            Player.Motion = { 0, 0, 0 }
        end
        inventory.isVisible = true

        if selector then
            inventory:selectSlot(1)
        end

        return bg
    end

    local prevSelectedSlotIndex
    inventory.selectSlot = function(_, index)
        index = index or prevSelectedSlotIndex
        if prevSelectedSlotIndex then
            uiSlots[prevSelectedSlotIndex]:setColor(Color(85, 85, 85))
        end
        if not uiSlots[index] then
            return
        end
        uiSlots[index]:setColor(Color.White)
        prevSelectedSlotIndex = index
        LocalEvent:Send("invSelect(" .. iKey .. ")", slots[index])
    end

    local loadingInventory = true

    local ui = require("uikit")
    LocalEvent:Listen("invUpdateSlot(" .. iKey .. ")", function(slot)
        if not loadingInventory and toSave then
            saveInventory(iKey)
        end

        if not uiSlots or not slot.index or inventory.isVisible == false then
            return
        end

        if selector then
            inventory:selectSlot() -- remove item in hand if reached 0 or add it if at least 1
        end

        if
            uiSlots[slot.index].key == slot.key
            and slot.amount
            and slot.amount > 1
            and uiSlots[slot.index].content.amountText
        then
            uiSlots[slot.index].content.amountText.Text = string.format("%d", slot.amount)
            uiSlots[slot.index].content.amountText:show()
            uiSlots[slot.index].content:parentDidResize()
            return
        end

        if uiSlots[slot.index].content then
            uiSlots[slot.index].content:remove()
            uiSlots[slot.index].content = nil
        end

        if slot.key == nil then
            return
        end

        uiSlots[slot.index].key = slot.key
        local uiSlot = uiSlots[slot.index].slot

        local content = ui:createFrame()

        local amountText = ui:createText(string.format("%d", slot.amount), Color.White, "small")
        content.amountText = amountText
        amountText.pos.Z = -500
        amountText:setParent(content)
        if slot.amount == 1 then
            amountText:hide()
        end

        local resource = resourcesByKey[slot.key]
        if resource.block then
            local b = MutableShape()
            b:AddBlock(resourcesByKey[slot.key].block.color, 0, 0, 0)

            local shape = ui:createShape(b)
            shape.pivot.Rotation = { math.pi * 0.1, math.pi * 0.25, 0 }
            shape:setParent(content)

            shape.parentDidResize = function()
                shape.Size = uiSlot.Width * 0.5
                shape.pos = { uiSlot.Width * 0.25, uiSlot.Height * 0.25 }
            end
        elseif resource.icon and resource.cachedShape then
            local obj = Shape(resource.cachedShape, { includeChildren = true })
            local shape = ui:createShape(obj, { spherized = true })
            shape:setParent(content)
            shape.pivot.Rotation = resource.icon.rotation
            shape.pivot.Scale = shape.pivot.Scale * resource.icon.scale

            shape.parentDidResize = function()
                shape.Size = math.min(uiSlot.Width * 0.5, uiSlot.Height * 0.5)
                shape.pos = Number3(uiSlot.Width * 0.25, uiSlot.Height * 0.25, 0)
                    + { resource.icon.pos[1] * uiSlot.Width, resource.icon.pos[2] * uiSlot.Height, 0 }
            end
        else -- unknown, red block
            local b = MutableShape()
            b:AddBlock(Color.Red, 0, 0, 0)

            local shape = ui:createShape(b)
            shape:setParent(content)

            shape.parentDidResize = function()
                shape.Size = uiSlot.Width * 0.5
                shape.pos = { uiSlot.Width * 0.25, uiSlot.Height * 0.25 }
            end
        end

        if slot.amount == 1 then
            amountText:hide()
        end
        content.parentDidResize = function()
            if not uiSlot then
                return
            end
            content.Size = uiSlot.Width
            amountText.pos = { content.Width - amountText.Width, 0 }
            amountText.pos.Z = -500
        end
        content:setParent(uiSlot)
        uiSlots[slot.index].content = content
    end)

    if selector then -- Hotbar
        LocalEvent:Listen(LocalEvent.Name.PointerWheel, function(delta)
            local newSlot = prevSelectedSlotIndex + (delta > 0 and 1 or -1)
            if newSlot <= 0 then
                newSlot = nbSlots
            end
            if newSlot > nbSlots then
                newSlot = 1
            end
            inventory:selectSlot(newSlot)
        end)
        LocalEvent:Listen(LocalEvent.Name.KeyboardInput, function(char, keycode, modifiers, down)
            if not down then
                return
            end
            local keys = { 82, 83, 84, 85, 86, 87, 88, 89, 90, 81 }
            for i = 1, math.min(#keys, nbSlots) do
                if keycode == keys[i] then
                    inventory:selectSlot(i)
                    return
                end
            end
        end)
    end

    inventory.hide = function(_)
        if not bg then
            return
        end
        if alwaysVisible then
            return
        end
        inventory.isVisible = false
        bg:remove()
        bg = nil
        inventory.ui = nil

        Pointer:Hide()
        require("crosshair"):show()
        require("controls"):turnOn()
    end

    inventory.isVisible = false
    inventory.alwaysVisible = alwaysVisible
    if alwaysVisible then
        inventory:show()
        inventory_module.listUIOpened[iKey] = inventory
        inventory_module.nbUIOpen = inventory_module.nbUIOpen + 1
        inventory_module.nbAlwaysVisible = inventory_module.nbAlwaysVisible + 1
    end

    loadingInventory = false

    return inventory
end

LocalEvent:Listen("InvAdd", function(data)
    local key = data.key
    local rKey = data.rKey
    local amount = data.amount
    local inventory = inventory_module.inventories[key]
    if not inventory then
        error("Inventory: can't find " .. key, 2)
    end
    local success = inventory:tryAddElement(rKey, amount)
    if not data.callback then
        return
    end
    data.callback(success)
end)

LocalEvent:Listen("InvGetQuantity", function(data)
    local keys = type(data.keys) == "table" and data.keys or { data.keys }
    local rKey = data.rKey

    local quantities = {
        total = 0,
    }
    for _, key in ipairs(keys) do
        local inventory = inventory_module.inventories[key]
        if not inventory then
            error("Inventory: can't find " .. key, 2)
        end
        local qty = inventory:getQuantity(rKey)
        quantities.total = quantities.total + qty
        quantities[key] = qty
    end
    if not data.callback then
        return
    end
    data.callback(quantities)
end)

LocalEvent:Listen("InvRemove", function(data)
    local key = data.key
    local rKey = data.rKey
    local amount = data.amount
    local inventory = inventory_module.inventories[key]
    if not inventory then
        error("Inventory: can't find " .. key, 2)
    end
    local success = inventory:tryRemoveElement(rKey, amount)
    if not data.callback then
        return
    end
    data.callback(success)
end)

LocalEvent:Listen("InvAddGlobal", function(data)
    local keys = type(data.keys) == "table" and data.keys or { data.keys }
    local rKey = data.rKey
    local amount = data.amount

    for _, key in ipairs(keys) do
        local inventory = inventory_module.inventories[key]
        if not inventory then
            error("Inventory: can't find " .. key, 2)
        end
        if inventory:tryAddElement(rKey, amount) then
            if not data.callback then
                return
            end
            data.callback(true)
            return
        end
    end
    data.callback(false)
end)

LocalEvent:Listen("InvRemoveGlobal", function(data)
    local keys = type(data.keys) == "table" and data.keys or { data.keys }
    local rKey = data.rKey
    local amount = data.amount

    LocalEvent:Send("InvGetQuantity", {
        keys = keys,
        rKey = rKey,
        callback = function(quantities)
            if quantities.total < amount then
                print("Not enough resources")
                data.callback(false)
                return
            end
            for _, key in ipairs(keys) do
                local inventory = inventory_module.inventories[key]
                if not inventory then
                    error("Inventory: can't find " .. key, 2)
                end
                local qty = inventory:getQuantity(rKey)
                if amount <= qty then
                    inventory:tryRemoveElement(rKey, amount)
                    if not data.callback then
                        return
                    end
                    data.callback(true)
                    return
                else
                    amount = amount - qty
                    inventory:tryRemoveElement(rKey, qty)
                end
            end
            data.callback(true)
        end,
    })
end)

LocalEvent:Listen("InvClearAll", function(data)
    local key = data.key
    local inventory = inventory_module.inventories[key]
    if not inventory then
        error("Inventory: can't find " .. key, 2)
    end
    for index = 1, inventory.nbSlots do
        inventory:clearSlotContent(index)
    end
    if not data.callback then
        return
    end
    data.callback()
end)

LocalEvent:Listen("InvClearSlot", function(data)
    local key = data.key
    local index = data.slotIndex
    local inventory = inventory_module.inventories[key]
    if not inventory then
        error("Inventory: can't find " .. key, 2)
    end
    local success = inventory:clearSlotContent(index)
    if not data.callback then
        return
    end
    data.callback(success)
end)

LocalEvent:Listen("InvShow", function(data)
    local key = data.key
    local inventory = inventory_module.inventories[key]
    if not inventory then
        error("Inventory: can't open " .. key, 2)
    end
    if inventory.alwaysVisible or inventory.isVisible then
        return
    end
    inventory:show()
    if inventory.onOpen then
        inventory:onOpen()
    end
    inventory_module.listUIOpened[key] = inventory
    inventory_module.nbUIOpen = inventory_module.nbUIOpen + 1
    inventory_module.uiOpened = true
end)

LocalEvent:Listen("InvHide", function(data)
    local key = data.key
    local inventory = inventory_module.inventories[key]
    if not inventory then
        error("Inventory: can't close " .. key, 2)
    end
    if inventory.alwaysVisible or inventory.isVisible == false then
        return
    end
    inventory:hide()
    inventory_module.nbUIOpen = inventory_module.nbUIOpen - 1
    inventory_module.listUIOpened[key] = nil
    if inventory_module.nbUIOpen <= inventory_module.nbAlwaysVisible then
        inventory_module.uiOpened = false
    end
end)

LocalEvent:Listen("InvToggle", function(data)
    local key = data.key
    local inventory = inventory_module.inventories[key]
    if not inventory then
        error("Inventory: can't close " .. key, 2)
    end
    if inventory.isVisible then
        LocalEvent:Send("InvHide", data)
    else
        LocalEvent:Send("InvShow", data)
    end
end)
