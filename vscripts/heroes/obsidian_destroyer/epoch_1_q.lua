require('/heroes/obsidian_destroyer/epoch_constants')

function time_bind_cast(event)
	local caster = event.caster
	local ability = event.ability
	Filters:CastSkillArguments(1, caster)

	local q_4_level = caster:GetRuneValue("q", 4)
	if q_4_level > 0 then
		local manaDrain = caster:GetMaxMana() * EPOCH_Q4_MANA_DRAIN_BASE_PCT
		if caster:GetMana() < manaDrain then
			manaDrain = caster:GetMana()
		end
		caster:ReduceMana(manaDrain)
		ability.damageAmp = manaDrain * EPOCH_Q4_DMG_BONUS_PCT * q_4_level / 10000 + 1 -- /10000 -> % mana * % rune
	else
		ability.damageAmp = 1
	end
end

function epoch_time_binder_phase_start(event)
	local caster = event.caster
	StartAnimation(caster, {duration = 0.5, activity = ACT_DOTA_CAST_ABILITY_2, rate = 0.94})
end

function projectile_hit(event)
	local caster = event.caster
	local target = event.target
	local target_location = target:GetAbsOrigin()
	local ability = event.ability

	if caster.time_bound_units == nil then
		caster.time_bound_units = {}
	end
	local number_of_targets = event.number_of_targets
	--table.insert(caster.time_bound_units, target)
	target.time_bound = true
	ability.q_1_level = caster:GetRuneValue("q", 1)
	local q_2_level = caster:GetRuneValue("q", 2)
	-- if caster:HasModifier("modifier_epoch_glyph_5_a") then
	-- local particleName = "particles/roshpit/epoch/binder_bomb_epoch_5_a_immortal1.vpcf"
	-- local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	-- ParticleManager:SetParticleControl(pfx, 0, target_location)
	-- EmitSoundOnLocationWithCaster(target_location, "Epoch.BinderBomb.Explode", target)
	-- Timers:CreateTimer(4, function()
	-- ParticleManager:DestroyParticle(pfx, false)
	-- ParticleManager:ReleaseParticleIndex(pfx)
	-- end)
	-- end
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target_location, nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	local i = 2
	ability.linked_enemies_base = {}
	for _, enemy in pairs(enemies) do
		if i <= #enemies then
			-- if i > number_of_targets then
			-- break
			-- end
			local stacks = enemy:GetModifierStackCount("modifier_time_bound", ability)
			ability:ApplyDataDrivenModifier(caster, enemies[i - 1], "modifier_time_bound", {duration = 7})
			ability:ApplyDataDrivenModifier(caster, enemies[i], "modifier_time_bound", {duration = 7})
			-- enemy:SetModifierStackCount( "modifier_time_bound", ability, stacks+1)
			local particleName = "particles/units/heroes/hero_wisp/tether_green.vpcf"
			local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, enemy)
			ParticleManager:SetParticleControlEnt(pfx, 0, enemies[i - 1], PATTACH_POINT_FOLLOW, "attach_hitloc", enemies[i - 1]:GetAbsOrigin() + Vector(0, 0, 90), true)
			ParticleManager:SetParticleControlEnt(pfx, 1, enemies[i], PATTACH_POINT_FOLLOW, "attach_hitloc", enemies[i]:GetAbsOrigin() + Vector(0, 0, 90), true)
			enemy.time_pfx = pfx
			i = i + 1
		end
		if 1 == #enemies then
			-- apply dmg overtime debuff even if only one target
			local stacks = enemy:GetModifierStackCount("modifier_time_bound", ability)
			ability:ApplyDataDrivenModifier(caster, enemies[i - 1], "modifier_time_bound", {duration = 7})
			--ability:ApplyDataDrivenModifier(caster, enemies[i], "modifier_time_bound", {duration = 7})
			-- enemy:SetModifierStackCount( "modifier_time_bound", ability, stacks+1)
			local particleName = "particles/units/heroes/hero_wisp/tether_green.vpcf"
			local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, enemy)
			--ParticleManager:SetParticleControlEnt(pfx, 0, enemies[i-1], PATTACH_POINT_FOLLOW, "attach_hitloc", enemies[i-1]:GetAbsOrigin()+Vector(0,0,90), true)
			--ParticleManager:SetParticleControlEnt(pfx, 1, enemies[i], PATTACH_POINT_FOLLOW, "attach_hitloc", enemies[i]:GetAbsOrigin()+Vector(0,0,90), true)
			enemy.time_pfx = pfx
			--i = i + 1
		end
		table.insert(ability.linked_enemies_base, enemies[i])
	end
	if #enemies > 0 then
		EmitSoundOn("Hero_Spirit_Breaker.EmpoweringHaste.Cast", enemies[1])
	end
	local point = target:GetAbsOrigin()
	local particleName = "particles/units/heroes/hero_abaddon/abaddon_aphotic_shield_explosion.vpcf"
	local particleVector = point
	local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(pfx, 0, particleVector)
	ParticleManager:SetParticleControl(pfx, 1, particleVector)
	local damage = event.impact_damage
	-- if caster:HasModifier("modifier_epoch_glyph_5_a") then
	-- damage = damage + OverflowProtectedGetAverageTrueAttackDamage(caster)*2
	-- end
	damage = damage * ability.damageAmp
	EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_Abaddon.AphoticShield.Destroy", caster)
	local enemies2 = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, 320, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies2) do
		Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_Q, RPC_ELEMENT_TIME, RPC_ELEMENT_NONE)
	end
	Timers:CreateTimer(4, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)
	if ability.q_1_level > 0 then
		ability.jump_count = 0
		a_a_search(caster, target, ability)
	end
	if q_2_level > 0 then
		if caster:HasModifier("modifier_epoch_glyph_6_1") then
			q_2_level = q_2_level * EPOCH_GLYPH_6_1_Q2_MULTI
		end
		local b_a_duration = Filters:GetAdjustedBuffDuration(caster, 7, false)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_eon_channel_friendly", {duration = b_a_duration})
		ability:ApplyDataDrivenModifier(caster, target, "modifier_eon_channel_enemy", {duration = b_a_duration})
		caster:SetModifierStackCount("modifier_eon_channel_friendly", ability, q_2_level)
		target:SetModifierStackCount("modifier_eon_channel_enemy", ability, q_2_level)
		local particleName = "particles/units/heroes/hero_wisp/epoch_rune_b_a.vpcf"
		local eonPfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, enemy)
		ParticleManager:SetParticleControlEnt(eonPfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin() + Vector(0, 0, 90), true)
		ParticleManager:SetParticleControlEnt(eonPfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin() + Vector(0, 0, 90), true)
		Timers:CreateTimer(7, function()
			ParticleManager:DestroyParticle(eonPfx, false)
		end)
	end
