local DMW = DMW
local DEATHKNIGHT = DMW.Rotations.DEATHKNIGHT
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Buff, Debuff, Spell, Stance, Target, Talent, Item, Pet, GCD, CDs, HUD, EnemyMelee, EnemyMeleeCount, Rage, Enemy10Y, Enemy10YC,
      Enemy30Y, Enemy30YC, Enemy8Y, Enemy8YC, UnholyStopScourge,WoundSpender
local ShouldReturn

local function Locals()
    Player = DMW.Player
    Buff = Player.Buffs
    Debuff = Player.Debuffs
    Spell = Player.Spells
    Talent = Player.Talents
    Item = Player.Items
    Target = Player.Target or false
	-- Rage = Player.Rage
	Pet = Player.Pet
    HUD = DMW.Settings.profile.HUD
    CDs = Player:CDs() and Target and Target.TTD > 5 and Target.Distance < 5
    EnemyMelee, EnemyMeleeCount = Player:GetEnemies(8)
    -- EnemyMelee, EnemyMeleeCount = select(2, Player:GetEnemies(10))
    -- Enemy8Y, Enemy8YC = Player:GetEnemies(8)
    Enemy10Y, Enemy10YC = Player:GetEnemies(10)
    Enemy30Y, Enemy30YC = Player:GetEnemies(30)

    -- mainSwing, mainSpeed = Player:GetSwing("main")
    -- offSwing, offSpeed = Player:GetSwing("off")

    GCD = Player:GCDRemain()
    -- print(canExecute)
    -- if combatLeftCheck == nil and Player.CombatLeft > 0 then combatLeftCheck = false end
    -- print(Player.CombatLeft)
end
local function num(val)
    if val then
        return 1
    else
        return 0
    end
end

local function bool(val) return val ~= 0 end

local function LocalsUnholy()
	UnholyStopScourge = 0
	if Talent.ClawingShadows then
		WoundSpender = Spell.ClawingShadows
	else
		WoundSpender = Spell.ScourgeStrike
	end
    if Player:CDs() then if Spell.Apocalypse:CD() <= 5 then UnholyStopScourge = 4 end end
end

local function isCurrentlyTanking()
    -- is player currently tanking any enemies within 16 yard radius
    local IsTanking = Player:IsTankingAoE(16) or (DMW.Player.Target and (DMW.Player.Target:IsTanking() or DMW.Player.Target.Dummy))
    return IsTanking;
end

local function DeathStrikeHeal()
    -- return (Player.Is and
    --            (Player:HealthPercentage() < Settings.Commons.UseDeathStrikeHP or Player:HealthPercentage() <
    --                Settings.Commons.UseDarkSuccorHP and Player:BuffP(S.DeathStrikeBuff))) and true or false;
