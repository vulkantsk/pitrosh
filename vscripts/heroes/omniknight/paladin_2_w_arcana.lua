LinkLuaModifier("modifier_paladin_penance_attack_lua", "modifiers/paladin/modifier_paladin_penance_attack", LUA_MODIFIER_MOTION_NONE)

function penance_start(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local source = event.source
	local castArgs = false
	if not event.source then
		castArgs = true
		source = caster
	end
	if ability:GetAbilityName() == "paladin_penance" then
		ability.w_4_level = caster:GetRuneValue("w", 4)
		dummyAbility = caster.InventoryUnit:AddAbility("paladin_penance_dummy")
		dummyAbility.creationTime = GameRules:GetGameTime()
		--print("-----")
		--print(dummyAbility.creationTime)
		if not dummyAbility then
			local remove = caster.InventoryUnit:FindAbilityByName("paladin_penance_dummy")
			UTIL_Remove(remove)
			dummyAbility = caster.InventoryUnit:AddAbility("paladin_penance_dummy")
		end
		if not ability.projectileCount then
			ability.projectileCount = 0
		end
		--print(ability.projectileCount)
		penance_dummy_checker(caster, ability)
		if ability.projectileCount >= 10 then
			ability:SetActivated(false)
		end
		--print(ability.projectileCount)
		dummyAbility:SetLevel(ability:GetLevel())
		dummyAbility.penanceProcs = Runes:Procs(ability.w_4_level, 10, 1)
	else
		dummyAbility = ability
		dummyAbility.creationTime = GameRules:GetGameTime()
		caster = caster.hero
		ability = caster:FindAbilityByName("paladin_penance")
	end
	local extraData = {1}
	local info =
	{
		Target = target,
		Source = source,
		Ability = dummyAbility,
		EffectName = "particles/roshpit/paladin/penance.vpcf",
		StartPosition = "attach_attack2",
		bDrawsOnMinimap = false,
		bDodgeable = true,
		bIsAttack = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		flExpireTime = GameRules:GetGameTime() + 4,
		bProvidesVision = true,
		iVisionRadius = 0,
		iMoveSpeed = 1300,
	iVisionTeamNumber = caster:GetTeamNumber()}
	projectile = ProjectileManager:CreateTrackingProjectile(info)
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin() + RandomVector(RandomInt(1, 400)), "Paladin.PenanceLaunch", caster)
	--print(ability.projectileCount)
	ability.w_1_level = caster:GetRuneValue("w", 1)
	ability.w_2_level = caster:GetRuneValue("w", 2)
	ability.w_3_level = caster:GetRuneValue("w", 3)

	if ability.w_1_level > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_paladin_a_b_damage_growth_visible", {duration = 4})
		local newStacks = caster:GetModifierStackCount("modifier_paladin_a_b_damage_growth_visible", caster) + 1
		-- caster:SetModifierStackCount("modifier_paladin_a_b_damage_growth_visible", caster, newStacks)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_paladin_a_b_damage_growth_invisible", {duration = 4})
		caster:SetModifierStackCount("modifier_paladin_a_b_damage_growth_invisible", caster, ability.w_1_level)
	end
	if castArgs then
		if ability:GetAbilityName() == "paladin_penance" then
			Filters:CastSkillArguments(2, caster)
		end
	end
	if caster:HasModifier("modifier_paladin_glyph_4_2") then
		Timers:CreateTimer(0.03, function()
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_glyph_4_2_push", {duration = 0.5})
		end)
	end
end

