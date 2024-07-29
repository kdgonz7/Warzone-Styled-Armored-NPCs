-- Armored NPCs
-- by Kai D. Gonzalez

--[[
	Allows NPCs to have armor, similar to players, and games like Call of Duty have.
]]

-- precahce sounds
Sound("mw_carmor/bullet_small_flesh_helmet.wav")
Sound("mw_carmor/bullet_impact_helmet_shatter_01.wav")

local Sounds = {
	["BulletFleshHelmet01"] = function ()
		local snd = "mw_carmor/bullet_small_flesh_helmet.wav"
		return snd
	end,
	["BulletArmorHit01"] = function ()
		local snd = { "mw_carmor/bullet_impact_helmet_shatter_01.wav", "mw_carmor/bullet_impact_helmet_shatter_02.wav", "mw_carmor/bullet_impact_helmet_shatter_03.wav" }

		return snd[math.random(1, 3)]
	end,
}

--[[ 
	Should this system be enabled?
]]
local Enabled = CreateConVar("gk_armor_enabled", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Enable the damage system.")

--[[ 
	The type of protection. nodmg is more like blast protection, 
	while deplete is similar to the half life 2 damage system.
]]
local ProtType = CreateConVar("gk_protection_type", "nodmg", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "How should the damage be applied? nodmg - Take no damage until there's no armor, deplete - Take slightly less damage")

--[[ 
	Should the mod send messages (print to console) when damage calculations are made? 
]]
local SendMessages = CreateConVar("gk_send_messages", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Notify the server when damage is taken. (for devs)")

--[[ 
	How much harder should it be to kill the super soldier/super NPCs? 
	scales the damage by this percentage. default is 70%. Probably 
	shouldn't be touched.
]]
local SuperSoldierModifier = CreateConVar("gk_super_soldier_modifier", 0.7, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "How much armor should super NPCs have compared to normal ones?")


-- Included NPCs
local IncludedNPCs = {
	["npc_combine_s"] = true,
	["npc_citizen"] = true
}
-- NPCs with more armor than the average.
local SuperModels = {
	["models/combine_super_soldier.mdl"] = true,
}

-- The amount of armor NPCs should have.
local RegularArmorAmount = 235

-- scales the damage by the type that is in the settings.
-- nodmg - take 0 damage
-- deplete - take slightly less damage
local function ScaleByType(dmg)
	if ProtType:GetString() == "nodmg" then
		return 0	-- we take no damage :)
	elseif ProtType:GetString() == "deplete" then
		return 0.5	-- we take slightly less damage
	else
		return 1
	end
end

hook.Add("Initialize", "ManageSettings", function()
	sql.Begin()

	local js = sql.Query("SELECT json FROM armored_npcs_settings")

	if js and js[1] then
		local tbl = util.JSONToTable(js[1]["json"])

		if tbl then
			Enabled:SetBool(tbl.enabled)
			ProtType:SetString(tbl.type)
			SendMessages:SetBool(tbl.messages)
			SuperSoldierModifier:SetFloat(tbl.soldier)
			RegularArmorAmount = tbl.armor
		end
	end

	sql.Commit()
end)

-- hook onto entity create to add the networked armor
hook.Add("OnEntityCreated", "ManageNPCArmor", function(ent)
	if ! IsValid(ent) then return end
	if ! Enabled:GetBool() then return end

	-- if the entity is an NPC
	if ent:IsNPC() then
		if ! IncludedNPCs[ent:GetClass()] then
			return
		end

		-- we set the armor
		ent:SetNWInt("Armor", (function()
			-- note: add any extra logic here (for developers)

			if SendMessages:GetBool() then
				print("[Armored NPCs] Added " .. RegularArmorAmount .. " armor to " .. ent:GetClass())
			end

			return RegularArmorAmount
		end)())
	end
end)

-- to scale the NPC damage by the armor
hook.Add("ScaleNPCDamage", "ManageNPCDamage", function(ent, hitgroup, dmginfo)
	if ! IsValid(ent) then return end
	if ! Enabled:GetBool() then return end
	if ! ent:GetNWInt("Armor") then return end

	if ent:GetNWInt("Armor") - dmginfo:GetDamage() <= 0 and IncludedNPCs[ent:GetClass()] and ent:GetNWInt("Armor") == RegularArmorAmount then
		-- kill the NPC
		ent:Fire("Kill", "", 0)
		if SendMessages:GetBool() then
			print("[Armored NPCs] Killed " .. ent:GetClass())
		end
		return
	end

	local NPCCurrentArmor = ent:GetNWInt("Armor")

	ent:SetNWInt("Armor", NPCCurrentArmor - (dmginfo:GetDamage() * (function () if SuperModels[ent:GetModel()] then return SuperSoldierModifier:GetFloat() else return 1 end end)()))

	-- if the NPC has no more armor, 
	-- play the configured sound effect.
	if NPCCurrentArmor <= 0 then
		ent:EmitSound(Sounds["BulletFleshHelmet01"]())
		ent:SetNWInt("Armor", 0)

		return 1
	end

	-- scale the damage by the type
	dmginfo:ScaleDamage(ScaleByType(dmginfo:GetDamage()))

	-- add x2 damage to headshots
	if hitgroup == HITGROUP_HEAD then
		dmginfo:ScaleDamage(2)
	end

	-- we're most likely fine at this stage, so play a hit sound
	ent:EmitSound(Sounds["BulletArmorHit01"]())

	return 1
end)

hook.Add("ShutDown", "ManageSettings", function()
	local settingJSON = util.TableToJSON({
		enabled = Enabled:GetBool(),
		type = ProtType:GetString(),
		messages = SendMessages:GetBool(),
		soldier = SuperSoldierModifier:GetFloat(),
		armor = RegularArmorAmount
	})

	sql.Begin()

	sql.Query("DROP TABLE IF EXISTS armored_npcs_settings")
	sql.Query("CREATE TABLE IF NOT EXISTS armored_npcs_settings (json TEXT)")
	sql.Query("INSERT INTO armored_npcs_settings VALUES ('" .. sql.SQLStr(settingJSON, true) .. "')")

	sql.Commit()
end)