end
-------------------------
local BloodRotationSimc = function()
    -- actions.standard=blood_tap,if=rune<=2&rune.time_to_4>gcd&charges_fractional>=1.8

    -- actions.standard+=/dancing_rune_weapon,if=!talent.blooddrinker.enabled|!cooldown.blooddrinker.ready
    -- actions.standard+=/tombstone,if=buff.bone_shield.stack>=7&rune>=2
    -- actions.standard+=/marrowrend,if=(!covenant.necrolord|buff.abomination_limb.up)&(buff.bone_shield.remains<=rune.time_to_3|buff.bone_shield.remains<=(gcd+cooldown.blooddrinker.ready*talent.blooddrinker.enabled*2)|buff.bone_shield.stack<3)&runic_power.deficit>=20
    -- actions.standard+=/death_strike,if=runic_power.deficit<=70

    if Spell.DeathStrike:IsCastable("Melee") and Player.RunicPowerDeficit <= 70 then
        for _, Unit in ipairs(EnemyMelee) do if Spell.DeathStrike:Cast(Unit) then return true end end
    end
    -- actions.standard+=/marrowrend,if=buff.bone_shield.stack<6&runic_power.deficit>=15&(!covenant.night_fae|buff.deaths_due.remains>5)
    if Spell.Marrowrend:IsCastable("Melee") and (Buff.BoneShield:Stacks() < 6 and Player.RunicPowerDeficit >= 15) then
        for _, Unit in ipairs(EnemyMelee) do if Spell.Marrowrend:Cast(Unit) then return true end end
    end
    -- actions.standard+=/heart_strike,if=!talent.blooddrinker.enabled&death_and_decay.remains<5&runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2)
    if Spell.HeartStrike:IsReady("Melee") and Player.RunicPowerDeficit >= 15 then
        for _, Unit in ipairs(EnemyMelee) do if Spell.HeartStrike:Cast(Unit) then return true end end
    end
    -- actions.standard+=/blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2)
    if Spell.BloodBoil:IsCastable() and not GetKeyState(0x12) and Enemy10YC and Spell.BloodBoil:ChargesFrac() >= 1.8 then
        if Spell.BloodBoil:Cast(Player) then return true end
    end
    -- actions.standard+=/death_and_decay,i f=(buff.crimson_scourge.up&talent.relish_in_blood.enabled)&runic_power.deficit>10
    if Spell.DeathAndDecay:IsReady() and Buff.CrimsonScourge:Exist() and Player.RunicPowerDeficit > 10 then
        if Spell.DeathAndDecay:Cast(Player) then return true end
    end
    -- actions.standard+=/bonestorm,if=runic_power>=100&!buff.dancing_rune_weapon.up
    if Spell.Bonestorm:IsReady() and CDs and not Buff.DancingRuneWeaponBuff:Exist() and Player.RunicPower >= 100 then
        if Spell.Bonestorm:Cast(Player) then return true end
    end
    -- actions.standard+=/death_strike,if=runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2)|target.1.time_to_die<10
    if Spell.DeathStrike:IsCastable() and Player.RunicPowerDeficit <= 70 then
        for _, Unit in ipairs(EnemyMelee) do if Spell.DeathStrike:Cast(Unit) then return true end end
    end
    -- actions.standard+=/death_and_decay,if=spell_targets.death_and_decay>=3
    if Spell.DeathAndDecay:IsReady() and Enemy10YC >= 3 then if Spell.DeathAndDecay:Cast(Player) then return true end end
    -- actions.standard+=/heart_strike,if=buff.dancing_rune_weapon.up|rune.time_to_4<gcd
    if Spell.HeartStrike:IsReady() and (Buff.DancingRuneWeaponBuff:Exist() or Player:RuneTimeToX(4) < 1.5) then
        for _, Unit in ipairs(EnemyMelee) do if Spell.HeartStrike:Cast(Unit) then return true end end
    end
    -- actions.standard+=/blood_boil,if=buff.dancing_rune_weapon.up
    if Spell.BloodBoil:IsCastable() and not GetKeyState(0x12) and Enemy10YC > 2 and Buff.DancingRuneWeaponBuff:Exist() then
        if Spell.BloodBoil:Cast(Player) then return true end
    end
    -- actions.standard+=/blood_tap,if=rune.time_to_3>gcd
    -- actions.standard+=/death_and_decay,if=buff.crimson_scourge.up|talent.rapid_decomposition.enabled|spell_targets.death_and_decay>=2
    -- actions.standard+=/consumption
    -- actions.standard+=/blood_boil,if=charges_fractional>=1.1
    if Spell.BloodBoil:IsCastable() and not GetKeyState(0x12) and Enemy10YC >= 1 and Spell.BloodBoil:ChargesFrac() >= 1.1 then
        if Spell.BloodBoil:Cast(Player) then return true end
    end
    -- actions.standard+=/heart_strike,if=(rune>1&(rune.time_to_3<gcd|buff.bone_shield.stack>7))
    if Spell.HeartStrike:IsReady("Melee") and Player.Runes > 1 and (Player:RuneTimeToX(3) < 1.5 or Buff.BoneShield:Stacks() > 7) then
        for _, Unit in ipairs(EnemyMelee) do if Spell.HeartStrike:Cast(Unit) then return true end end
    end
    -- actions.standard+=/arcane_torrent,if=runic_power.deficit>20
