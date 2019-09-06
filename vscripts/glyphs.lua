if Glyphs == nil then
	Glyphs = class({})
end

Glyphs.glyphDropIndex = 0
Glyphs.ArcaneCrystalTable = {}

function Glyphs:DropArcaneCrystals(position, quantityScale)
	if GameMode.VoteSystem.crystal_loot_disabled then
		--print("crystal_loot_disabled")
		return
	end

	local maxFactor = RPCItems:GetMaxFactor()
	--DEBUG
	--
	local connectedPlayerCount = RPCItems:GetConnectedPlayerCount()
	local crystalQuantity = (maxFactor / 2) * (1 + connectedPlayerCount * 0.5) * quantityScale
	crystalQuantity = crystalQuantity * (1 + GameState:GetPlayerPremiumStatusCount() * 0.1)
	crystalQuantity = RPCItems:GetLogarithmicVarianceValue(crystalQuantity, 0, 0, 0, 0)
	local divisor = 3
	if GameState:GetDifficultyFactor() == 1 then
		if GameState:IsTanariJungle() then
			divisor = 2.5
		end
	end
	if GameState:GetDifficultyFactor() == 2 then
		divisor = 3
		if GameState:IsTanariJungle() then
			divisor = 2.2
		end
	end
	if GameState:GetDifficultyFactor() == 3 then
		divisor = 1.0
	end
	if Events.SpiritRealm then
		crystalQuantity = crystalQuantity * 2
	end
	crystalQuantity = math.ceil(crystalQuantity / divisor)
	local crystalsPerPlayer = math.floor(crystalQuantity / connectedPlayerCount)
	Glyphs.glyphDropIndex = Glyphs.glyphDropIndex + 1
	for i = 1, #MAIN_HERO_TABLE, 1 do
		MAIN_HERO_TABLE[i].maxCrystals = MAIN_HERO_TABLE[i].maxCrystals + crystalsPerPlayer
	end
	local massiveCrystalQuantity = math.max((crystalQuantity - 200) / 100, 0)
	crystalQuantity = crystalQuantity - massiveCrystalQuantity * 100
	local greatestCrystalQuantity = math.max((crystalQuantity - 100) / 50, 0)
	crystalQuantity = crystalQuantity - greatestCrystalQuantity * 50
	local greatCrystalQuantity = math.max((crystalQuantity - 20) / 20, 0)
	crystalQuantity = crystalQuantity - greatCrystalQuantity * 20
	local largeCrystalQuantity = math.max((crystalQuantity - 0) / 10, 1)
	crystalQuantity = crystalQuantity - largeCrystalQuantity * 10
	local smallCrystalQuantity = math.max(crystalQuantity / 5, 0)
	for i = 1, largeCrystalQuantity, 1 do
		Timers:CreateTimer(0.12 * i, function()
			Glyphs:CreateIndividualCrystal(position, 10)
		end)
	end
	Timers:CreateTimer(0.53, function()
		for i = 1, greatCrystalQuantity, 1 do
			Timers:CreateTimer(0.12 * i, function()
				Glyphs:CreateIndividualCrystal(position, 20)
			end)
		end
	end)
	Timers:CreateTimer(2.03, function()
		for i = 1, greatestCrystalQuantity, 1 do
			Timers:CreateTimer(0.12 * i, function()
				Glyphs:CreateIndividualCrystal(position, 50)
			end)
		end
	end)
	Timers:CreateTimer(1.53, function()
		for i = 1, massiveCrystalQuantity, 1 do
			Timers:CreateTimer(0.12 * i, function()
				Glyphs:CreateIndividualCrystal(position, 100)
			end)
		end
	end)
	Timers:CreateTimer(1.06, function()
		for i = 1, smallCrystalQuantity, 1 do
			Timers:CreateTimer(0.12 * i, function()
				Glyphs:CreateIndividualCrystal(position, 5)
			end)
		end
	end)
	Timers:CreateTimer(45, function()
		for i = 1, #MAIN_HERO_TABLE, 1 do
			MAIN_HERO_TABLE[i].crystalsToSave = MAIN_HERO_TABLE[i].crystalsToSave + MAIN_HERO_TABLE[i].crystalsPickedUp
			MAIN_HERO_TABLE[i].crystalsPickedUp = 0
			MAIN_HERO_TABLE[i].maxCrystals = MAIN_HERO_TABLE[i].maxCrystals - crystalsPerPlayer
		end
		Glyphs.glyphDropIndex = Glyphs.glyphDropIndex - 1
		if Glyphs.glyphDropIndex == 0 then
			for i = 1, #Glyphs.ArcaneCrystalTable, 1 do
				if IsValidEntity(Glyphs.ArcaneCrystalTable[i]) then
					UTIL_Remove(Glyphs.ArcaneCrystalTable[i])
				end
			end
			Glyphs:SaveResources()
			CustomGameEventManager:Send_ServerToAllClients("arcane_out", {})
		end
	end)
