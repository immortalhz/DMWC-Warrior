local DMW = DMW
local Warrior = DMW.Rotations.WARRIOR
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Buff, Debuff, Spell, Stance, Target, Talent, Item, GCD, CDs, HUD, EnemyMelee, EnemyMeleeCount, Enemy14Y,Enemy14YC, Enemy8Y, Enemy8YC, rageLost, dumpEnabled, castTime, syncSS, combatLeftCheck, forcedStance, stanceChangedSkill, stanceChangedSkillTimer, stanceChangedSkillUnit, targetChange
local forcedStanceChange = {}
if stanceChangedSkillTimer == nil then stanceChangedSkillTimer = DMW.Time end
local stanceCheckBattle = {
    ["Overpower"] = true,
    ["Hamstring"] = true,
    ["MockingBLow"] = true,
    ["Rend"] = true,
    ["Retaliation"] = true,
    ["SweepStrikes"] = true,
    ["ThunderClap"] = true,
    ["Charge"] = true,
    -- ["Execute"] = true,
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
    ["Bloodthirst"] = true,
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
    -- Enemy144Y, Enemy144YC = Player:GetEnemies(144)
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
    if Setting("Auto Disable SS") and HUD.Sweeping == 1 and Buff.SweepStrikes:Exist(Player) then DMWHUDSWEEPING:Toggle(2) end
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
    -- if value >= 30 then
    --     if Spell.MortalStrike:Cast(Target) then return true end
    -- else
    -- if value >= 20 then
    --     if EnemyMeleeCount >= 2 then
    --         if Spell.ThunderClap:Cast(Target) then return true end
    --         -- if smartCast("cleavehs") then end
    --     end
        -- if Spell.Slam:Cast(Target) then return true end

    -- elseif value >= 15 then
    --     if Spell.Slam:Cast(Target) then return true end
    -- else
    if value >= 10 then
        if Spell.Bloodthirst:IsReady() then
            if Spell.Bloodthirst:Cast(Target) then return true end
        elseif Spell.Whirlwind:IsReady() then
            if Spell.Whirlwind:Cast(Player) then return true end   
        else
            if Spell.Hamstring:Cast(Target) then return true end
        end
    end
end

local function stanceDanceCast(spell, dest, stance)
    if rageLost <= Setting("Rage Lost on stance change") then
        -- print("spell = "..tostring(spell).." , Unit = ".. tostring(dest) .. " , stance = "..tostring(stance))
        -- if Player:StanceGCDRemain() == 0 then
        if GetShapeshiftFormCooldown(1) == 0 and (stanceChangedSkillTimer == nil or DMW.Time - stanceChangedSkillTimer > 0.5) then
            if stance == 1 then
                if Spell.StanceBattle:IsReady() then
                    if Spell.StanceBattle:Cast() then 
                        stanceChangedSkill = spell
                        stanceChangedSkillTimer = DMW.Time
                        stanceChangedSkillUnit = dest
                        forcedStanceChange[spell] = {}
                        forcedStanceChange[spell].time = DMW.Time; 
                        return true 
                    end
                end
            elseif stance == 2 then
                if Spell.StanceDefense:IsReady() then
                    if Spell.StanceDefense:Cast() then 
                        stanceChangedSkillTimer = DMW.Time
                        return true 
                    end
                end
            elseif stance == 3 then
                if Spell.StanceBers:IsReady() then
                    if Spell.StanceBers:Cast() then 
                        stanceChangedSkillTimer = DMW.Time
                        return true 
                    end
                end
            end
        else
            return true
        end
    else
        dumpRage(rageLost)
    end
end

local onetime = true
local function tagger() 
    if Setting("Tagger") then
        if onetime then
            for k,v in pairs(DMW.Units) do
                if v.Name == "High Chief Winterfall" then
                    TargetUnit(v.Pointer)
                    StartAttack()
                    if v.Distance <= 5 then
                        Spell.Bloodrage:Cast(Player)
                        Spell.Hamstring:Cast(Target)
                    end
                    onetime = false
                end
            end
        else
            if not Player.Combat then
                onetime = true
            end
        end
            -- if Player:AutoTargetQuest(5) then
            --     if Target and Target.Quest and not Target.Facing then
            --         FaceDirection(Target.Pointer, true)
            --     end
            --     RunMacroText("/startattack")
            -- end
    end
end

local function questTagger()
    if Setting("questTagger") then
        -- for k,v in ipairs(DMW.Units) do
        --     print(v)
        -- end
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

local function bersOnTanking()
    if Setting("Berserker Rage") > 0 and Spell.BersRage:CD() == 0 and Stance == "Bers" then
        local count = 0
        for _, Unit in ipairs(DMW.Enemies) do
            if Player:IsTanking(Unit) and Unit.TTD >= 8 then
                count = count + 1
                if count > 0 and count >= Setting("Berserker Rage") then
                    if Spell.BersRage:Cast() then return true end
                end
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
        if spell == "SweepStrikes" and Stance ~= "Battle" then
            if Spell.StanceBattle:IsReady() then
                Spell.StanceBattle:Cast()
            else
                return true
            end
        end
        if forceStance(spell) then return true end
        
        castTime = DMW.Time
        if forcedStance then
            if forceStance(spell) then return true end
        end
        if Stance == "Battle" then
            if not stanceCheckBattle[spell] then
                if stanceCheckDefence[spell] then
                    -- print(spell)
                    if stanceDanceCast(spell, Unit, 2) then return true end
                elseif stanceCheckBers[spell] then
                    -- print(spell)
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
                    -- print(spell)
                    if stanceDanceCast(spell, Unit, 1) then return true end
                elseif stanceCheckBers[spell] then
                    -- print(spell)
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
                    -- print(spell)
                    if stanceDanceCast(spell, Unit, 1) then return true end
                elseif stanceCheckDefence[spell] then
                    -- print(spell)
                    if stanceDanceCast(spell, Unit, 2)  then return true end
                else
                    if Spell[spell]:Cast(Unit) then return true end
                end
            else
                if Spell[spell]:Cast(Unit) then return true end
            end
        end

    
    if pool and Spell[spell]:CD() <= Player:GCDRemain() + 0.3 then 
        
        return true 
    end
end

local function bersCheck()
    if Setting("Berserker Rage") > 0 then
        local count = 0
        for _, Unit in ipairs(DMW.Enemies) do
            if Player:IsTanking(Unit) and Unit.TTD >= 7 then
                count = count + 1
                if count > 0 and count >= Setting("Berserker Rage") then
                    if smartCast("BersRage") then return true end
                end
            end
        end
    end
end


local blizzardshit = true
local assistUnit

local function targetassist()
end
-- Execute 360++", Tooltip = "
-- Execute If <= 3 units", Too
-- Execute |cffffffffTarget", 
-- Execute |cFFFFFF00Disabled"
local function AutoExecute()
    if Spell.Execute:IsReady() then
        if HUD.Execute == 1  then
            for _,Unit in ipairs(EnemyMelee) do
                if Unit.HP < 20 and not Unit.Dead then
                    -- print("exec")
                    local oldTarget
                    if Target.Pointer ~= Unit.Pointer then
                        local oldTarget = Target and Target.Pointer or false
                        TargetUnit(Unit.Pointer)
                    end
                    if smartCast("Execute",Target, true) then return true end
                    if oldTarget ~= nil then 
                        TargetUnit(oldTarget); oldTarget = nil 
                    end
                    return true
                    -- return true                    
                end
            end
        elseif HUD.Execute == 2 then

        elseif HUD.Execute == 3 then
            if Target and Target.HP < 20 and not Target.Dead and Target.Attackable then
                if smartCast("Execute", Target, true) then return true end
            end
        end
    end
end

local function AutoOverpower()
    if Setting("Overpower") and Player.Power >= 5 and Spell.Overpower:CD() <= Spell.StanceBattle:CD() + 0.1 and (Stance == "Battle" or rageLost <= Setting("Rage Lost on stance change")) then
        for _,Unit in ipairs(EnemyMelee) do
            if Player.OverpowerUnit[Unit.Pointer] ~= nil and Spell.Overpower:CD() < Player.OverpowerUnit[Unit.Pointer].time - 0.3  then
                if smartCast("Overpower", Unit, nil) then
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

function checkOnHit()
    -- for k,v in ipairs(Spell.HeroicStrike.Ranks) do
    --     if IsCurrentSpell(v) then
    --         return true
    --     end
    -- end
    for k,v in ipairs(Spell.HeroicStrike.Ranks) do
        if IsCurrentSpell(v) then
            return true
        end
    end
    for k,v in ipairs(Spell.Cleave.Ranks) do
        if IsCurrentSpell(v) then
            return true
        end
    end
    return false    
end

local mountedDcheck
local function itemSets()
    if mountedDcheck == nil then mountedDcheck = IsMounted()end 
    if mountedDcheck and not IsMounted() then
        -- RunMacro("geardps")
        EquipItemByName(15063)
        EquipItemByName(12555)
        EquipItemByName(19120)
        mountedDcheck = false
        return true
    elseif IsMounted() and not mountedDcheck then
        EquipItemByName(18722)
        EquipItemByName(13068)
        EquipItemByName(11122)
        mountedDcheck = true
        return true
    end
end

local function PvP()
    if Target and Target.Player and Target.Distance <= 3 and not Target.Dead and UnitCanAttack("player", Target.Pointer) then
        if Target.Class == "ROGUE" and not Debuff.Rend:Exist(Target) then
            smartCast("Rend", Target)
            return true
        end 
        -- if select(2, GetUnitSpeed("target")) >= 7 then
        --     Spell.Hamstring:Cast(Target)
        --     return true
        -- end
    end
    
end
 
local abuseOH = false
local hsQueued = false
function Warrior.Rotation()
    Locals()
    -- if itemSets() then return true end
    itemSets()
    -- for _, Unit in pairs(Enemy144Y) do
    -- end
    tagger()
    if PvP() then return true end
    -- questTagger()
    if Setting("BattleStance NoCombat") and Player.CombatLeft then
        if Stance ~= "Battle" then
            if Spell.StanceBattle:IsReady()  then
                Spell.StanceBattle:Cast()
            else
                return  true
            end
        end
    end
    if Setting("Assist Use") then
        if HUD.Charge == 1  and Target and not UnitPlayerControlled(Target.Pointer) and Target.Distance >= 8 and Target.Distance < 25 and UnitIsTapDenied(Target.Pointer) and not Target.Dead and UnitCanAttack("player", Target.Pointer) then
            if not Player.Combat and Spell.Charge:CD() == 0 then
                -- print("trying shit")
                if smartCast("Charge", Target) then return end
            elseif Spell.Intercept:CD() == 0 and Player.Power >= 10 and not Spell.Charge:LastCast(1) and not Spell.Charge:LastCast(2) then
                if smartCast("Charge", Target) then return end
            end
        end
        -- if Target and GetUnitName("targettarget") == "" and Player.Combat and Target.Distance == 0 then
        --     if Spell.Taunt:CD() <= 0 then
        --         -- print("taunt")
        --         if smartCast("Taunt", Target) then return end
        --     end
        --     if Spell.SunderArmor:Cast(Target) then
        --         -- print("SunderArmor")
        --         return
        --     end
        -- end
    else
        if HUD.Charge == 1 and Target and UnitCanAttack("player", Target.Pointer) and not Target.Dead and not UnitPlayerControlled(Target.Pointer) and Target.Distance >= 8 and Target.Distance < 25 and IsSpellInRange("Charge", "target") == 1 and not UnitIsTapDenied(Target.Pointer) then
            if not Player.Combat and Spell.Charge:CD() == 0 then
                if smartCast("Charge", Target) then return true end
            elseif Spell.Intercept:CD() == 0 and Player.Power >= 10 and not Spell.Charge:LastCast(1) then
                if smartCast("Intercept", Target) then return true end
            end
            -- StartAttack()
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
    -- local onHitQueued = false
    
    -- if not onHitQueued then 
    --     for k,v in ipairs(Spell.HeroicStrike.Ranks) do
    --         if IsCurrentSpell(v) then
    --             onHitQueued = true
    --             break
    --         end
    -- end
    
    if Setting("abuse") and Player.Combat and Target and not Target.Dead then
        if DMW.Tables.Swing.Player.HasOH then
            hsQueued = checkOnHit() or abuseOH
            -- print(hsQueued)
            -- for k,v in ipairs(Spell.HeroicStrike.Ranks) do
            --     if IsCurrentSpell(v) then
            --         hsQueued = true
            --         break
            --     end
            -- end
            -- print(hsQueued)
            -- if Player.SwingOH < 0.15 and Player.SwingOH + 0.2 < Player.SwingMH then
            if Player.SwingMH > Setting("abuse range") then
            -- if Player.SwingMH  > Player.SwingOH and Player.SwingMH > 0.3 and Player.SwingOH <= 0.3 then
                if not hsQueued then
                    if EnemyMeleeCount >=2 and Player.Power >= 20 then
                        RunMacroText("/cast Cleave")
                        abuseOH = true
                        Player.LastHS = DMW.Time
                    else
                        if Player.Power >= 13 then 
                            RunMacroText("/cast Heroic Strike")
                            abuseOH = true
                            Player.LastHS = DMW.Time
                        end
                        -- print("MH = "..Player.SwingMH..", OH = "..Player.SwingOH)
                        
                    end
                end
            else
                if hsQueued and Player.Power < Setting("Rage Dump") then
                    -- print("off")
                    SpellStopCasting()
                    
                end
                abuseOH = false
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
    

    --brd banden
    -- if Player.Combat then return true end
    -- if DMW.Time <= castTime + 0.3 then return true end
    -- if Stance == "Defense" then Spell.StanceBers:Cast() end
    -- print(Setting("Rage Lost on stance change"))
    -- print(Spell.Whirlwind:CD())
    -- smartCast("Overpower")
    -- print(Player.SwingLeft)
    -- print(addon_data.player.main_swing_timer)
    -- print(overpowerCheck)
    -- if Player.Instance == "party" then
    if Setting("AutoTarget") and (not Target or not Target.Attackable or Target.Dead or not Target.Facing or IsSpellInRange("Hamstring", "target") == 0)    then
        -- -- print("huy")
        -- local FacingTarget
        -- for _, Unit in ipairs(DMW.Units) do
        --     -- if Unit.Distance <= 3 and Unit.CreatureType ~= "Critter" and Unit.Facing and not Unit.Dead and not Unit.Target and (Unit.Player or not UnitPlayerControlled(Unit.Pointer)) and not UnitIsTapDenied(Unit.Pointer) then
        --     --     TargetUnit(Unit.Pointer)
        --     --     targetChange = DMW.Time + 0.1
        --     --     print("changed Target")
        --     --     break
        --     -- end
        --     if Unit.Distance <= 2 and Unit.Attackable and not Unit.Dead then
        --         -- if Unit.Facing then
        --             TargetUnit(Unit.Pointer)
                    
        --             print("changed Target")
        --         -- else
        --         --     if not Player.Moving then
        --         --         FacingTarget = Unit.Pointer
        --         --     end
        --         -- end
        --         targetChange = DMW.Time + 0.1
        --         break
        --     end
        -- end
        -- if FacingTarget ~= nil then
        --     FaceDirection(FacingTarget, true)
        --     TargetUnit(FacingTarget)
        --     FacingTarget = nil
        --     print("changed face and Target")
        -- end
        if Player.Combat then
            if Player:AutoTarget(5, false) then
                return true
            end
        end

    
    end
    -- end
    if Setting("Stop If Shift") and GetKeyState(0x10) then
        return true
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
    -- if Setting("Berserker Rage") then
    --     local count = 0
    --     for _, Unit in ipairs(DMW.Enemies) do
    --         if Player:IsTanking(Unit) then
    --             count = count + 1
    --             if count > 0 and count >= Setting("Berserker Rage") then
    --                 if smartCast("BersRage") then return true end
    --             end
    --         end
    --     end
    -- end

    --/dump UnitAttackSpeed("target")
    if Setting("Rotation") == 2 then
            if Target and not Target.Dead and Target.Distance <= 3 and Target.Attackable and not IsCurrentSpell(Spell.Attack.SpellID) then
                StartAttack()
            end
            if Player.Combat and EnemyMeleeCount > 0 then
                if stanceChangedSkill and stanceChangedSkill == "Overpower" then
                    -- print(stanceChangedSkill)
                    Spell.Overpower:Cast(stanceChangedSkillUnit) 
                    if Spell.Overpower:LastCast(1) or not Spell.Overpower:IsReady() then print("op down");stanceChangedSkill = nil; stanceChangedSkillUnit = nil;stanceChangedSkillTimer = nil; end
                    return true
                end
                if stanceChangedSkill == nil and Stance ~= "Bers" and Spell.StanceBers:IsReady() and Spell.StanceBers:Cast() then
                    return true
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
                -- if AutoBuff() then return true end
                if HUD.DeathWish == 1 and Target and Target.TTD >= 7 then
                    if Spell.DeathWish:IsReady() then
                        if smartCast("DeathWish", Player, true) then return true end
                    elseif Spell.BloodFury:IsReady() and Player.HP > 70 then
                        if Spell.BloodFury:Cast(Player) then return true end
                    end
                end
                if Setting("Pummel") and Target and Target:Interrupt() then
                    smartCast("Pummel", Target, true)
                end
                if Enemy8YC >= 6 then
                    if Setting("Whirlwind") and Spell.Whirlwind:CD() <= Player:GCDRemain() + 0.3  then
                        if smartCast("Whirlwind", Player, true) then return true end
                    end
                    if not hsQueued and Player.Power >= 20 then
                        RunMacroText("/cast Cleave")
                    end
                elseif Enemy8YC >= 2 then
                    if Setting("Whirlwind") and Spell.Whirlwind:CD() <= Player:GCDRemain() + 0.3  then
                        if smartCast("Whirlwind", Player, true) then return true end
                    end
                   

                    if AutoBuff() or AutoExecute() or AutoOverpower() then return true end
                    
                    
                    -- if Setting("Cleave")  then
                    --     if smartCast("Cleave", Player, true) then return true end
                    -- end
                    if Setting("MS/BT") and Target and (Spell.Whirlwind:CD() >= 4  or Player.Power >= 45) then
                        if smartCast("Bloodthirst", Target, true) then return true end
                    end
                    
                else
                    if Target and Target.ValidEnemy then
                        
                        if AutoBuff() then return true end
                        if Setting("SunderArmor ST") and Target.HP > Setting("SunderArmor ST") then
                            AutoOverpower()
                            if Setting("MS/BT") then
                                if smartCast("Bloodthirst", Target, true) then return true end
                            end
                            if Debuff.SunderArmor:Stacks(Target) < 5 or Debuff.SunderArmor:Refresh(Target) then
                                if smartCast("SunderArmor", Target, true) then return true end
                            end
                        end
                        if AutoExecute() then return true end


                        if Setting("MS/BT") and Spell.Bloodthirst:CD() <= Player:GCDRemain() + 0.3 then
                            if Player.Power < 30 then 
                                if AutoOverpower() then return true end
                            end
                            if smartCast("Bloodthirst", Target, true) then return true end
                        end

                        if AutoOverpower() then return true end

                        if Setting("Whirlwind") and (Spell.Bloodthirst:CD() >= 4 or Player.Power >= 45) then
                            if smartCast("Whirlwind", Player, nil) then return true end
                        end

                        -- if (Spell.Bloodthirst:CD() >= 4 and Spell.Whirlwind:CD() >= 5) or Player.Power >= 70 then
                        --     if smartCast("Hamstring", Target, true) then return true end
                        -- end

                        -- if Player.Power >= 50 and not IsCurrentSpell(Spell.Cleave.SpellID) and not IsCurrentSpell(Spell.HeroicStrike.SpellID) then
                        --     if EnemyMeleeCount >= 2 then
                        --         if Spell.Cleave:IsReady() and Spell.Cleave:Cast() then
                        --             return true
                        --         end
                        --     else
                        --         if Spell.HeroicStrike:IsReady() and Spell.HeroicStrike:Cast() then
                        --             return true
                        --         end
                        --     end
                        -- end

                    -- else
                    --     AutoBuff()
                    --     AutoOverpower()
                    --     AutoExecute()
                    end
                end
                bersOnTanking()
                if Player.Power >= Setting("Rage Dump") then
                    if not hsQueued then
                        if EnemyMeleeCount >= 2 and Player.Power >= 20 then
                            RunMacroText("/cast Cleave")
                            
                        else
                            if Player.Power >= 13 then 
                                RunMacroText("/cast Heroic Strike")
                                
                            end
                            -- print("MH = "..Player.SwingMH..", OH = "..Player.SwingOH)
                            
                        end
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