end
local BloodRotationGuide = function()
    -- Use  Marrowrend if your  Bone Shield will expire before you have a chance to refresh it in the normal course of your rotation.
    if Spell.Marrowrend:IsCastable("Melee") and (Buff.BoneShield:Exist() and Buff.BoneShield:Remain() < 2) then
        for _, Unit in ipairs(EnemyMelee) do if Spell.Marrowrend:Cast(Unit) then return true end end
    end
    -- Use  Heart Strike as the last GCD before  Death's Due fades. You can find a weakaura on the Weakauras page to help you with this!
    -- Use  Death Strike if your next ability would cause you to overcap Runic Power
    if Spell.DeathStrike:IsCastable("Melee") and Player.RunicPowerDeficit <= 15 then
        for _, Unit in ipairs(EnemyMelee) do if Spell.DeathStrike:Cast(Unit) then return true end end
    end
    -- Use  Blood Tap while at fewer than 3 runes, and make sure not to cap its charges.
    if Talent.BloodTap and Spell.BloodTap:IsReady() and Player.Runes < 3 and Spell.BloodTap:ChargesFrac() >= 1.8 then
        if Spell.BloodTap:Cast(Player) then return true end
    end
    -- Use  Blood Boil if you have 2 charges
    if Spell.BloodBoil:IsCastable() and not GetKeyState(0x12) and Enemy10YC >= 1 and Spell.BloodBoil:ChargesFrac() >= 2 then
        if Spell.BloodBoil:Cast(Player) then return true end
    end
    -- Use  Swarming Mist unless you will have a possibility to hit more targets with it within 10s of it going off cooldown.
    -- Use  Death and Decay as soon as possible after receiving a  Crimson Scourge proc.
    if Spell.DeathAndDecay:IsReady() and Buff.CrimsonScourge:Exist() then if Spell.DeathAndDecay:Cast(Player) then return true end end
    -- Use  Shackle the Unworthy.
    -- Use  Abomination Limb. Be aware that it will attempt to grip targets 8 yards or further from you - you ideally want this to happen at least once to gain 3 bone shield charges.
    if Player.Covenant == "Necrolord" and CDs and Spell.AbominationLimb:IsReady() then
        if Spell.AbominationLimb:Cast(Player) then return true end
    end
    -- Use  Blooddrinker. Be sure you will not need to interrupt the channel, for example to use  Dark Command or  Death Strike.
    -- Use  Blood Boil if any enemies in range are not affected by  Blood Plague.
    if Spell.BloodBoil:IsReady() and Spell.BloodBoil:ChargesFrac() >= 1 then
        for _, Unit in ipairs(Enemy10Y) do
            if not Debuff.BloodPlague:Exist(Unit) then if Spell.BloodBoil:Cast(Player) then return true end end
        end
    end
    -- Use  Marrowrend if you have 7 or fewer stacks of  Bone Shield. During  Dancing Rune Weapon, avoid refreshing  Bone Shield until you are at 4 stacks.
    if Spell.Marrowrend:IsCastable("Melee") and
        ((Buff.BoneShield:Stacks() <= 7 and not Buff.DancingRuneWeaponBuff:Exist()) or Buff.BoneShield:Stacks() <= 4) then
        for _, Unit in ipairs(EnemyMelee) do if Spell.Marrowrend:Cast(Unit) then return true end end
    end
    -- Use  Death and Decay.
    if Spell.DeathAndDecay:IsReady() and Enemy10YC >= 3 then if Spell.DeathAndDecay:Cast(Player) then return true end end
    -- Use  Heart Strike if you have 3 or more runes. You can also use this ability to rapidly generate Runic Power, even if you already have 3 runes recharging, but be sure to make sure you can use  Marrowrend when needed to keep  Bone Shield from falling below 5 stacks.
    if Spell.HeartStrike:IsReady("Melee") and Player.Runes >= 3 then
        for _, Unit in ipairs(EnemyMelee) do if Spell.HeartStrike:Cast(Unit) then return true end end
    end
    -- Use  Blood Boil during  Dancing Rune Weapon.
    if Spell.BloodBoil:IsReady() and Spell.BloodBoil:ChargesFrac() >= 1 and Buff.DancingRuneWeaponBuff:Exist() then
        if Spell.BloodBoil:Cast(Player) then return true end
    end
    if Spell.DeathAndDecay:IsReady() and Buff.CrimsonScourge:Exist() then if Spell.DeathAndDecay:Cast(Player) then return true end end
    -- Use  Heart Strike.
    if Spell.HeartStrike:IsReady("Melee") and Player.Runes > 1 and (Player:RuneTimeToX(3) < 1.5 or Buff.BoneShield:Stacks() > 7) then
        for _, Unit in ipairs(EnemyMelee) do if Spell.HeartStrike:Cast(Unit) then return true end end
    end
end

local function BloodTaunt()
    if Spell.DarkCommand:CDUp() and (not TauntTime or DMW.Time - TauntTime > 1) then
        for _, Unit in ipairs(DMW.Enemies) do
            if Unit:NotPlayerTanking() then
                Spell.DarkCommand:Cast(Unit)
                TauntTime = DMW.Time
                break
            end
        end
    end
    if Spell.DeathGrip:CDUp() and (not TauntTime or DMW.Time - TauntTime > 1) then
        for _, Unit in ipairs(DMW.Enemies) do
            if Unit:NotPlayerTanking() and Unit.Distance >= 15 then
                Spell.DeathGrip:Cast(Unit)
                TauntTime = DMW.Time
                break
            end
        end
    end
end

local function BloodDefensive()
	--Lichborne
	if Setting("Lichborne") > 0 and Player.HP <= Setting("Lichborne") and Spell.Lichborne:IsReady() then
		if Spell.Lichborne:Cast(Player) then return true end
	end
	--Runetap
	if Setting("RuneTap") > 0 and Player.HP <= Setting("RuneTap") and Spell.RuneTap:IsReady() and not Buff.RuneTap:Exist() then
		if Spell.RuneTap:Cast(Player) then return true end
	end
	--AMS
	--DRW
	if Setting("DancingRW") > 0 and Player.HP <= Setting("DancingRW") and Spell.DancingRuneWeapon:IsReady() then
		if Spell.DancingRuneWeapon:Cast(Player) then return true end
	end
	--IF
	if Setting("IceboundFortitude") > 0 and Player.HP <= Setting("IceboundFortitude") and Spell.IceboundFortitude:IsReady() then
		if Spell.IceboundFortitude:Cast(Player) then return true end
	end
	--VB
	if Setting("VampiricBlood") > 0 and Player.HP <= Setting("VampiricBlood") and Spell.VampiricBlood:IsReady() then
		if Spell.VampiricBlood:Cast(Player) then return true end
	end

	if Setting("BoneStorm") > 0 and Player.HP <= Setting("BoneStorm") and Spell.BoneStorm:IsReady() then
		if Spell.BoneStorm:Cast(Player) then return true end
	end
	if Spell.DeathStrike:IsCastable("Melee") and Player.HP < Setting("Critical Death Strike") then
        for _, Unit in ipairs(EnemyMelee) do if Spell.DeathStrike:Cast(Unit) then return true end end
    end
