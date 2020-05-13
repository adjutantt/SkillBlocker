SkillBlocker = {}

SkillBlocker.lock = {}

local ADDON_NAME = "SkillBlocker"
local ADDON_VERSION	= "1.0b"
local ESOUI_URL = "https://www.esoui.com/downloads/info2619-SkillBlocker.html"
local currentHotbar
local flag = true -- flip-flop for prehook control
local slotNum

--==============================SavedVariables==============================--

local variableVersion = 5
local savedVarsName = "SkillBlockerVars"

local defaults = {
	settingsAccountWide = true,
	displayAlert = false,
	logToChat = true,
	rememberLocks = true,
	alertLogin = true,

	mainBarSaved = { 
		[1] = false,
 		[2] = false, 
		[3] = false, 
		[4] = false, 
		[5] = false, 
		[6] = false
	},

	offBarSaved = { 
		[1] = false,
 		[2] = false, 
		[3] = false, 
		[4] = false, 
		[5] = false, 
		[6] = false
	}
}

local function getSettings()
	if SkillBlocker.settings.settingsAccountWide then
		return SkillBlocker.globalSettings
    else
		return SkillBlocker.settings
  end
end

SkillBlocker.getSettings = getSettings

--==============================LibAddonMenu==============================--

local LAM = LibAddonMenu2

local panelData = {
    type = "panel",
	name = "Skill Blocker",
	author = "@adjutant",
	version = ADDON_VERSION,
	website = ESOUI_URL,
}

local optionsData = {

	[1] = {
		type = "checkbox",
        name = "Remember locked skills?",
        getFunc = function() return SkillBlocker.settings.rememberLocks end,
        setFunc = function(value) SkillBlocker.settings.rememberLocks = value end,
        width = "full",
  	},

	[2] = {
		type = "checkbox",
        name = "Enable account-wide settings:",
        getFunc = function() return SkillBlocker.settings.settingsAccountWide end,
        setFunc = function(value) SkillBlocker.settings.settingsAccountWide = value end,
        width = "full",
        requiresReload = true
  	},

  	[3] = {
        type = "description",
        title = nil,
        text = "Note: this will make settings below account-wide, however locked skills remain per-character.",
        width = "full",
    },

    [4] = {
			type    = "header",
			name    = nil,
    },

    [5] = {
        type = "checkbox",
        name = "Display alert:",
       	tooltip = "Display ZOS-like alert on locked skill cast attempt",
        getFunc = function() return SkillBlocker.getSettings().displayAlert end,
        setFunc = function(value) SkillBlocker.getSettings().displayAlert = value end,
    },

    [6] = {
    	type = "checkbox",
    	name = "Log to chat:",
    	tooltip = "Log to chat on locked skill cast attempt",
        getFunc = function() return SkillBlocker.getSettings().logToChat end,
        setFunc = function(value) SkillBlocker.getSettings().logToChat = value end,
    },

    [7] = {
    	type = "checkbox",
    	name = "Alert on login:",
    	tooltip = "Display a chat message on login if you have saved locked skills",
        getFunc = function() return SkillBlocker.getSettings().alertLogin end,
        setFunc = function(value) SkillBlocker.getSettings().alertLogin = value end,
    },

    [8] = {
        type = "description",
        title = nil,
        text = "This addon is in active development. Feature requests and bug reports are very welcome! Please leave your comments at ESOUI.",
        width = "full",
    },
}

--==============================Main==============================--

local function loadSaved()
	for i = 1, 6 do
		SkillBlocker.lock[i].mainBarLocked = SkillBlocker.settings.mainBarSaved[i]
		SkillBlocker.lock[i].offBarLocked = SkillBlocker.settings.offBarSaved[i]
	end
end

local function drawLocks() -- refresh lock textures based on their state and current hotbar
    for i = 1, 6 do
        if currentHotbar == 0 then -- main bar
            SkillBlocker.lock[i]:SetHidden(false)
            if SkillBlocker.lock[i].mainBarLocked then
                SkillBlocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/locked_up.dds")
                SkillBlocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/locked_down.dds")
                SkillBlocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/locked_over.dds")
            else
                SkillBlocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/unlocked_up.dds")
                SkillBlocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/unlocked_down.dds")
                SkillBlocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/unlocked_over.dds")   
            end
        elseif currentHotbar == 1 then -- offbar
            SkillBlocker.lock[i]:SetHidden(false)
            if SkillBlocker.lock[i].offBarLocked then
                SkillBlocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/locked_up.dds")
                SkillBlocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/locked_down.dds")
                SkillBlocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/locked_over.dds")
            else
                SkillBlocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/unlocked_up.dds")
                SkillBlocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/unlocked_down.dds") 
                SkillBlocker.lock[i]:SetMouseOverTexture("/esoui/art/miscellaneous/unlocked_over.dds")   
            end
        else
            SkillBlocker.lock[i]:SetHidden(true) -- Werewolf, Volendrung, etc...
        end
    end
