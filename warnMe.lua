local warnMe = CreateFrame("Frame", "warnMeDummy", UIParent)
warnMe:RegisterEvent("ADDON_LOADED")
warnMe:RegisterEvent("PLAYER_TARGET_CHANGED")
warnMe:SetPoint("TOP", 0, 0)
warnMe:SetHeight(400)
warnMe:SetWidth(800)

warnMe.alert   = nil
warnMe.alert_t = 0
warnMe.state   = ""

warnMe.label = warnMe:CreateFontString("warnMeText")
warnMe.label:SetFont(STANDARD_TEXT_FONT, 18)
warnMe.label:SetText("foo")
--warnMe.label:SetTextColor(.9,.1,.1,1)
warnMe.label:SetShadowOffset(1,-1)
warnMe.label:SetShadowColor(.1,.1,.1,.8)
warnMe.label:SetAllPoints()
warnMe:Show()

-- loads default config
if(not warnMe_config) then
    warnMe_config = {}
    warnMe_config["sound"] = "RaidWarning"
    warnMe_config["interval"] = 10
    warnMe_config["warn_if_target_is_elite"] = true
    warnMe_config["warn_if_target_is_pvp"] = true
    warnMe_config["check_group_for_pvp_flag"] = true
end

function ShowAlert(message, console)
    warnMe.alert   = message
    warnMe.alert_t = 5
    warnMe.label:SetText(message)
    if(console == true) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff9e42f5<warnMe>|r " .. message)
    end

    if(not warnMe.label:IsShown()) then 
        warnMe.label:SetAlpha(1)
        warnMe.label:Show()
    end
end

warnMe:SetScript("OnEvent", function()
    if(event == "ADDON_LOADED")
	then
        if(arg1 == "warnMe") then
            DEFAULT_CHAT_FRAME:AddMessage("|cff9e42f5<warnMe>|r Addon loaded.")
        end
    elseif(event == "PLAYER_TARGET_CHANGED" and arg1 == nil) then
        if(warnMe_config["warn_if_target_is_pvp"]) then
            if(UnitIsPlayer("target") and UnitIsPVP("target")) then
                PlaySound(warnMe_config["sound"])
                ShowAlert("Your target |cffcccc22[" .. UnitName("target") .. "]|r is PVP flagged!", true)
            end
        end

        if(warnMe_config["warn_if_target_is_elite"]) then
            if(not IsInInstance() and UnitIsEnemy("player", "target") and UnitIsPlusMob("target")) then
                PlaySound(warnMe_config["sound"])
                ShowAlert("Your target |cffcccc22[" .. UnitName("target") .. "]|r is an ELITE!", false)
            end
        end
    end
end)

warnMe:SetScript("OnUpdate", function()
    local dt = arg1
    if(warnMe.time == nil) then 
        warnMe.time = 0
    end
    
    if(warnMe.alert_t >= 0) then
        warnMe.alert_t = warnMe.alert_t - dt
        if(warnMe.alert_t < 1) then
            warnMe.label:SetAlpha(warnMe.alert_t)
        end
        
        if(warnMe.alert_t < 0) then
            warnMe.label:Hide()
        end
    end
    
    if(warnMe_config["check_group_for_pvp_flag"]) then
        warnMe.time = warnMe.time - dt
        if(warnMe.time <= 0) then
            warnMe.time = warnMe_config["interval"]
            
            --- check pvp flags
            local state = ""
            local is_player_flagged = false
            if(UnitIsPVP("player")) then 
                is_player_flagged = true
                state = state .. "Y"
            end
            
            local pvp_tagged_party_members = {}
            local is_party_flagged = false
            for i=1, GetNumPartyMembers() do
                local party   = "party"..tostring(i)
                local name    = UnitName(party)
                local flagged = UnitIsPVP(party)
                if(flagged) then 
                    is_party_flagged = true
                    table.insert(pvp_tagged_party_members, name)
                    state = state .. "P" .. tostring(i)
                end
            end

            --- notifiy flagged players
            if(is_player_flagged or is_party_flagged) then
                if(warnMe.state ~= state) then
                    warnMe.state = state

                    PlaySound(warnMe_config["sound"])
                    
                    local message = "PvP flagged players: "
                    if(is_player_flagged) then
                        message = message .. "|cff42f5a7YOU|r "                        
                    end
            
                    if(is_party_flagged) then
                        local marked = ""
                        local num_marked = table.getn(pvp_tagged_party_members)
                        for k,v in pairs(pvp_tagged_party_members) do
                            message = message .. "|cfff542a7"..v.."|r "
                        end
                    end

                    if(message ~= "") then
                        ShowAlert(message, true)
                    end
                end
            end
        end
    end
end)