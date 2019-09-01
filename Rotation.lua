local DMW = DMW
local Warrior = DMW.Rotations.WARRIOR
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Buff, Debuff, Spell, Stance, Target, Talent, Item, GCD, CDs, HUD, Enemy5Y, Enemy5YC, Enemy14Y,Enemy14YC, rageDanceCheck

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
    Enemy5Y, Enemy5YC = Player:GetEnemies(1)
    Enemy14Y, Enemy14YC = Player:GetEnemies(14)

    if select(2,GetShapeshiftFormInfo(1)) then
        Stance = "Battle"
    elseif select(2,GetShapeshiftFormInfo(2)) then
        Stance = "Defense"
    else
        Stance = "Bers"
    end
    if Talent.TacticalMastery.Rank * 5 >= Player.Power then
        rageDanceCheck = true
    else
        rageDanceCheck = false
    end


end

local stanceCheckBattle = {
    ["Overpower"] = true,
    ["Hamstring"] = true,
    ["MockingBLow"] = true,
    ["Rend"] = true,
    ["Retaliation"] = true,
    ["SweepStrikes"] = true,
    ["ThunderClap"] = true,
    ["Charge"] = true,
    ["Execute"] = true,
    ["ShieldBash"] = true
}

local stanceCheckDefence = {
    ["Rend"] = true,
    ["Disarm"] = true,
    ["Revenge"] = true,
    ["ShieldBlock"] = true,
    ["ShieldBash"] = true,
    ["ShieldWall"] = true,
    ["Taunt"] = true
}

local stanceCheckBers = {
    ["BersRage"] = true,
    ["Hamstring"] = true,
    ["Intercept"] = true,
    ["Pummel"] = true,
    ["Recklessness"] = true,
    ["Whirlwind"] = true,
    ["Execute"] = true
}

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
local function tagger()
    if Setting("Tagger") then
        for _,Unit in ipairs(Enemy14Y) do
            if Unit.Quest then 
                TargetUnit(Unit.Pointer)
                if not IsCurrentSpell(Spell.Attack.SpellID) then
                    StartAttack()
                end
            end
        end
    end
end

local function questTagger()
    if Setting("questTagger") then
        for k,v in ipairs(DMW.Units) do
            print(v)
        end
    end
