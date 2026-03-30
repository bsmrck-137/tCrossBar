local imgui = require('imgui');
local header = { 1.0, 0.75, 0.55, 1.0 };

local state = {
    IsOpen = { false },
    SelectedBar = 1,
    SelectedSlot = 1,
    HotkeyInput = { '' },
    Scope = 3,
};

local bindMode = {
    Active = false,
};

local exposed = {};

function exposed:Close()
    state.IsOpen[1] = false;
    gMacroEditor:Close();
end

function exposed:GetActive()
    return (state.IsOpen[1] == true) or gMacroEditor:GetActive();
end

function exposed:GetCapturing()
    return (state.CapturingKey == true);
end

function exposed:GetBindMode()
    return bindMode.Active;
end

function exposed:SetBindMode(active)
    bindMode.Active = active;
    if active then
        Message('Hotbar bind mode enabled. Click any hotbar slot to bind an action. Right-click to clear. Use /tc hotbar bindmode to exit.');
    else
        Message('Hotbar bind mode disabled.');
    end
end

function exposed:ToggleBindMode()
    self:SetBindMode(not bindMode.Active);
end

function exposed:Show(barIndex, slotIndex)
    if (barIndex == nil) or (slotIndex == nil) then
        return;
    end

    state.SelectedBar = barIndex;
    state.SelectedSlot = slotIndex;
    state.IsOpen[1] = true;

    local slot = gHotbarBindings:GetSlot(barIndex, slotIndex);
    local hotkey = '';
    local binding = nil;

    if (slot ~= nil) then
        hotkey = slot.Hotkey or '';
        binding = slot.Binding;
    end

    state.HotkeyInput = { hotkey };
    state.Scope = 3;
    if (binding ~= nil) and (binding.Scope ~= nil) then
        state.Scope = binding.Scope;
    end

    local hotkeyLabel = string.format('HB%d:%d', barIndex, slotIndex);
    gMacroEditor:Show(hotkeyLabel, binding, function(hk, newBinding)
        self:SaveBinding(barIndex, slotIndex, newBinding);
        self:Close();
    end, function()
        self:Close();
    end, { showScope = true, initialScope = state.Scope });
end

function exposed:SaveBinding(barIndex, slotIndex, binding)
    local hotkey = state.HotkeyInput[1];

    if (hotkey ~= nil) and (hotkey ~= '') then
        local success, err = gHotbarInput:ValidateKeybind(hotkey);
        if not success then
            Error(string.format('Cannot bind key %s: %s', hotkey, err));
            return;
        end
    end

    local isGlobal = (state.Scope == 1);

    if (hotkey ~= nil) and (hotkey ~= '') then
        gHotbarInput:SetKeybind(barIndex, slotIndex, hotkey, isGlobal);
    end

    if (binding == nil) then
        gHotbarBindings:ClearSlot(barIndex, slotIndex, isGlobal);
    elseif isGlobal then
        gHotbarBindings:BindGlobal(barIndex, slotIndex, binding);
    else
        gHotbarBindings:BindJob(barIndex, slotIndex, binding);
    end

    if (gHotbarDisplay) then
        gHotbarDisplay:UpdateBindings();
    end
end

function exposed:Render()
    if (not state.IsOpen[1]) then
        return;
    end

    if (gMacroEditor:GetActive()) then
        return;
    end

    if (imgui.Begin('Hotbar Binding', state.IsOpen, ImGuiWindowFlags_AlwaysAutoResize)) then
        imgui.TextColored(header, string.format('Bar %d, Slot %d', state.SelectedBar, state.SelectedSlot));

        imgui.TextColored(header, 'Keybind');
        imgui.SameLine();
        imgui.SetNextItemWidth(150);
        imgui.InputText('##HotkeyInput', state.HotkeyInput, 32);

        imgui.SameLine();
        if (imgui.Button('Clear##ClearHotkey')) then
            state.HotkeyInput = { '' };
        end

        imgui.SameLine();
        if (imgui.Button('Capture##CaptureHotkey')) then
            Message('Press any key combination (Ctrl/Alt/Shift + key)...');
            state.CapturingKey = true;
        end

        imgui.TextColored(header, 'Scope');
        imgui.SameLine();
        if (imgui.RadioButton('Global##ScopeGlobal', state.Scope == 1)) then
            state.Scope = 1;
        end
        imgui.SameLine();
        if (imgui.RadioButton('Job##ScopeJob', state.Scope == 2)) then
            state.Scope = 2;
        end
        imgui.SameLine();
        if (imgui.RadioButton('Palette##ScopePalette', state.Scope == 3)) then
            state.Scope = 3;
        end

        imgui.Separator();

        if (imgui.Button('Edit Binding', { 120, 0 })) then
            local slot = gHotbarBindings:GetSlot(state.SelectedBar, state.SelectedSlot);
            local binding = nil;
            if (slot ~= nil) then
                binding = slot.Binding;
            end
            local hotkeyLabel = string.format('HB%d:%d', state.SelectedBar, state.SelectedSlot);
            gMacroEditor:Show(hotkeyLabel, binding, function(hk, newBinding)
                self:SaveBinding(state.SelectedBar, state.SelectedSlot, newBinding);
                self:Close();
            end, function()
                self:Close();
            end, { showScope = true, initialScope = state.Scope });
        end

        imgui.SameLine();
        if (imgui.Button('Clear Binding', { 120, 0 })) then
            self:SaveBinding(state.SelectedBar, state.SelectedSlot, nil);
            self:Close();
        end

        imgui.SameLine();
        if (imgui.Button('Cancel', { 80, 0 })) then
            self:Close();
        end

        imgui.End();
    end
end

function exposed:HandleKeyCapture(key, down)
    if (not state.CapturingKey) or (not down) then
        return false;
    end

    local keyName = nil;
    local modifier = '';

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
    };

    keyName = keyNames[key];
    if (keyName == nil) then
        return false;
    end

    local ctrlState = AshitaCore:GetInputManager():GetKeyboard():IsKeyDown(0x1D);
    local altState = AshitaCore:GetInputManager():GetKeyboard():IsKeyDown(0x38);
    local shiftState = AshitaCore:GetInputManager():GetKeyboard():IsKeyDown(0x2A);

    local hotkey = '';
    if ctrlState then
        hotkey = hotkey .. '^';
    end
    if altState then
        hotkey = hotkey .. '!';
    end
    if shiftState then
        hotkey = hotkey .. '+';
    end
    hotkey = hotkey .. keyName;

    state.HotkeyInput = { hotkey };
    state.CapturingKey = false;
    Message(string.format('Captured keybind: %s', hotkey));

    return true;
end

return exposed;
