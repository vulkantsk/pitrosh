require('/heroes/monkey_king/constants')

function draghor_main_think(event)
	local caster = event.caster
	local catAbility = caster:FindAbilityByName("draghor_shapeshift_cat")
	if catAbility then
		if not caster:HasModifier("modifier_mark_of_the_fang") then
			catAbility:SetActivated(false)
		end
	end
	local bearAbility = caster:FindAbilityByName("draghor_shapeshift_bear")
	if bearAbility then
		if not caster:HasModifier("modifier_mark_of_the_claw") then
			bearAbility:SetActivated(false)
		end
	end
	local crowAbility = caster:FindAbilityByName("draghor_shapeshift_crow")
	if crowAbility then
		if not caster:HasModifier("modifier_mark_of_the_talon") then
			crowAbility:SetActivated(false)
		end
	end
	if caster.q3_level > 0 then
		local durationIncrease = 0.3 + DJANGHOR_Q3_BUFF_DURATION_INCREASE * caster.q3_level
		Filters:ExtendBuffsDurationOnTarget(caster, 'djanghor_rune_q3', 0, durationIncrease)
	end
end

function mark_of_the_fang(event)
	local caster = event.caster
	local ability = event.ability

	local catAbility = caster:FindAbilityByName("draghor_shapeshift_cat")
	if catAbility then
		if not catAbility:IsActivated() then
			catAbility:SetActivated(true)
		end
	end
	caster:RemoveModifierByName("modifier_mark_of_the_claw")
	caster:RemoveModifierByName("modifier_mark_of_the_claw_rune")
	caster:RemoveModifierByName("modifier_mark_of_the_talon")
	caster:RemoveModifierByName("modifier_mark_of_the_talon_rune")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_mark_of_the_fang", {})

	CustomAbilities:AddAndOrSwapSkill(caster, "draghor_mark_of_the_fang", "draghor_mark_of_the_claw", 0)
	if not caster:HasModifier("modifier_djanghor_arcana1") then
		if caster:HasAbility("draghor_shapeshift_crow") then
			CustomAbilities:AddAndOrSwapSkill(caster, "draghor_shapeshift_crow", "draghor_shapeshift_cat", DOTA_R_SLOT)
		end
	end

	EmitSoundOn("Draghor.MarkBG.Med", caster)

	StartAnimation(caster, {duration = 0.64, activity = ACT_DOTA_MK_FUR_ARMY, rate = 1.0})

	ability.q_4_level = caster:GetRuneValue("q", 4)
	if ability.q_4_level > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mark_of_the_fang_rune", {})
		caster:SetModifierStackCount("modifier_mark_of_the_fang_rune", caster, ability.q_4_level)
	end
end

function mark_of_the_claw(event)
	local caster = event.caster
	local ability = event.ability

	local bearAbility = caster:FindAbilityByName("draghor_shapeshift_bear")
	if bearAbility then
		if not bearAbility:IsActivated() then
			bearAbility:SetActivated(true)
		end
	end
	caster:RemoveModifierByName("modifier_mark_of_the_fang")
	caster:RemoveModifierByName("modifier_mark_of_the_fang_rune")
	caster:RemoveModifierByName("modifier_mark_of_the_talon")
	caster:RemoveModifierByName("modifier_mark_of_the_talon_rune")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_mark_of_the_claw", {})

	CustomAbilities:AddAndOrSwapSkill(caster, "draghor_mark_of_the_claw", "draghor_mark_of_the_talon", 0)
	if not caster:HasModifier("modifier_djanghor_arcana1") then
		CustomAbilities:AddAndOrSwapSkill(caster, "draghor_shapeshift_cat", "draghor_shapeshift_bear", DOTA_R_SLOT)
	end
	EmitSoundOn("Draghor.MarkBG.Low", caster)

	StartAnimation(caster, {duration = 0.64, activity = ACT_DOTA_MK_FUR_ARMY, rate = 1.0})

	ability.q_4_level = caster:GetRuneValue("q", 4)
	if ability.q_4_level > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mark_of_the_claw_rune", {})
		caster:SetModifierStackCount("modifier_mark_of_the_claw_rune", caster, ability.q_4_level)
	end
end

function mark_of_the_talon(event)
	local caster = event.caster
	local ability = event.ability

	local crowAbility = caster:FindAbilityByName("draghor_shapeshift_crow")
	if crowAbility then
		if not crowAbility:IsActivated() then
			crowAbility:SetActivated(true)
		end
	end
	caster:RemoveModifierByName("modifier_mark_of_the_fang")
	caster:RemoveModifierByName("modifier_mark_of_the_fang_rune")
	caster:RemoveModifierByName("modifier_mark_of_the_claw")
	caster:RemoveModifierByName("modifier_mark_of_the_claw_rune")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_mark_of_the_talon", {})

	CustomAbilities:AddAndOrSwapSkill(caster, "draghor_mark_of_the_talon", "draghor_mark_of_the_fang", 0)
	if not caster:HasModifier("modifier_djanghor_arcana1") then
		CustomAbilities:AddAndOrSwapSkill(caster, "draghor_shapeshift_bear", "draghor_shapeshift_crow", DOTA_R_SLOT)
	end
	EmitSoundOn("Draghor.MarkBG.High", caster)

	StartAnimation(caster, {duration = 0.64, activity = ACT_DOTA_MK_FUR_ARMY, rate = 1.0})

	ability.q_4_level = caster:GetRuneValue("q", 4)
	if ability.q_4_level > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mark_of_the_talon_rune", {})
		caster:SetModifierStackCount("modifier_mark_of_the_talon_rune", caster, ability.q_4_level)
	end
end

function draghor_attack_land(event)
	local attacker = event.attacker
	local target = event.target
	if target.dummy then
		return false
	end
	local w_1_level = attacker:GetRuneValue("w", 1)
	if w_1_level > 0 then
		local damage = event.damage * DJANGHOR_W1_DAMAGE_MULT * w_1_level
		Filters:TakeArgumentsAndApplyDamage(target, attacker, damage, DAMAGE_TYPE_MAGICAL, BASE_ABILITY_W, RPC_ELEMENT_NATURE, RPC_ELEMENT_NONE)
		CustomAbilities:QuickAttachParticle("particles/units/heroes/hero_venomancer/venomancer_venomous_gale_impact.vpcf", target, 0.4)
	end
end