end

local function UnholySpender(coil)
	if coil then
		for _, Unit in ipairs(Enemy10Y) do
			if Spell.DeathCoil:Cast(Unit) then return true end
		end
	else
		if Debuff.VirulentPlague:Count() >= 2 then
			if Spell.Epidemic:IsReady() then
				if Spell.Epidemic:Cast(Player) then return true
				else
					for _, Unit in ipairs(Enemy30Y) do
						if Spell.DeathCoil:Cast(Unit) then return true end
					end
				end
			end
		else
			if Spell.DeathCoil:IsReady() then
				for _, Unit in ipairs(Enemy30Y) do
					if Spell.DeathCoil:Cast(Unit) then return true end
				end
			end
		end
	end
end

local function UnholyDefensive()
	if Player.HP <= 50 and Spell.DeathStrike:IsReady() and Buff.DarkSuccor:Exist() then
		for _, Unit in ipairs(EnemyMelee) do if Spell.DeathStrike:Cast(Unit) then return true end end
	end
end

local function UnholyRotationST()
    -- outbreak
    -- if Spell.Outbreak:IsReady() and HUD.OutbreakMode == 1 then
    --     for _, Unit in ipairs(EnemyMelee) do
    --         if not Debuff.VirulentPlague:Exist(Unit) then if Spell.Outbreak:Cast(Unit) then return true end end
    --     end
    -- end
    -- dc when high
    if (Player.RunicPowerDeficit < 13 or Buff.SuddenDoom:Exist()) then
        if UnholySpender(true) then return true end
	end

	if WoundSpender:IsReady() then
		if Talent.ClawingShadows then
			for _, Unit in ipairs(Enemy30Y) do
				if Debuff.FesteringWound:Stacks(Unit) > UnholyStopScourge then if WoundSpender:Cast(Unit) then return true end end
			end
		else
			for _, Unit in ipairs(EnemyMelee) do
				if Debuff.FesteringWound:Stacks(Unit) > UnholyStopScourge then if WoundSpender:Cast(Unit) then return true end end
			end
		end
	end
	if Player.RunicPowerDeficit < 20 then
        if UnholySpender(true) then return true end
    end
    if Spell.FesteringStrike:IsReady() then
        for _, Unit in ipairs(EnemyMelee) do
            if not Debuff.FesteringWound:Exist(Unit) then
    	        if Spell.FesteringStrike:Cast(Unit) then return true end
            end
        end
    end
	if Spell.FesteringStrike:IsReady() and CDs and Spell.Apocalypse:CD() < 3 and (not Talent.UnholyBlight or Talent.ArmyOfTheDamned) then --or Conduit ))	then
        for _, Unit in ipairs(EnemyMelee) do
            if Debuff.FesteringWound:Stacks(Unit) < 4 then
            	if Spell.FesteringStrike:Cast(Unit) then return true end
            end
        end
    end
    if Spell.FesteringStrike:IsReady() and Talent.UnholyBlight and not Talent.ArmyOfTheDamned and Spell.Apocalypse:CDUp() and (Spell.UnholyBlight:CD() < 3 or Buff.UnholyBlight:Exist()) then
        for _, Unit in ipairs(EnemyMelee) do
            if Debuff.FesteringWound:Stacks(Unit) < 4 then
            	if Spell.FesteringStrike:Cast(Unit) then return true end
            end
        end
    end
	if UnholySpender() then return true end
