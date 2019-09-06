require('heroes/arc_warden/abilities/onibi')

function jex_activate_q_nature_nature(event)
	local caster = event.caster
	local ability = event.ability

	local duration_base = event.duration
	local duration_per_tech = event.duration_per_tech_level
	local stacks_per_tech = event.stacks_per_tech

	local tech_level = onibi_get_total_tech_level(caster, "nature", "nature", "Q")

	ability.tech_level = tech_level

	local full_duration = duration_base + (duration_per_tech * tech_level)
	local duration = Filters:GetAdjustedBuffDuration(caster, full_duration, false)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_jex_nature_nature_shield_visible", {duration = duration})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_jex_nature_nature_shield_invisible", {duration = duration})
	-- EmitSoundOn("Jex.NatureQShieldStart", caster)
	EmitSoundOn("Jex.NatureQShieldStart2", caster)

	CustomAbilities:QuickAttachParticle("particles/units/heroes/hero_enchantress/enchantress_enchant.vpcf", caster, 4)

	caster:SetModifierStackCount("modifier_jex_nature_nature_shield_invisible", caster, tech_level)

	local q_4_level = caster:GetRuneValue("q", 4)
	if q_4_level > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_jex_oak_infusion_strength", {duration = duration})
		caster:SetModifierStackCount("modifier_jex_oak_infusion_strength", caster, q_4_level)
	end
	Filters:CastSkillArguments(1, caster)
end

function enemy_damage_jex_nature_nature_shield(event)
	local attacker = event.attacker
	local ability = event.ability
	local caster = event.caster

	local stun_per_tech = event.stun_per_tech
	local stun_duration = stun_per_tech * ability.tech_level
	if caster:GetTeamNumber() ~= attacker:GetTeamNumber() then
		Filters:ApplyStun(caster, stun_duration, attacker)
	end
end
