local DMW = DMW
local Warrior = DMW.Rotations.WARRIOR
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Buff, Debuff, Spell, Stance, Target, Talent, Item, GCD, CDs, HUD, EnemyMelee, EnemyMeleeCount, Enemy14Y,Enemy14YC, Enemy8Y, Enemy8YC, rageLost, dumpEnabled, castTime, syncSS, combatLeftCheck, forcedStance

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
    EnemyMelee, EnemyMeleeCount = Player:GetEnemies(1)
    Enemy8Y, Enemy8YC = Player:GetEnemies(8)
    Enemy14Y, Enemy14YC = Player:GetEnemies(14)
    if select(2,GetShapeshiftFormInfo(1)) then
        Stance = "Battle"
    elseif select(2,GetShapeshiftFormInfo(2)) then
        Stance = "Defense"
    else
        Stance = "Bers"
    end
    if Setting("Stance") > 1 then
        if Setting("Stance") == 2 then
            forcedStance = "Battle"
        elseif Setting("Stance") == 3 then
            forcedStance = "Defense"
        elseif Setting("Stance") == 4 then
            forcedStance = "Bers"
        end
    else
        forcedStance = nil
    end
    if castTime == nil then castTime = DMW.Time end
    rageLost = Player.Power - Talent.TacticalMastery.Rank*5
    dumpEnabled = false
    syncSS = false
    if HUD.Sweeping == 1 and Buff.SweepStrikes:Exist(Player) then DMWHUDSWEEPING:Toggle(2) end
    -- if combatLeftCheck == nil and Player.CombatLeft > 0 then combatLeftCheck = false end
    -- print(Player.CombatLeft)
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
    -- print(value)
    if value >= 30 then
        if Spell.MortalStrike:Cast(Target) then return true end
    elseif value >= 20 then
            if EnemyMeleeCount >= 2 then
                if Spell.ThunderClap:Cast(Target) then return true end
                -- if smartCast("cleavehs") then end
            end
            -- if Spell.Slam:Cast(Target) then return true end

    -- elseif value >= 15 then
    --     if Spell.Slam:Cast(Target) then return true end
    elseif value >= 10 then
        if Spell.Hamstring:Cast(Target) then return true end
    end
end

local function stanceDanceCast(spell, dest, stance)
    if rageLost <= Setting("Rage Lost on stance change") then
        -- print("spell = "..tostring(spell).." , Unit = ".. tostring(dest) .. " , stance = "..tostring(stance))
        if stance == 1 then
            if Spell.StanceBattle:IsReady() then
                if Spell.StanceBattle:Cast() then return true  end
            end
        elseif stance == 2 then
            if Spell.StanceDefense:IsReady() then
                if Spell.StanceDefense:Cast() then return true  end
            end
        elseif stance == 3 then
            if Spell.StanceBers:IsReady() then
                if Spell.StanceBers:Cast() then return true end
            end
        end
    else
        dumpRage(rageLost)
    end
end

local function tagger()
    if Setting("Tagger") then
        if Setting("Tag Quest Hostile") and not Target then
            if Player:AutoTargetQuest(5) then
                if Target and Target.Quest and not Target.Facing then
                    FaceDirection(Target.Pointer, true)
                end
                RunMacroText("/startattack")
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

local function regularCast(spell, Unit, pool)
    if pool and Spell[spell]:Cost() > Player.Power then
        
        return true
    end
    if Spell[spell]:Cast(Unit) then
        return true
    end
end

local function forceStance(spell)
    if forcedStance and forcedStance ~= Stance then
        if forcedStance == "Bers" and (stanceCheckBers[spell] or (stanceCheckBattle[spell] == nil and stanceCheckDefence[spell] == nil)) then
            if Spell.StanceBers:IsReady() then
                Spell.StanceBers:Cast()
            else
                return true
            end
        elseif forcedStance == "Defense" and (stanceCheckDefence[spell] or (stanceCheckBattle[spell] == nil and stanceCheckBers[spell] == nil)) then
            if Spell.StanceDefense:IsReady() then
                Spell.StanceDefense:Cast()
            else
                return true
            end
        elseif forcedStance == "Battle" and (stanceCheckBattle[spell] or (stanceCheckBers[spell] == nil and stanceCheckDefence[spell] == nil)) then
            if Spell.StanceBattle:IsReady() then
                Spell.StanceBattle:Cast()
            else
                return true
            end
        end
    end
end

