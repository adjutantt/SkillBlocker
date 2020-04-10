blocker = {}
blocker.name = "SkillBlocker"
blocker.lock = {}

local LAM = LibAddonMenu2

local panelData = {
    type = "panel",
	name = "Skill Blocker",
	author = "@adjutant",
	version = "1.0"
	registerForDefaults = true
}

local optionsData = {
    [1] = {
        type = "checkbox",
        name = "My Checkbox",
       	tooltip = "Checkbox's tooltip text.",
        getFunc = function() return true end,
        setFunc = function(value) d(value) end,
    },
}

local logToChat = true
local currentHotbar

local function drawLocks()
    for i = 1, 6 do
        if currentHotbar == 0 then
            blocker.lock[i]:SetHidden(false)
            if blocker.lock[i].mainBarLocked then
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/locked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/unlocked_up.dds")
            else
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/unlocked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/locked_up.dds")   
            end
        elseif currentHotbar == 1 then
            blocker.lock[i]:SetHidden(false)
            if blocker.lock[i].offBarLocked then
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/locked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/unlocked_up.dds")
            else
                blocker.lock[i]:SetNormalTexture("/esoui/art/miscellaneous/unlocked_up.dds")
                blocker.lock[i]:SetPressedTexture("/esoui/art/miscellaneous/locked_up.dds")    
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

local function Initialize()
	EVENT_MANAGER:UnregisterForEvent(blocker.name, EVENT_ADD_ON_LOADED)
	LAM2:RegisterAddonPanel("SkillBlocker", panelData)
	LAM2:RegisterOptionControls("SkillBlocker", optionsData)
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
		slotNum = tonumber(debug.traceback():match('keybind = "ACTION_BUTTON_(%d)'))
		if (currentHotbar == 0 and blocker.lock[slotNum - 2].mainBarLocked) or 
	   	   (currentHotbar == 1 and blocker.lock[slotNum - 2].offBarLocked) then
				ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.CHAMPION_PENDING_POINTS_CLEARED, SI_TRADEACTIONRESULT62)
		--	if (logToChat) then
		--		d("\""..GetAbilityName(GetSlotBoundId(slotNum)).."\" cast was prevented by Skill Blocker")
		--	end
				ZO_ActionBar_OnActionButtonUp(slotNum)
			
				return true
		end
	end)
end


local function OnAddOnLoaded(event, addonName)
	if addonName == blocker.name then
    	Initialize()
  	end
end

EVENT_MANAGER:RegisterForEvent(blocker.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)