end

function Glyphs:CreateIndividualCrystal(position, size)
	local crystal = CreateUnitByName("arcane_crystal", position + Vector(0, 0, 50), true, nil, nil, DOTA_TEAM_GOODGUYS)
	crystal.active = false
	local crystalAbility = crystal:AddAbility("arcane_crystal_ability")
	crystalAbility:SetLevel(1)
	local fv = RandomVector(1)
	crystal.quantity = size
	WallPhysics:Jump(crystal, fv, RandomInt(4, 9), RandomInt(50, 60), 30, 2)
	crystal:SetOriginalModel("models/props_gameplay/rune_invisibility01.vmdl")
	crystal:SetModel("models/props_gameplay/rune_invisibility01.vmdl")

	crystal:SetModelScale(0)

	Timers:CreateTimer(1, function()
		if IsValidEntity(crystal) then
			if size == 5 then
				crystal:SetModelScale(0.5)
				crystal.scale = 0.5
			elseif size == 10 then
				crystal:SetModelScale(0.7)
				crystal.scale = 0.7
			elseif size == 20 then
				crystal:SetModelScale(1.0)
				crystal.scale = 1
			elseif size == 50 then
				crystal:SetModelScale(1.2)
				crystal.scale = 1.2
			elseif size >= 100 then
				crystal:SetModelScale(1.5)
				crystal.scale = 1.5
			end
		end
	end)
	Timers:CreateTimer(1.5, function()
		if IsValidEntity(crystal) then
			crystal.active = true
			crystal:RemoveModifierByName("modifier_hero_aura_apply")
		end
	end)
	StartAnimation(crystal, {duration = 300, activity = ACT_DOTA_IDLE, rate = 1})
	table.insert(Glyphs.ArcaneCrystalTable, crystal)
end

function Glyphs:SaveResources()
	if SaveLoad:GetAllowSaving() then
		for i = 1, #MAIN_HERO_TABLE, 1 do
			local hero = MAIN_HERO_TABLE[i]
			if hero.crystalsToSave > 0 then
				local playerID = hero:GetPlayerOwnerID()
				local steamID = PlayerResource:GetSteamAccountID(playerID)
				local player = PlayerResource:GetPlayer(playerID)
				local amount = hero.crystalsToSave
				local url = ROSHPIT_URL.."/champions/modifyArcaneCrystals?"
				url = url.."steam_id="..steamID
				url = url.."&amount="..amount
				url = url.."&key1="..GetDedicatedServerKeyV2(SaveLoad.KeyVersion)
				CreateHTTPRequestScriptVM("POST", url):Send(function(result)
					--SaveLoad:NewKey()
					local resultTable = {}
					--print( "GET response:\n" )
					for k, v in pairs(result) do
						--print( string.format( "%s : %s\n", k, v ) )
					end
					--print( "Done." )
					local resultTable = JSON:decode(result.Body)
					hero.crystalsToSave = 0
					if resultTable then
						-- resultTable = Quests:GetQuestDataFromJSON(resultTable)
						local arcaneCrystals = resultTable.arcane_crystals
						local enchanterTier = resultTable.glyph_enchanter_tier
						CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-resources", {arcane = arcaneCrystals})
						CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-enchanter", {tier = enchanterTier})
						CustomGameEventManager:Send_ServerToPlayer(player, "update_resources", {arcane_crystals = arcaneCrystals, enchanter_tier = enchanterTier, player = playerID})

						Statistics.dispatch("crystals:change", {playerID = playerID});
					end
				end)
				--print("SAVING HERO CRYSTALS: "..hero.crystalsToSave)
			end
		end
	end
	Glyphs.ArcaneCrystalTable = {}
end

function Glyphs:GetPlayerResources(playerID)
	local steamID = PlayerResource:GetSteamAccountID(playerID)
	local player = PlayerResource:GetPlayer(playerID)
	local url = ROSHPIT_URL.."/champions/getResources?"
	url = url.."steam_id="..steamID
	CreateHTTPRequestScriptVM("GET", url):Send(function(result)
		local resultTable = {}
		--print( "GET response:\n" )
		for k, v in pairs(result) do
			--print( string.format( "%s : %s\n", k, v ) )
		end
		--print( "Done." )
		local resultTable = JSON:decode(result.Body)
		-- resultTable = Quests:GetQuestDataFromJSON(resultTable)
		local arcaneCrystals = resultTable.arcane_crystals
		local enchanterTier = resultTable.glyph_enchanter_tier
		local mithrilShards = resultTable.mithril_shards
		CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-resources", {arcane = arcaneCrystals})
		CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-enchanter", {tier = enchanterTier})
		CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-mithril", {mithril = mithrilShards})
		CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-income", {available = resultTable.income_available})
		CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-challenge", {completed = resultTable.challenge_completed})
		CustomGameEventManager:Send_ServerToPlayer(player, "update_resources", {arcane_crystals = arcaneCrystals, enchanter_tier = enchanterTier, player = playerID, mithril = mithrilShards})

		local webPremTime = resultTable.web_premium
		local premiumStatus = Glyphs:GetWebStatus(os:TimeStamp(webPremTime), os:ServerTimeToTable())
		if premiumStatus then
			CustomNetTables:SetTableValue("premium_pass", "web-"..tostring(playerID), {premium = 1})
			CustomGameEventManager:Send_ServerToAllClients("update_premium", {playerID = playerID})
		end
	end)