local function smartCast(spell, Unit, pool)
    -- if spell == "cleavehs" then 
    --     if Enemy5YC >= 2 then
    --         if Spell.Cleave:IsReady() and Spell.Cleave:Cast() then
    --             return true
    --         end
    --     else
    --         if Spell.HeroicStrike:IsReady() and Spell.HeroicStrike:Cast() then
    --             return true
    --         end
    --     end 
    -- end
    if pool and Spell[spell]:Cost() > Player.Power then
        if spell == "SweepStrikes" and Stance ~= "Battle" then
            if Spell.StanceBattle:IsReady() then
                Spell.StanceBattle:Cast()
            else
                return true
            end
        elseif spell == "Whirlwind" then
            if Stance ~= "Bers" then
                if Spell.StanceBers:IsReady() then
                    Spell.StanceBers:Cast()
                else
                    return true
                end
            end
        end
        if forceStance(spell) then return true end
        if Setting("Berserker Rage") then
            local count = 0
            for _, Unit in ipairs(DMW.Enemies) do
                if Player:IsTanking(Unit) then
                    count = count + 1
                    if count > 0 and count >= Setting("Berserker Rage") then
                        if Spell.BersRage:IsReady() then
                            Spell.BersRage:Cast()
                        end
                    end
                end
            end
        end
        return true
    else
        castTime = DMW.Time
        if forcedStance then
            if forceStance(spell) then return true end
        end
        if Stance == "Battle" then
            if not stanceCheckBattle[spell] then
                if stanceCheckDefence[spell] then
                    if stanceDanceCast(spell, Unit, 2) then return true end
                elseif stanceCheckBers[spell] then
                    if stanceDanceCast(spell, Unit, 3) then return true end
                else
                    if Spell[spell]:Cast(Unit) then return true end
                end
            else
                if Spell[spell]:Cast(Unit) then return true end
            end
        elseif Stance == "Defense" then
            if not stanceCheckDefence[spell] then
                if stanceCheckBattle[spell] then
                    if stanceDanceCast(spell, Unit, 1) then return true end
                elseif stanceCheckBers[spell] then
                    if stanceDanceCast(spell, Unit, 3) then return true end
                else
                    if Spell[spell]:Cast(Unit) then return true end
                end
            else
                if Spell[spell]:Cast(Unit) then return true end
            end
        elseif Stance == "Bers" then
            if not stanceCheckBers[spell] then
                if stanceCheckBattle[spell] then
                    if stanceDanceCast(spell, Unit, 1) then return true end
                elseif stanceCheckDefence[spell] then
                    if stanceDanceCast(spell, Unit, 2)  then return true end
                else
                    if Spell[spell]:Cast(Unit) then return true end
                end
            else
                if Spell[spell]:Cast(Unit) then return true end
            end
        end
    end
end

local function bersCheck()
    if Setting("Berserker Rage") then
        local count = 0
        for _, Unit in ipairs(DMW.Enemies) do
            if Player:IsTanking(Unit) then
                count = count + 1
                if count > 0 and count >= Setting("Berserker Rage") then
                    if smartCast("BersRage") then return true end
                end
            end
        end
    end
end


blizzardshit = true
abuseOH = false
local assistUnit

local function targetassist()
end

local function AutoExecute()
    if Setting("AutoExecute360") then
        for _,Unit in ipairs(EnemyMelee) do
            if Unit.HP < 20 and not Unit.Dead then
                -- print("exec")
                -- local oldTarget = Target and Target.Pointer or false
                -- TargetUnit(Unit.Pointer)
                if smartCast("Execute", Unit, true) then 
                    return true
                end
            end
        end
    end
end

local function AutoOverpower()
    if Setting("Overpower")  then
        for _,Unit in ipairs(EnemyMelee) do
            if Player.OverpowerUnit[Unit.Pointer] ~= nil then
                if smartCast("Overpower", Unit, true) then
                    return true
                end
            end
        end
    end
end

local function AutoBuff()
    if Setting("BattleShout") and not Buff.BattleShout:Exist(Player) then
        if Spell.BattleShout:Cast(Player) then
            return true
        end
    end
end

