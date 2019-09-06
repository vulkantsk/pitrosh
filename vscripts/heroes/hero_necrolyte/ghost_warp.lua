require('heroes/hero_necrolyte/constants')

function ghost_warp_start(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target_points[1]
	local maxDistance = event.cast_range
	if caster:HasModifier('modifier_venomort_glyph_3_1') then
		maxDistance = maxDistance * VENOMORT_T31_E_CAST_RANGE_AMP
	end
	local distance = WallPhysics:GetDistance2d(caster:GetAbsOrigin(), target)
	local scale = math.min(1, distance/maxDistance)

	if caster:HasModifier('modifier_venomort_glyph_3_1') then
		scale = scale * VENOMORT_T31_E_CAST_RANGE_AMP
	end
	if distance > maxDistance then
		target = WallPhysics:ClampedVector(caster:GetAbsOrigin(), target, maxDistance)
	end
	target = WallPhysics:ClampedVector(caster:GetAbsOrigin(), target, maxDistance)
	target = WallPhysics:WallSearch(caster:GetAbsOrigin(), target, caster)

	local invisible_duration = event.invisible_duration
	ability.fv = ((target - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
	ability.targetPoint = target
	local warpDuration = 1.5 * scale
	ability.fallVelocity = 2
	ability.forwardVelocity = 30
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_ghost_warp_flying", {duration = warpDuration})
	if ability.pfx then
		ParticleManager:DestroyParticle(ability.pfx, true)
		ability.pfx = false
	end
	caster:RemoveModifierByName("modifier_end_ghost_warp_falling")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_ghost_warp_invisible", {duration = invisible_duration})
	local modifier = caster:FindModifierByName("modifier_venomort_glyph_3_1")
	if modifier then
		local glyphAbility = modifier:GetAbility()
		glyphAbility:ApplyDataDrivenModifier(caster, caster, "modifier_venomort_glyph_3_1_regen", {duration = invisible_duration})

	end

	EmitSoundOn("Venomort.GhostWarp", caster)
	local pfx = CustomAbilities:QuickAttachParticle("particles/roshpit/venomort/ghost_warp_flare.vpcf", caster, 1)
	ability.pfx = ParticleManager:CreateParticle("particles/econ/courier/courier_polycount_01/courier_trail_polycount_01.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(ability.pfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(ability.pfx, 15, Vector(100, 220, 100))
	Filters:CastSkillArguments(3, caster)
end

function ghost_warping_think(event)
	local caster = event.caster
	local ability = event.ability

	local acceleration = 0.5
	acceleration = Filters:GetAdjustedESpeed(caster, acceleration, false)
	ability.forwardVelocity = ability.forwardVelocity + acceleration

	local blockSearch = caster:GetAbsOrigin() * Vector(1, 1, 0) + Vector(0, 0, GetGroundHeight(caster:GetAbsOrigin(), caster))
	local obstruction = WallPhysics:FindNearestObstruction(blockSearch)
	local blockUnit = WallPhysics:ShouldBlockUnit(obstruction, (blockSearch + ability.fv * 45), caster)
	local forwardSpeed = ability.forwardVelocity
	if blockUnit then
		forwardSpeed = 0
	end

	caster:SetAbsOrigin(caster:GetAbsOrigin() + ability.fv * forwardSpeed + Vector(0, 0, 3))
	local distance = WallPhysics:GetDistance2d(ability.targetPoint, caster:GetAbsOrigin())
	if distance < 100 then
		caster:RemoveModifierByName("modifier_ghost_warp_flying")
		if ability.pfx then
			ParticleManager:DestroyParticle(ability.pfx, false)
			ability.pfx = false
		end
	end
end

function after_warp_falling(event)
	local caster = event.caster
	local ability = event.ability
	caster:SetAbsOrigin(caster:GetAbsOrigin() - Vector(0, 0, ability.fallVelocity))
	local fallSpeed = 2
	fallSpeed = Filters:GetAdjustedESpeed(caster, fallSpeed, false)
	ability.fallVelocity = ability.fallVelocity + fallSpeed
	local groundHeight = GetGroundHeight(caster:GetAbsOrigin(), caster)
	if caster:GetAbsOrigin().z - groundHeight < ability.fallVelocity / 2 then
		caster:RemoveModifierByName("modifier_end_ghost_warp_falling")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
		StartAnimation(caster, {duration = 0.3, activity = ACT_DOTA_SPAWN, rate = 1})
	end
end

function ghost_warp_take_damage(event)
	local caster = event.caster
	local ability = event.ability
	local attacker = event.attacker
	local duration = VENONORT_E2_DURATION
	if attacker:GetTeamNumber() == caster:GetTeamNumber() then
		return false
	end
	local has_weapon3 = caster:HasModifier("modifier_venomort_immortal_weapon_3")

	local e2_level = caster:GetRuneValue("e", 2)
	local e2_damage = e2_level * E2_DAMAGE_PER_LEVEL * caster:GetLevel()

	if e2_level == 0 then
		return
	end
	if has_weapon3 then
		e2_damage = e2_damage + e2_level * WEAPON3_E2_DAMAGE_PER_RUNE_FROM_HP_PERCENT / 100 * caster:GetHealth()
		local pfx = CustomAbilities:QuickParticleAtPoint("particles/roshpit/venomort/viper_channel_flare.vpcf", attacker:GetAbsOrigin() + Vector(0, 0, attacker:GetBoundingMaxs().z), 1)
		ParticleManager:SetParticleControl(pfx, 1, Vector(40, 40, 40))
		ParticleManager:SetParticleControl(pfx, 2, Vector(18, 18, 18))
	end

	if caster:HasModifier("modifier_venomort_glyph_3_2") then
		if ability.previous_health then
			local currentHealth = caster:GetHealth()
			if math.floor(ability.previous_health * T32_HEALTH_THRESHOLD_PERCENT / caster:GetMaxHealth()) - math.floor(currentHealth * T32_HEALTH_THRESHOLD_PERCENT / caster:GetMaxHealth()) > 0 then
				e2_damage = e2_damage * VENOMORT_T32_AMPLIFY
				--print('E2 amplify apply')
			end
		end
		ability.previous_health = caster:GetHealth()
	end

	ability.e2_level = e2_level
	ability.e2_damage = e2_damage

	if caster:HasModifier("modifier_venomort_glyph_2_2") then
		local radius = T22_RADIUS
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), attacker:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				apply_e2(caster, ability, enemy, duration)
			end
		end
	else
		apply_e2(caster, ability, attacker, duration)
	end
end

function apply_e2(caster, ability, target, duration)
	ability:ApplyDataDrivenModifier(caster, target, "modifier_ghost_warp_return", {duration = duration})
end

function e2_think(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	Damage:Apply({
		attacker = caster,
		victim = target,
		source = ability,
		sourceType = BASE_ABILITY_E,
		damage = ability.e2_damage,
		damageType = DAMAGE_TYPE_PURE,
		elements = { RPC_ELEMENT_POISON },
		isDot = true
	})
end
function e3_think(event)
	local caster = event.caster
	local ability = event.ability
	local radius = E3_RADIUS
	local duration = E3_DURATION
	ability.e3_level = caster:GetRuneValue("e", 3)

	if ability.e3_level == 0 then
		return
	end

	local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for _, ally in pairs(allies) do
		ability:ApplyDataDrivenModifier(caster, ally, "modifier_venomort_bonus_attack_damage_ally", {duration = duration})
		local modifier = ally:FindModifierByName('modifier_venomort_bonus_attack_damage_ally')
		modifier:SetStackCount(ability.e3_level)
	end
end

function apply_e4_stacks(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target

	local bossesCountAs = VENOMORT_BOSSES_COUNT_AS_ENEMIES
	local paragonsCountAs = VENOMORT_PARAGONS_COUNT_AS_ENEMIES
	if caster:HasModifier("modifier_venomort_glyph_2_1") then
		bossesCountAs = VENOMORT_T21_BOSSES_COUNT_AS_ENEMIES
		paragonsCountAs = VENOMORT_T21_PARAGONS_COUNT_AS_ENEMIES
	end

	local duration = VENOMORT_E4_DURATION + E4_DELAY

	if caster:HasModifier("modifier_venomort_glyph_4_2") then
		duration = T42_DURATION + E4_DELAY
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_venomort_e4_hero_bonus_visible", nil)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_venomort_e4_hero_bonus_invisible", {duration = duration})
	if not ability.e4_data then
		ability.e4_data = {}
	end
	local thisStack = {}
	thisStack.createdAt = GameRules:GetGameTime()
	thisStack.value = 1
	if target.mainBoss or target.isBossFFS then
		thisStack.value = thisStack.value + bossesCountAs - 1
	end
	if target.paragon then
		thisStack.value = thisStack.value + paragonsCountAs - 1
	end
	table.insert(ability.e4_data, thisStack)
	recalculate_e4_stacks(event, true)
end
function recalculate_e4_stacks(event)
	local caster = event.caster
	local ability = event.ability
	local runesCount = caster:GetRuneValue("e", 4)

	if not runesCount then
		return
	end

	if not ability.e4_previous_stacks then
		ability.e4_previous_stacks = 0
	end

	if ability.e4_use_previous_stacks == nil then
		ability.e4_use_previous_stacks = false
	end

	local duration = VENOMORT_E4_DURATION

	if caster:HasModifier("modifier_venomort_glyph_4_2") then
		duration = T42_DURATION
	end

	local new_e4_data = {}
	local totalStacks = 0
	if not ability.e4_data then
		ability.e4_data = {}
	end
	for i = 1, #ability.e4_data, 1 do
		if GameRules:GetGameTime() - ability.e4_data[i].createdAt >= duration then
		else
			table.insert(new_e4_data, ability.e4_data[i])
			totalStacks = totalStacks + ability.e4_data[i].value
		end
	end

	ability.e4_data = new_e4_data
	if totalStacks < ability.e4_previous_stacks then
		local oldStacks = ability.e4_previous_stacks
		ability.e4_previous_stacks = totalStacks

		if ability.e4_use_previous_stacks then
			totalStacks = oldStacks
			ability.e4_use_previous_stacks = false
		else
			ability.e4_use_previous_stacks = true
		end

	end

	totalStacks = math.min(totalStacks, VENOMORT_E4_MAX_STACKS)

	caster:SetModifierStackCount("modifier_venomort_e4_hero_bonus_visible", caster, totalStacks)
	caster:SetModifierStackCount("modifier_venomort_e4_hero_bonus_invisible", caster, totalStacks * runesCount)
end
