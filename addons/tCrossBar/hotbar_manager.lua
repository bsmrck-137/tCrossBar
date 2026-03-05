local imgui = require('imgui');
local header = { 1.0, 0.75, 0.55, 1.0 };
local activeHeader = { 0.5, 1.0, 0.5, 1.0 };

local state = {
    SelectedHotbar = 1,
    HotkeyInputs = {},
};

local keyNames = {
    [0x01] = 'ESCAPE', [0x02] = '1', [0x03] = '2', [0x04] = '3', [0x05] = '4',
    [0x06] = '5', [0x07] = '6', [0x08] = '7', [0x09] = '8', [0x0A] = '9',
    [0x0B] = '0', [0x0C] = '-', [0x0D] = '=', [0x0E] = 'BACK',
    [0x0F] = 'TAB', [0x10] = 'Q', [0x11] = 'W', [0x12] = 'E', [0x13] = 'R',
    [0x14] = 'T', [0x15] = 'Y', [0x16] = 'U', [0x17] = 'I', [0x18] = 'O',
    [0x19] = 'P', [0x1A] = '[', [0x1B] = ']', [0x1C] = 'RETURN',
    [0x1E] = 'A', [0x1F] = 'S', [0x20] = 'D', [0x21] = 'F', [0x22] = 'G',
    [0x23] = 'H', [0x24] = 'J', [0x25] = 'K', [0x26] = 'L', [0x27] = "'",
    [0x28] = '`', [0x2C] = 'Z', [0x2D] = 'X', [0x2E] = 'C', [0x2F] = 'V',
    [0x30] = 'B', [0x31] = 'N', [0x32] = 'M', [0x33] = ',', [0x34] = '.',
    [0x35] = '/', [0x39] = 'SPACE',
    [0xC8] = 'UP', [0xD0] = 'DOWN', [0xCB] = 'LEFT', [0xCD] = 'RIGHT',
    [0x3B] = 'F1', [0x3C] = 'F2', [0x3D] = 'F3', [0x3E] = 'F4',
    [0x3F] = 'F5', [0x40] = 'F6', [0x41] = 'F7', [0x42] = 'F8',
    [0x43] = 'F9', [0x44] = 'F10', [0x57] = 'F11', [0x58] = 'F12',
};

local function GetHotkeyLabel(hotkey)
    if (hotkey == nil) or (hotkey == '') then
        return '';
    end
    
    local result = hotkey;
    result = string.gsub(result, '%^', 'Ctrl+');
    result = string.gsub(result, '!', 'Alt+');
    result = string.gsub(result, '%+', 'Shift+');
    result = string.gsub(result, '#', 'Apps+');
    
    return result;
end

local function SaveHotkey(barIndex, slotIndex, hotkey)
    if (hotkey ~= nil) and (hotkey ~= '') then
        local success, err = gHotbarInput:ValidateKeybind(hotkey);
        if not success then
            Error(string.format('Cannot bind key %s: %s', hotkey, err));
            return false;
        end
    end
    
    gHotbarBindings:SetHotkey(barIndex, slotIndex, hotkey, false);
    
    if gHotbarInput then
        gHotbarInput:RefreshKeybinds();
    end
    
    return true;
end

local function ClearSlot(barIndex, slotIndex)
    local hotbars = gHotbarBindings:GetMergedHotbars();
    if (hotbars ~= nil) and (hotbars[barIndex] ~= nil) and (hotbars[barIndex].Slots ~= nil) then
        local slot = hotbars[barIndex].Slots[slotIndex];
        if (slot ~= nil) and (slot.Hotkey ~= nil) then
            gHotbarInput:ClearKeybind(barIndex, slotIndex);
        end
    end
    
    gHotbarBindings:ClearSlot(barIndex, slotIndex, false);
    
    if gHotbarInput then
        gHotbarInput:RefreshKeybinds();
    end
end

local function InitHotkeyInputs()
    for i = 1, 12 do
        if (state.HotkeyInputs[i] == nil) then
            state.HotkeyInputs[i] = { '' };
        end
    end
end