function Warrior.Rotation()
    Locals()
    -- tagger()
    -- questTagger()
    if Setting("BattleStance NoCombat") and Player.CombatLeft  then
        if Stance ~= "Battle" then
            if Spell.StanceBattle:IsReady() then
                Spell.StanceBattle:Cast()
            else
                return  true
            end
        end
    end
    if Setting("Assist Use") then
        if Setting("Charge") and Target and Target.Distance >= 8 and Target.Distance < 25 and UnitIsTapDenied(Target.Pointer) and not Target.Dead then
            
            if not Player.Combat and Spell.Charge:CD() == 0 then
                -- print("trying shit")
                if smartCast("Charge", Target) then return end
            elseif Spell.Intercept:CD() == 0 and Player.Power >= 10 and not Spell.Charge:LastCast() then
                if Spell.Charge:Cast(Target) then return end
            end
        end


        if Target and GetUnitName("targettarget") == "Ivymadison" and Player.Combat and Target.Distance == 0 then
            if Spell.Taunt:CD() <= 0 then
                -- print("taunt")
                if smartCast("Taunt", Target) then return end
            end
            if Spell.SunderArmor:Cast(Target) then
                -- print("SunderArmor")
                return
            end
        end
    end
    -- if DMW.Tables.AuraCache[Target.Pointer]["Charge Stun"] ~= nil then print("123") end
    -- print(ObjectDescriptor("target", GetOffset("CGUnitData__StateAnimKitID"), Types.Byte))
    -- if ChannelInfo("player") then
    --     print("bad code")
    -- end

    -- if Target then
    --     print(Target.SwingMH)
    -- end
    -- if Target then print(Target.SwingMH) end
    -- if Player.Standing then
    --     blizzardshit = true
    -- end
    -- if Target and Target.ValidEnemy and Player.Combat and blizzardshit  then
    --     if Target.SwingMH < Player.SwingMH and Target.SwingMH > 0.01 and Player.SwingMH > 0.01 then
    --         print("sit")
    --         RunMacroText("/sit")
    --         blizzardshit = false
    --         -- SitStandOrDescendStart()
    --     end
    -- end
    -- if not Player.Standing() then
    --     RunMacroText("/stand")
    -- end
    -- if select(8, ChannelInfo("player")) == 9632 then
    --     print("123")
    --     SpellStopCasting()
    -- end
    if Setting("abuse") and Player.Combat then
        if DMW.Tables.Swing.Player.HasOH then
            local hsQueued = IsCurrentSpell(11565)
            if Player.SwingOH < Player.SwingMH - 0.15 then
                if not hsQueued then
                    RunMacroText("/cast Heroic Strike")
                    abuseOH = true
                end
            
            else
                if hsQueued then
                    SpellStopCasting()
                    abuseOH = false
                end
            end
            -- if Player.SwingMH < 0.2 and abuseOH and IsCurrentSpell(11565) then
            --     SpellStopCasting()
            --     abuseOH = false
            --     print("cancel hs")
            -- else
            --     if Player.Power >= 13 and not IsCurrentSpell(11565) and Player.SwingOH < Player.SwingMH and Player.SwingOH < 0.2 then
            --         abuseOH = true
            --         RunMacroText("/cast heroic strike")
            --         print("queue hs")
            --     else
            --         if Player.SwingOH > 0.2 and abuseOH then
            --             SpellStopCasting()
            --             abuseOH = false
            --         end
            --     end
            -- end
        end
    end
    
    -- if Player.Combat then return true end
    if DMW.Time <= castTime + 0.3 then return true end
    -- if Stance == "Defense" then Spell.StanceBers:Cast() end
    -- print(Setting("Rage Lost on stance change"))
    -- print(Spell.Whirlwind:CD())
    -- smartCast("Overpower")
    -- print(Player.SwingLeft)
    -- print(addon_data.player.main_swing_timer)
    -- print(overpowerCheck)
    -- if Player.Instance == "party" then
    -- if not Target or not Target.Facing or Target.Distance > 0 then
    --     Player:AutoTargetAny(0, true)
    -- end
    -- end
    if Setting("Stop If Shift") and GetKeyState(0x10) then
        return true
    end
    if Setting("Charge") and not Setting("Assist Use") and Target and not Target.Dead and Target.Distance > 8 and Target.Distance < 25 and not UnitIsTapDenied(Target.Pointer) then
        if not Player.Combat then
            if smartCast("Charge", Target) then return true end
        end
        if Spell.Intercept:CD() == 0 then
            if smartCast("Intercept", Target) then return true end
        end
        StartAttack()
    end
    if Setting("AutoFaceMelee") then
        if Player.Combat and Target and Target.Distance == 0 and not Target.Facing then
            FaceDirection(Target.Pointer, true)
        end
    end
        -- if Target and not Target:IsTanking() then
                
        --     if Spell.SunderArmor:Cast(Target) then
        --         print("SunderArmor")
        --         return
        --     end
        -- end
    -- if Setting("BattleShout") and not Buff.BattleShout:Exist(Player) then
    --     if Spell.BattleShout:Cast(Player) then
    --         return true
    --     end
    -- end
    if Setting("Berserker Rage") then
        local count = 0
        for _, Unit in ipairs(DMW.Enemies) do
            if Player:IsTanking(Unit) then
                count = count + 1
                if count > 0 and count >= Setting("Berserker Rage") then
                    if smartCast("BersRage") then return true end
                end
            end
        end
    end

    --/dump UnitAttackSpeed("target")
    if Setting("Rotation") == 3 then
        if Player.Combat and EnemyMeleeCount > 0 then
            if Target and Target.ValidEnemy and not IsCurrentSpell(Spell.Attack.SpellID) then
                StartAttack()
            end
            -- if Setting("Stance") == 2 and Stance ~= "Defense" then
            --     if Spell.StanceDefense:IsReady() then
            --         Spell.StanceDefense:Cast()
            --     else
            --         return true
            --     end
            -- elseif Setting("Stance") == 3 and Stance ~= "Bers" then
            --     if Spell.StanceBers:IsReady() then
            --         Spell.StanceBers:Cast()
            --     else
            --         return true
            --     end

            -- end
            if Setting("Pummel") and Target and Target:Interrupt() then
                smartCast("Pummel", Target, true)
            end
            if Enemy8YC >= 2 then
                if Setting("SweepingStrikes") and Enemy8YC >= 2 and Spell.SweepStrikes:CD() <= 2 and HUD.Sweeping == 1 then
                    -- if IsCurrentSpell(Spell.Cleave.SpellID) or IsCurrentSpell(Spell.HeroicStrike.SpellID) then
                        -- RunMacroText("/stopcasting")
                    -- end
                    syncSS = true
                    if smartCast("SweepStrikes", Player, true) then syncSS = nil; return true end
                end

                if Setting("Bloodrage") and syncSS and Player.Power < 25 then
                    if Spell.Bloodrage:IsReady() then
                        syncSS = false
                        Spell.Bloodrage:Cast()
                    end
                end

                if Setting("Whirlwind") and Spell.Whirlwind:CD() <= 3  then
                    if smartCast("Whirlwind", Player, true) then return true end
                end

                AutoOverpower()

                AutoBuff()
                
                AutoExecute()
                
                if Setting("Cleave") and Spell.Cleave:CD() <= 3 then
                    if smartCast("Cleave", Player, true) then return true end
                end

                if Setting("MS/BT") and Target and Spell.Whirlwind:CD() >= 2 and EnemyMeleeCount > 0 then
                    if smartCast("MortalStrike", Target, true) then return true end
                    if smartCast("BloodThirst", Target, true) then return true end
                end 
            else
                if Target and Target.ValidEnemy then
                    AutoOverpower()

                    AutoBuff()

                    if Setting("SunderArmor") and Target.HP >= Setting("SunderArmor") then
                        if Debuff.SunderArmor:Stacks(Target) < 5 or Debuff.SunderArmor:Refresh(Target) then
                            if smartCast("SunderArmor", Target, true) then return true end
                        end
                    end

                    AutoExecute()

                    if Setting("MortalStrike") and Spell.MortalStrike:CD() <= 3 then
                        if smartCast("MortalStrike", Target, true) then return true end
                    end

                    -- if Spell.Bloodthirst:CD() <= 3 and smartCast("Bloodthirst", Target, true) then
                    --     return 
                    -- end

                    if Setting("Whirlwind") and Enemy8YC > 0 and (Spell.MortalStrike:CD() >= 3 or Player.Power >= 40) then
                        if smartCast("Whirlwind", Player, true) then return true end
                    end
                else
                    AutoBuff()
                    AutoOverpower()
                    AutoExecute()
                end
            end

            
            -- if Setting("Berserker Rage") then
            --     for _, Unit in ipairs(DMW.Enemies)
            -- end
            -- if (Player.Power - rageLost) >= Setting("Rage Lost on stance change") then
            --     local dumpRageValue = (Player.Power - rageLost)
                
            --     if Enemy5YC >= 2 and dumpRageValue >= 20 then
            --         if not IsCurrentSpell(Spell.Cleave.SpellID) then
            --             if Spell.Cleave:Cast() then end
            --         end
            --     else
            --         if not IsCurrentSpell(Spell.HeroicStrike.SpellID) then
            --             if Spell.HeroicStrike:Cast() then end
            --         end
            --     end

            --     if IsCurrentSpell(Spell.Cleave.SpellID) then dumpRageValue = dumpRageValue - 20 end
            --     if IsCurrentSpell(Spell.HeroicStrike.SpellID) then dumpRageValue = dumpRageValue - 15 end
            -- end   
        end--combat
    end--rotation setting
end