end

function a_a_search(caster, target, ability)
	ability.linked_enemies_q1 = {}
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	local links = 3 + Runes:Procs(ability.q_1_level, EPOCH_Q1_ADDITIONAL_LINKS_CHANCE, 1)
	for _, enemy in pairs(enemies) do
		--print("A A SEARCH")
		if ability.jump_count >= links then
			break
			-- apply dmg overtime debuff even if only one target
		else
			if enemy:GetEntityIndex() == target:GetEntityIndex() then
			else
				if not enemy:HasModifier("modifier_space_link") then
					--print("DO A LINK")
					local stacks = enemy:GetModifierStackCount("modifier_space_link", ability)
					ability:ApplyDataDrivenModifier(caster, enemy, "modifier_space_link", {duration = 7})
					ability:ApplyDataDrivenModifier(caster, target, "modifier_space_link", {duration = 7})
					local particleName = "particles/units/heroes/hero_wisp/wisp_tether.vpcf"
					local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, enemy)
					ParticleManager:SetParticleControlEnt(pfx, 0, target, PATTACH_CUSTOMORIGIN_FOLLOW, "attach_hitloc", target:GetAbsOrigin() + Vector(0, 0, 90), true)
					ParticleManager:SetParticleControlEnt(pfx, 1, enemy, PATTACH_CUSTOMORIGIN_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin() + Vector(0, 0, 90), true)
					target.space_pfx = pfx
					EmitSoundOn("Hero_Spirit_Breaker.EmpoweringHaste.Cast", target)
					Timers:CreateTimer(0.2, function()
						a_a_search(caster, enemy, ability)
					end)
					ability.jump_count = ability.jump_count + 1
					break
				end
			end
		end
		table.insert(ability.linked_enemies_q1, enemies[i])
	end
end