end
local function UnholyRotationAOE()
    -- outbreak
    if Spell.Outbreak:IsReady() and HUD.OutbreakMode == 1 then
        for _, Unit in ipairs(EnemyMelee) do
            if not Debuff.VirulentPlague:Exist(Unit) then if Spell.Outbreak:Cast(Unit) then return true end end
        end
    end
	-- dc when high
	if Player.Runeforge == "DeadliestCoil" and Spell.DeathCoil:IsReady() and (Player.RunicPower >= 80 or Buff.SuddenDoom:Exist()) and (Debuff.VirulentPlague:Count() >= 1 and Debuff.VirulentPlague:Count() <= 3 and Buff.DarkTransformation:Exist(Pet)) then
		for _, Unit in ipairs(Enemy10Y) do
            if Spell.DeathCoil:Cast(Unit) then return true end
        end
    end
    if Spell.Epidemic:IsReady() and (Player.RunicPower >= 80 or Buff.SuddenDoom:Exist()) and Debuff.VirulentPlague:Count() >= 2 then
        if Spell.Epidemic:Cast(Player) then return true end
    end
    if WoundSpender:IsReady() and Buff.DeathAndDecay:Exist() then
		if Talent.ClawingShadows then
			for _, Unit in ipairs(Enemy30Y) do
				if Debuff.FesteringWound:Stacks(Unit) > UnholyStopScourge then if WoundSpender:Cast(Unit) then return true end end
			end
		else
			for _, Unit in ipairs(EnemyMelee) do
				if Debuff.FesteringWound:Stacks(Unit) > UnholyStopScourge then if WoundSpender:Cast(Unit) then return true end end
			end
		end
	end
	--
	if Player.Runeforge == "DeadliestCoil" and Spell.DeathCoil:IsReady() and (Debuff.VirulentPlague:Count() >= 1 and Debuff.VirulentPlague:Count() <= 3 and Buff.DarkTransformation:Exist(Pet)) then
		for _, Unit in ipairs(Enemy10Y) do
            if Spell.DeathCoil:Cast(Unit) then return true end
        end
    end
	if Spell.Epidemic:IsReady() and Debuff.VirulentPlague:Count() >= 2 then
		if Spell.Epidemic:Cast(Player) then return true end
	end
    if WoundSpender:IsReady() then
		if Talent.ClawingShadows then
			for _, Unit in ipairs(Enemy30Y) do
				if Debuff.FesteringWound:Stacks(Unit) > UnholyStopScourge then if WoundSpender:Cast(Unit) then return true end end
			end
		else
			for _, Unit in ipairs(EnemyMelee) do
				if Debuff.FesteringWound:Stacks(Unit) > UnholyStopScourge then if WoundSpender:Cast(Unit) then return true end end
			end
		end
	end
    if Spell.FesteringStrike:IsReady() then
        for _, Unit in ipairs(EnemyMelee) do if Spell.FesteringStrike:Cast(Unit) then return true end end
    end
end

local function UnholyRotationCDS()
	-- if Spell.DarkTransformation:IsReady() then
	-- 	if UnitPower("pet") < 100 then
	-- 		RunMacroText("/petautocastoff Цапнуть")
	-- 	else
	-- 		RunMacroText("/petautocaston Цапнуть")
	-- 		if Spell.DarkTransformation:Cast(Player) then return true end
	-- 	end
    -- end
	-- if Player.Covenant == "Necrolord" and Spell.AbominationLimb:IsReady() then if Spell.AbominationLimb:Cast(Player) then return true end end
    -- if Spell.Apocalypse:IsReady() then
    --     if Target and Debuff.FesteringWound:Stacks(Target) >= 4 then if Spell.Apocalypse:Cast(Target) then return true end end
    --     for _, Unit in ipairs(EnemyMelee) do
    --         if Debuff.FesteringWound:Stacks(Unit) >= 4 then if Spell.Apocalypse:Cast(Unit) then return true end end
    --     end
    -- end
    -- if Spell.Apocalypse:CDDown() and Spell.UnholyAssault:IsReady() then
    --     if Target and Debuff.FesteringWound:Stacks(Target) <= 2 then if Spell.UnholyAssault:Cast(Target) then return true end end
	-- end

	-- actions.covenants+=/abomination_limb,if=variable.st_planning&rune.time_to_4>(3+buff.runic_corruption.remains)
	-- actions.covenants+=/abomination_limb,if=active_enemies>=2&rune.time_to_4>(3+buff.runic_corruption.remains)
	-- abomination_limb,if=variable.st_planning&soulbind.lead_by_example&(cooldown.unholy_blight.remains|!talent.unholy_blight&cooldown.dark_transformation.remains)
	-- Covenant
	if Player.Covenant == "Necrolord" and DMW.Player.Spells.AbominationLimb:IsReady() then
		if EnemyMeleeCount >= 1 then
			if (not Talent.UnholyBlight and Spell.DarkTransformation:CDDown()) or Spell.UnholyBlight:CDDown() then
				if Spell.AbominationLimb:Cast(Player) then return true end
			end
		elseif EnemyMeleeCount >= 2 then
			if Player:RuneTimeToX(4) < 3 + Buff.RunicCorruption:Remain() then
				if Spell.AbominationLimb:Cast(Player) then return true end
			end
		end
	end
	-- actions.cooldowns+=/army_of_the_dead,if=debuff.festering_wound.up&cooldown.unholy_blight.remains<5&talent.unholy_blight|!talent.unholy_blight
	if Spell.ArmyOfTheDead:IsReady() and Setting("Army of the Dead") and EnemyMeleeCount >= 1 and Debuff.FesteringWound:Exist(Target) and (not Talent.UnholyBlight or Spell.UnholyBlight:CD() <= 5 or Buff.UnholyBlight:Exist()) then
		if Spell.ArmyOfTheDead:Cast(Player) then return true end
	end

	--unholy_blight,if=variable.st_planning&(cooldown.army_of_the_dead.remains>5|death_knight.disable_aotd)&(cooldown.dark_transformation.remains<gcd|buff.dark_transformation.up)&(!runeforge.deadliest_coil|!talent.army_of_the_damned|conduit.convocation_of_the_dead.rank<5)