end

function Glyphs:GetWebStatus(premiumTime, actualTime)
	local premium = false
	if actualTime.year < premiumTime.year then
		premium = true
	else
		if actualTime.month < premiumTime.month then
			premium = true
		else
			if actualTime.day <= premiumTime.day then
				premium = true
			end
		end
	end
	return premium
end

function Glyphs:CreateGlyphItem(variantName, rarityName, itemNameText, slotText, useDescription, deathLocation, requiredHero, minLevel, property1, dropIndex)
	local itemVariant = variantName
	local item = RPCItems:CreateItem(itemVariant, nil, nil)
	item.newItemTable.rarity = rarityName
	item.newItemTable.itemPrefix = ""
	item.newItemTable.itemSuffix = ""
	item.newItemTable.rarityFactor = RPCItems:GetRarityFactor(item.newItemTable.rarity)
	item.newItemTable.qualityColor = RPCItems:GetRarityColor(item.newItemTable.rarity)
	item.newItemTable.stackedConsumable = true
	item.newItemTable.consumable = false
	item.newItemTable.itemDescription = description
	item.newItemTable.itemDescription = slotText
	item.newItemTable.useDescription = useDescription
	item.newItemTable.item_slot = -1
	item.newItemTable.qualityName = rarityName
	item.newItemTable.glyph = 1
	item.newItemTable.gear = false
	item.newItemTable.glyph = true
	item.newItemTable.property1 = property1
	item.newItemTable.minLevel = minLevel
	item.newItemTable.requiredHero = requiredHero
	RPCItems:SetTableValues(item, itemNameText, false, slotText, RPCItems:GetRarityColor(item.newItemTable.rarity), item.newItemTable.rarity, "", "", RPCItems:GetRarityFactor(item.newItemTable.rarity))
	if requiredHero == "tooltip_neutral" then
	else
		item.newItemTable.requiredHero = requiredHero
	end
	CustomNetTables:SetTableValue("weapons", "item"..tostring(item:GetEntityIndex()), {})
	RPCItems:RemovePropertyValues(item)

	RPCItems:ItemUpdateCustomNetTables(item)
	-- DeepPrintTable(item)
	if dropIndex == 0 then
		local drop = CreateItemOnPositionSync(deathLocation, item)
		local position = deathLocation
		RPCItems:DropItem(item, position)
	elseif dropIndex == -1 then
	else
		local hero = EntIndexToHScript(dropIndex)
		item.pickedUp = true
		RPCItems:GiveItemToHeroWithSlotCheck(hero, item)
	end

	return item
end

function Glyphs:DebugCreateGlyph()
	-- Glyphs:GlyphRollLesserStrength(Vector(-14528, 14528))
	-- Glyphs:GlyphRollLesserAgility(Vector(-14528, 14528))
	-- Glyphs:GlyphRollIntelligence(Vector(-14528, 14528))
	-- Glyphs:GlyphRollGreaterIntelligence(Vector(-14528, 14528))
	Glyphs:RollGlyphAll("item_rpc_flamewaker_glyph_3_1", Vector(-14528, 14528), 0)
end

function Glyphs:PlaceGlyphInSlot(msg)
	local hero = EntIndexToHScript(msg.heroIndex)
	local item = EntIndexToHScript(msg.itemIndex)
	local glyphSlot = msg.glyphSlot
	hero:Stop()
	--print("[Glyphs:PlaceGlyphInSlot] +++++++++++++++++++++++++++++++++++++++++++++")
	--DeepPrintTable(msg)
	--print(msg.heroIndex)
	--print('glyph SLOT'..msg.glyphSlot)
	if item.newItemTable.glyph then
		--print("PlaceGlyphInSlot 1")
		local applicable = Glyphs:CheckApplicable(item, hero)
		if applicable == 1 then
			--print("PlaceGlyphInSlot 2")
			hero:TakeItem(item)
			--print(tostring(msg.heroIndex).."-glyph-"..tostring(glyphSlot))
			Glyphs:ApplyGlyph(hero, glyphSlot, msg.itemIndex)
			CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "new_glyph_inserted", {glyphSlot = glyphSlot})
		else
			--print("PlaceGlyphInSlot 3")
			Timers:CreateTimer(0.03, function()
				hero:Stop()
			end)
			Notifications:Top(hero:GetPlayerOwnerID(), {text = applicable, duration = 2, style = {color = "red"}, continue = false})
		end
	end