local function SyncHotkeyInputs()
    local hotbar = gHotbarBindings:GetHotbar(state.SelectedHotbar);
    if (hotbar == nil) or (hotbar.Slots == nil) then
        return;
    end
    
    for slotIndex = 1, 12 do
        local slot = hotbar.Slots[slotIndex];
        if (slot ~= nil) and (slot.Hotkey ~= nil) then
            state.HotkeyInputs[slotIndex] = { slot.Hotkey };
        else
            state.HotkeyInputs[slotIndex] = { '' };
        end
    end
end

local exposed = {};

function exposed:Render()
    InitHotkeyInputs();
    
    if (gHotbarBindings == nil) then
        imgui.Text('No character loaded. Please wait for character selection.');
        return;
    end
    
    local availX, availY = imgui.GetContentRegionAvail();
    
    imgui.BeginChild('HotbarManagerChild', { 0, 0 }, ImGuiChildFlags_Borders);
    
    imgui.TextColored(header, 'Hotbar Selector');
    
    imgui.BeginGroup();
    for i = 1, 10 do
        local hotbar = gHotbarBindings:GetHotbar(i);
        local hasContent = false;
        if (hotbar ~= nil) and (hotbar.Slots ~= nil) then
            for _, slot in pairs(hotbar.Slots) do
                if (slot.Binding ~= nil) or ((slot.Hotkey ~= nil) and (slot.Hotkey ~= '')) then
                    hasContent = true;
                    break;
                end
            end
        end
        
        local label = string.format('%d', i);
        if (i == state.SelectedHotbar) then
            label = label .. '*';
        end
        
        imgui.PushID(string.format('HotbarBtn%d', i));
        local isSelected = (i == state.SelectedHotbar);
        if isSelected then
            imgui.PushStyleColor(ImGuiCol_Button, { 0.3, 0.5, 0.3, 1.0 });
        elseif hasContent then
            imgui.PushStyleColor(ImGuiCol_Button, { 0.4, 0.4, 0.4, 1.0 });
        else
            imgui.PushStyleColor(ImGuiCol_Button, { 0.2, 0.2, 0.2, 1.0 });
        end
        
        if (imgui.Button(label, { 28, 0 })) then
            if (state.SelectedHotbar ~= i) then
                state.SelectedHotbar = i;
                SyncHotkeyInputs();
            end
        end
        imgui.PopStyleColor();
        imgui.PopID();
        
        if (i % 5 ~= 0) then
            imgui.SameLine();
        end
    end
    imgui.EndGroup();
    
    imgui.SameLine();
    imgui.TextColored(header, string.format('Bar %d', state.SelectedHotbar));
    
    imgui.Separator();
    

    
    SyncHotkeyInputs();
    
    local hotbar = gHotbarBindings:GetHotbar(state.SelectedHotbar);
    
    if (imgui.BeginTable('SlotsTable', 6, bit.bor(ImGuiTableFlags_Borders, ImGuiTableFlags_Resizable, ImGuiTableFlags_RowBg))) then
        imgui.TableSetupColumn('Slot', ImGuiTableColumnFlags_WidthFixed, 40);
        imgui.TableSetupColumn('Hotkey', ImGuiTableColumnFlags_WidthFixed, 160);
        imgui.TableSetupColumn('Type', ImGuiTableColumnFlags_WidthFixed, 70);
        imgui.TableSetupColumn('Label', ImGuiTableColumnFlags_WidthStretch);
        imgui.TableSetupColumn('Status', ImGuiTableColumnFlags_WidthFixed, 55);
        imgui.TableSetupColumn('Actions', ImGuiTableColumnFlags_WidthFixed, 130);
        imgui.TableHeadersRow();
        
        for slotIndex = 1, 12 do
            local slot = hotbar and hotbar.Slots and hotbar.Slots[slotIndex];
            local binding = slot and slot.Binding;
            local hotkey = slot and slot.Hotkey or '';
            local isUsed = (binding ~= nil);
            
            imgui.TableNextRow();
            
            imgui.TableSetColumnIndex(0);
            imgui.Text(string.format('%d', slotIndex));
            
            imgui.TableSetColumnIndex(1);
            imgui.PushID(string.format('Hotkey_%d', slotIndex));
            
            local hotkeyInput = state.HotkeyInputs[slotIndex] or { '' };
            imgui.SetNextItemWidth(70);
            if (imgui.InputText('##HotkeyInput', hotkeyInput, 32, bit.bor(ImGuiInputTextFlags_EnterReturnsTrue, ImGuiInputTextFlags_AutoSelectAll))) then
                if SaveHotkey(state.SelectedHotbar, slotIndex, hotkeyInput[1]) then
                    state.HotkeyInputs[slotIndex] = { hotkeyInput[1] };
                end
            end
            state.HotkeyInputs[slotIndex] = hotkeyInput;
            

            
            imgui.SameLine();
            if (imgui.Button('X', { 22, 0 })) then
                state.HotkeyInputs[slotIndex] = { '' };
                SaveHotkey(state.SelectedHotbar, slotIndex, '');
            end
            
            imgui.PopID();
            
            imgui.TableSetColumnIndex(2);
            imgui.Text(isUsed and (binding.ActionType or 'Unknown') or '-');
            
            imgui.TableSetColumnIndex(3);
            imgui.Text(isUsed and (binding.Label or '') or '-');
            
            imgui.TableSetColumnIndex(4);
            if isUsed then
                imgui.TextColored(activeHeader, 'Used');
            else
                imgui.TextColored({ 0.6, 0.6, 0.6, 1.0 }, 'Empty');
            end
            
            imgui.TableSetColumnIndex(5);
            
            imgui.PushID(string.format('Actions_%d', slotIndex));
            local selectedHotbar = state.SelectedHotbar;
            local selectedSlot = slotIndex;
            
            if isUsed then
                if (imgui.Button('Edit', { 40, 0 })) then
                    local hotkeyLabel = string.format('HB%d:%d', selectedHotbar, selectedSlot);
                    gMacroEditor:Show(hotkeyLabel, binding, function(hk, newBinding)
                        if (newBinding == nil) then
                            ClearSlot(selectedHotbar, selectedSlot);
                        else
                            gHotbarBindings:BindJob(selectedHotbar, selectedSlot, newBinding);
                        end
                        if (gHotbarBindings ~= nil) then
                            gHotbarBindings:Save();
                        end
                        if gHotbarDisplay then
                            gHotbarDisplay:UpdateBindings();
                        end
                    end);
                end
                imgui.SameLine();
                if (imgui.Button('Clear', { 40, 0 })) then
                    ClearSlot(selectedHotbar, selectedSlot);
                    if (gHotbarBindings ~= nil) then
                        gHotbarBindings:Save();
                    end
                end
            else
                if (imgui.Button('Add', { 40, 0 })) then
                    local hotkeyLabel = string.format('HB%d:%d', selectedHotbar, selectedSlot);
                    gMacroEditor:Show(hotkeyLabel, nil, function(hk, newBinding)
                        if (newBinding ~= nil) then
                            gHotbarBindings:BindJob(selectedHotbar, selectedSlot, newBinding);
                            if (gHotbarBindings ~= nil) then
                                gHotbarBindings:Save();
                            end
                        end
                        if gHotbarDisplay then
                            gHotbarDisplay:UpdateBindings();
                        end
                    end);
                end
            end
            
            imgui.PopID();
        end
        
        imgui.EndTable();
    end
    
    imgui.Separator();
    imgui.TextColored(header, 'Quick Actions');
    
    if (imgui.Button('Clear All Hotkeys (This Bar)')) then
        for slotIndex = 1, 12 do
            SaveHotkey(state.SelectedHotbar, slotIndex, '');
            state.HotkeyInputs[slotIndex] = { '' };
        end
        if (gHotbarBindings ~= nil) then
            gHotbarBindings:Save();
        end
        Message(string.format('Cleared all hotkeys for Bar %d', state.SelectedHotbar));
    end
    imgui.SameLine();
    if (imgui.Button('Clear All Bindings (This Bar)')) then
        for slotIndex = 1, 12 do
            ClearSlot(state.SelectedHotbar, slotIndex);
        end
        if (gHotbarBindings ~= nil) then
            gHotbarBindings:Save();
        end
        Message(string.format('Cleared all bindings for Bar %d', state.SelectedHotbar));
    end
    imgui.SameLine();
    if (imgui.Button('Refresh Display')) then
        if gHotbarDisplay then
            gHotbarDisplay:UpdateBindings();
        end
        if gHotbarInput then
            gHotbarInput:RefreshKeybinds();
        end
    end
    
    imgui.EndChild();
end
function exposed:Show()
    SyncHotkeyInputs();
end

return exposed;
