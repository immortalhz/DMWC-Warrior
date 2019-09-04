local DMW = DMW
local Warrior = DMW.Rotations.WARRIOR
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Buff, Debuff, Spell, Stance, Target, Talent, Item, GCD, CDs, HUD, Enemy5Y, Enemy5YC, Enemy14Y,Enemy14YC, Enemy8Y, Enemy8YC, rageLost, dumpEnabled

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
    Enemy8Y, Enemy8YC = Player:GetEnemies(8)
    Enemy14Y, Enemy14YC = Player:GetEnemies(14)

    if select(2,GetShapeshiftFormInfo(1)) then
        Stance = "Battle"
    elseif select(2,GetShapeshiftFormInfo(2)) then
        Stance = "Defense"
    else
        Stance = "Bers"
    end
    
    rageLost = (Talent.TacticalMastery.Rank > 0 and Talent.TacticalMastery.Rank*5) or Player.Power
    dumpEnabled = false

end

local function cancelAAmod()
    if IsCurrentSpell(Spell.Cleave.SpellID) or IsCurrentSpell(Spell.HeroicStrike.SpellID) then
        SpellStopCasting()
    end
end 
local function dumpStart()
    return Player.Power >= Setting("Rage Dump") or dumpEnabled
end

local function dumpRage(value)
    if value >= 30 then
        if Spell.MortalStrike:Cast(Target) then return true end
    elseif value >= 20 then
            if Enemy5YC >= 2 then
                if Spell.ThunderClap:Cast(Target) then return true end
                if smartcast("cleavehs") then end
            end
            if Spell.Slam:Cast(Target) then return true end

    elseif value >= 15 then
        if Spell.Slam:Cast(Target) then return true end
    elseif value >= 10 then
        if Spell.Hamstring:Cast(Target) then return true end
    end
end
local function stanceDanceCast(spell, Unit, stance)
    if rageLost <= Setting("Rage Lost on stance change") then
        if stance == 1 then
            if Spell.StanceBattle:Cast() then end
        elseif stance == 2 then
            if Spell.StanceDefense:Cast() then end
        elseif stance == 3 then
            if Spell.StanceBers:Cast() then end
        end
    else
        if ((spell == "SweepStrikes" or spell == "Overpower") and Stance ~= "Battle") or
           ((spell == "Whirlwind") and Stance ~= "Bers") or
           ((spell == "Taunt") and Stance ~= "Defense") then
                dumpEnabled = true
                dumpRage(Player.Power-(Talent.TacticalMastery.Rank * 5))
        end
    end
end


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
        -- for k,v in ipairs(DMW.Units) do
        --     print(v)
        -- end
        Player:AutoTargetQuest(25)
    end
end

local function dpsAA()
    local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage = UnitDamage("player")
    local speed, offhandSpeed = UnitAttackSpeed("player")
    local apGain = UnitAttackPower("player") / 14
    return ((maxDamage + minDamage)/2/speed) + apGain
end
local function timeToCost(value)
    -- return Spell[spell].Cost()
    local deficit = value <= Player.Power and 0 or (value - Player.Power)
    local damageForOneRage = Player.Level * 0.5 -- = 1 rage
    local realGain = dpsAA() / damageForOneRage
    return math.floor(deficit,realGain)
    -- every UnitAttackSpeed("player") u get 1
end

local function smartCast(spell, Unit, pool)
    if spell == "cleavehs" then 
        if Enemy5YC >= 2 then
            if Spell.Cleave:IsReady() and Spell.Cleave:Cast() then
                return true
            end
        else
            if Spell.HeroicStrike:IsReady() and Spell.HeroicStrike:Cast() then
                return true
            end
        end 
    end
    if pool and Spell[spell]:Cost() > Player.Power then
        return true
    end
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
    -- print(Setting("Rage Lost on stance change"))
    -- print(Spell.Whirlwind:CD())
    -- smartCast("Overpower")
    -- print(Player.SwingLeft)
    -- print(overpowerCheck)
    if Player.Instance == "party" then
        if not Target or not Target.ValidEnemy then
            Player:AutoTarget(5, true)
        end
    end
    if Setting("Stop If Shift") and GetKeyState(0x10) then
        return true
    end
    if Setting("Charge") and Target and Target.ValidEnemy and not UnitIsTapDenied(Target.Pointer) then
        if smartCast("Charge", Target) then
            return true
        end
        if Spell.Intercept:IsReady() and smartCast("Intercept", Target) then
            return true
        end
        StartAttack()
    end
    if Setting("BattleShout") and not Buff.BattleShout:Exist(Player) then
        if Spell.BattleShout:Cast(Player) then
            return true
        end
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
                        if not Debuff.Rend:Exist(Unit) and Unit.TTD >= 10 and Spell.Rend:Cast(Unit) then
                            return true
                        end
                    end
                end

                -- if Spell.Taunt:IsReady() then
                -- end
            end
            -- DUMP
            if dumpStart() and Player.SwingLeft <= 0.2 then
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