end

function Glyphs:CheckApplicable(glyph, hero)
	--print("[Glyphs:CheckApplicable] +++++++++++++++++++++++++")
	--print(hero:GetUnitName())
	--print(glyph.newItemTable.requiredHero)
	local modifierToFind = ""
	if glyph.newItemTable.property1 then
		modifierToFind = glyph.newItemTable.property1
	else
		return "No modifier name."
	end
	if hero:GetUnitName() == glyph.newItemTable.requiredHero or glyph.newItemTable.requiredHero == "tooltip_neutral" then
	else
		return "Can't Equip"
	end
	if hero:GetLevel() < glyph.newItemTable.minLevel then
		return "Level Requirement"
	elseif (not hero:GetUnitName() == glyph.newItemTable.requiredHero and not glyph.newItemTable.requiredHero == "tooltip_neutral") then
		return "Can't Equip"
	elseif hero:HasModifier(modifierToFind) then
		return "Can't Have Duplicate Glyphs"
	else
		return 1
	end
end

function Glyphs:ApplyGlyph(heroEntity, glyphSlot, glyphIndex)
	local glyph = EntIndexToHScript(glyphIndex)
	glyph.pickedUp = true
	glyph.newItemTable.hero = heroEntity
	if Glyphs:ValidateGlyph(glyph, heroEntity) then
		CustomNetTables:SetTableValue("skill_tree", tostring(heroEntity:GetPlayerOwnerID()) .. "-glyph-"..tostring(glyphSlot), {glyphIndex = glyphIndex})
		heroEntity.glyphUnit:AddItem(glyph)
		Glyphs:RemoveGlyphBonusesAndRecalculateAll(heroEntity)
	end
end

function Glyphs:ValidateGlyph(glyph, hero)
	local internalName = HerosCustom:GetInternalHeroNameMain(hero:GetUnitName())
	local glyphName = glyph:GetAbilityName()
	if string.match(glyphName, internalName) or string.match(glyphName, "neutral") then
		return true
	else
		return false
	end
end

if not Glyphs.GLYPH_MODIFIER_TABLE then
	Glyphs.GLYPH_MODIFIER_TABLE = {}
end

function Glyphs:CreateGlyphModifierTable()
	if #Glyphs.GLYPH_MODIFIER_TABLE < 1 then
		local heroTable = HerosCustom:GetHeroNameTable()
		for i = 1, #heroTable, 1 do
			for tier = 1, 7, 1 do
				for number = 1, 3, 1 do
					table.insert(Glyphs.GLYPH_MODIFIER_TABLE, "modifier_"..heroTable[i] .. "_glyph_"..tier.."_"..number)
				end
			end
			table.insert(Glyphs.GLYPH_MODIFIER_TABLE, "modifier_"..heroTable[i] .. "_glyph_" .. "5" .. "_" .. "a")
		end
	end
end

function Glyphs:RollRandomGlyph(position)
	local tier = Glyphs:RollRandomTier()
	local heroName = Glyphs:GetRandomHeroname()
	local rowItem = Glyphs:GetAvailableColumnCount(heroName)
	if heroName == "neutral" then
		rowItem = RandomInt(1, 3)
	end
	local glyphName = "item_rpc_"..heroName.."_glyph_"..tier.."_"..rowItem
	Glyphs:RollGlyphAll(glyphName, position, 0)
end

function Glyphs:RollRandomGlyphName()
	local tier = Glyphs:RollRandomTier()
	local heroName = Glyphs:GetRandomHeroname()
	local rowItem = Glyphs:GetAvailableColumnCount(heroName)
	if heroName == "neutral" then
		rowItem = RandomInt(1, 3)
	end
	local glyphName = "item_rpc_"..heroName.."_glyph_"..tier.."_"..rowItem
	return {glyphName, heroName}
end

function Glyphs:RollRandomGlyphBook(position)
	local tier = Glyphs:RollRandomTier()
	local column = 2
	local heroName = Glyphs:GetRandomHeronameForBook()
	-- local bookName = "item_rpc_"..heroName.."_glyph_"..tier.."_"..column
	Glyphs:RollGlyphBook(position, heroName, tier, column)
end

function Glyphs:RollRandomTier()
	local difficulty = GameState:GetDifficultyFactor()
	local rollIncreaser = 0
	local tier = 1
	if difficulty == 2 then
		rollIncreaser = 25
	elseif difficulty == 3 then
		rollIncreaser = 35
	end
	local luck = RandomInt(1, 100 + rollIncreaser)
	if luck <= 50 then
		tier = 1
	elseif luck <= 80 then
		tier = 2
	elseif luck <= 100 then
		tier = 3
	elseif luck <= 115 then
		tier = 4
	elseif luck <= 125 then
		tier = 5
	elseif luck <= 130 then
		tier = 6
	elseif luck <= 135 then
		tier = 7
	end
	return tier
