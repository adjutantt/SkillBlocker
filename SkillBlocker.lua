blocker = {}
blocker.name = "SkillBlocker"
blocker.lock = {}

blocker.savedVariables = {}
blocker.variableVersion = 3

blocker.default = {
	displayAlert = true,
	logToChat = true
}

local LAM = LibAddonMenu2

local flag = true -- flip-flop for prehook control

local panelData = {
    type = "panel",
	name = "Skill Blocker",
	author = "@adjutant",
	version = "1.0",
	registerForDefaults = true
}

local optionsData = {
    [1] = {
        type = "checkbox",
        name = "Display alert:",
       	tooltip = "Display an alert on locked skill cast attempt",
       	default = blocker.default.displayAlert,
        getFunc = function() return blocker.savedVariables.displayAlert end,
        setFunc = function(value) blocker.savedVariables.displayAlert = value end,
    },

    [2] = {
    	type = "checkbox",
    	name = "Log to chat:",
    	tooltip = "Log to chat on locked skill cast attempt",
    	default = blocker.default.logToChat,
        getFunc = function() return blocker.savedVariables.logToChat end,
        setFunc = function(value) blocker.savedVariables.logToChat = value end,
    },
}

local currentHotbar

local function drawLocks()
    for i = 1, 6 do
        if currentHotbar == 0 then
            blocker.lock[i]:SetHidden(false)
            if blocker.lock[i].mainBarLocked then
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/locked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/locked_down.dds")
                blocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/locked_over.dds")
            else
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/unlocked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/unlocked_down.dds")
                blocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/unlocked_over.dds")   
            end
        elseif currentHotbar == 1 then
            blocker.lock[i]:SetHidden(false)
            if blocker.lock[i].offBarLocked then
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/locked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/locked_down.dds")
                blocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/locked_over.dds")
            else
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/unlocked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/unlocked_down.dds") 
                blocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/unlocked_over.dds")   
            end
        else
            blocker.lock[i]:SetHidden(true)
        end
    end
end

local function toggleLock(lock)
	if currentHotbar == 0 then
    	if lock.mainBarLocked then
      		lock.mainBarLocked = false
	  		PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
    	else
      		lock.mainBarLocked = true
	  		PlaySound(SOUNDS.INVENTORY_ITEM_LOCKED)
    	end
  	elseif currentHotbar == 1 then
    	if lock.offBarLocked then
      		lock.offBarLocked = false
	  		PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
    	else
      		lock.offBarLocked = true
	  		PlaySound(SOUNDS.INVENTORY_ITEM_LOCKED)
    	end
  	end
  	drawLocks()
end
  
local function loadLocks()
	for i = 1, 6 do
    	local lock = CreateControl(string.format("lock%d", i), ZO_SkillsAssignableActionBar, CT_BUTTON)
      	lock.index = i
      	lock.mainBarLocked = false
      	lock.offBarLocked = false
      	lock:SetDimensions(16,16)
      	lock:SetNormalTexture("/esoui/art/miscellaneous/unlocked_up.dds")
      	lock:SetPressedTexture("/esoui/art/miscellaneous/locked_up.dds")
      	lock:SetHandler("OnClicked", toggleLock)
      	blocker.lock[i] = lock
	end
	blocker.lock[1]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton1, TOP, 0, -7)
  	blocker.lock[2]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton2, TOP, 0, -7)
  	blocker.lock[3]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton3, TOP, 0, -7)
  	blocker.lock[4]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton4, TOP, 0, -7)
  	blocker.lock[5]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton5, TOP, 0, -7)
  	blocker.lock[6]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton6, TOP, 0, -7)
end

local function alert()
	if (blocker.savedVariables.displayAlert) then
		ZO_Alert(UI_displayAlert_CATEGORY_ERROR, SOUNDS.CHAMPION_PENDING_POINTS_CLEARED, SI_TRADEACTIONRESULT62)
	end
	if blocker.savedVariables.logToChat then
		d("[Skill Blocker]: \""..GetAbilityName(GetSlotBoundId(slotNum)).."\" is locked")
	end
end

local function Initialize()
	EVENT_MANAGER:UnregisterForEvent(blocker.name, EVENT_ADD_ON_LOADED)
	blocker.savedVariables = ZO_SavedVars:NewAccountWide("SkillBlockerVars", blocker.variableVersion, nil, blocker.default)
	LAM:RegisterAddonPanel("Skill Blocker", panelData)
	LAM:RegisterOptionControls("Skill Blocker", optionsData)
  	currentHotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory()

  	loadLocks()
  	drawLocks()

  	ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", 
    function(hotbarCategory, oldHotbarCategory)
    	currentHotbar = hotbarCategory
    	if SCENE_MANAGER:IsShowing("skills") then
        	drawLocks()
      	end
    end)

  	ZO_PreHook("ZO_ActionBar_CanUseActionSlots", function()
  		flag = not flag -- Since ZO_ActionBar_CanUseActionSlots is called twice for each ability cast
		if flag then
			slotNum = tonumber(debug.traceback():match('keybind = "ACTION_BUTTON_(%d)'))
			if (currentHotbar == 0 and blocker.lock[slotNum - 2].mainBarLocked) or 
	   	    	(currentHotbar == 1 and blocker.lock[slotNum - 2].offBarLocked) then
					ZO_ActionBar_OnActionButtonUp(slotNum)
					alert()
					return true
			end
		end
	end)
end

local function OnAddOnLoaded(event, addonName)
	if addonName == blocker.name then
    	Initialize()
  	end
end

EVENT_MANAGER:RegisterForEvent(blocker.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)