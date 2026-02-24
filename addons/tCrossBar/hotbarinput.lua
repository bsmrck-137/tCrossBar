local HotbarInput = {
    RegisteredKeybinds = T{},
    Initialized = false,
};

local function CheckKeybindConflict(keybind)
    return false, nil;
end

local function FormatKeybind(keybind)
    if (keybind == nil) or (keybind == '') then
        return nil;
    end

    local formatted = keybind;
    formatted = string.gsub(formatted, 'Ctrl', '^');
    formatted = string.gsub(formatted, 'Alt', '!');
    formatted = string.gsub(formatted, 'Shift', '+');
    formatted = string.gsub(formatted, 'Apps', '#');

    formatted = string.lower(formatted);

    formatted = string.gsub(formatted, '([^!@#]+)(%+)([%w].*)$', '%1%3');

    return formatted;
end

local function RegisterKeybind(hotbarIndex, slotIndex, keybind)
    if (keybind == nil) or (keybind == '') then
        return false, 'No keybind specified.';
    end

    local formattedKey = FormatKeybind(keybind);
    if (formattedKey == nil) then
        formattedKey = keybind;
    end

    local hasConflict, conflictingCommand = CheckKeybindConflict(formattedKey);
    if hasConflict then
        return false, string.format('Keybind %s conflicts with existing bind: %s', keybind, conflictingCommand);
    end

    local command = string.format('/tc hotbar %d %d', hotbarIndex, slotIndex);

    local chatManager = AshitaCore:GetChatManager();
    if (chatManager ~= nil) then
        AshitaCore:GetChatManager():QueueCommand(-1, string.format('/bind %s %s', formattedKey, command));
        HotbarInput.RegisteredKeybinds[formattedKey] = {
            HotbarIndex = hotbarIndex,
            SlotIndex = slotIndex,
            Keybind = formattedKey,
            Command = command,
        };
        return true, nil;
    end

    return false, 'Failed to access chat manager.';
end

local function UnregisterKeybind(keybind)
    if (keybind == nil) or (keybind == '') then
        return;
    end

    local formattedKey = FormatKeybind(keybind);
    if (formattedKey == nil) then
        formattedKey = keybind;
    end

    if (HotbarInput.RegisteredKeybinds[formattedKey] ~= nil) then
        local chatManager = AshitaCore:GetChatManager();
        if (chatManager ~= nil) then
            AshitaCore:GetChatManager():QueueCommand(-1, string.format('/unbind %s', formattedKey));
        end
        HotbarInput.RegisteredKeybinds[formattedKey] = nil;
    end
end

function HotbarInput:Initialize()
    if (self.Initialized == true) then
        return;
    end

    self:RefreshKeybinds();
    self.Initialized = true;
end

function HotbarInput:RefreshKeybinds()
    for keybind, _ in pairs(self.RegisteredKeybinds) do
        UnregisterKeybind(keybind);
    end
    self.RegisteredKeybinds = T{};

    if (gHotbarBindings == nil) then
        return;
    end

    local hotbars = gHotbarBindings:GetMergedHotbars();
    if (hotbars == nil) then
        return;
    end

    for hotbarIndex, hotbar in pairs(hotbars) do
        if (hotbar.Slots ~= nil) then
            for slotIndex, slot in pairs(hotbar.Slots) do
                if (slot.Hotkey ~= nil) and (slot.Hotkey ~= '') then
                    local success, err = RegisterKeybind(hotbarIndex, slotIndex, slot.Hotkey);
                    if not success then
                        Error(string.format('Failed to bind hotbar %d slot %d: %s', hotbarIndex, slotIndex, err or 'Unknown error'));
                    end
                end
            end
        end
    end
end

function HotbarInput:SetKeybind(hotbarIndex, slotIndex, keybind, isGlobal)
    local oldKeybind = nil;
    local hotbars = gHotbarBindings:GetMergedHotbars();
    if (hotbars ~= nil) and (hotbars[hotbarIndex] ~= nil) and (hotbars[hotbarIndex].Slots ~= nil) then
        local slot = hotbars[hotbarIndex].Slots[slotIndex];
        if (slot ~= nil) and (slot.Hotkey ~= nil) then
            oldKeybind = slot.Hotkey;
        end
    end

    if (oldKeybind ~= nil) then
        UnregisterKeybind(oldKeybind);
    end

    if (keybind ~= nil) and (keybind ~= '') then
        local success, err = RegisterKeybind(hotbarIndex, slotIndex, keybind);
        if not success then
            Error(string.format('Failed to bind key %s: %s', keybind, err or 'Unknown error'));
            return false;
        end
    end

    gHotbarBindings:SetHotkey(hotbarIndex, slotIndex, keybind, isGlobal);
    return true;
end

function HotbarInput:ClearKeybind(hotbarIndex, slotIndex)
    local hotbars = gHotbarBindings:GetMergedHotbars();
    if (hotbars ~= nil) and (hotbars[hotbarIndex] ~= nil) and (hotbars[hotbarIndex].Slots ~= nil) then
        local slot = hotbars[hotbarIndex].Slots[slotIndex];
        if (slot ~= nil) and (slot.Hotkey ~= nil) then
            UnregisterKeybind(slot.Hotkey);
        end
    end
end

function HotbarInput:GetRegisteredKeybinds()
    return self.RegisteredKeybinds;
end

function HotbarInput:HandleHotbarCommand(hotbarIndex, slotIndex)
    if (gHotbarDisplay == nil) then
        return;
    end

    gHotbarDisplay:Activate(hotbarIndex, slotIndex);
end

function HotbarInput:ValidateKeybind(keybind)
    if (keybind == nil) or (keybind == '') then
        return false, 'Keybind cannot be empty.';
    end

    local formattedKey = FormatKeybind(keybind);
    if (formattedKey == nil) then
        formattedKey = keybind;
    end

    local hasConflict, conflictingCommand = CheckKeybindConflict(formattedKey);
    if hasConflict then
        return false, string.format('Keybind conflicts with: %s', conflictingCommand);
    end

    return true, nil;
end

function HotbarInput:Shutdown()
    for keybind, _ in pairs(self.RegisteredKeybinds) do
        UnregisterKeybind(keybind);
    end
    self.RegisteredKeybinds = T{};
    self.Initialized = false;
end

return HotbarInput;