end

function Glyphs:GetRandomHeroname()
	local heroNameTable = HerosCustom:GetHeroNameTable()
	local luck = RandomInt(1, #heroNameTable + 2)
	local heroname = "neutral"
	if luck <= #heroNameTable then
		heroname = heroNameTable[luck]
	end
	return heroname
end

function Glyphs:GetRandomHeronameForBook()
	local heroNameTable = {"sorceress", "axe", "trapper", "duskbringer", "venomort", "paladin"}
	local random = RandomInt(1, #heroNameTable)
	return heroNameTable[random]
end

function Glyphs:RemoveGlyphBonusesAndRecalculateAll(heroEntity)
	local MAX_GLYPHS = 3
	for i = 1, #Glyphs.GLYPH_MODIFIER_TABLE, 1 do
		heroEntity:RemoveModifierByName(Glyphs.GLYPH_MODIFIER_TABLE[i])
		--print(Glyphs.GLYPH_MODIFIER_TABLE[i])
	end
	for j = 1, MAX_GLYPHS, 1 do
		local glyph = CustomNetTables:GetTableValue("skill_tree", tostring(heroEntity:GetPlayerOwnerID()) .. "-glyph-"..tostring(j))
		if glyph.glyphIndex > 0 then
			glyph = EntIndexToHScript(glyph.glyphIndex)
			local glyphModifierName = glyph.newItemTable.property1
			glyph:ApplyDataDrivenModifier(heroEntity.glyphUnit, heroEntity, glyphModifierName, {})
		end
	end
end

function Glyphs:OpenGlyphShop(playerId)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "open_glyph_shop", {})
end

function Glyphs:UpgradeArcaneTier(msg)
	local playerID = msg.playerID
	local currentTier = CustomNetTables:GetTableValue("player_stats", tostring(playerID) .. "-enchanter").tier
	local cost = Glyphs:GetArcaneUpgradeCost(currentTier)
	local currentCrystals = CustomNetTables:GetTableValue("player_stats", tostring(playerID) .. "-resources").arcane
	if currentCrystals >= cost then
		local newTier = math.min(currentTier + 1, 7)
		local steamID = PlayerResource:GetSteamAccountID(playerID)
		local player = PlayerResource:GetPlayer(playerID)
		local url = ROSHPIT_URL.."/champions/upgradeEnchanter?"
		url = url.."steam_id="..steamID
		url = url.."&newTier="..newTier
		url = url.."&cost="..cost
		url = url.."&key1="..GetDedicatedServerKeyV2(SaveLoad.KeyVersion)
		CreateHTTPRequestScriptVM("POST", url):Send(function(result)
			--SaveLoad:NewKey()
			local resultTable = {}
			--print( "GET response:\n" )
			for k, v in pairs(result) do
				--print( string.format( "%s : %s\n", k, v ) )
			end
			--print( "Done." )
			local resultTable = JSON:decode(result.Body)
			-- resultTable = Quests:GetQuestDataFromJSON(resultTable)
			local arcaneCrystals = resultTable.arcane_crystals
			local enchanterTier = resultTable.glyph_enchanter_tier
			CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-resources", {arcane = arcaneCrystals})
			CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-enchanter", {tier = enchanterTier})
			CustomGameEventManager:Send_ServerToPlayer(player, "update_resources", {arcane_crystals = arcaneCrystals, enchanter_tier = enchanterTier, player = playerID})
			CustomAbilities:QuickAttachParticle("particles/generic_hero_status/hero_levelup.vpcf", Events.GlyphEnchanter, 2)
			EmitSoundOn("General.LevelUp", Events.GlyphEnchanter)
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "reopen_glyph_shop", {})
		end)
	end
end

function Glyphs:GetArcaneUpgradeCost(tier)
	local upgradeCost = 0
	if tier == 0 then
		upgradeCost = 100
	elseif tier == 1 then
		upgradeCost = 500
	elseif tier == 2 then
		upgradeCost = 5000
	elseif tier == 3 then
		upgradeCost = 10000
	elseif tier == 4 then
		upgradeCost = 50000
	elseif tier == 5 then
		upgradeCost = 100000
	elseif tier == 6 then
		upgradeCost = 500000
	end
	return upgradeCost
end

function Glyphs:UpdateResourceUI(resultTable, playerID)
	local arcaneCrystals = resultTable.arcane_crystals
	local enchanterTier = resultTable.glyph_enchanter_tier
	CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-resources", {arcane = arcaneCrystals})
	CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-enchanter", {tier = enchanterTier})
	CustomGameEventManager:Send_ServerToPlayer(player, "update_resources", {arcane_crystals = arcaneCrystals, enchanter_tier = enchanterTier, player = playerID})
end

--INDIVIDUAL GLYPHS--

