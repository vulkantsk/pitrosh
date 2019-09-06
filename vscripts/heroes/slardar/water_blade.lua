function begin_water_blade(event)
	local caster = event.caster
	local ability = event.ability
	CustomAbilities:QuickAttachParticle("particles/econ/items/kunkka/divine_anchor/hero_kunkka_dafx_weapon/kunkka_spell_tidebringer_fxset.vpcf", caster, 2)
end

function water_bomb_start(event)
	local caster = event.caster
	local ability = event.ability

	local pfx = ParticleManager:CreateParticle("particles/roshpit/hydroxis/water_orb_throw.vpcf", PATTACH_POINT_FOLLOW, caster)
	Timers:CreateTimer(0.06, function()
		ParticleManager:SetParticleControlEnt(pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	end)
	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)
	caster.e_4_Level = Runes:GetTotalRuneLevel(caster, 4, "e_4", "hydroxis")
	local target = event.target_points[1]
	local damage = event.damage
	water_bomb_throw(caster, ability, target, event.damage, 1)
	Filters:CastSkillArguments(2, caster)
end

function water_bomb_throw(caster, ability, target, damage, damageAmp)
	local w_3_level = Runes:GetTotalRuneLevel(caster, 3, "w_3", "hydroxis")
	if w_3_level > 0 then
		damage = damage + OverflowProtectedGetAverageTrueAttackDamage(caster) * HYDROXIS_W3_ATTACK_TO_DMG_PCT/100 * w_3_level
	end
	local w_4_level = Runes:GetTotalRuneLevel(caster, 4, "w_4", "hydroxis")
	local manaAmp = 1
	if w_4_level > 0 then
		local manaDrain = caster:GetMaxMana() * HYDROXIS_W4_MANA_DRAIN_PCT/100
		if caster:GetMana() < manaDrain then
			manaDrain = caster:GetMana()
		end
		caster:ReduceMana(manaDrain)
		manaAmp = (manaDrain / 100) * HYDROXIS_W4_DMG_PER_MANA_PCT/100 * w_4_level + 1
	else

	end
	local startPosition = caster:GetAttachmentOrigin(2)
	local zDifferential = target.z - startPosition.z
	local baseFV = (target * Vector(1, 1, 0) - startPosition * Vector(1, 1, 0)):Normalized()
	local forwardVelocity = WallPhysics:GetDistance2d(target, startPosition) / 24
	local randomOffset = 0
	-- local flareAngle = WallPhysics:rotateVector(baseFV, math.pi*randomOffset/160)
	local flare = CreateUnitByName("selethas_boomerang", startPosition, false, caster, nil, caster:GetTeamNumber())
	flare:SetOriginalModel("models/hydroxis/water_bomb.vmdl")
	flare:SetModel("models/hydroxis/water_bomb.vmdl")
	flare:SetRenderColor(20, 110, 240)
	flare:SetModelScale(0.05)
	flare.fv = baseFV
	flare.slow_duration = 5
	flare.liftVelocity = 40 + zDifferential / 25
	flare.forwardVelocity = forwardVelocity
	flare.interval = 0
	flare.damage = damage * damageAmp * manaAmp
	flare.origCaster = caster
	flare.origAbility = ability
	flare.w_2_level = Runes:GetTotalRuneLevel(caster, 2, "w_2", "hydroxis")
	flare:AddAbility("hydroxis_water_bomb_ability"):SetLevel(1)
	local flareSubAbility = flare:FindAbilityByName("hydroxis_water_bomb_ability")
	flareSubAbility:ApplyDataDrivenModifier(flare, flare, "modifier_water_bomb_motion", {})
	EmitSoundOn("Hydroxis.WaterBomb.Start", flare)

	local pfx2 = ParticleManager:CreateParticle("particles/roshpit/hydroxis/water_orb_throw.vpcf", PATTACH_POINT_FOLLOW, caster)
	Timers:CreateTimer(0.15, function()
		ParticleManager:SetParticleControlEnt(pfx2, 0, flare, PATTACH_POINT_FOLLOW, "attach_origin", flare:GetAbsOrigin(), true)
	end)
	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle(pfx2, false)
	end)
end