-------------------------------------------------------------------------------------------------- soemthing lookalike elite rotation ---------------------------------------------------------------------------
    elseif Setting("Rotation") == 3 then
        if Player.Combat then
            if Target and Target.ValidEnemy and not IsCurrentSpell(Spell.Attack.SpellID) then
                StartAttack()
            end
            if Setting("Overpower") and #Player.OverpowerUnit > 0 then
                for _,Unit in ipairs(Enemy5Y) do
                   for i = 1, #Player.OverpowerUnit do
                        if Unit.GUID == Player.OverpowerUnit[i].overpowerUnit then
                            if smartCast("Overpower", Unit, true) then
                                return true
                            end
                        end
                    end 
                end
            end
            if Setting("AutoExecute360") then
                for _,Unit in ipairs(Enemy5Y) do
                    if Unit.HP < 20 then
                        local oldTarget = Target and Target.Pointer or false
                        TargetUnit(Unit.Pointer)
                        if smartCast("Execute", Target, true) then
                            if oldTarget ~= false then
                                TargetUnit(oldTarget)
                            end
                            return true
                        end
                    end
                end
            end
------------------------------------------------------------------------- 3+ targets------------------------------------------------------------------------- 3+ targets------------------------------------------------------------------------- 3+ targets
            if Enemy5YC >= 3 then
                cancelAAmod()
                if Setting("SweepingStrikes") and Enemy8YC >= 2 and Spell.SweepStrikes:CD() <= 2 then
                    if IsCurrentSpell(Spell.Cleave.SpellID) or IsCurrentSpell(Spell.HeroicStrike.SpellID) then
                        RunMacroText("/stopcasting")
                    end
                    if smartCast("SweepStrikes", Player, true) then
                        return true
                    end
                end

                if Setting("Whirlwind") and Spell.Whirlwind:CD() <= 3 and Enemy8YC > 0 then
                    if smartCast("Whirlwind", Player, true) then 
                        return true
                    end
                end

                if Setting("MortalStrike") and Spell.Whirlwind:CD() <= 2 and Enemy5YC > 0 then
                    if smartCast("MortalStrike", Target, true) then 
                        return true
                    end
                end 
------------------------------------------------------------------------- 2 targets------------------------------------------------------------------------ 2 targets------------------------------------------------------------------------ 2 targets
            elseif Enemy5YC == 2 then
                cancelAAmod()
                if Setting("SweepingStrikes") and Enemy8YC >= 2 and Spell.SweepStrikes:CD() <= 2 then
                    if IsCurrentSpell(Spell.Cleave.SpellID) or IsCurrentSpell(Spell.HeroicStrike.SpellID) then
                        RunMacroText("/stopcasting")
                    end
                    if smartCast("SweepStrikes", Player, true) then
                        return true
                    end
                end

                if Setting("Whirlwind") and Spell.Whirlwind:CD() <= 3 and Enemy8YC > 0 then
                    if smartCast("Whirlwind", Player, true) then 
                        return true
                    end
                end

                if Setting("MortalStrike") and Spell.Whirlwind:CD() <= 2 and Enemy5YC > 0 then
                    if smartCast("MortalStrike", Target, true) then 
                        return true
                    end
                end 
                if not IsCurrentSpell(Spell.Cleave.SpellID) and dumpStart() then
                    if Spell.Cleave:IsReady() and Spell.Cleave:Cast() then
                        return true
                    end
                end
------------------------------------------------------------------------- 1 targets------------------------------------------------------------------------ 1 targets------------------------------------------------------------------------ 1 targets
            elseif Target and Target.ValidEnemy and Enemy5YC == 1 then
                cancelAAmod() 
                -- if Debuff.Rend:Refresh(Target) then
                --     print(Debuff.Rend:Remain(Target))
                -- end
                
                if Setting("Rend") and not Debuff.Rend:Exist(Target) and Target.CreatureType ~= "Elemental" and Target.TTD >= 10 then
                    smartCast("Rend", Target, true)
                end
                if Setting("SunderArmor") and (Debuff.SunderArmor:Stacks(Target) < 5 or Debuff.SunderArmor:Refresh(Target)) and Spell.SunderArmor:Cast(Target) then
                    return true
                end
                if smartCast("MortalStrike", Target, true) then
                    return true
                end
                if smartCast("Whirlwind", Target, true) then
                    return true
                end
                if not IsCurrentSpell(Spell.HeroicStrike.SpellID) and dumpEnabled then
                    if Spell.HeroicStrike:IsReady() and Spell.HeroicStrike:Cast() then
                        return true
                    end
                end
            end  --enemies

            if (Player.Power - rageLost) >= Setting("Rage Lost on stance change") then
                local dumpRageValue = (Player.Power - rageLost)
                
                if Enemy5YC >= 2 then
                    if not IsCurrentSpell(Spell.Cleave.SpellID) then
                        if Spell.Cleave:Cast() then end
                    end
                else
                    if not IsCurrentSpell(Spell.HeroicStrike.SpellID) then
                        if Spell.HeroicStrike:Cast() then end
                    end
                end

                if IsCurrentSpell(Spell.Cleave.SpellID) then dumpRageValue = dumpRageValue - 20 end
                if IsCurrentSpell(Spell.HeroicStrike.SpellID) then dumpRageValue = dumpRageValue - 15 end
            end   
        end--combat
    elseif Setting("Rotation") == 1 then
        Spell.Slam:Cast(Target)
        if smartCast("Whirlwind", Player) then return true end
    end--rotation setting
end