-- Sync Blight with Dark Transformation if utilizing other Dark Transformation buffs, those being Deadliest Coil, Frenzied Monstrosity or Eternal Hunger. Also checks if conditions are met to instead hold for Apocalypse.
	if Talent.UnholyBlight and Spell.UnholyBlight:IsReady() and (not Setting("Army of the Dead") or Spell.ArmyOfTheDead:CD() > 5 ) and (Buff.DarkTransformation:Exist(Pet) or Spell.DarkTransformation:CD() < Player:GCD()) then
		if Spell.UnholyBlight:Cast(Player) then return true end
	end
	-- if Talent.UnholyBlight and Spell.UnholyBlight:IsReady() and (not Setting("Army of the Dead") or Spell.ArmyOfTheDead:CD() > 5 ) and (Spell.Apocalypse:CDDown() or (Debuff.FesteringWound:Stacks(Target) >=4 or Player.Runes >= 3)) then
	-- 	if Spell.UnholyBlight:Cast(Player) then return true end
	-- end
	-- actions.cooldowns+=/unholy_blight,if=active_enemies>=2
	-- if Talent.UnholyBlight
	-- if Talent.UnholyBlight and Spell.UnholyBlight:IsReady() and EnemyMeleeCount >= 2 then
	-- 	if Spell.UnholyBlight:Cast(Player) then return true end
	-- end
	--TODO  Convocation of the Dead unholy blight
	-- actions.cooldowns+=/dark_transformation,if=variable.st_planning&cooldown.unholy_blight.remains&(!runeforge.deadliest_coil|runeforge.deadliest_coil&(!buff.dark_transformation.up&!talent.unholy_pact|talent.unholy_pact))
	if Talent.UnholyBlight and Spell.DarkTransformation:IsReady() and Buff.UnholyBlight:Exist() --TODO Runeforge
	then
		if Spell.DarkTransformation:Cast(Player) then return true end
	end
	-- actions.cooldowns+=/dark_transformation,if=variable.st_planning&!talent.unholy_blight
	if not Talent.UnholyBlight and Spell.DarkTransformation:IsReady() then
		if Spell.DarkTransformation:Cast(Player) then return true end
	end
	-- actions.cooldowns+=/dark_transformation,if=active_enemies>=2
	if Spell.DarkTransformation:IsReady() and EnemyMeleeCount >= 2 then
		if Spell.DarkTransformation:Cast(Player) then return true end
	end
	-- actions.cooldowns+=/apocalypse,if=active_enemies=1&debuff.festering_wound.stack>=4&
	-- ((!talent.unholy_blight|talent.army_of_the_damned|conduit.convocation_of_the_dead)|talent.unholy_blight&!talent.army_of_the_damned&dot.unholy_blight.remains)
	-- actions.cooldowns+=/apocalypse,target_if=max:debuff.festering_wound.stack,if=active_enemies>=2&debuff.festering_wound.stack>=4&!death_and_decay.ticking
	if Spell.Apocalypse:IsReady() then
		if EnemyMeleeCount == 1 then
			for _, Unit in ipairs(EnemyMelee) do
				if Debuff.FesteringWound:Stacks(Unit) >= 4 then --and ((not Talent.UnholyBlight or Talent.ArmyOfTheDamned --TODO or conduit) or Debuff.UnholyBlight:Exist(Unit))
			--  then
					if Spell.Apocalypse:Cast(Unit) then return true end
				end
			end
		elseif EnemyMeleeCount >= 2 and not Buff.DeathAndDecay:Exist() then
			for _, Unit in ipairs(EnemyMelee) do
				if Debuff.FesteringWound:Stacks(Unit) >= 4 then
					if Spell.Apocalypse:Cast(Unit) then return true end
				end
			end
		end
	end
	-- actions.cooldowns+=/summon_gargoyle,if=runic_power.deficit<14
	--TODO Gargoyle
	-- actions.cooldowns+=/unholy_assault,if=variable.st_planning&debuff.festering_wound.stack<2&(pet.apoc_ghoul.active|conduit.convocation_of_the_dead&cooldown.apocalypse.remains)
	-- actions.cooldowns+=/unholy_assault,target_if=min:debuff.festering_wound.stack,if=active_enemies>=2&debuff.festering_wound.stack<2
	--TODO UA
	-- actions.cooldowns+=/soul_reaper,target_if=target.time_to_pct_35<5&target.time_to_die>5
	if Talent.SoulReaper and Spell.SoulReaper:IsReady() then
		for _, Unit in ipairs(EnemyMelee) do
			if Unit:GetTTD(35) < 5 and Unit.TTD > 5 then
				if Spell.SoulReaper:Cast(Unit) then return true end
			end
		end
		-- for _, Unit in ipairs(EnemyMelee) do
		-- 	if Unit.HP <= 35 then
		-- 		if Spell.SoulReaper:Cast(Unit) then return true end
		-- 	end
		-- end
	end
	-- actions.cooldowns+=/raise_dead,if=!pet.ghoul.active
	if not Player.Pet and Spell.RaiseDead:IsReady() then
		if Spell.RaiseDead:Cast(Player) then return true end
	end