function bombadier_bomb_thinking(event)
	local caster = event.caster
	local ability = event.ability
	caster:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0, 0, caster.liftVelocity) + caster.fv * caster.forwardVelocity)
	caster.liftVelocity = caster.liftVelocity - 3
	local maxScale = 0.35
	if caster.altMaxScale then
		maxScale = caster.altMaxScale
	end
	caster:SetModelScale(0.01)
	local newFV = WallPhysics:rotateVector(caster:GetForwardVector(), math.pi / 30)
	caster:SetForwardVector(newFV)
	caster:SetAngles(caster.interval * 7, caster.interval * 7, caster.interval * 7)
	caster.interval = caster.interval + 1
	local groundHeight = GetGroundHeight(caster:GetAbsOrigin(), caster)
	if caster:GetAbsOrigin().z - groundHeight < 10 then
		flareParticle(caster:GetAbsOrigin(), caster)
		EmitSoundOn("Hydroxis.WaterBomb.Explode", caster)
		caster:RemoveModifierByName("modifier_water_bomb_motion")
		bombImpact(caster, ability)
		caster:SetAbsOrigin(caster:GetAbsOrigin() - Vector(0, 0, 1000))
		Timers:CreateTimer(0.1, function()
			caster:SetModelScale(0.01)
			Timers:CreateTimer(1, function()
				UTIL_Remove(caster)
			end)
		end)
	end
end

