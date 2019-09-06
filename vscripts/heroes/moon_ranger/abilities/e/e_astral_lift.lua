require('heroes/moon_ranger/init')
require('heroes/moon_ranger/astral_arcana_ability')
require('heroes/moon_ranger/moon_shroud')

local pegasus = require('heroes/moon_ranger/abilities/e/e1_pegasus')
local astralEmpowerment = require('heroes/moon_ranger/abilities/e/e2_astral_empowerment')
local astralShroud = require('heroes/moon_ranger/abilities/e/e3_astral_shroud')

function precast(event)
    local caster = event.caster
    StartAnimation(caster, {duration = 0.5, activity = ACT_DOTA_CAST_ABILITY_3, rate = 1.3})
end

function cast(event)
    local caster = event.caster
    Helper.initializeAbilityRunes(event.caster, 'astral', 'w')
    Helper.initializeAbilityRunes(event.caster, 'astral', 'e')
    Helper.initializeAbilityRunes(event.caster, 'astral', 'r')

    local ability = event.ability
    if caster:HasModifier("modifier_astral_glyph_4_1") then
        local cd = ability:GetCooldown(ability:GetLevel()) / 2
        ability:EndCooldown()
        ability:StartCooldown(cd)
    end

    local target = event.target_points[1]
    target = WallPhysics:WallSearch(caster:GetAbsOrigin(), target, caster)

    local delay = E_DELAY
    if caster:HasModifier("modifier_astral_glyph_4_1") then
        delay = delay / 2
    end
    delay = Filters:GetAdjustedESpeed(caster, delay, true)
    EmitSoundOn("Astral.StarBlink.SpellStart", caster)
    local particleName = E_PARTICLE1
    local particleLocation = target
    local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle1, 0, particleLocation)
    -- EmitSoundOn("Hero_Invoker.SunStrike.Ignite", caster)

    Timers:CreateTimer(0.35, function()

        EmitSoundOnLocationWithCaster(target, "Hero_Invoker.SunStrike.Ignite", caster)
    end)
    CustomAbilities:QuickParticleAtPoint("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", target, 0.35)
    Timers:CreateTimer(delay, function()
        -- ability:ApplyDataDrivenModifier(caster, caster, "modifier_astral_e_lift_moving", {duration = 0.3})
        ParticleManager:DestroyParticle(particle1, false)
        particleName = E_PARTICLE2

        local particle2 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())

        local particle3 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(particle3, 0, target)

        EmitSoundOn("Astral.BlinkMovement", caster)
        FindClearSpaceForUnit(caster, target, true)

        ProjectileManager:ProjectileDodge(caster)
        Timers:CreateTimer(2, function()
            ParticleManager:DestroyParticle(particle2, false)
            ParticleManager:DestroyParticle(particle3, false)
        end)
        if caster:HasModifier("modifier_astral_arcana_on_platform") then
            arcana_star_blink_move(caster, ability)
        elseif caster:HasModifier("modifier_moon_shroud_buff") then
            moon_shroud_move(caster, target)
        end
        -- dustParticle(caster:GetAbsOrigin(), caster)
    end)
    astralEmpowerment.hitUnitsAndApplyMidifier(caster, ability, target)
    pegasus.createPegasus(caster, ability, caster:GetAbsOrigin(), target, delay)
    astralShroud.cast(caster, ability)

    Filters:CastSkillArguments(3, caster)
    Timers:CreateTimer(0.2, function()
        dustParticle(target, caster)
    end)

    local particle = "particles/units/heroes/hero_drow/drow_marksmanship_frost_arrow.vpcf"
    local arrowPFX = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(arrowPFX, 0, caster:GetAttachmentOrigin(1) + Vector(0, 0, 20))
    ParticleManager:SetParticleControl(arrowPFX, 1, caster:GetAttachmentOrigin(1) + Vector(0, 0, 2000))
    ParticleManager:SetParticleControl(arrowPFX, 2, Vector(5000, 5000, 5000))
    Timers:CreateTimer(1, function()
        ParticleManager:DestroyParticle(arrowPFX, false)
    end)
end

function dustParticle(position, caster)
    local pfx2 = ParticleManager:CreateParticle("particles/roshpit/mountain_protector/unshakable_stone_dust.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(pfx2, 0, position)
    ParticleManager:SetParticleControl(pfx2, 5, Vector(0.3, 0.3, 0.9))
    ParticleManager:SetParticleControl(pfx2, 2, Vector(0.15, 0.15, 0.15))
    Timers:CreateTimer(0.8, function()
        ParticleManager:DestroyParticle(pfx2, false)
    end)
end

function damage(event)
    local target = event.target
    local caster = event.caster
    local damage = event.damage
    local stun_duration = event.stun_duration
    Filters:ApplyStun(caster, stun_duration, target)
    Filters:TakeArgumentsAndApplyDamage(target, caster, damage, DAMAGE_TYPE_PURE, BASE_ABILITY_E, RPC_ELEMENT_COSMOS, RPC_ELEMENT_NONE)
end