function Glyphs:GlyphRecreation(variantName, rarityName, itemNameText, slotText, useDescription, position, requiredHero, minLevel, propertyName, heroIndex)
	local item = Glyphs:CreateGlyphItem(variantName, rarityName, itemNameText, slotText, useDescription, position, requiredHero, minLevel, propertyName, heroIndex)
	return item
	--follow up with ApplyGlyph to equip it
end

function Glyphs:GlyphPurchase(msg)
	local hero = EntIndexToHScript(msg.heroIndex)
	local tier = tonumber(msg.tier)
	local column = tonumber(msg.column)
	local glyphName = msg.glyphName
	local cost = Glyphs:GetGlyphCostByTier(tier, column, msg.glyphHero)
	local crystalReduce = cost *- 1
	local glyphHero = HerosCustom:GetInternalHeroName(msg.glyphHero)
	if hero.glyphRecipes[glyphHero] then
		if column == 2 then
			if hero.glyphRecipes[glyphHero][2][tier] == 0 then
				Notifications:Top(hero:GetPlayerOwnerID(), {text = "Not Learned", duration = 3, style = {color = "red"}, continue = true})
				return false
			end
		end
	end
	local playerID = hero:GetPlayerOwnerID()
	local currentCrystals = CustomNetTables:GetTableValue("player_stats", tostring(playerID) .. "-resources").arcane
	if currentCrystals >= cost then
		EmitSoundOn("Glyphs.Purchase", caster)
		local steamID = PlayerResource:GetSteamAccountID(playerID)
		local player = PlayerResource:GetPlayer(playerID)
		local url = ROSHPIT_URL.."/champions/modifyArcaneCrystals?"
		url = url.."steam_id="..steamID
		url = url.."&amount="..crystalReduce
		url = url.."&key1="..GetDedicatedServerKeyV2(SaveLoad.KeyVersion)
		CreateHTTPRequestScriptVM("POST", url):Send(function(result)
			--SaveLoad:NewKey()
			local resultTable = {}
			--print( "GET response:\n" )
			for k, v in pairs(result) do
				--print( string.format( "%s : %s\n", k, v ) )
			end
			--print( "Done." )
			local resultTable = JSON:decode(result.Body)
			-- resultTable = Quests:GetQuestDataFromJSON(resultTable)
			local arcaneCrystals = resultTable.arcane_crystals
			local enchanterTier = resultTable.glyph_enchanter_tier
			CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-resources", {arcane = arcaneCrystals})
			CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-enchanter", {tier = enchanterTier})
			CustomGameEventManager:Send_ServerToPlayer(player, "update_resources", {arcane_crystals = arcaneCrystals, enchanter_tier = enchanterTier, player = playerID})
			Glyphs:RollGlyphAll(glyphName, Vector(0, 0), msg.heroIndex)
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "reopen_glyph_shop", {})
			Events:TutorialServerEvent(hero, "3_4", 0)
			Statistics.dispatch("crystals:change", {playerID = playerID});
		end)
	end

	--print("spend "..cost.." crystals to buy "..glyphName)
end

function Glyphs:GetGlyphCostByTier(tier, column, heroName)
	local cost = 0
	if tier == 1 then
		cost = 200
	elseif tier == 2 then
		cost = 500
	elseif tier == 3 then
		cost = 1000
	elseif tier == 4 then
		cost = 2000
	elseif tier == 5 then
		cost = 5000
	elseif tier == 6 then
		cost = 10000
	elseif tier == 7 then
		cost = 25000
	end
	if column == 2 then
		if heroName == "tooltip_neutral" then
		else
			cost = cost * 5
		end
	end
	return cost
end

function Glyphs:RollGlyphAll(variantName, position, heroIndex)
	local nameLength = string.len(variantName)
	--print(string.sub(variantName, nameLength-2, nameLength-2))
	local tier = tonumber(string.sub(variantName, nameLength - 2, nameLength - 2))
	--print(tier)
	local index = string.sub(variantName, nameLength, nameLength)
	local rarityName = Glyphs:GetRarityFromGlyphTier(tier, index)
	--print(rarityName)
	local itemName = "Basic Glyph"
	local slotText = "Glyph"
	local useDescription = variantName.."_description"
	local minLevel = tier * 15
	local rpcName = variantName:gsub("item_rpc_", "")
	rpcName = rpcName:gsub(string.sub(rpcName, string.len(rpcName) - 9), "")
	--print(rpcName)
	local tooltipName = HerosCustom:ConvertRPCNameToStringHeroName(rpcName)
	local modifierName = variantName:gsub("item_rpc", "modifier")
	--print(modifierName)

	local glyph = Glyphs:CreateGlyphItem(variantName, rarityName, nil, slotText, useDescription, position, tooltipName, minLevel, modifierName, heroIndex)
	RPCItems:ItemUpdateCustomNetTables(glyph)
	return glyph
end

