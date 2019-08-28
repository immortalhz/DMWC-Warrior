local DMW = DMW
DMW.Rotations.WARRIOR = {}
local Warrior = DMW.Rotations.WARRIOR
local UI = DMW.UI

function Warrior.Settings()
    UI.HUD.Options = {
        [1] = {
            Test = {
                [1] = {Text = "HUD Test |cFF00FF00On", Tooltip = ""},
                [2] = {Text = "HUD Test |cFFFFFF00Sort Of On", Tooltip = ""},
                [3] = {Text = "HUD Test |cffff0000Disabled", Tooltip = ""}
            }
        }
    }

    UI.AddHeader("This Is A Header")
    UI.AddDropdown("This Is A Dropdown", nil, {"Yay", "Nay"}, 1)
    UI.AddToggle("This Is A Toggle", "This is a tooltip", true)
    -- UI.AddRange("This Is A Range", "One more tooltip", 0, 100, 1, 70)
    UI.AddToggle("AutoTarget", nil, true)
    UI.AddToggle("Rend", nil, true)
    UI.AddToggle("BattleShout", nil, true)
    UI.AddToggle("Overpower", nil, true)
    UI.AddToggle("Revenge", nil, true)
    UI.AddToggle("Rend", nil, true)
    UI.AddToggle("Sunder Target", nil, true)
    UI.AddToggle("Thunderclap", nil, true)
    UI.AddRange("Rage Dump", "Will Dump Rage after ", 0, 100, 1, 70)
end