function passive_think(event)
	local caster = event.caster
	local ability = event.ability

	ability.w_3_level = caster:GetRuneValue("w", 3)
	if ability.w_3_level > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_paladin_c_b_armor", {})
		caster:SetModifierStackCount("modifier_paladin_c_b_armor", caster, ability.w_3_level)
	else
		caster:RemoveModifierByName("modifier_paladin_c_b_armor")
	end
	if not ability.w_4_level then
		ability.w_4_level = caster:GetRuneValue("w", 4)
	end
	if ability.w_4_level > 0 then
		local stacks = caster:GetPhysicalArmorValue(false) * ability.w_4_level * 1.0
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_paladin_arcana_armor", {})
		caster:SetModifierStackCount("modifier_paladin_arcana_armor", caster, stacks)
	else
		if caster:HasModifier("modifier_paladin_arcana_armor") then
			caster:RemoveModifierByName("modifier_paladin_arcana_armor")
		end
	end
	penance_dummy_checker(caster, ability)
end

function penance_dummy_checker(caster, ability)
	if caster.InventoryUnit:HasAbility("paladin_penance_dummy") then
		local penanceCount = 0
		for i = 0, 23, 1 do
			local dummyPenance = caster.InventoryUnit:GetAbilityByIndex(i)
			if dummyPenance then
				if dummyPenance:GetAbilityName() == "paladin_penance_dummy" then
					penanceCount = penanceCount + 1
					if dummyPenance.creationTime then
						if dummyPenance.creationTime < GameRules:GetGameTime() - 6 then
							UTIL_Remove(dummyPenance)
							penanceCount = penanceCount - 1
							ability:SetActivated(true)
						end
					else
						UTIL_Remove(dummyPenance)
						penanceCount = penanceCount - 1
						ability:SetActivated(true)
					end
				end
			end
		end
		--print("---P---")
		ability.projectileCount = penanceCount
		set_penance_projectiles(ability, caster)
		--print(penanceCount)

	end
end

function set_penance_projectiles(ability, caster)

	if ability.projectileCount > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_penance_projectiles", {})
		--print(ability.projectileCount)
		caster:SetModifierStackCount("modifier_penance_projectiles", caster, ability.projectileCount)
	else
		caster:RemoveModifierByName("modifier_penance_projectiles")
	end
end