function flareParticle(position)
	local particleNameS = "particles/roshpit/hydroxis/water_bomb_explode.vpcf"
	local particle2 = ParticleManager:CreateParticle(particleNameS, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(particle2, 0, position)
	ParticleManager:SetParticleControl(particle2, 1, Vector(260, 260, 260))
	ParticleManager:SetParticleControl(particle2, 2, Vector(3.0, 3.0, 1))
	ParticleManager:SetParticleControl(particle2, 4, Vector(60, 70, 215))
	Timers:CreateTimer(1.5, function()
		ParticleManager:DestroyParticle(particle2, false)
	end)

	local pfx = ParticleManager:CreateParticle("particles/roshpit/hydroxis/water_bomb_water_explosion_splash_fxset.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(pfx, 0, position - Vector(0, 0, 200))
	Timers:CreateTimer(2, function()
		ParticleManager:DestroyParticle(pfx, false)
	end)

	local particleName = "particles/roshpit/hydroxis/slipstream_puddle.vpcf"
	local pfx2 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(pfx2, 0, position + Vector(0, 0, 100))
	Timers:CreateTimer(5, function()
		ParticleManager:DestroyParticle(pfx2, false)
	end)
end

function bombImpact(caster, ability)
	local enemies = FindUnitsInRadius(caster.origCaster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 260, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	local damage = caster.damage
	if #enemies > 0 then
		for _, enemy in pairs(enemies) do
			Filters:TakeArgumentsAndApplyDamage(enemy, caster.origCaster, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_W, RPC_ELEMENT_WATER, RPC_ELEMENT_NONE)
			caster.origAbility:ApplyDataDrivenModifier(caster.origCaster, enemy, "modifier_water_bomb_slow", {duration = caster.slow_duration})
		end
		if caster.w_2_level > 0 then
			local b_b_duration = Filters:GetAdjustedBuffDuration(caster, 15, false)
			if not caster.origCaster:HasModifier("modifier_water_bomb_w_2_damage_buff_spillover") then
				caster.origAbility:ApplyDataDrivenModifier(caster.origCaster, caster.origCaster, "modifier_water_bomb_w_2_damage_buff_visible", {duration = b_b_duration})
			else
				caster.origAbility:ApplyDataDrivenModifier(caster.origCaster, caster.origCaster, "modifier_water_bomb_w_2_damage_buff_spillover", {duration = b_b_duration})
				caster.origAbility:ApplyDataDrivenModifier(caster.origCaster, caster.origCaster, "modifier_water_bomb_w_2_damage_buff_spillover_invis", {duration = b_b_duration})
				caster.origCaster:SetModifierStackCount("modifier_water_bomb_w_2_damage_buff_spillover_invis", caster.origCaster, caster.w_2_level)
			end
			local newStacks = caster.origCaster:GetModifierStackCount("modifier_water_bomb_w_2_damage_buff_visible", caster.origCaster) + #enemies
			if newStacks >= 20 then
				caster.origCaster:RemoveModifierByName("modifier_water_bomb_w_2_damage_buff_visible")
				caster.origCaster:RemoveModifierByName("modifier_water_bomb_w_2_damage_buff_invisible")
				caster.origAbility:ApplyDataDrivenModifier(caster.origCaster, caster.origCaster, "modifier_water_bomb_w_2_damage_buff_spillover", {duration = b_b_duration})
				caster.origAbility:ApplyDataDrivenModifier(caster.origCaster, caster.origCaster, "modifier_water_bomb_w_2_damage_buff_spillover_invis", {duration = b_b_duration})
				caster.origCaster:SetModifierStackCount("modifier_water_bomb_w_2_damage_buff_spillover_invis", caster.origCaster, caster.w_2_level)
			else
				caster.origCaster:SetModifierStackCount("modifier_water_bomb_w_2_damage_buff_visible", caster.origCaster, newStacks)
				caster.origAbility:ApplyDataDrivenModifier(caster.origCaster, caster.origCaster, "modifier_water_bomb_w_2_damage_buff_invisible", {duration = b_b_duration})
				caster.origCaster:SetModifierStackCount("modifier_water_bomb_w_2_damage_buff_invisible", caster.origCaster, newStacks * caster.w_2_level)
			end
		end
	end

end

function hydroxis_attack_land(event)
	local attacker = event.attacker
	local ability = event.ability
	local target = event.target
	local caster = attacker
	local w_1_level = caster:GetRuneValue("w", 1)
	if w_1_level > 0 then
		local crit = false
		if caster:HasModifier("modifier_hydroxis_glyph_5_1") then
			local luck = RandomInt(1, 100)
			if luck <= 15 then
				crit = true
				EmitSoundOnLocationWithCaster(attacker:GetAbsOrigin(), "Hydroxis.VaporCrit", attacker)
			end
		end
		local fv = ((target:GetAbsOrigin() - attacker:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
		local damage = event.attack_damage * w_1_level * HYDROXIS_W1_SPLASH_PCT/100
		if caster:HasAbility("hydroxis_arcana_ability_1") then
			damage = event.attack_damage * w_1_level * HYDROXIS_ARCANA_W1_SPLASH_PCT/100
		end
		-- CustomAbilities:QuickAttachParticle("particles/econ/items/kunkka/divine_anchor/hero_kunkka_dafx_weapon/kunkka_spell_tidebringer_fxset.vpcf", attacker, 2)
		local pfx = ParticleManager:CreateParticle("particle/roshpit/hydroxis/hydroxis_a_b.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(pfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin() + fv * 200, true)
		Timers:CreateTimer(2, function()
			ParticleManager:DestroyParticle(pfx, false)
			ParticleManager:ReleaseParticleIndex(pfx)
		end)

		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				-- Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, DAMAGE_TYPE_PHYSICAL, 2)
				-- local targetAngle = ((enemy:GetAbsOrigin()-caster:GetAbsOrigin())*Vector(1,1,0)):Normalized()
				-- local angleDifferential = math.acos(fv:Dot(targetAngle, fv))
				--print(angleDifferential)
				-- if angleDifferential < math.pi/2 then
				Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, DAMAGE_TYPE_PHYSICAL, BASE_ABILITY_W, RPC_ELEMENT_WATER, RPC_ELEMENT_NONE)
				if crit then
					local pfx2 = ParticleManager:CreateParticle("particles/econ/items/kunkka/kunkka_tidebringer_base/kunkka_spell_tidebringer.vpcf", PATTACH_CUSTOMORIGIN, caster)
					ParticleManager:SetParticleControlEnt(pfx2, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(pfx2, 1, enemy, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
					Timers:CreateTimer(1, function()
						ParticleManager:DestroyParticle(pfx2, false)
						ParticleManager:ReleaseParticleIndex(pfx2)
					end)
					-- CustomAbilities:QuickAttachParticle("particles/econ/items/kunkka/kunkka_tidebringer_base/kunkka_spell_tidebringer.vpcf", enemy, 1)
					local glyphDamage = OverflowProtectedGetAverageTrueAttackDamage(attacker) * 4
					Filters:TakeArgumentsAndApplyDamage(enemy, attacker, glyphDamage, DAMAGE_TYPE_MAGICAL, BASE_ITEM, RPC_ELEMENT_WATER, RPC_ELEMENT_NONE)
				end
				-- ApplyDamage({ victim = enemy, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})
				-- end
			end
		end
	end

end

function weapon_particle_buff(event)
	local caster = event.caster
	--print("WEAPON PARTICLE BUFF")
	local ability = event.ability
	if not ability.w_2_particle then
		--print("ATTACH PARTICLE")
		local index = ParticleManager:CreateParticle("particles/roshpit/hydroxis/b_b_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(index, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(index, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(index, 2, Vector(-100, -100, -100))
		ParticleManager:SetParticleControl(index, 3, Vector(-100, -100, -100))
		ability.w_2_particle = index
	end
end

function weapon_particle_end(event)
	local caster = event.caster
	local ability = event.ability
	ParticleManager:DestroyParticle(ability.w_2_particle, false)
	ability.w_2_particle = nil
end