function Glyphs:GetRarityFromGlyphTier(tier, index)
	local rarity = "common"
	if tier <= 2 then
		rarity = "uncommon"
	elseif tier <= 4 then
		rarity = "rare"
	else
		rarity = "mythical"
	end
	if index == "a" then
		rarity = "immortal"
	end
	return rarity
end

function Glyphs:ReanimationPurchase(msg)
	local playerID = msg.playerID
	local currentCrystals = CustomNetTables:GetTableValue("player_stats", tostring(playerID) .. "-resources").arcane
	if currentCrystals >= 30000 then

		local steamID = PlayerResource:GetSteamAccountID(playerID)
		local player = PlayerResource:GetPlayer(playerID)
		local hero = player:GetAssignedHero()
		EmitSoundOn("Glyphs.Purchase", hero)
		local url = ROSHPIT_URL.."/champions/modifyArcaneCrystals?"
		url = url.."steam_id="..steamID
		url = url.."&amount=" .. -30000
		url = url.."&key1="..GetDedicatedServerKeyV2(SaveLoad.KeyVersion)
		CreateHTTPRequestScriptVM("POST", url):Send(function(result)
			--SaveLoad:NewKey()
			local resultTable = {}
			--print( "GET response:\n" )
			for k, v in pairs(result) do
				--print( string.format( "%s : %s\n", k, v ) )
			end
			--print( "Done." )
			local resultTable = JSON:decode(result.Body)
			-- resultTable = Quests:GetQuestDataFromJSON(resultTable)
			local arcaneCrystals = resultTable.arcane_crystals
			local enchanterTier = resultTable.glyph_enchanter_tier
			CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-resources", {arcane = arcaneCrystals})
			CustomNetTables:SetTableValue("player_stats", tostring(playerID) .. "-enchanter", {tier = enchanterTier})
			CustomGameEventManager:Send_ServerToPlayer(player, "update_resources", {arcane_crystals = arcaneCrystals, enchanter_tier = enchanterTier, player = playerID})
			RPCItems:GiveReanimationStoneToHero(hero)
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "reopen_glyph_shop", {})

			Statistics.dispatch("crystals:change", {playerID = playerID});
		end)
	end
end