function penance_impact(event)
	local caster = event.caster
	local origCaster = caster
	local ability = event.ability
	local dummyAbility = nil
	if ability:GetAbilityName() == "paladin_penance_dummy" then
		dummyAbility = ability
		caster = caster.hero
		ability = caster:FindAbilityByName("paladin_penance")
	end
	local target = event.target
	EmitSoundOn("Paladin.PenanceImpact", target)
	local radius = 300
	local particleName = "particles/roshpit/paladin/penance_impact.vpcf"
	local pfx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(pfx, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControl(pfx, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(radius - 100, 1, radius - 100))

	Timers:CreateTimer(3, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)
	local damage = event.damage
	if ability.w_3_level > 0 then
		damage = damage + caster:GetPhysicalArmorValue(false) * 6 * ability.w_3_level
	end
	local heal_percent = event.heal_percentage
	if target:GetTeamNumber() == caster:GetTeamNumber() then
		local healAmount = damage * heal_percent / 100
		Filters:ApplyHeal(caster, target, healAmount, true)
		--ally effect
	else
		if ability.w_1_level > 0 then
			--print("ATTACK??")
			if not target.dummy then
				caster:AddNewModifier(caster, ability, "modifier_paladin_penance_attack_lua", {})
				caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
				Filters:PerformAttackSpecial(caster, target, true, true, true, false, false, false, false)
				Timers:CreateTimer(0.05, function()
					caster:RemoveModifierByName("modifier_paladin_penance_attack_lua")
					caster:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
				end)
			end
			-- (handle hTarget, bool bUseCastAttackOrb, bool bProcessProcs, bool bSkipCooldown, bool bIgnoreInvis, bool bUseProjectile, bool bFakeAttack, bool bNeverMiss)
		end
	end

	local newStacks = caster:GetModifierStackCount("modifier_paladin_a_b_damage_growth_visible", caster) - 1
	if newStacks == 0 then
		caster:RemoveModifierByName("modifier_paladin_a_b_damage_growth_visible")
		caster:RemoveModifierByName("modifier_paladin_a_b_damage_growth_invisible")
	else
		caster:SetModifierStackCount("modifier_paladin_a_b_damage_growth_visible", caster, newStacks)
	end

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	if #enemies > 0 then
		for _, enemy in pairs(enemies) do
			Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_W, RPC_ELEMENT_HOLY, RPC_ELEMENT_GHOST)
			ability:ApplyDataDrivenModifier(caster, enemy, "modifier_paladin_glyph_1_2_effect", {duration = 8})
		end
	end
	if ability.w_2_level > 0 then
		local luck = RandomInt(1, 4)
		luck = 1
		if luck == 1 then
			local radius = 550
			local damage = ability.w_2_level * 30 * caster:GetIntellect() + OverflowProtectedGetAverageTrueAttackDamage(caster) * 0.3 * ability.w_2_level
			damage = math.floor(damage)

			EmitSoundOn("Paladin.HolyNova", caster)
			local particleName = "particles/units/heroes/hero_elder_titan/paladin_holy_nova.vpcf"
			local position = caster:GetAbsOrigin()
			local particleVector = position

			local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(pfx, 0, particleVector)
			Timers:CreateTimer(1, function()
				ParticleManager:DestroyParticle(pfx, false)
			end)
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			if #enemies > 0 then
				for _, enemy in pairs(enemies) do
					Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_W, RPC_ELEMENT_HOLY, RPC_ELEMENT_NONE)
					if not enemy:HasModifier("modifeir_paladin_c_b_disarm_immunity") then
						ability:ApplyDataDrivenModifier(caster, enemy, "modifier_paladin_c_b_disarm", {duration = 1})
						ability:ApplyDataDrivenModifier(caster, enemy, "modifeir_paladin_c_b_disarm_immunity", {duration = 1.5})
					end
				end
			end
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			local heal = math.floor(damage / 10)
			if #allies > 0 then
				for _, ally in pairs(allies) do
					-- d_b_heal(caster, ally, ability, heal)
					CustomAbilities:QuickAttachParticle("particles/units/heroes/hero_oracle/holy_heal_heal.vpcf", ally, 3)
					Filters:ApplyHeal(caster, ally, heal, false)
				end
			end
		end
	end
	if dummyAbility then
		if dummyAbility.penanceProcs then
			if dummyAbility.penanceProcs > 0 then
				--print("BOUNCE?")
				local remove = true
				local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, 650, DOTA_UNIT_TARGET_TEAM_ENEMY + DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				if #enemies > 0 then
					for _, enemy in pairs(enemies) do
						if enemy:GetEntityIndex() == target:GetEntityIndex() then
						else
							dummyAbility.penanceProcs = dummyAbility.penanceProcs - 1
							local eventTable = {}
							eventTable.caster = origCaster
							eventTable.target = enemy
							eventTable.source = target
							eventTable.ability = dummyAbility
							penance_start(eventTable)
							remove = false
							break
						end
					end
					if remove then
						ability.projectileCount = ability.projectileCount - 1
						set_penance_projectiles(ability, caster)
						UTIL_Remove(dummyAbility)
						ability:SetActivated(true)
					end
				else
					ability.projectileCount = ability.projectileCount - 1
					set_penance_projectiles(ability, caster)
					UTIL_Remove(dummyAbility)
					ability:SetActivated(true)
				end
			else
				ability.projectileCount = ability.projectileCount - 1
				set_penance_projectiles(ability, caster)
				UTIL_Remove(dummyAbility)
				ability:SetActivated(true)
			end
		else
			ability.projectileCount = ability.projectileCount - 1
			set_penance_projectiles(ability, caster)
			UTIL_Remove(dummyAbility)
			ability:SetActivated(true)
		end
	else
		ability:SetActivated(true)
	end

end

function penance_die(event)
	event.ability:SetActivated(true)
end
