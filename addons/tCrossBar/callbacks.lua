local renderTarget;
local isHidden = false;
local player = require('state.player');
local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);
local pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0, "8B4424046A016A0050B9????????E8????????F6D81BC040C3", 0, 0);
local pChatExpanded = ashita.memory.find('FFXiMain.dll', 0, '83EC??B9????????E8????????0FBF4C24??84C0', 0x04, 0);

local function GetMenuName()
    local subPointer = ashita.memory.read_uint32(pGameMenu);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

--Credit: Loonsie / 
local function GetChatExpanded()
    local ptr = ashita.memory.read_uint32(pChatExpanded);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr + 0xF1) ~= 0);
end

local function GetEventSystemActive()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pEventSystem + 1);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr) == 1);

end

local function GetInterfaceHidden()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr + 0xB4) == 1);
end

local altMaps = T{
    ['menu    cnqframe'] = true,
    ['menu    scanlist'] = true,
};
local mainMenuPrefixes = T{
    'menu    status',
    'menu    equip',
    'menu    item',
    'menu    magic',
    'menu    ability',
    'menu    config',
    'menu    mission',
    'menu    quest',
    'menu    keyitem',
    'menu    bazaar',
    'menu    delivery',
    'menu    comment',
    'menu    profile',
    'menu    jobpoint',
    'menu    unity',
    'menu    master',
    'menu    moghouse',
    'menu    merit',
    'menu    recruit',
    'menu    friendlist',
    'menu    linkshell',
    'menu    party',
    'menu    trade',
    'menu    shop',
    'menu    send',
    'menu    recv',
};

local function IsEngaged()
    local party = AshitaCore:GetMemoryManager():GetParty();
    if (party == nil) then
        return false;
    end
    local playerIndex = party:GetMemberTargetIndex(0);
    if (playerIndex == 0) then
        return false;
    end
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    if (entity == nil) then
        return false;
    end
    return (entity:GetStatus(playerIndex) == 1);
end