end

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
    tagger()
    questTagger()
    -- smartCast("Overpower")
    -- print(Player.SwingLeft)
    -- print(#TrackUnits)
    -- print(overpowerCheck)
    if Player.Instance == "party" then
        Player:AutoTarget(5, true)
    end
    if Setting("Stop If Shift") and GetKeyState(0x10) then
        return true
    end
    if Setting("Charge") and Target and Target.ValidEnemy then
        if Spell.Charge:Cast(Target) then
            return true
        end
    end
    if Setting("BattleShout") and not Buff.BattleShout:Exist(Player) and Spell.BattleShout:Cast(Player) then
        return true
    end
    --/dump UnitAttackSpeed("target")
    if Setting("Rotation") == 2 then
        if Player.Combat and Enemy5YC > 0 then
            if Target and Target.ValidEnemy and not IsCurrentSpell(6603) then
                StartAttack(Target.Pointer)
            end

            if Setting("AutoFaceMelee") then
                if Player.SwingLeft == 0 then

                    if DMW.Time > Player.SwingNext and DMW.Time > swingTime and IsCurrentSpell(6603) then
                        for _,Unit in ipairs(Enemy5Y) do
                            local Facing = ObjectFacing("player")
                            local MouselookActive = false
                            if IsMouselooking() then
                                MouselookActive = true
                                MouselookStop()
                            end
                            FaceDirection(Unit.Pointer, true)
                            FaceDirection(Facing, true)
                            if MouselookActive then
                                MouselookStart()
                            end
                            swingTime = DMW.Time + 0.1
                            
                        end
                    end
                end
            end
            if Setting("AutoExecute360") and Stance ~= "Defense" then
                for _,Unit in ipairs(Enemy5Y) do
                    if Unit.HP < 20 then
                        if Spell.Execute:Cast(Unit) then 
                            return true
                        end
                    end
                end
            end
            if Setting("BattleShout") and not Buff.BattleShout:Exist(Player) and Spell.BattleShout:Cast(Player) then
                return true
            end
            if Setting("DemoShout") > 0 then
                
                    local demoCount = 0
                    for i = 1, #Enemy14Y do
                        if not Debuff.DemoShout:Exist(Enemy14Y[i]) then
                            demoCount = demoCount + 1
                        end
                    end
                    if demoCount >= Setting("DemoShout") then
                        if Spell.DemoShout:Cast() then
                            return true
                        end
                    end

                -- print(demoCount)
                
            end

            if Setting("Overpower") and Spell.Overpower:IsReady() then
                for _,Unit in ipairs(Enemy5Y) do
                    if Spell.Overpower:Cast(Unit) then 
                        return true
                    end
                end
            end
            if Setting("Revenge") and Spell.Revenge:IsReady() then
                for _,Unit in ipairs(Enemy5Y) do
                    if Spell.Revenge:Cast(Unit) then 
                        return true
                    end
                end
            end
            if Setting("ThunderClap") and Stance == "Battle" then
                if Enemy5YC >= 3 then
                    if Spell.ThunderClap:Cast(Target) then
                        return true
                    end
                end
            end
            --rend
            if Enemy5YC >= 1 then 
                if Stance == "Defense" then
                    if Setting("SunderArmor") and Spell.SunderArmor:IsReady() then
                        for _,Unit in ipairs(Enemy5Y) do
                            if not Debuff.SunderArmor:Exist(Unit) and Spell.SunderArmor:Cast(Unit) then
                                return true
                            end
                        end
                    end
                end
                if Setting("Rend") and Stance ~= "Bers" and Spell.Rend:IsReady() then
                    for _,Unit in ipairs(Enemy5Y) do
                        if not Debuff.Rend:Exist(Unit) and Spell.Rend:Cast(Unit) and Unit.TTD >= 10 then
                            return true
                        end
                    end
                end

                -- if Spell.Taunt:IsReady() then
                -- end
            end
            -- DUMP
            if Player.Power >= Setting("Rage Dump") and Player.SwingLeft <= 0.2 then
                if not IsCurrentSpell(845) and not IsCurrentSpell(285) then
                    if Enemy5YC >= 2 and not Buff.SweepStrikes:Exist("player") then
                        if Spell.Cleave:IsReady() and Spell.Cleave:Cast() then
                            return true
                        end
                    else
                        if Spell.HeroicStrike:IsReady() and Spell.HeroicStrike:Cast() then
                            return true
                        end
                    end
                end
            end 
            

            -- if Debuff.Rend:Refresh(Target) and Spell.Rend:Cast(Target) then
            --     return true
            -- end
            -- if not DMW.Player.Target and Player.CombatLeftTime >= 6 then
            --     TargetUnit(Unit.Pointer)
            --     RunMacroText("/follow")
            -- end
        end
    elseif Setting("Rotation") == 3 then
        if Player.Combat then
            if not IsCurrentSpell(Spell.Attack.SpellID) then
                StartAttack()
            end
            if Setting("Overpower") and Player.overpowerTime ~= false and Spell.Overpower:IsReady() then
                for _,Unit in ipairs(Enemy5Y) do
                    if Unit.GUID == Player.overpowerUnit and Spell.Overpower:Cast(Unit) then
                        return true
                    end
                end
                return true
            end
            if Setting("AutoExecute360") and Stance ~= "Defense" then
                for _,Unit in ipairs(Enemy5Y) do
                    if Unit.HP < 20 and Spell.Execute:IsReady() then
                        if Spell.Execute:Cast(Unit) then 
                            return true
                        end
                        return true
                    end
                end
            end
------------------------------------------------------------------------- 3+ targets------------------------------------------------------------------------- 3+ targets------------------------------------------------------------------------- 3+ targets
            if Enemy5YC >= 3 then
                if Setting("SweepingStrikes") and Stance == "Battle" then
                    if Spell.SweepStrikes:Cast(Player) then
                        return true
                    end
                    if Player.Power < 30 and Spell.SweepStrikes:CD() == 0 then
                        return true
                    end
                end

                if Setting("Rend") and Stance ~= "Bers" and Spell.Rend:IsReady() then
                    for _,Unit in ipairs(Enemy5Y) do
                        if not Debuff.Rend:Exist(Unit) and Spell.Rend:Cast(Unit) and Unit.TTD >= 15 then
                            return true
                        end
                    end
                end

                if Setting("ThunderClap") and Stance == "Battle" then
                    if Spell.ThunderClap:Cast() then 
                        return true
                    end
                    if Player.Power < 20 and Spell.ThunderClap:CD() == 0 then
                        return true
                    end
                end

                if not IsCurrentSpell(Spell.Cleave.SpellID) then
                    if Spell.Cleave:IsReady() and Spell.Cleave:Cast() then
                        return true
                    end
                end
------------------------------------------------------------------------- 2 targets------------------------------------------------------------------------ 2 targets------------------------------------------------------------------------ 2 targets
            elseif Enemy5YC == 2 then
                if Setting("SweepingStrikes") and Stance == "Battle" then
                    if Spell.SweepStrikes:Cast() then
                        return true
                    end
                    if Player.Power < 30 and Spell.SweepStrikes:CD() == 0 then
                        return true
                    end
                end
                if Setting("Rend") and Stance ~= "Bers" and Spell.Rend:IsReady() then
                    for _,Unit in ipairs(Enemy5Y) do
                        if not Debuff.Rend:Exist(Unit) and Spell.Rend:Cast(Unit) and Unit.TTD >= 15 then
                            return true
                        end
                    end
                end
                if not IsCurrentSpell(Spell.Cleave.SpellID) then
                    if Spell.Cleave:IsReady() and Spell.Cleave:Cast() then
                        return true
                    end
                end
------------------------------------------------------------------------- 1 targets------------------------------------------------------------------------ 1 targets------------------------------------------------------------------------ 1 targets

            elseif Target and Target.ValidEnemy and Enemy5YC == 1 then 

                if Target.HP >= 50 then 
                    
                    
                    if Setting("Rend") and not Debuff.Rend:Exist(Target) and Spell.Rend:Cast(Target) and Target.TTD >= 10 then
                        return true
                    end
                    if Setting("SunderArmor") and Spell.SunderArmor:Cast(Target) then
                        return true
                    end
                else
                    if Setting("Hamstring Dump") and Spell.Hamstring:Cast(Target) then
                        return true
                    end
                end
            end 
        end
    end
end