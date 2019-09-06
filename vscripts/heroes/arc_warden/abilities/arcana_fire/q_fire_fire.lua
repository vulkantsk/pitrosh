require('heroes/arc_warden/abilities/onibi')
require('heroes/arc_warden/jex_constants')

function jex_activate_q_fire_fire(event)
	local caster = event.caster
	local ability = event.ability
	ability.unique_ring_index_last = ability.unique_ring_index_last or 0
	ability.unique_ring_index_last = ability.unique_ring_index_last + 1

	local attack_damage_per_tech = event.attack_damage_per_tech
	local radius = event.radius
	local radius_per_tech = event.radius_per_tech
	local base_damage = event.base_damage
	local agility_added_to_base_damage = event.agility_added_to_base_damage

	local tech_level = onibi_get_total_tech_level(caster, "fire", "fire", "Q")
	local damage = base_damage + agility_added_to_base_damage * caster:GetAgility() + (attack_damage_per_tech / 100) * OverflowProtectedGetAverageTrueAttackDamage(caster) * tech_level

	ability.damage = damage

	if not ability.ring_table then
		ability.ring_table = {}

	end
	local new_ring = {}
	new_ring.active = true
	new_ring.pfx = ParticleManager:CreateParticle("particles/roshpit/jex/ring_of_fire_reduced_flash.vpcf", PATTACH_CUSTOMORIGIN, nil)
	new_ring.uid = ability.unique_ring_index_last
	table.insert(ability.ring_table, new_ring)
	local ringDuration = 0
	local speed = radius * 1
	ability.speed = speed
	ability.radius = radius
	new_ring.distance_from_center = 0
	new_ring.interval = 0
	new_ring.attachmentUnit = caster
	ParticleManager:SetParticleControl(new_ring.pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(new_ring.pfx, 1, Vector(speed, radius, 600))
	Timers:CreateTimer(ringDuration + (radius / speed), function()
		new_ring.retracing = true
		ParticleManager:SetParticleControl(new_ring.pfx, 1, Vector(speed, -radius, 600))
		Timers:CreateTimer(radius / speed, function()
			new_ring.active = false
			ParticleManager:DestroyParticle(new_ring.pfx, false)
			ParticleManager:ReleaseParticleIndex(new_ring.pfx)
			reindex_fire_fire_q_table(caster, ability)
		end)
	end)
	EmitSoundOn("Jex.RingOfFire.Start", caster)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_jex_ring_of_fire_thinker", {})
	Filters:CastSkillArguments(1, caster)
	local cd = ability:GetCooldownTimeRemaining()
	cd = cd - tech_level * event.cooldown_reduction_per_tech
	cd = math.max(cd, 0.2)
	if caster:HasModifier("modifier_hood_of_lords_lua") then
		cd = math.max(cd, 1.2)
	end
	ability:EndCooldown()
	ability:StartCooldown(cd)
end

function reindex_fire_fire_q_table(caster, ability)
	local new_table = {}
	for i = 1, #ability.ring_table, 1 do
		if ability.ring_table[i].active then
			table.insert(new_table, ability.ring_table[i])
		end
	end
	ability.ring_table = new_table
	if #ability.ring_table == 0 then
		caster:RemoveModifierByName("modifier_jex_ring_of_fire_thinker")
	end
end

function jex_fire_fire_ring_thinker(event)
	local caster = event.caster
	local ability = event.ability
	local w_4_level = caster:GetRuneValue("w", 4)
	local limitKey = caster:GetPlayerOwnerID() .. '_jex_fire_fire_ring'
	local hitAtLeastOneTarget = false
	for i = 1, #ability.ring_table, 1 do
		local ring = ability.ring_table[i]
		if ring.active then
			ParticleManager:SetParticleControl(ring.pfx, 0, caster:GetAbsOrigin())
			if ring.retracing then
				ring.distance_from_center = ring.distance_from_center - ability.speed * 0.03
			else
				ring.distance_from_center = ring.distance_from_center + ability.speed * 0.03
			end
			ring.interval = ring.interval + 1
			if ring.interval % 3 == 0 then
				local excluded_enemies = {}
				if ring.retracing then
					local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, ring.distance_from_center -  ability.speed * 0.09, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
					for _,enemy in pairs(enemies) do
						excluded_enemies[enemy:GetEntityIndex()] = true
					end
				end
				local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, ring.distance_from_center, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				if #enemies > 0 then
					for _, enemy in pairs(enemies) do
						local ringKey = 'jex_fire_fire_' .. ring.uid
						if ring.retracing then
							ringKey = ringKey .. '_retracing'
						end
						if enemy[ringKey] or (ring.retracing and excluded_enemies[enemy:GetEntityIndex()]) then
						else
							enemy[ringKey] = true
							hitAtLeastOneTarget = true
							local damage = ability.damage
							if w_4_level > 0 then
								local distance = WallPhysics:GetDistance2d(caster:GetAbsOrigin(), enemy:GetAbsOrigin())
								local distance_percentage = distance / ability.radius
								damage = damage + damage * distance_percentage * (event.w_4_damage_increase_pct_edges / 100) * w_4_level
							end
							Filters:TakeArgumentsAndApplyDamage(enemy, caster, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_Q, RPC_ELEMENT_FIRE, RPC_ELEMENT_NONE)

							if not enemy.has_jex_fire_fire_ring_particle then
								Util.Common:LimitPerTime(25, 1, limitKey, function()
									CustomAbilities:QuickAttachParticle("particles/econ/items/ogre_magi/ogre_ti8_immortal_weapon/ogre_ti8_immortal_bloodlust_buff_flash.vpcf", enemy, 2)
									enemy.has_jex_fire_fire_ring_particle = true
									Timers:CreateTimer(1, function()
										enemy.has_jex_fire_fire_ring_particle = false
									end)
								end)
							end
						end
					end
				end
			end
		end
	end
	if hitAtLeastOneTarget then
		EmitSoundOn("Jex.RingOfFire.Hit", caster)
	end
end