end

local function toggleLock(lock) -- toggle lock state based on current hotbar
	if currentHotbar == 0 then
    	if lock.mainBarLocked then
      		lock.mainBarLocked = false
      		SkillBlocker.settings.mainBarSaved[lock.index] = false
	  		PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
    	else
      		lock.mainBarLocked = true
      		SkillBlocker.settings.mainBarSaved[lock.index] = true
	  		PlaySound(SOUNDS.INVENTORY_ITEM_LOCKED)
    	end
  	elseif currentHotbar == 1 then
    	if lock.offBarLocked then
      		lock.offBarLocked = false
      		SkillBlocker.settings.offBarSaved[lock.index] = false
	  		PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
    	else
      		lock.offBarLocked = true
      		SkillBlocker.settings.offBarSaved[lock.index] = true
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
      	SkillBlocker.lock[i] = lock
	end
	SkillBlocker.lock[1]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton1, TOP, 0, -7)
  	SkillBlocker.lock[2]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton2, TOP, 0, -7)
  	SkillBlocker.lock[3]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton3, TOP, 0, -7)
  	SkillBlocker.lock[4]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton4, TOP, 0, -7)
  	SkillBlocker.lock[5]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton5, TOP, 0, -7)
  	SkillBlocker.lock[6]:SetAnchor(BOTTOM, ZO_SkillsAssignableActionBarButton6, TOP, 0, -7)
end

local function alert() -- called on locked skill cast attempt. More to come...?
	if (SkillBlocker.getSettings().displayAlert) then
		ZO_Alert(UI_displayAlert_CATEGORY_ERROR, SOUNDS.CHAMPION_PENDING_POINTS_CLEARED, SI_TRADEACTIONRESULT62)
	end
	if SkillBlocker.getSettings().logToChat then
		d("[Skill Blocker]: \""..GetAbilityName(GetSlotBoundId(slotNum)).."\" is locked")
	end
end

function SkillBlocker.unlockAll() -- hotkey
	for i = 1, 6 do
		SkillBlocker.lock[i].mainBarLocked = false
		SkillBlocker.lock[i].offBarLocked = false
	end
	drawLocks()
	d("[Skill Blocker]: all skills unlocked")
	PlaySound(SOUNDS.INVENTORY_ITEM_UNLOCKED)
end

local function Initialize()
	EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

	ZO_CreateStringId("SI_BINDING_NAME_UNLOCK_ALL", "Unlock all skills")

	SkillBlocker.settings = ZO_SavedVars:NewCharacterIdSettings(savedVarsName, variableVersion, "settings", defaults, GetWorldName())
  	SkillBlocker.globalSettings = ZO_SavedVars:NewAccountWide(savedVarsName, variableVersion, "globals", defaults, GetWorldName(), "AllAccountsTheSame")

	LAM:RegisterAddonPanel("Skill Blocker", panelData)
	LAM:RegisterOptionControls("Skill Blocker", optionsData)

  	currentHotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() -- get initial bar on login

  	loadLocks()

  	if (SkillBlocker.getSettings().rememberLocks) then
  		loadSaved()
  		if (SkillBlocker.getSettings().alertLogin) then
  			for i = 1, 6 do
  				if (SkillBlocker.lock[i].mainBarLocked or SkillBlocker.lock[i].offBarLocked) then
  					d("[Skill Blocker]: Some of your skills are locked!")
  					break
  				end
  			end
  		end
  	end

  	drawLocks()

  	ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", -- to keep currentHotbar relevant
    function(hotbarCategory, oldHotbarCategory)
    	currentHotbar = hotbarCategory
    	if SCENE_MANAGER:IsShowing("skills") then -- refresh textures if hotbar is swapped while in skills menu
        	drawLocks()
      	end
    end)

  	ZO_PreHook("ZO_ActionBar_CanUseActionSlots", function()
  		flag = not flag -- Since ZO_ActionBar_CanUseActionSlots is called twice for each ability cast
		if flag then
			slotNum = tonumber(debug.traceback():match('keybind = "ACTION_BUTTON_(%d)')) -- get pressed button
			if (slotNum == 9 or GetSlotBoundId(slotNum) == 0) then return false end -- break if consumable or empty slot
				if (currentHotbar == 0 and SkillBlocker.lock[slotNum - 2].mainBarLocked) or 
	   	    	(currentHotbar == 1 and SkillBlocker.lock[slotNum - 2].offBarLocked) then
					alert() -- notify player
					return true -- ESO won't run ability press if PreHook returns true
			end
		end
	end)
end

local function OnAddOnLoaded(event, addonName)
	if addonName == ADDON_NAME then
    	Initialize()
  	end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)