end

local function UnholyRotationCleaveSetup()
	-- actions.aoe_setup=any_dnd,if=death_knight.fwounded_targets=active_enemies|raid_event.adds.exists&raid_event.adds.remains<=11
	-- actions.aoe_setup+=/any_dnd,if=death_knight.fwounded_targets>=5
	-- actions.aoe_setup+=/epidemic,if=!variable.pooling_for_gargoyle
	-- actions.aoe_setup+=/festering_strike,target_if=max:debuff.festering_wound.stack,if=debuff.festering_wound.stack<=3&cooldown.apocalypse.remains<3
	-- actions.aoe_setup+=/festering_strike,target_if=debuff.festering_wound.stack<1
	-- actions.aoe_setup+=/festering_strike,target_if=min:debuff.festering_wound.stack,if=rune.time_to_4<(cooldown.death_and_decay.remains&!talent.defile|cooldown.defile.remains&talent.defile)
	if EnemyMeleeCount > 1 and Spell.Epidemic:IsReady() and Debuff.VirulentPlague:Count() >= 2 then
		if Spell.Epidemic:Cast(Player) then return true end
	end
	if Target and Spell.DeathCoil:IsReady() then
		if Spell.DeathCoil:Cast(Target) then return true end
	end

	local woundedTargets = 0
	for _, Unit in ipairs(Enemy10Y) do
		if Debuff.FesteringWound:Stacks(Unit) >= 2 then
			woundedTargets = woundedTargets + 1
		end
	end
	if woundedTargets >= 5 then
		if Spell.DeathAndDecay:IsReady() then
			if Spell.DeathAndDecay:Cast(Player) then
				DMWHUDSETUPCLEAVEMODE:Toggle(2)
				return true
			end
		end
		return true
	end
	if Spell.FesteringStrike:IsReady() then
		if CDs and Spell.Apocalypse:CD() < 3 then
			local highestUnit, highestStacks = Debuff.FesteringWound:HighestStack(EnemyMelee)
			if highestStacks <= 3 then
				if Spell.FesteringStrike:Cast(highestUnit) then return true end
			end
		end
		for _, Unit in ipairs(EnemyMelee) do
			if not Debuff.FesteringWound:Exist(Unit) then
				if Spell.FesteringStrike:Cast(Unit) then return true end
			end
		end
		-- print(Player:RuneTimeToX(4))
		if Player:RuneTimeToX(4) <= Spell.DeathAndDecay:CD() then
			-- print("last")
			local lowestUnit, lowestStacks = Debuff.FesteringWound:LowestStack(EnemyMelee)
			-- print(lowestStacks)
			if lowestStacks < 4 then
				if Spell.FesteringStrike:Cast(lowestUnit) then return true end
			end
		end
	end
	if Player.Runes > 3 then

	end
end

local function UnholyOutbreak()
	-- actions+=/outbreak,if=dot.virulent_plague.refreshable&!talent.unholy_blight&!raid_event.adds.exists
	if not Talent.UnholyBlight then
		if HUD.Outbreak == 1 and (not Talent.UnholyBlight or Spell.UnholyBlight:CD() > 10) then
			for _, Unit in ipairs(EnemyMelee) do
				if Debuff.VirulentPlague:Refresh(Unit) then
					if Spell.Outbreak:Cast(Unit) then return true end
				end
			end
		end
	end
	-- actions+=/outbreak,if=dot.virulent_plague.refreshable&(!talent.unholy_blight|talent.unholy_blight&cooldown.unholy_blight.remains)&active_enemies>=2

	-- actions+=/outbreak,if=runeforge.superstrain&(dot.frost_fever.refreshable|dot.blood_plague.refreshable)
end

