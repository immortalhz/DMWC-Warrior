local DMW = DMW
DMW.Rotations.DEATHKNIGHT = {}
local DEATHKNIGHT = DMW.Rotations.DEATHKNIGHT
local UI = DMW.UI

function DEATHKNIGHT.Settings()
    -- DMW.Helpers.Rotation.CastingCheck = false

    UI.HUD.Options = {
        [1] = {
            Defensive = {
                [1] = {Text = "|cFF00FF00Defensives On", Tooltip = ""},
                [2] = {Text = "|cFFFFFF00No Defensives", Tooltip = ""}
            }
		}
	}
    if DMW.Player.SpecID == "Blood" then
        UI.HUD.Options[2] = {
            PullMode = {
                [1] = {Text = "|cFF00FF00Pull", Tooltip = ""},
                [2] = {Text = "Pull", Tooltip = ""}
            }
        }
        UI.HUD.Options[3] = {
            TauntMode = {
                [1] = {Text = "|cFF00FF00Taunt", Tooltip = ""},
                [2] = {Text = "Taunt", Tooltip = ""}
            }
		}
	elseif DMW.Player.SpecID == "Unholy" then
		UI.HUD.Options[2] = {
            OutbreakMode = {
                [1] = {Text = "|cFF00FF00Outbreak", Tooltip = ""},
                [2] = {Text = "Outbreak", Tooltip = ""}
            }
        }
        UI.HUD.Options[3] = {
            SetupCleaveMode = {
                [1] = {Text = "|cFF00FF00Setup Mode", Tooltip = ""},
                [2] = {Text = "Default", Tooltip = ""}
            }
		}
	end



	    --Healing
        UI.AddTab("Defensives")
		UI.AddHeader("")
		if DMW.Player.SpecID == "Blood" then
			UI.AddRange("Critical Death Strike", "", 0, 100, 5, 0)
			UI.AddRange("Lichborne", "", 0, 100, 5, 0)
			UI.AddRange("RuneTap", "", 0, 100, 5, 0)
			UI.AddRange("DancingRW", "", 0, 100, 5, 0)
			UI.AddRange("IceboundFortitude", "", 0, 100, 5, 0)
			UI.AddRange("VampiricBlood", "", 0, 100, 5, 0)
			UI.AddRange("BoneStorm", "", 0, 100, 5, 0)
		end
	if DMW.Player.SpecID == "Unholy" then
		UI.AddTab("Starter")
		UI.AddToggle("Army of the Dead", nil, false)
	end
    -- UI.AddHeader("This Is A Header")
    -- UI.AddDropdown("This Is A Dropdown", nil, {"Yay", "Nay"}, 1)
    -- UI.AddToggle("This Is A Toggle", "This is a tooltip", true)
    -- UI.AddRange("This Is A Range", "One more tooltip", 0, 100, 1, 70)
    -- UI.AddHeader("Usual Options")
    --     -- UI.AddToggle("AutoExecute360", nil, false)
    --     -- UI.AddRange("Rotation", "4 = furyprot, 3 leveling, 2 - dps , 1 - tanking  ", 1, 4, 1, 1)
    --     UI.AddToggle("Debug", nil, false)
    --     UI.AddDropdown("Rotation", nil, {"Tanking","Fury","Fury/Slam","Fury/Prot","Testing", "PVP", "Arms PVP", "TESTTESTTEST"}, "Tanking")
    --     -- UI.AddRange("Stance", "any, combat, def, bers", 1, 4, 1, 1)
    --     UI.AddDropdown("First check Stance", "", {"Battle","Defensive","Berserker"}, "Battle")
    --     UI.AddDropdown("Second check Stance", "", {"Battle","Defensive","Berserker"}, "Berserker")
    --     UI.AddDropdown("Third check Stance", "", {"Battle","Defensive","Berserker"}, "Defensive")
    --     UI.AddToggle("Charge", nil, false)
    -- UI.AddHeader("Auto stuff")
    --     UI.AddToggle("AutoFaceMelee", nil, false)
    --     UI.AddToggle("AutoTarget", nil, false)
    --     UI.AddToggle("AutoTreatTarget", nil, false)
    --     UI.AddToggle("BattleShout", nil, true)
    --     UI.AddToggle("Pummel", nil, false)
    --     UI.AddToggle("Auto Disable SS", nil, false)
    -- UI.AddHeader("Big Cooldowns")
    --     UI.AddToggle("Racial", nil, false)
    --     UI.AddToggle("asd", nil, false)
    --     UI.AddToggle("assd", nil, false)
    --     UI.AddToggle("Pumfmel", nil, false)
    --     UI.AddToggle("Bloodrage", nil, false)
    -- UI.AddHeader("Dps shit")
    --     UI.AddToggle("Rend", nil, false)
    --     UI.AddToggle("MS/BT", nil, true)
    --     UI.AddToggle("Whirlwind", nil, true)
    --     UI.AddToggle("SweepingStrikes", nil, false)
    --     UI.AddToggle("Overpower", nil, true)
    -- UI.AddHeader("Tank stuff")
    --     UI.AddToggle("Revenge", nil, false)
    --     UI.AddToggle("SunderArmor", "Applies SunderArmor debuff to Targets", false,true)
	-- UI.AddDropdown("Apply # Stacks of Sunder Armor", "Apply # Stacks of Sunder Armor", {"1","2","3","4","5"}, "3")

    --     UI.AddToggle("MockingBlow", nil, false)
    --     UI.AddToggle("Taunt", nil, false)
    --     UI.AddToggle("Use ShieldBlock", nil, true)
    --     UI.AddRange("Shieldblock HP", nil, 30, 100, 10, 50)
    -- UI.AddHeader("Debuffs")
    --     UI.AddRange("PiercingHowl", "Units count w/o debuff", 0, 10, 1, 0)
    --     UI.AddRange("ThunderClap", "Units count w/o debuff", 0, 10, 1, 0)
    --     UI.AddRange("DemoShout", "Units count w/o debuff", 0, 10, 1, 0)
    -- UI.AddHeader("Experiments")
    --     UI.AddToggle("abuse", nil, false)
    --     UI.AddRange("abuse range", "qwe", 0, 3, 0.01, 0.5)
    --     UI.AddToggle("Stop If Shift", nil, false)
    -- UI.AddHeader("Misc")
    --     UI.AddRange("Rage Lost on stance change", "Rage Lost on stance change", 0, 100, 5, 50)
    --     UI.AddToggle("Tagger", nil, false)
    --     UI.AddToggle("questTagger", nil, false)
    --     UI.AddToggle("BattleStance NoCombat", nil, false)
    --     UI.AddRange("Berserker Rage", "How many units", 0, 5, 1, 0)
    --     UI.AddToggle("Assist Use", nil, false)
    --     UI.AddToggle("show", nil, false)
    -- UI.AddHeader("Dump Stuff")
    --     UI.AddToggle("Dump Enable", nil, false)
    --     UI.AddRange("Rage Dump", "Will Dump Rage after ", 0, 100, 5, 50)
    --     UI.AddToggle("Cleave", nil, false)
    --     UI.AddToggle("HeroicStrike", nil, false)
    --     UI.AddToggle("Hamstring Dump if WF", nil, false)
    --     UI.AddToggle("Hamstring Dump", nil, false)
    --     UI.AddToggle("WhirlWind", nil, false)
    --     UI.AddToggle("Bloodthirst/MS", nil, false)
    --     UI.AddToggle("Slam Dump", nil, false)
    --     UI.AddToggle("Demo Shout", nil, false)
    --     UI.AddToggle("Thunder Clap", nil, false)

end