local function IsMainMenuOpen()
    local menuName = GetMenuName();
    if (menuName == nil) or (menuName == '') then
        return false;
    end
    for _, prefix in ipairs(mainMenuPrefixes) do
        if (string.sub(menuName, 1, #prefix) == prefix) then
            return true;
        end
    end
    return false;
end

local function ShouldHide()
    if (gSettings.HideWhileZoning) then
        if (player:GetLoggedIn() == false) then
            return true;
        end
    end

    if (gSettings.HideWhileCutscene) then
        if (GetEventSystemActive()) then
            return true;
        end
    end

    if (gSettings.HideWhileMap) then
        local activeMenu = GetMenuName();
        if (string.sub(activeMenu, 1, 11) == 'menu    map') or (altMaps[activeMenu]) then
            return true;
        end
    end
    
    if (gSettings.HideWhileChat) then
        if (GetChatExpanded()) then
            return true;
        end
    end

    if (GetInterfaceHidden()) then
        return true;
    end

    if (gSettings.HideWhileMainMenu) then
        if (IsMainMenuOpen()) then
            return true;
        end
    end

    if (gSettings.HideWhenInactive) then
        local macroState = gController:GetMacroState();
        if (macroState == 0) and (IsEngaged() == false) then
            return true;
        end
    end
    
    return false;
end

local function IsDraggingHotbar()
    if (gHotbarDisplay == nil) or (not gHotbarDisplay.Valid) then
        return false;
    end
    for _, hotbar in ipairs(gHotbarDisplay.Hotbars) do
        if hotbar.AllowDrag then
            return true;
        end
    end
    return false;
end

ashita.events.register('d3d_present', 'd3d_present_cb', function ()
player:UpdateBLUSpells();
    gController:Tick();    
    gConfigGUI:Render();
    gBindingGUI:Render();
    gMacroEditor:Render();
    gHotbarGUI:Render();

    renderTarget = nil;
    if (gConfigGUI.ForceDisplay) then
        isHidden = false;
        gConfigGUI.ForceDisplay:Render(1);
        renderTarget = gConfigGUI.ForceDisplay;
        return;
    end

    if (gBindingGUI.ForceDisplay) then
        gBindingGUI.ForceDisplay:Render(gBindingGUI.ForceState);
        renderTarget = gBindingGUI.ForceDisplay;
        return;
    end

    local draggingHotbar = IsDraggingHotbar();
    
    if (ShouldHide()) and (not draggingHotbar) then
        isHidden = true;
        return;
    end
    
    isHidden = false;
    
    renderTarget = gSingleDisplay;
    local macroState = gController:GetMacroState();

    if (gSettings.ShowExpandedDisplay) and ((macroState == 5) or (macroState == 6)) then
        local mainState = (macroState == 5) and 1 or 2;
        if (gSettings.LTRTMode == 'FullDouble') then
            gDoubleDisplay:Render(mainState, false, -1);
            renderTarget = gDoubleDisplay;
        elseif (gSettings.LTRTMode == 'HalfDouble') then
            gDoubleDisplay:Render(mainState, true, -1);
            renderTarget = gDoubleDisplay;
        else
            gSingleDisplay:Render(mainState);
            renderTarget = gSingleDisplay;
        end
        gExpandedDisplay:Render(macroState);
    elseif (macroState == 0) then
        if (gSettings.ShowDoubleDisplay) then
            gDoubleDisplay:Render(0, false, 0);
            renderTarget = gDoubleDisplay;
        end
        if (gSettings.ShowExpandedDisplay) then
            gExpandedDisplay:Render();
        end
    elseif (macroState < 3) then
        if (gSettings.LTRTMode == 'FullDouble') then
            gDoubleDisplay:Render(macroState, false, macroState);
            renderTarget = gDoubleDisplay;
        elseif (gSettings.LTRTMode == 'HalfDouble') then
            gDoubleDisplay:Render(macroState, true);
            if (gSettings.ShowExpandedDisplay) then
                gExpandedDisplay:Render();
            end
        else
            renderTarget:Render(macroState);
            if (gSettings.ShowExpandedDisplay) then
                gExpandedDisplay:Render();
            end
        end
    else
        renderTarget:Render(macroState);
        if (gSettings.ShowExpandedDisplay) then
            gExpandedDisplay:Render();
        end
    end

    if (gSettings.ShowHotbars or draggingHotbar) and (gHotbarDisplay) and (gHotbarDisplay.Valid) then
        gHotbarDisplay:Render();
    end
end);

local mouseDown;
ashita.events.register('mouse', 'mouse_cb', function (e)
    if (isHidden) and (gConfigGUI.ForceDisplay == nil) and (not IsDraggingHotbar()) then
        return;
    end

    if (renderTarget ~= nil) then
        renderTarget:HandleMouse(e);
    end

    if (gSettings.ShowExpandedDisplay) and (not e.blocked) then
        gExpandedDisplay:HandleMouse(e);
    end

    if (gSettings.ShowHotbars or IsDraggingHotbar()) and (gHotbarDisplay) and (gHotbarDisplay.Valid) and (not e.blocked) then
        gHotbarDisplay:HandleMouse(e);
    end

    if (e.message == 513) then
        if (e.blocked == true) then
            mouseDown = true;
        end
    end

    if (e.message == 514) then
        if mouseDown then
            e.blocked = true;
            mouseDown = false;
        end
    end
end);

local modifierScanCodes = {
    [0x1D] = 'Ctrl', [0x9D] = 'Ctrl',
    [0x38] = 'Alt',  [0xB8] = 'Alt',
    [0x2A] = 'Shift', [0x36] = 'Shift',
};

local function ShouldBlockModifier(modifierName)
    if (ShouldHide()) then
        return false;
    end
    if (gHotbarInput == nil) then
        return false;
    end
    local modBinds = gHotbarInput:HasModifierBinds();
    if (modBinds == nil) then
        return false;
    end
    return modBinds[modifierName] == true;
end

ashita.events.register('keyboard', 'keyboard_cb', function (e)
    local modName = modifierScanCodes[e.key];
    if (modName ~= nil) then
        if (ShouldBlockModifier(modName)) then
            e.blocked = true;
            return;
        end
    end

    local managerCapturing = gHotbarManager:GetCapturing();
    local guiCapturing = (gHotbarGUI ~= nil) and (gHotbarGUI.GetCapturing ~= nil) and (gHotbarGUI:GetCapturing());
    if (managerCapturing or guiCapturing) then
        if (managerCapturing) then
            gHotbarManager:HandleKeyCapture(e.key, (e.down == 1));
        elseif (guiCapturing) then
            gHotbarGUI:HandleKeyCapture(e.key, (e.down == 1));
        end
        e.blocked = true;
        return;
    end
end);