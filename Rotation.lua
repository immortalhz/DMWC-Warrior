local DMW = DMW
local Warrior = DMW.Rotations.WARRIOR
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Buff, Debuff, Spell, Stance, Target, Talent, Item, GCD, CDs, HUD, Enemy5Y, Enemy5YC, rageDanceCheck

local function Locals()
    Player = DMW.Player
    Buff = Player.Buffs
    Debuff = Player.Debuffs
    Spell = Player.Spells
    Talent = Player.Talents
    Item = Player.Items
    Target = Player.Target or false
    HUD = DMW.Settings.profile.HUD
    CDs = Player:CDs()
    Enemy5Y, Enemy5YC = Player:GetEnemies(5)

    if select(2,GetShapeshiftFormInfo(1)) then
        Stance = "Battle"
    elseif select(2,GetShapeshiftFormInfo(2)) then
        Stance = "Defense"
    else
        Stance = "Bers"
    end
    -- if Player.Talent:Rank("TacticalMastery") * 5 <= Player.Power then
    --     rageDanceCheck = true
    -- else
        rageDanceCheck = false
    -- end

end

-- local stanceCheckBattle = {
    
-- }

-- local stanceCheckDefence = {
    
-- }

-- local stanceCheckBers = {
    
-- }

-- local function stanceDanceCast(spell, Unit, stance)
--     if rageDanceCheck then
--         if stance == 1 then
--             if Spell.StanceBattle:Cast() then end
--         elseif stance == 2 then
--             if Spell.StanceDefense:Cast() then end
--         elseif stance == 3 then
--             if Spell.StanceBers:Cast() then end
--         end
--     else
--         return end
--     end
-- end

local function smartCast(spell, Unit)
    if stanceCheckBattle[spell] then
        if Stance == "Battle" then
            if Spell[spell]:Cast(Unit) then
                return true
            end
        else
            stanceDanceCast(spell, Unit, 1)
        end
    elseif stanceCheckDefence[spell] then
        if Stance == "Defense" then
            if Spell[spell]:Cast(Unit) then
                return true
            end
        else
            stanceDanceCast(spell, Unit, 2)
        end
    elseif stanceCheckBers[spell] then
        if Stance == "Bers" then
            if Spell[spell]:Cast(Unit) then
                return true
            end
        else
            stanceDanceCast(spell, Unit,3)
        end
    else
        if Spell[spell]:Cast(Unit) then
            return true
        end
    end
end

function Warrior.Rotation()
    
    Locals()
    if not (Target and Target.ValidEnemy) and #Enemy5Y >= 1 then
        TargetUnit(DMW.Attackable[1].unit)
    end
    if Target and Target.ValidEnemy then
        --aa
        -- print(Debuff.Rend:Remain(Target.Pointer))
        if not IsCurrentSpell(6603) then
            StartAttack(Target.Pointer)
        end
        if not Buff.BattleShout:Exist(Player) and Spell.BattleShout:Cast(Player) then
            return true
        end
        if Spell.Overpower:IsReady() then
            for _,Unit in ipairs(Enemy5Y) do
                if Spell.Overpower:Cast(Unit) then 
                    break
                end
            end
        end
        if Spell.Revenge:IsReady() then
            for _,Unit in ipairs(Enemy5Y) do
                if Spell.Revenge:Cast(Unit) then 
                    break
                end
            end
        end
        if Stance == "Battle" then
            if #Enemy5Y >= 2 then
                if Spell.ThunderClap:Cast() then
                    return true
                end
            end
        end
        --rend
        if #Enemy5Y >= 1 then 
            if Stance == "Defense" then
                if Spell.SunderArmor:IsReady() then
                    for _,Unit in ipairs(Enemy5Y) do
                        if not Debuff.SunderArmor:Exist(Unit) and Spell.SunderArmor:Cast(Unit) then
                            return true
                        end
                    end
                end
            end
            if Spell.Rend:IsReady() then
                for _,Unit in ipairs(Enemy5Y) do
                    if not Debuff.Rend:Exist(Unit) and Spell.Rend:Cast(Unit) then
                        return true
                    end
                end
            end

            -- if Spell.Taunt:IsReady() then
            -- end
        end
        -- DUMP
        if Player.Power >= Setting("Rage Dump") then
            if not IsCurrentSpell(285) then
                if Spell.HeroicStrike:IsReady() and Spell.HeroicStrike:Cast() then
                    return true
                end
            end
        end

        -- if Debuff.Rend:Refresh(Target) and Spell.Rend:Cast(Target) then
        --     return true
        -- end
    end
end