function DEATHKNIGHT.Rotation()
    Locals()
    if Target and Target.ValidEnemy and Target.Distance <= 5 and Target.Facing then
        if not IsCurrentSpell(Spell.Attack.SpellID) then StartAttack() end
    end
    if Player:InterruptsMode() ~= 4 and Spell.MindFreeze:CDUp() then
        for _, Unit in pairs(EnemyMelee) do
            if Unit:Interrupt() then
                Spell.MindFreeze:Cast(Unit)
                break
            end
        end
    end
    -- if Player.Combat then if Player:AutoTargetMelee(5, true) then return true end end
    if Player.SpecID == "Blood" then
        if HUD.PullMode == 1 then
            if Target and Target.CanAttack and not UnitAffectingCombat(DMW.Player.Target.Pointer) and Target.Distance <= 30 and
                not Target.Pulled then
                if Spell.DeathsCaress:IsReady() then
                    Target.Pulled = true
                    Spell.DeathsCaress:Cast(Target)
                elseif Spell.DarkCommand:IsReady() then
                    Target.Pulled = true
                    Spell.DarkCommand:Cast(Target)
                    -- elseif Spell.HandOfReckoning:IsReady() then
                    --     Target.Pulled = true
                    --     Spell.HandOfReckoning:Cast(Target)
                end
                return true
            end
        end
        if (Target and Target.ValidEnemy and Target.Distance <= 5) or (DMW.Player.Instance == "party" and DMW.Player.Combat) then
            -- if S.DancingRuneWeapon:IsCastable("Melee") and (not S.Blooddrinker:IsAvailable() or not S.Blooddrinker:CooldownUpP()) then
            --     if HR.Cast(S.DancingRuneWeapon, Settings.Blood.OffGCDasOffGCD.DancingRuneWeapon) then return ""; end
            --   end
            --   -- tombstone,if=buff.bone_shield.stack>=7
            --   if S.Tombstone:IsCastable() and (Player:BuffStackP(S.BoneShield) >= 7) then
            --     if HR.Cast(S.Tombstone, Settings.Blood.GCDasOffGCD.Tombstone) then return ""; end
            --   end
            -- call_action_list,name=standard
            if Player.Combat and CDs then if Spell.DancingRuneWeapon:Cast(Player) then return true end end
            if HUD.TauntMode == 1 then if BloodTaunt() then return true end end
			if HUD.Defensive == 1 and isCurrentlyTanking() then if BloodDefensive() then return true end end
            if Spell.BoneStorm:IsReady() and CDs and not Buff.DancingRuneWeaponBuff:Exist() and Player.RunicPower >= 100 then
                if Spell.BoneStorm:Cast(Player) then return true end
			end
			if BloodRotationGuide() then return true end

        end
    elseif Player.SpecID == "Frost" then
        if (Target and Target.ValidEnemy and Target.Distance <= 5) or (DMW.Player.Instance == "party" and DMW.Player.Combat) then
            -- if Spell.HowlingBlast:IsCastable(30) then --and (Target:DebuffDownP(S.FrostFeverDebuff) and (not S.BreathofSindragosa:IsAvailable() or S.BreathofSindragosa:CooldownRemainsP() > 15)) then
            --     for _, Unit in ipairs(EnemyMelee) do if not Debuff.FrostFeverDebuff:Exist(Unit) then if  Spell.HowlingBlast:Cast(Unit) then return true end end end
            -- end
            -- -- frost_strike,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&(!talent.breath_of_sindragosa.enabled|cooldown.breath_of_sindragosa.remains>15)
            -- if Spell.FrostStrike:IsReady("Melee") and Buff.IcyTalonsBuff:Remain() <= 1 and Buff.IcyTalonsBuff:Exist() then
            --     for _, Unit in ipairs(EnemyMelee) do if  Spell.FrostStrike:Cast(Unit) then return true end end
            -- end
            -- if select(2, Player:GetEnemies(10)) >= 2 then
            --     return FrostAoe()
            -- else
            --     return FrostStandard()
            -- end
        end
    elseif Player.SpecID == "Unholy" then
        if (Target and Target.ValidEnemy and Target.Distance <= 5) or ((DMW.Player.Instance == "party" or DMW.Player.Instance == "raid" or DMW.Player.Instance == "scenario") and DMW.Player.Combat) then
            LocalsUnholy()
			if CDs then if UnholyRotationCDS() then return true end end
			if HUD.Defensive == 1 then
				if UnholyDefensive() then return true end
			end
			if HUD.OutbreakMode == 1 and UnholyOutbreak() then return true end
			if Talent.SoulReaper and Spell.SoulReaper:IsReady() then
				for _, Unit in ipairs(EnemyMelee) do
					if Unit:GetTTD(35) < 5 and Unit.TTD > 5 then
						if Spell.SoulReaper:Cast(Unit) then return true end
					end
				end
				for _, Unit in ipairs(EnemyMelee) do
					if Unit.HP <= 35 and  Unit.TTD > 5 then
						if Spell.SoulReaper:Cast(Unit) then return true end
					end
				end
			end
			if HUD.SetupCleaveMode == 1 then
				if UnholyRotationCleaveSetup() then return true end
				return true
			end
			if Pet and UnitPower("pet") >= 40 then
				if UnitExists("pettarget") then
					RunMacroText("/cast [@pettarget] Цапнуть")
				end
			end
			if Player.Runeforge == "DeadliestCoil" and Buff.DarkTransformation:Exist(Pet) and Buff.DarkTransformation:Remain(Pet) <= 4 and Spell.DeathCoil:IsReady() then
				for _, Unit in ipairs(Enemy30Y) do
					if Spell.DeathCoil:Cast(Unit) then return true end
				end
			end
            if EnemyMeleeCount >= 2 then
                if UnholyRotationAOE() then return true end
            else
                if UnholyRotationST() then return true end
			end
			if UnholySpender() then return true end
        end
    end
end