function spacelink_think(event)
	local damage = event.damage_per_tick
	local ability = event.ability
	damage = damage * ability.q_1_level * EPOCH_Q1_DMG_MULTI_PCT / 100
	damage = damage * ability.damageAmp
	local dummy_binder = event.target
	local caster = event.caster
	-- local stacks = dummy_binder:GetModifierStackCount( "modifier_time_bound", ability )
	Filters:TakeArgumentsAndApplyDamage(dummy_binder, caster, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_Q, RPC_ELEMENT_TIME, RPC_ELEMENT_NONE)
	local particleName = "particles/econ/items/antimage/antimage_weapon_basher_ti5/leshrac_wall_burn.vpcf"
	local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(pfx, 0, dummy_binder, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", dummy_binder:GetAbsOrigin(), true)
	Timers:CreateTimer(0.5, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)
end

function space_link_end(event)
	local target = event.target
	local ability = event.ability
	if target.space_pfx then
		ParticleManager:DestroyParticle(target.space_pfx, false)
	end
end

function time_bind_end(event)
	local target = event.target
	local ability = event.ability
	if target.time_pfx then
		ParticleManager:DestroyParticle(target.time_pfx, false)
	end
end

function time_bind(target, next_target, caster, time_bind_name, q_1_level, enemies, q_2_level, rune_q_3_level)
	if target and next_target then
		target:AddAbility(time_bind_name)
		local dummy_time_bind = target:FindAbilityByName(time_bind_name)
		dummy_time_bind:SetLevel(1)
		target.epoch_time_binder = caster
		local queue = false
		-- if time_bind_name == "dummy_time_bind_two" then
		-- queue = true
		-- end
		local order =
		{
			UnitIndex = target:GetEntityIndex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			AbilityIndex = dummy_time_bind:GetEntityIndex(),
			TargetIndex = next_target:GetEntityIndex(),
			Queue = queue
		}
		ExecuteOrderFromTable(order)
		if time_bind_name == "dummy_time_bind" and q_1_level > 0 then
			local procs = Runes:Procs(q_1_level, 10, 1)
			if procs > 0 then
				for i = 0, procs, 1 do
					Timers:CreateTimer(i * 0.15, function()
						time_bind(target, enemies[RandomInt(1, #enemies)], caster, "dummy_time_bind_two", q_1_level, enemies, q_2_level)
					end)
				end
			end
		end
		if time_bind_name == "dummy_time_bind" and q_2_level > 0 then
			local lucky = RandomInt(1, 100)
			if lucky < q_2_level * 2 then
				Timers:CreateTimer(0.06, function()
					time_bind(target, caster, caster, "dummy_time_bind_three", q_1_level, enemies, q_2_level)
				end)
			end
		end
	end
end

function damage_think(event)
	local damage = event.damage_per_tick
	local ability = event.ability
	damage = damage * ability.damageAmp
	local dummy_binder = event.target
	local caster = event.caster
	-- local stacks = dummy_binder:GetModifierStackCount( "modifier_time_bound", ability )
	Filters:TakeArgumentsAndApplyDamage(dummy_binder, caster, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_Q, RPC_ELEMENT_TIME, RPC_ELEMENT_NONE)
	local particleName = "particles/econ/items/antimage/antimage_weapon_basher_ti5/time_bind_damage.vpcf"
	local pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(pfx, 0, dummy_binder, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", dummy_binder:GetAbsOrigin(), true)
	Timers:CreateTimer(0.5, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)
end

function modifier_end(event)
	local unit = event.target
	unit.epoch_time_binder = nil
	unit:RemoveAbility("dummy_time_bind")
end

function binder_passive_think(event)
	local caster = event.caster
	local q_3_level = caster:GetRuneValue("q", 3)
	if q_3_level > 0 then
		local runeAbility = caster.runeUnit3:FindAbilityByName("epoch_rune_q_3")
		runeAbility:ApplyDataDrivenModifier(caster.runeUnit3, caster, "modifier_epoch_q_3", {})
		runeAbility.q_3_level = q_3_level
		caster.q_3_level = q_3_level
	else
		caster:RemoveModifierByName("modifier_epoch_q_3")
	end
end

function epoch_q_3_get_damage(attacker, caster, reduceMana)
	local ability = caster:FindAbilityByName("epoch_rune_q_3")
	local manaDrain = attacker:GetMaxMana() * EPOCH_Q3_BASE_MANA_DRAIN_PCT / 100
	local damage = 0
	--print("man drain before "..manaDrain)
	local q_4_level = attacker:GetRuneValue("q", 4)
	--print("q_4_level: "..q_4_level)
	if q_4_level > 0 then
		manaDrain = manaDrain + attacker:GetMaxMana() * q_4_level * EPOCH_Q4_Q3_BONUS_MANA_DRAIN_PCT / 100
	end
	--print("man drain after "..manaDrain)
	if not ability then
		return false
	end
	if manaDrain > attacker:GetMana() then
		return nil
	end
	local q_3_level = attacker:GetRuneValue("q", 3)
	--print("q_3_level: "..q_3_level)
	if q_3_level > 0 then
		if not attacker:HasModifier("modifier_epoch_q_3_lock") and reduceMana then
			ability:ApplyDataDrivenModifier(caster, attacker, "modifier_epoch_q_3_lock", {duration = 0.1})
			attacker:ReduceMana(manaDrain)
		end
		damage = manaDrain * q_3_level * EPOCH_Q3_TIMES_MANA_DRAINED
	end
	--print("q_3_damage: "..damage)
	return damage
end

function epoch_q_3_strike(event)
	local target = event.target
	local ability = event.ability
	local caster = event.caster

	if not target.dummy then
		Filters:TakeArgumentsAndApplyDamage(target, caster, ability.q_3_damage, DAMAGE_TYPE_PURE, BASE_ABILITY_Q, RPC_ELEMENT_TIME, RPC_ELEMENT_NONE)
	end
end

function epoch_glyph_1_1(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target

	if caster:HasModifier("modifier_epoch_glyph_1_1") then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_epoch_glyph_1_1_effect", {duration = 7})
	end
	if caster:HasModifier("modifier_epoch_glyph_6_1") then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_epoch_glyph_6_1_effect", {duration = 7})
	end
end
