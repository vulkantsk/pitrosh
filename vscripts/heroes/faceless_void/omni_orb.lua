function omni_orb_charge_procced(event, basic_damage)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local mace_hit_data = omni_mace_basic_element_data(caster.active_element)
	local orb_ability = caster:FindAbilityByName("omniro_omni_orb")
	if caster.active_element == RPC_ELEMENT_NORMAL then
		local damage = orb_ability:GetSpecialValueFor("normal_orb_a") * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_NORMAL]["level"]
		local pfx = ParticleManager:CreateParticle("particles/roshpit/omniro/omniro_normal_orb.vpcf", PATTACH_ABSORIGIN, caster)
		-- local pull_direction = ((target:GetAbsOrigin() - caster:GetAbsOrigin())*Vector(1,1,0)):Normalized()
		ParticleManager:SetParticleControl(pfx, 0, target:GetAbsOrigin() + Vector(0, 0, 40))
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_NORMAL, RPC_ELEMENT_NONE)
			end
		end
		Timers:CreateTimer(0.5, function()
			ParticleManager:DestroyParticle(pfx, false)
		end)
		EmitSoundOn("Omniro.Orb.Normal", target)
	elseif caster.active_element == RPC_ELEMENT_FIRE then
		local damage = (orb_ability:GetSpecialValueFor("fire_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_FIRE]["level"]

		local particleName = "particles/units/heroes/hero_elder_titan/ring_of_fire.vpcf"
		local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		local origin = target:GetAbsOrigin()
		ParticleManager:SetParticleControl(particle1, 0, origin + Vector(0, 0, 50))
		for i = 1, 9, 1 do
			ParticleManager:SetParticleControl(particle1, i, Vector(440, 440, 440))
		end

		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, OMNIRO_ORB_FIRE_AOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_FIRE, RPC_ELEMENT_NONE)
			end
		end
		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(particle1, false)
		end)

		EmitSoundOn("Omniro.Orb.Fire", target)
	elseif caster.active_element == RPC_ELEMENT_EARTH then
		local damage = (orb_ability:GetSpecialValueFor("earth_orb_a")) * caster:GetStrength() * caster.omniro_data[RPC_ELEMENT_EARTH]["level"]
		local radius = OMNIRO_ORB_EARTH_AOE
		local position = target:GetAbsOrigin()
		local stun_duration = (orb_ability:GetSpecialValueFor("earth_orb_b")) * caster.omniro_data[RPC_ELEMENT_EARTH]["level"]
		local splitEarthParticle = "particles/units/heroes/hero_leshrac/leshrac_split_earth.vpcf"
		local pfx = ParticleManager:CreateParticle(splitEarthParticle, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(pfx, 0, position)
		ParticleManager:SetParticleControl(pfx, 1, Vector(radius, radius, radius))
		EmitSoundOn("Omniro.Orb.Earth", target)
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius + 5, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_EARTH, RPC_ELEMENT_NONE)
				Filters:ApplyStun(caster, stun_duration, enemy)
			end
		end
		Timers:CreateTimer(3.5, function()
			ParticleManager:DestroyParticle(pfx, false)
		end)
	elseif caster.active_element == RPC_ELEMENT_LIGHTNING then
		local damage = (orb_ability:GetSpecialValueFor("lightning_orb_a")) * caster:GetAgility() * caster.omniro_data[RPC_ELEMENT_LIGHTNING]["level"]

		local chain = {}
		chain.index_hit = 0
		chain.enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, OMNIRO_ORB_LIGHTNING_SEARCH_RADIUS, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		local targets_to_hit = OMNIRO_ORB_LIGHTNING_BASE_BOUNCES + caster.omniro_data[RPC_ELEMENT_LIGHTNING]["max_charges"]
		for i = 1, targets_to_hit, 1 do
			Timers:CreateTimer((i - 1) * 0.15, function()
				local enemy = chain.enemies[i]
				if IsValidEntity(enemy) and enemy:IsAlive() then
					EmitSoundOn("Omniro.Orb.Lightning", enemy)
					Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_LIGHTNING, RPC_ELEMENT_NONE)
					local particleName = "particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf"
					local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_CUSTOMORIGIN, nil)
					local attach_unit_1 = caster
					if i > 1 then
						attach_unit_1 = chain.enemies[i - 1]
					end
					ParticleManager:SetParticleControl(pfx, 0, attach_unit_1:GetAbsOrigin() + Vector(0, 0, attach_unit_1:GetBoundingMaxs().z + 80))
					ParticleManager:SetParticleControl(pfx, 1, enemy:GetAbsOrigin() + Vector(0, 0, enemy:GetBoundingMaxs().z + 100))
					Timers:CreateTimer(0.3, function()
						ParticleManager:DestroyParticle(pfx, false)
					end)
				end
			end)
		end
	elseif caster.active_element == RPC_ELEMENT_POISON then
		-- local damage = (orb_ability:GetSpecialValueFor("poison_orb_a")/100)*OverflowProtectedGetAverageTrueAttackDamage(caster)*caster.omniro_data[RPC_ELEMENT_POISON]["level"]
		local thinkerDuration = OMNIRO_ORB_POISON_POOL_DURATION
		local particleName = "particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf"
		CustomAbilities:QuickAttachThinker(orb_ability, caster, target:GetAbsOrigin(), "modifier_omniro_poison_orb_pool", {duration = thinkerDuration})
		StartSoundEvent("Omniro.Orb.Poison", target)
		Timers:CreateTimer(4, function()
			if target and IsValidEntity(target) then
				StopSoundEvent("Omniro.Orb.Poison", target)
			end
		end)
		local pfx = CustomAbilities:QuickParticleAtPoint("particles/units/heroes/hero_alchemist/alchemist_acid_spray.vpcf", target:GetAbsOrigin(), thinkerDuration)
		ParticleManager:SetParticleControl(pfx, 1, Vector(OMNIRO_ORB_POISON_POOL_RADIUS, OMNIRO_ORB_POISON_POOL_RADIUS, OMNIRO_ORB_POISON_POOL_RADIUS))
	elseif caster.active_element == RPC_ELEMENT_TIME then
		local debuff_duration = (orb_ability:GetSpecialValueFor("time_orb_b")) * caster.omniro_data[RPC_ELEMENT_TIME]["level"] + OMNIRO_TIME_ORB_BASE_DURATION
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, OMNIRO_ORB_TIME_AOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				CustomAbilities:QuickAttachParticle("particles/roshpit/omniro/timelock.vpcf", enemy, 3)
				orb_ability:ApplyDataDrivenModifier(caster, enemy, "modifier_omniro_time_freeze", {duration = debuff_duration})
			end
		end
		EmitSoundOn("Omniro.Orb.Time.Start", target)
	elseif caster.active_element == RPC_ELEMENT_HOLY then
		local damage = (orb_ability:GetSpecialValueFor("holy_orb_a")) * caster:GetIntellect() * caster.omniro_data[RPC_ELEMENT_HOLY]["level"] + (orb_ability:GetSpecialValueFor("holy_orb_b")) * caster:GetPhysicalArmorValue(false) * caster.omniro_data[RPC_ELEMENT_HOLY]["level"]
		EmitSoundOn("Omniro.Orb.Holy", caster)
		local radius = OMNIRO_ORB_HOLY_AOE
		local particleName = "particles/units/heroes/hero_elder_titan/paladin_holy_nova.vpcf"
		local position = caster:GetAbsOrigin()
		local particleVector = position + Vector(0, 0, 40)

		local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(pfx, 0, particleVector)
		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(pfx, false)
		end)
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_HOLY, RPC_ELEMENT_NONE)
			end
		end
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local heal = damage * (OMNIRO_ORB_HOLY_HEAL_PCT / 100)
		if #allies > 0 then
			for _, ally in pairs(allies) do
				Filters:ApplyHeal(caster, ally, heal, false)
			end
		end
	elseif caster.active_element == RPC_ELEMENT_COSMOS then
		local comet_damage = (orb_ability:GetSpecialValueFor("cosmic_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_COSMOS]["level"] + (orb_ability:GetSpecialValueFor("cosmic_orb_b")) * caster:GetMaxHealth() * caster.omniro_data[RPC_ELEMENT_COSMOS]["level"]
		local starParticle = "particles/roshpit/solunia/comet_moon_attack_attack.vpcf"
		local position = target:GetAbsOrigin()
		local pfx = CustomAbilities:QuickParticleAtPoint(starParticle, position, 3)
		EmitSoundOnLocationWithCaster(position, "Omniro.Orb.Cosmic.Start", caster)
		Timers:CreateTimer(0.45, function()
			local radius = OMNIRO_ORB_COSMIC_RADIUS
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			if #enemies > 0 then
				for _, enemy in pairs(enemies) do
					Filters:TakeArgumentsAndApplyDamage(enemy, caster, comet_damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_COSMOS, RPC_ELEMENT_NONE)
				end
			end
			CustomAbilities:QuickParticleAtPoint("particles/roshpit/omniro/cosmic_orb_impact.vpcf", position, 3)
			EmitSoundOnLocationWithCaster(position, "Omniro.Orb.Cosmic", caster)
		end)
	elseif caster.active_element == RPC_ELEMENT_ICE then
		local mace_ability = caster:FindAbilityByName("omniro_omni_mace")
		EmitSoundOn("Omniro.Orb.Ice", target)
		local duration = OMNIRO_ICE_SPECIAL_DURATION
		local icePoint = target:GetAbsOrigin()
		local radius = OMNIRO_ICE_ORB_BASE_RADIUS + orb_ability:GetSpecialValueFor("ice_orb_b") * caster.omniro_data[RPC_ELEMENT_ICE]["level"]
		local particle = "particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf"
		local pfx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, caster)

		local agi_mult = 1
		local str_mult = 1
		local int_mult = 1
		if caster:GetAgility() < caster:GetStrength() and caster:GetAgility() < caster:GetIntellect() then
			agi_mult = OMNIRO_ICE_LOWEST_ATTRIBUTE_MULT
		elseif caster:GetStrength() < caster:GetAgility() and caster:GetStrength() < caster:GetIntellect() then
			str_mult = OMNIRO_ICE_LOWEST_ATTRIBUTE_MULT
		elseif caster:GetIntellect() < caster:GetStrength() and caster:GetIntellect() < caster:GetAgility() then
			agi_mult = OMNIRO_ICE_LOWEST_ATTRIBUTE_MULT
		end
		local damage = (orb_ability:GetSpecialValueFor("ice_orb_a")) * (caster:GetIntellect() * int_mult + caster:GetStrength() * str_mult + caster:GetAgility() * agi_mult) * caster.omniro_data[RPC_ELEMENT_ICE]["level"]
		ParticleManager:SetParticleControl(pfx, 0, icePoint)
		ParticleManager:SetParticleControl(pfx, 1, Vector(radius, 2, radius * 2))
		Timers:CreateTimer(2.5, function()
			ParticleManager:DestroyParticle(pfx, false)
		end)
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), icePoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				mace_ability:ApplyDataDrivenModifier(caster, enemy, "modifier_ice_debuff", {duration = duration})
				enemy:SetModifierStackCount("modifier_ice_debuff", caster, caster.omniro_data[RPC_ELEMENT_ICE]["level"])
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_ICE, RPC_ELEMENT_NONE)
			end
		end
	elseif caster.active_element == RPC_ELEMENT_ARCANE then
		EmitSoundOn("Omniro.Orb.Arcane", caster)

		local debuff_duration = OMNIRO_ARCANE_ORB_MR_LOSS_DURATION
		local radius = OMNIRO_ARCANE_BASE_AOE + orb_ability:GetSpecialValueFor("arcane_orb_a") * caster.omniro_data[RPC_ELEMENT_ARCANE]["level"]
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		local pulses = OMNIRO_ARCANE_ORB_BASE_PULSES + caster.omniro_data[RPC_ELEMENT_ARCANE]["max_charges"]
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				orb_ability:ApplyDataDrivenModifier(caster, enemy, "modifier_arcane_orb_magic_resist", {duration = debuff_duration})
				enemy:SetModifierStackCount("modifier_arcane_orb_magic_resist", caster, caster.omniro_data[RPC_ELEMENT_ARCANE]["level"])
				for i = 1, pulses, 1 do
					Timers:CreateTimer((i - 1) * 0.5, function()
						if enemy and IsValidEntity(enemy) then
							local pfx = CustomAbilities:QuickAttachParticle("particles/roshpit/omniro/omni_mace.vpcf", enemy, 0.4)
							ParticleManager:SetParticleControl(pfx, 1, mace_hit_data["color"])
							Filters:TakeArgumentsAndApplyDamage(enemy, caster, basic_damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_ARCANE, RPC_ELEMENT_NONE)
							EmitSoundOn("Omniro.Orb.Arcane.Sub", enemy)
						end
					end)
				end

			end
		end
	elseif caster.active_element == RPC_ELEMENT_SHADOW then
		local mace_ability = caster:FindAbilityByName("omniro_omni_mace")
		EmitSoundOn("Omniro.Orb.Shadow", target)
		local damage = (orb_ability:GetSpecialValueFor("shadow_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_SHADOW]["level"]
		local shadowRadius = OMNIRO_SHADOW_ORB_BASE_AOE + orb_ability:GetSpecialValueFor("shadow_orb_b") * caster.omniro_data[RPC_ELEMENT_SHADOW]["level"]
		local duration = OMNIRO_SHADOW_SPECIAL_DURATION
		local origin = target:GetAbsOrigin()
		local particleName = "particles/roshpit/items/nightmare_rider_mantle_cowlofice.vpcf"
		local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl(particle1, 0, origin + Vector(0, 0, 20))
		ParticleManager:SetParticleControl(particle1, 1, Vector(shadowRadius, 2, shadowRadius))
		ParticleManager:SetParticleControl(particle1, 3, Vector(shadowRadius, shadowRadius, shadowRadius))
		Timers:CreateTimer(3, function()
			ParticleManager:DestroyParticle(particle1, false)
		end)
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, shadowRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				mace_ability:ApplyDataDrivenModifier(caster, enemy, "modifier_omniro_shadow_debuff", {duration = duration})
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_SHADOW, RPC_ELEMENT_NONE)
			end
		end
	elseif caster.active_element == RPC_ELEMENT_WIND then
		local fv = caster:GetForwardVector()
		local speed = 1300
		local rune_ability = caster.runeUnit3:FindAbilityByName("omniro_rune_e_3")
		local wind_range = OMNIRO_WIND_ORB_RANGE
		EmitSoundOn("Omniro.Orb.Wind", target)
		orb_ability.wind_orb_damage = (orb_ability:GetSpecialValueFor("wind_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_WIND]["level"] + (orb_ability:GetSpecialValueFor("wind_orb_b")) * caster:GetAgility() * caster.omniro_data[RPC_ELEMENT_WIND]["level"]
		for i = 1, 8, 1 do
			local wind_fv = WallPhysics:rotateVector(fv, 2 * math.pi * i / 8)
			local info =
			{
				Ability = rune_ability,
				EffectName = "particles/items/hurricane_vest_projectile.vpcf",
				vSpawnOrigin = target:GetAbsOrigin() + Vector(0, 0, 60),
				fDistance = wind_range,
				fStartRadius = 130,
				fEndRadius = 130,
				Source = caster,
				StartPosition = "attach_attack1",
				bHasFrontalCone = true,
				bReplaceExisting = false,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				fExpireTime = GameRules:GetGameTime() + 5.0,
				bDeleteOnHit = false,
				vVelocity = wind_fv * Vector(1, 1, 0) * speed,
				bProvidesVision = false,
			}
			projectile = ProjectileManager:CreateLinearProjectile(info)
		end
	elseif caster.active_element == RPC_ELEMENT_GHOST then
		local radius = OMNIRO_GHOST_ORB_AOE
		local duration = OMNIRO_GHOST_ORB_BASE_DURATION + (orb_ability:GetSpecialValueFor("ghost_orb_b")) * caster.omniro_data[RPC_ELEMENT_GHOST]["level"]
		local location = target:GetAbsOrigin()
		local dummy = CreateUnitByName("npc_dummy_unit", location, false, nil, nil, caster:GetTeamNumber())
		dummy:SetAbsOrigin(location)
		dummy:FindAbilityByName("dummy_unit"):SetLevel(1)
		dummy.hero = caster
		orb_ability:ApplyDataDrivenModifier(dummy, dummy, "modifier_ghost_orb_aura", {duration = duration})
		dummy.pfx = ParticleManager:CreateParticle("particles/roshpit/omniro/ghost_orb_cloud.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(dummy.pfx, 0, location + Vector(0, 0, 80))
		ParticleManager:SetParticleControl(dummy.pfx, 1, Vector(radius, radius, 200))
		EmitSoundOn("Omniro.Orb.Ghost", target)
	elseif caster.active_element == RPC_ELEMENT_WATER then
		local damage = (orb_ability:GetSpecialValueFor("water_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_WATER]["level"]
		local hydroPosition = target:GetAbsOrigin()
		hydroPosition = GetGroundPosition(hydroPosition, target)
		EmitSoundOnLocationWithCaster(hydroPosition, "Omniro.Orb.Water", caster)
		local pfx = ParticleManager:CreateParticle("particles/econ/items/kunkka/divine_anchor/hero_kunkka_dafx_skills/kunkka_spell_torrent_splash_fxset.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(pfx, 0, hydroPosition)
		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(pfx, false)
		end)
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), hydroPosition, nil, OMNIRO_WATER_ORB_AOE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				if not enemy.jumpLock then
					if enemy:GetAbsOrigin().z - GetGroundHeight(enemy:GetAbsOrigin(), enemy) < 500 then
						if not Filters:HasFlyingModifier(enemy) then
							if not enemy:IsMagicImmune() then
								orb_ability:ApplyDataDrivenModifier(caster, enemy, "modifier_torrent_stun", {duration = 4})
								orb_ability:ApplyDataDrivenModifier(caster, enemy, "modifier_torrent_lifting", {duration = OMNIRO_WATER_STUN_DURATION})
								enemy.torrentLiftVelocity = 19
							end
						end
					end
				end
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_WATER, RPC_ELEMENT_NONE)
			end
		end
	elseif caster.active_element == RPC_ELEMENT_DEMON then
		local damage = (orb_ability:GetSpecialValueFor("demon_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_DEMON]["level"]
		CustomAbilities:QuickAttachParticle("particles/roshpit/omniro/omniro_demon_orb.vpcf", target, 3)
		EmitSoundOn("Omniro.Orb.Demon", target)
		caster.ignore_steadfast = true
		Filters:TakeArgumentsAndApplyDamage(target, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_DEMON, RPC_ELEMENT_NONE)
	elseif caster.active_element == RPC_ELEMENT_NATURE then
		EmitSoundOn("Omniro.Orb.Nature", target)
		local max_shield_stacks = OMNIRO_NATURE_SHIELD_BASE_MAX_STACKS + orb_ability:GetSpecialValueFor("nature_orb_b") * caster.omniro_data[RPC_ELEMENT_NATURE]["level"]
		local current_stacks = caster:GetModifierStackCount("modifier_omniro_nature_shield", caster)
		local additional_stacks = Runes:Procs(caster.omniro_data[RPC_ELEMENT_NATURE]["level"], orb_ability:GetSpecialValueFor("nature_orb_a"), 1)
		--print(additional_stacks)
		local final_new_stacks = math.min(current_stacks + additional_stacks, max_shield_stacks)

		local shield_duration = Filters:GetAdjustedBuffDuration(caster, OMNIRO_NATURE_SHIELD_DURATION, false)
		-- if not caster:HasModifier("modifier_omniro_nature_shield") then
		CustomAbilities:QuickAttachParticle("particles/units/heroes/hero_oracle/grithault_heal_core.vpcf", caster, 3)
		-- end
		orb_ability:ApplyDataDrivenModifier(caster, caster, "modifier_omniro_nature_shield", {duration = shield_duration})
		caster:SetModifierStackCount("modifier_omniro_nature_shield", caster, final_new_stacks)
	elseif caster.active_element == RPC_ELEMENT_UNDEAD then
		local fv = caster:GetForwardVector()
		local speed = 1200
		local rune_ability = caster.runeUnit4:FindAbilityByName("omniro_rune_r_4")
		local wind_range = OMNIRO_UNDEAD_ORB_RANGE
		EmitSoundOn("Omniro.Orb.Undead", target)
		orb_ability.undead_orb_damage = (orb_ability:GetSpecialValueFor("undead_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_UNDEAD]["level"] + (orb_ability:GetSpecialValueFor("undead_orb_b")) * caster:GetHealth() * caster.omniro_data[RPC_ELEMENT_UNDEAD]["level"]

		local undead_fv = fv
		local info =
		{
			Ability = rune_ability,
			EffectName = "particles/roshpit/omniro/omniro_undead_orb_terror.vpcf",
			vSpawnOrigin = target:GetAbsOrigin() + Vector(0, 0, 60),
			fDistance = wind_range,
			fStartRadius = 130,
			fEndRadius = 130,
			Source = caster,
			StartPosition = "attach_attack1",
			bHasFrontalCone = true,
			bReplaceExisting = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			fExpireTime = GameRules:GetGameTime() + 5.0,
			bDeleteOnHit = false,
			vVelocity = undead_fv * Vector(1, 1, 0) * speed,
			bProvidesVision = false,
		}
		projectile = ProjectileManager:CreateLinearProjectile(info)
	elseif caster.active_element == RPC_ELEMENT_DRAGON then
		EmitSoundOn("Omniro.Orb.Dragon", caster)
		for i = 1, 17, 1 do
			caster.omniro_data[i]["charges"] = caster.omniro_data[i]["max_charges"]
			caster.omniro_data[i]["charge_up_fraction"] = 0
		end
		CustomAbilities:QuickAttachParticle("particles/act_2/frostbitten_icicle.vpcf", caster, 3)
	end
	Filters:CastSkillArguments(2, caster)
	caster:RemoveModifierByName("modifier_burnout")
end

function omniro_ghost_orb_aura_end(event)
	local target = event.target
	ParticleManager:DestroyParticle(target.pfx, false)
	UTIL_Remove(target)
end

function omniro_ghost_orb_aura_effect_think(event)
	local caster = event.ability:GetCaster()
	local ability = event.ability
	local target = event.target
	local mace_hit_data = omni_mace_basic_element_data(RPC_ELEMENT_GHOST)
	local damage = (ability:GetSpecialValueFor("ghost_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_GHOST]["level"]
	Filters:ApplyDotDamage(caster, ability, target, damage, mace_hit_data["damage_type"], 2, RPC_ELEMENT_GHOST, RPC_ELEMENT_NONE)
end

function omni_rune_undead_projectile_hit(event)
	local caster = event.caster.hero
	local ability = caster:FindAbilityByName("omniro_omni_mace")
	local orb_ability = caster:FindAbilityByName("omniro_omni_orb")
	local damage = orb_ability.undead_orb_damage
	local enemy = event.target
	local mace_hit_data = omni_mace_basic_element_data(RPC_ELEMENT_UNDEAD)
	Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_UNDEAD, RPC_ELEMENT_NONE)
	ability:ApplyDataDrivenModifier(caster, enemy, "modifier_omnimace_undead_debuff", {duration = OMNIRO_UNDEAD_SPECIAL_DURATION})
end

function omni_rune_wind_projectile_hit(event)
	local caster = event.caster.hero
	local ability = caster:FindAbilityByName("omniro_omni_orb")
	local damage = ability.wind_orb_damage
	local enemy = event.target
	local mace_hit_data = omni_mace_basic_element_data(RPC_ELEMENT_WIND)
	Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_WIND, RPC_ELEMENT_NONE)
	if enemy.pushLock then
	else
		ability:ApplyDataDrivenModifier(caster, enemy, "modifier_wind_orb_pushback", {duration = 1})
	end
end

function omniro_wind_orb_push_think(event)
	local caster = event.caster
	local target = event.target
	if target.pushLock then
		return false
	end
	local fv = ((target:GetAbsOrigin() - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
	local distance = WallPhysics:GetDistance2d(caster:GetAbsOrigin(), target:GetAbsOrigin())
	local pushSpeed = math.max(40 - (distance / 1400) * 40, 10)
	local newPosition = target:GetAbsOrigin() + pushSpeed * fv
	local obstruction = WallPhysics:FindNearestObstruction(newPosition)
	local blockUnit = WallPhysics:ShouldBlockUnit(obstruction, newPosition, target)
	if blockUnit then
	else
		WallPhysics:SetPushPositionOverGround(target, newPosition)
	end
end

function omniro_wind_orb_end(event)
	local caster = event.caster
	local target = event.target
	FindClearSpaceForUnit(target, target:GetAbsOrigin(), false)
end

function omniro_time_effect_end(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local mace_hit_data = omni_mace_basic_element_data(RPC_ELEMENT_TIME)
	local damage = (ability:GetSpecialValueFor("time_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_TIME]["level"]
	CustomAbilities:QuickAttachParticle("particles/roshpit/omniro/timelock.vpcf", target, 3)
	Filters:TakeArgumentsAndApplyDamage(target, caster, damage, mace_hit_data["damage_type"], BASE_ABILITY_W, RPC_ELEMENT_TIME, RPC_ELEMENT_NONE)
	EmitSoundOn("Omniro.Orb.Time.Pop", target)
end

function omniro_poison_pool_think(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local mace_hit_data = omni_mace_basic_element_data(RPC_ELEMENT_POISON)
	local damage = (ability:GetSpecialValueFor("poison_orb_a") / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * caster.omniro_data[RPC_ELEMENT_POISON]["level"]
	Filters:ApplyDotDamage(caster, ability, target, damage, mace_hit_data["damage_type"], 2, RPC_ELEMENT_POISON, RPC_ELEMENT_NONE)
end

function water_orb_torrent_stun_think(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	target:SetAbsOrigin(target:GetAbsOrigin() + Vector(0, 0, target.torrentLiftVelocity))
	target.torrentLiftVelocity = target.torrentLiftVelocity - 0.9
	if target.torrentLiftVelocity < 0 then
		target:RemoveModifierByName("modifier_torrent_lifting")
	end
	if not target:HasModifier("modifier_torrent_lifting") then
		if target:GetAbsOrigin().z - GetGroundHeight(target:GetAbsOrigin(), target) < 30 then
			target:RemoveModifierByName("modifier_torrent_stun")
		end
	end
end

function water_orb_torrent_stun_end(event)
	local target = event.target
	local ability = event.ability
	Timers:CreateTimer(0.06, function()
		target.torrentLiftVelocity = nil
	end)

	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_slardar/slardar_crush.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(pfx, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(70, 70, 70))
	Timers:CreateTimer(3.0, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)

end

-- RPC_ELEMENT_NONE = -1
-- RPC_ELEMENT_NORMAL = 1
-- RPC_ELEMENT_FIRE = 2
-- RPC_ELEMENT_EARTH = 3
-- RPC_ELEMENT_LIGHTNING = 4
-- RPC_ELEMENT_POISON = 5
-- RPC_ELEMENT_TIME = 6
-- RPC_ELEMENT_HOLY = 7
-- RPC_ELEMENT_COSMOS = 8
-- RPC_ELEMENT_ICE = 9
-- RPC_ELEMENT_ARCANE = 10
-- RPC_ELEMENT_SHADOW = 11
-- RPC_ELEMENT_WIND = 12
-- RPC_ELEMENT_GHOST = 13
-- RPC_ELEMENT_WATER = 14
-- RPC_ELEMENT_DEMON = 15
-- RPC_ELEMENT_NATURE = 16
-- RPC_ELEMENT_UNDEAD = 17
-- RPC_ELEMENT_DRAGON = 18
