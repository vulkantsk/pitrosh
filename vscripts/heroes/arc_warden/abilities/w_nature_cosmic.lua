require('heroes/arc_warden/abilities/onibi')

function jex_nature_cosmic_toggled_on(event)
	local caster = event.caster
	local ability = event.ability
	ability.tech_level = onibi_get_total_tech_level(caster, "nature", "cosmic", "W")

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_jex_nature_cosmic_movespeed", {})
	caster:SetModifierStackCount("modifier_jex_nature_cosmic_movespeed", caster, ability.tech_level)

	local q_4_level = caster:GetRuneValue("q", 4)
	if q_4_level > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_jex_nature_cosmic_w_max_mana", {})
		caster:SetModifierStackCount("modifier_jex_nature_cosmic_w_max_mana", caster, q_4_level)
	end

	EmitSoundOn("Jex.Equilibrium.Activate", caster)
	StartAnimation(caster, {duration = 0.3, activity = ACT_DOTA_OVERRIDE_ABILITY_4, rate = 1.5})

	ability.e_4_level = caster:GetRuneValue("e", 4)
	local attack_damage_buff = ability:GetSpecialValueFor("attack_damage")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_jex_nature_cosmic_attack_damage", {})
	caster:SetModifierStackCount("modifier_jex_nature_cosmic_attack_damage", caster, attack_damage_buff)
end

function jex_nature_cosmic_toggled_off(event)
	local caster = event.caster
	local ability = event.ability
	caster:RemoveModifierByName("modifier_jex_nature_cosmic_movespeed")
	caster:RemoveModifierByName("modifier_jex_nature_cosmic_w_max_mana")
	caster:RemoveModifierByName("modifier_jex_nature_cosmic_attack_damage")
end

function nature_cosmic_w_think(event)
	local caster = event.caster
	local ability = event.ability
	local mana_usage = event.mana_drain_per_second
	mana_usage = math.max(mana_usage - event.e_4_mana_drain_per_second_reduction * ability.e_4_level, 0)
	if mana_usage > caster:GetMana() then
		ability:ToggleAbility()
	end
	caster:ReduceMana(mana_usage)
end