function Glyphs:RollArchivistT5Glyph(position)
	local heroTable = HerosCustom:GetHeroNameTable()
	local heroName = heroTable[RandomInt(2, #heroTable)]
	local variantName = "item_rpc_"..heroName.."_glyph_5_a"
	Glyphs:RollGlyphAll(variantName, position, 0)
end

function Glyphs:DebugRollHeroGlyphs(heroName, position)
	local maxTiers = Glyphs:GetAvailableColumnCount(heroName)
	for j = 1, maxTiers, 1 do
		for i = 1, 7, 1 do
			local variantName = "item_rpc_"..heroName.."_glyph_"..i.."_"..j
			Glyphs:RollGlyphAll(variantName, position, 0)
		end
	end

	local variantName = "item_rpc_"..heroName.."_glyph_5_a"
	Glyphs:RollGlyphAll(variantName, position, 0)
end

function Glyphs:DebugArchivistGlyph(position)
	local heroTable = HerosCustom:GetHeroNameTable()
	for i = 2, #heroTable, 1 do
		local heroName = heroTable[i]
		--print(heroname)
		local variantName = "item_rpc_"..heroName.."_glyph_5_a"
		Glyphs:RollGlyphAll(variantName, position, 0)
	end
end

function Glyphs:GetGlyphAvailability(msg)
	local playerID = msg.playerID
	local heroName = msg.hero
	local rpcHeroName = HerosCustom:GetInternalHeroNameMain(heroName)
	if msg.hero == "tooltip_neutral" then
		rpcHeroName = "neutral"
	end
	local steamID = PlayerResource:GetSteamAccountID(playerID)
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()
	if not hero.glyphLoader then
		hero.glyphLoader = 0
	end
	hero.glyphLoader = hero.glyphLoader + 1
	local glyphCheck = hero.glyphLoader
	local url = ROSHPIT_URL.."/champions/getGlyphRecipes?"
	url = url.."steam_id="..steamID
	url = url.."&hero="..heroName
	CreateHTTPRequestScriptVM("GET", url):Send(function(result)
		local resultTable = {}
		--print( "GET response:\n" )
		for k, v in pairs(result) do
			--print( string.format( "%s : %s\n", k, v ) )
		end
		--print( "Done." )
		local resultTable = JSON:decode(result.Body)
		-- resultTable = Quests:GetQuestDataFromJSON(resultTable)
		--print(resultTable)
		local recipeResults = Glyphs:FormatRecipeResults(resultTable)
		--DeepPrintTable(recipeResults)
		if not hero.glyphRecipes then
			hero.glyphRecipes = {}
		end
		if hero.loadedGlyphDisplay then
			for i = 1, #hero.loadedGlyphDisplay, 1 do
				UTIL_Remove(hero.loadedGlyphDisplay[i])
			end
		end
		local columnsToLoad = Glyphs:GetAvailableColumnCount(rpcHeroName)
		hero.loadedGlyphDisplay = {}
		local totalDelay = 0.1
		for i = 1, 7, 1 do
			for j = 1, columnsToLoad, 1 do
				totalDelay = totalDelay + 0.1
				Timers:CreateTimer(0.03, function()
					local glyphName = "item_rpc_"..rpcHeroName.."_glyph_"..i.."_"..j
					local tempGlyph = Glyphs:RollGlyphAll(glyphName, hero:GetAbsOrigin(), -1)
					hero.loadedGlyphDisplay[i.."_"..j] = tempGlyph:GetEntityIndex()
				end)
			end
		end
		hero.glyphRecipes[rpcHeroName] = recipeResults
		Timers:CreateTimer(totalDelay, function()
			if hero.glyphLoader == glyphCheck then
				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "glyph_recipes_loaded", {heroName = heroName, data = recipeResults, glyphDisplay = hero.loadedGlyphDisplay})
			end
		end)
		--DeepPrintTable(hero.glyphRecipes)
	end)
end

function Glyphs:FormatRecipeResults(resultTable)
	if not resultTable then
		return {}
	end
	--DeepPrintTable(resultTable)
	if next(resultTable) == nil then
		return {}
	end
	recipeResults = {}
	recipeResults[1] = nil
	recipeResults[2] = {}
	for i = 1, 7, 1 do
		recipeResults[2][i] = resultTable[1]["t"..i.."_2"]
	end

	return recipeResults
end

function Glyphs:GetAvailableColumnCount(rpcHeroName)
	local columns = 1
	if rpcHeroName == "neutral" then
		columns = 3
	elseif rpcHeroName == "sorceress" or rpcHeroName == "axe" or rpcHeroName == "trapper" or rpcHeroName == "duskbringer" or rpcHeroName == "venomort" or rpcHeroName == "paladin" then
		columns = 2
	end
	return columns
end

function Glyphs:RollGlyphBook(deathLocation, class, row, column)
	local rarityName = Glyphs:GetRarityFromGlyphTier(row, column)
	local item = RPCItems:CreateConsumable("item_rpc_"..class.."_glyph_book", rarityName, "glyph_book", "glyph_book", false, "Consumable", "DOTA_Tooltip_ability_glyph_book_desc")
	item.newItemTable.glyphBook = true
	item.newItemTable.property1 = row
	item.newItemTable.property1name = "row"
	RPCItems:SetPropertyValues(item, item.newItemTable.property1, "item_row", "#99FF66", 1)

	item.newItemTable.property2 = column
	item.newItemTable.property2name = "column"
	RPCItems:SetPropertyValues(item, item.newItemTable.property2, "item_column", "#99FF66", 2)

	local glyphName = "DOTA_Tooltip_ability_item_rpc_"..class.."_glyph_"..row.."_"..column
	item.newItemTable.property3 = 0
	item.newItemTable.property3name = glyphName
	RPCItems:SetPropertyValues(item, 0, glyphName, "#D378ED", 3)

	item.newItemTable.property4 = 0
	item.newItemTable.property4name = ""
	RPCItems:SetPropertyValues(item, 0, "", "#FFFFFF", 4)
	local drop = CreateItemOnPositionSync(deathLocation, item)
	local position = deathLocation
	RPCItems:DropItem(item, position)
end

function Glyphs:CreateGlyphBook(itemName, row, column)
	local class = string.gsub(itemName, "item_rpc_", "")
	class = string.gsub(class, "_glyph_book", "")
	local rarityName = Glyphs:GetRarityFromGlyphTier(row, column)
	local item = RPCItems:CreateConsumable(itemName, rarityName, "glyph_book", "glyph_book", false, "Consumable", "DOTA_Tooltip_ability_glyph_book_desc")
	item.newItemTable.glyphBook = true
	item.newItemTable.property1 = row
	item.newItemTable.property1name = "row"
	RPCItems:SetPropertyValues(item, item.newItemTable.property1, "item_row", "#99FF66", 1)

	item.newItemTable.property2 = column
	item.newItemTable.property2name = "column"
	RPCItems:SetPropertyValues(item, item.newItemTable.property2, "item_column", "#99FF66", 2)

	local glyphName = "DOTA_Tooltip_ability_item_rpc_"..class.."_glyph_"..row.."_"..column
	item.newItemTable.property3 = 0
	item.newItemTable.property3name = glyphName
	RPCItems:SetPropertyValues(item, 0, glyphName, "#D378ED", 3)

	item.newItemTable.property4 = 0
	item.newItemTable.property4name = ""
	RPCItems:SetPropertyValues(item, 0, "", "#FFFFFF", 4)

	RPCItems:ItemUpdateCustomNetTables(item)
	return item
end
