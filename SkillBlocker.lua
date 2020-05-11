blocker = {}
blocker.name = "SkillBlocker"

blocker.lock = {}
local currentHotbar
local flag = true -- flip-flop for prehook control

--==============================SavedVariables==============================--

local variableVersion = 2
local savedVarsName = "SkillBlockerVars"

local defaults = {
	settingsAccountWide = false,
	displayAlert = false,
	logToChat = true,
	rememberLocks = true,

	-- skills


mainBarSaved = { 
	[1] = false,
 	[2] = true, 
	[3] = false, 
	[4] = true, 
	[5] = false, 
	[6] = true
},

offBarSaved = { 
	[1] = true,
 	[2] = false, 
	[3] = true, 
	[4] = false, 
	[5] = true, 
	[6] = false
}


}

local function GetSettings()
	if blocker.settings.settingsAccountWide then
		return blocker.globalSettings
    else
		return blocker.settings
  end
end

blocker.GetSettings = GetSettings

--==============================LibAddonMenu==============================--

local LAM = LibAddonMenu2

local panelData = {
    type = "panel",
	name = "Skill Blocker",
	author = "@adjutant",
	version = "1.0",
	-- website = "https://www.esoui.com/downloads/***",
    -- feedback = "https://www.esoui.com/downloads/***#comments",
}

local optionsData = {

	[1] = {
		type = "checkbox",
        name = "Remember locked skills?",
        getFunc = function() return blocker.settings.rememberLocks end,
        setFunc = function(value) blocker.settings.rememberLocks = value end,
        width = "full",
  	},

	[2] = {
		type = "checkbox",
        name = "Enable account-wide settings:",
        getFunc = function() return blocker.settings.settingsAccountWide end,
        setFunc = function(value) blocker.settings.settingsAccountWide = value end,
        width = "full",
  	},

  	[3] = {
        type = "description",
        title = nil,
        text = "Note: this will make settings below account-wide, however locked skills remain per-character.",
        width = "full",
    },

    [4] = { -- header: Use global variables?
			type    = "header",
			name    = nil,
    },

    [5] = {
        type = "checkbox",
        name = "Display alert:",
       	tooltip = "Display ZOS-like alert on locked skill cast attempt",
        getFunc = function() return blocker.GetSettings().displayAlert end,
        setFunc = function(value) blocker.GetSettings().displayAlert = value end,
    },

    [6] = {
    	type = "checkbox",
    	name = "Log to chat:",
    	tooltip = "Log to chat on locked skill cast attempt",
        getFunc = function() return blocker.GetSettings().logToChat end,
        setFunc = function(value) blocker.GetSettings().logToChat = value end,
    },

    [7] = {
        type = "description",
        title = nil,
        text = "This addon is in active development. Feature requests and bug reports are very welcome! Please leave your comments at ESOUI.",
        width = "full",
    },
}

--==============================Main==============================--

local function loadSaved()
	for i = 1, 6 do
		blocker.lock[i].mainBarLocked = blocker.settings.mainBarSaved[i]
		blocker.lock[i].offBarLocked = blocker.settings.offBarSaved[i]
	end
end

local function drawLocks() -- refresh lock textures based on their state and current hotbar
    for i = 1, 6 do
        if currentHotbar == 0 then -- main bar
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
        elseif currentHotbar == 1 then -- offbar
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
            blocker.lock[i]:SetHidden(true) -- Werewolf, Volendrung, etc...
        end
    end
end

local function toggleLock(lock) -- toggle lock state based on current hotbar
	if currentHotbar == 0 then
    	if lock.mainBarLocked then
      		lock.mainBarLocked = false
      		blocker.settings.mainBarSaved[lock.index] = false
	  		PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
    	else
      		lock.mainBarLocked = true
      		blocker.settings.mainBarSaved[lock.index] = true
	  		PlaySound(SOUNDS.INVENTORY_ITEM_LOCKED)
    	end
  	elseif currentHotbar == 1 then
    	if lock.offBarLocked then
      		lock.offBarLocked = false
      		blocker.settings.offBarSaved[lock.index] = false
	  		PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
    	else
      		lock.offBarLocked = true
      		blocker.settings.offBarSaved[lock.index] = true
	  		PlaySound(SOUNDS.INVENTORY_ITEM_LOCKED)
    	end
  	end
  	drawLocks()
end

local function loadLocks() -- register lock controls and anchors
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

local function alert() -- called on locked skill cast attempt. More to come...?
	if (blocker.GetSettings().displayAlert) then
		ZO_Alert(UI_displayAlert_CATEGORY_ERROR, SOUNDS.CHAMPION_PENDING_POINTS_CLEARED, SI_TRADEACTIONRESULT62)
	end
	if blocker.GetSettings().logToChat then
		d("[Skill Blocker]: \""..GetAbilityName(GetSlotBoundId(slotNum)).."\" is locked")
	end
end

function blocker.unlockAll() -- hotkey
	for i = 1, 6 do
		blocker.lock[i].mainBarLocked = false
		blocker.lock[i].offBarLocked = false
	end
	drawLocks()
	d("[Skill Blocker]: all skills unlocked")
	PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
end

local function Initialize()
	EVENT_MANAGER:UnregisterForEvent(blocker.name, EVENT_ADD_ON_LOADED)

	ZO_CreateStringId("SI_BINDING_NAME_UNLOCK_ALL", "Unlock all skills")

	blocker.settings        = ZO_SavedVars:New(             savedVarsName, variableVersion, "settings", defaults)
  	blocker.globalSettings  = ZO_SavedVars:NewAccountWide(  savedVarsName,  variableVersion, "globals",  defaults)

--	blocker.savedVariables = ZO_SavedVars:NewAccountWide("SkillBlockerVars", blocker.variableVersion, nil, blocker.default)
	LAM:RegisterAddonPanel("Skill Blocker", panelData)
	LAM:RegisterOptionControls("Skill Blocker", optionsData)

  	currentHotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() -- get initial bar on login

  	loadLocks()
  	if (blocker.globalSettings.settingsAccountWide == false and blocker.globalSettings.rememberLocks) then
		d("[Skill Blocker]: Some of your skills are locked!")
  		loadSaved()
  	end
  	drawLocks()

  	ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", -- to keep currentHotbar relevant
    function(hotbarCategory, oldHotbarCategory)
    	currentHotbar = hotbarCategory
    	if SCENE_MANAGER:IsShowing("skills") then
        	drawLocks()
      	end
    end)

  	ZO_PreHook("ZO_ActionBar_CanUseActionSlots", function()
  		flag = not flag -- Since ZO_ActionBar_CanUseActionSlots is called twice for each ability cast
		if flag then
			slotNum = tonumber(debug.traceback():match('keybind = "ACTION_BUTTON_(%d)')) -- get pressed button
			if (slotNum == 9 or GetSlotBoundId(slotNum) == 0) then return false end -- break if consumable or empty slot
			if (currentHotbar == 0 and blocker.lock[slotNum - 2].mainBarLocked) or 
	   	    	(currentHotbar == 1 and blocker.lock[slotNum - 2].offBarLocked) then
					alert() -- notify player
					return true -- ESO won't run ability press if PreHook returns true
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