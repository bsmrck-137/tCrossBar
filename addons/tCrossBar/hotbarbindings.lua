local bindings = {
    GlobalBindings = T{},
    JobBindings = T{},
};

local function GetDefaultSlot(hotkey)
    return {
        Hotkey = hotkey,
        Binding = nil,
    };
end

local function GetDefaultHotbar(index)
    local hotbar = {
        Name = string.format('Bar %d', index),
        Shared = false,
        Visible = (index <= 2),
        Position = { 0, 0 },
        Scale = 1.0,
        Layout = 'horizontal_12x1',
        Slots = {},
    };

    local defaultKeys = {
        [1] = { '^1', '^2', '^3', '^4', '^5', '^6', '^7', '^8', '^9', '^0', '^-', '^=' },
        [2] = { '!1', '!2', '!3', '!4', '!5', '!6', '!7', '!8', '!9', '!0', '!-', '!=' },
    };

    for slot = 1, 12 do
        local hotkey = nil;
        if (defaultKeys[index] ~= nil) then
            hotkey = defaultKeys[index][slot];
        end
        hotbar.Slots[slot] = GetDefaultSlot(hotkey);
    end

    return hotbar;
end

local function WriteBinding(writer, depth, slotIndex, slot)
    local pad1 = string.rep(' ', depth);
    local pad2 = string.rep(' ', depth + 4);
    local pad3 = string.rep(' ', depth + 8);

    writer:write(string.format('%s[%d] = {\n', pad1, slotIndex));
    writer:write(string.format('%sHotkey = %q,\n', pad2, slot.Hotkey or ''));

    if (slot.Binding ~= nil) then
        writer:write(string.format('%sBinding = {\n', pad2));
        writer:write(string.format('%sActionType = %q,\n', pad3, slot.Binding.ActionType));

        if T{'Ability', 'Item', 'Spell', 'Trust', 'Weaponskill'}:contains(slot.Binding.ActionType) then
            writer:write(string.format('%sId = %u,\n', pad3, slot.Binding.Id));
        end

        writer:write(string.format('%sMacro = T{\n', pad3));
        for _, line in ipairs(slot.Binding.Macro) do
            writer:write(string.format('%s    %q,\n', pad3, line));
        end
        writer:write(string.format('%s},\n', pad3));

        if (slot.Binding.CostOverride ~= nil) then
            writer:write(string.format('%sCostOverride = T{ ', pad3));
            local first = true;
            for _, id in ipairs(slot.Binding.CostOverride) do
                if not first then
                    writer:write(', ');
                end
                writer:write(tostring(id));
                first = false;
            end
            writer:write(' },\n');
        end

        writer:write(string.format('%sLabel = %q,\n', pad3, slot.Binding.Label or ''));
        writer:write(string.format('%sImage = %q,\n', pad3, slot.Binding.Image or ''));
        writer:write(string.format('%sShowCost = %s,\n', pad3, slot.Binding.ShowCost and 'true' or 'false'));
        writer:write(string.format('%sShowCross = %s,\n', pad3, slot.Binding.ShowCross and 'true' or 'false'));
        writer:write(string.format('%sShowFade = %s,\n', pad3, slot.Binding.ShowFade and 'true' or 'false'));
        writer:write(string.format('%sShowRecast = %s,\n', pad3, slot.Binding.ShowRecast and 'true' or 'false'));
        writer:write(string.format('%sShowName = %s,\n', pad3, slot.Binding.ShowName and 'true' or 'false'));
        writer:write(string.format('%sShowTrigger = %s,\n', pad3, slot.Binding.ShowTrigger and 'true' or 'false'));
        writer:write(string.format('%sShowSkillchainIcon = %s,\n', pad3, slot.Binding.ShowSkillchainIcon and 'true' or 'false'));
        writer:write(string.format('%sShowSkillchainAnimation = %s,\n', pad3, slot.Binding.ShowSkillchainAnimation and 'true' or 'false'));
        writer:write(string.format('%sShowHotkey = %s,\n', pad3, slot.Binding.ShowHotkey and 'true' or 'false'));
        writer:write(string.format('%s},\n', pad2));
    end

    writer:write(string.format('%s},\n', pad1));
end

local function WriteHotbar(writer, hotbarIndex, hotbar)
    local pad1 = '    ';
    local pad2 = '        ';
    local pad3 = '            ';

    writer:write(string.format('%s[%d] = {\n', pad1, hotbarIndex));
    writer:write(string.format('%sName = %q,\n', pad2, hotbar.Name));
    writer:write(string.format('%sShared = %s,\n', pad2, hotbar.Shared and 'true' or 'false'));
    writer:write(string.format('%sVisible = %s,\n', pad2, hotbar.Visible and 'true' or 'false'));
    writer:write(string.format('%sPosition = { %d, %d },\n', pad2, hotbar.Position[1] or 0, hotbar.Position[2] or 0));
    writer:write(string.format('%sScale = %f,\n', pad2, hotbar.Scale or 1.0));
    writer:write(string.format('%sLayout = %q,\n', pad2, hotbar.Layout or 'horizontal_12x1'));

    writer:write(string.format('%sSlots = {\n', pad2));
    for slotIndex, slot in pairs(hotbar.Slots) do
        if (slot.Hotkey ~= nil) or (slot.Binding ~= nil) then
            WriteBinding(writer, 12, slotIndex, slot);
        end
    end
    writer:write(string.format('%s},\n', pad2));

    writer:write(string.format('%s},\n', pad1));
end

local function WriteGlobals()
    if (bindings.GlobalPath == nil) then
        return;
    end

    local writer = io.open(bindings.GlobalPath, 'w');
    if (writer == nil) then
        return;
    end

    writer:write('return T{\n');
    for hotbarIndex, hotbar in pairs(bindings.GlobalBindings) do
        WriteHotbar(writer, hotbarIndex, hotbar);
    end
    writer:write('};\n');
    writer:close();
end

local function WriteJob()
    if (bindings.JobPath == nil) then
        return;
    end

    local writer = io.open(bindings.JobPath, 'w');
    if (writer == nil) then
        return;
    end

    writer:write('return T{\n');
    for hotbarIndex, hotbar in pairs(bindings.JobBindings) do
        WriteHotbar(writer, hotbarIndex, hotbar);
    end
    writer:write('};\n');
    writer:close();
end

local function MergeHotbars(globalBar, jobBar)
    if (globalBar == nil) then
        return jobBar;
    end
    if (jobBar == nil) then
        return globalBar;
    end

    local merged = {
        Name = jobBar.Name or globalBar.Name,
        Shared = jobBar.Shared or globalBar.Shared,
        Visible = jobBar.Visible,
        Position = jobBar.Position or globalBar.Position,
        Scale = jobBar.Scale or globalBar.Scale,
        Layout = jobBar.Layout or globalBar.Layout,
        Slots = {},
    };

    for slot = 1, 12 do
        local globalSlot = globalBar.Slots and globalBar.Slots[slot];
        local jobSlot = jobBar.Slots and jobBar.Slots[slot];

        if (jobSlot ~= nil) and (jobSlot.Binding ~= nil) then
            merged.Slots[slot] = {
                Hotkey = jobSlot.Hotkey or (globalSlot and globalSlot.Hotkey),
                Binding = jobSlot.Binding,
            };
        elseif (globalSlot ~= nil) and (globalSlot.Binding ~= nil) then
            merged.Slots[slot] = {
                Hotkey = globalSlot.Hotkey,
                Binding = globalSlot.Binding,
            };
        else
            merged.Slots[slot] = {
                Hotkey = (jobSlot and jobSlot.Hotkey) or (globalSlot and globalSlot.Hotkey),
                Binding = nil,
            };
        end
    end

    return merged;
end

local exposed = {};

function exposed:LoadDefaults(name, id, job)
    if (name == '') or (id == 0) then
        bindings = {
            GlobalBindings = T{},
            JobBindings = T{},
        };
        return;
    end

    local characterPath = string.format('%sconfig/addons/%s/%s_%u/hotbars', AshitaCore:GetInstallPath(), addon.name, name, id);
    if not (ashita.fs.exists(characterPath)) then
        ashita.fs.create_directory(characterPath);
    end

    bindings.GlobalPath = string.format('%s/global.lua', characterPath);
    bindings.GlobalBindings = LoadFile_s(bindings.GlobalPath);
    if (bindings.GlobalBindings == nil) then
        bindings.GlobalBindings = T{};
    end

    bindings.JobPath = string.format('%s/%s.lua', characterPath, AshitaCore:GetResourceManager():GetString('jobs.names_abbr', job));
    bindings.JobBindings = LoadFile_s(bindings.JobPath);
    if (bindings.JobBindings == nil) then
        bindings.JobBindings = T{};
    end
end

function exposed:GetMergedHotbars()
    local merged = T{};

    for hotbarIndex = 1, 10 do
        local globalBar = bindings.GlobalBindings[hotbarIndex];
        local jobBar = bindings.JobBindings[hotbarIndex];

        if (globalBar ~= nil) or (jobBar ~= nil) then
            merged[hotbarIndex] = MergeHotbars(globalBar, jobBar);
        else
            merged[hotbarIndex] = GetDefaultHotbar(hotbarIndex);
        end
    end

    return merged;
end

function exposed:GetHotbar(index)
    local merged = self:GetMergedHotbars();
    return merged[index];
end

function exposed:GetSlot(hotbarIndex, slotIndex)
    local hotbar = self:GetHotbar(hotbarIndex);
    if (hotbar == nil) or (hotbar.Slots == nil) then
        return nil;
    end
    return hotbar.Slots[slotIndex];
end

function exposed:BindGlobal(hotbarIndex, slotIndex, binding)
    if (bindings.GlobalBindings[hotbarIndex] == nil) then
        bindings.GlobalBindings[hotbarIndex] = GetDefaultHotbar(hotbarIndex);
    end

    if (bindings.GlobalBindings[hotbarIndex].Slots == nil) then
        bindings.GlobalBindings[hotbarIndex].Slots = {};
    end

    if (bindings.GlobalBindings[hotbarIndex].Slots[slotIndex] == nil) then
        bindings.GlobalBindings[hotbarIndex].Slots[slotIndex] = GetDefaultSlot(nil);
    end

    bindings.GlobalBindings[hotbarIndex].Slots[slotIndex].Binding = binding;
    WriteGlobals();

    if (gHotbarDisplay) then
        gHotbarDisplay:UpdateBindings();
    end
end

function exposed:BindJob(hotbarIndex, slotIndex, binding)
    if (bindings.JobBindings[hotbarIndex] == nil) then
        bindings.JobBindings[hotbarIndex] = GetDefaultHotbar(hotbarIndex);
    end

    if (bindings.JobBindings[hotbarIndex].Slots == nil) then
        bindings.JobBindings[hotbarIndex].Slots = {};
    end

    if (bindings.JobBindings[hotbarIndex].Slots[slotIndex] == nil) then
        bindings.JobBindings[hotbarIndex].Slots[slotIndex] = GetDefaultSlot(nil);
    end

    bindings.JobBindings[hotbarIndex].Slots[slotIndex].Binding = binding;
    WriteJob();

    if (gHotbarDisplay) then
        gHotbarDisplay:UpdateBindings();
    end
end

function exposed:SetHotkey(hotbarIndex, slotIndex, hotkey, isGlobal)
    if isGlobal then
        if (bindings.GlobalBindings[hotbarIndex] == nil) then
            bindings.GlobalBindings[hotbarIndex] = GetDefaultHotbar(hotbarIndex);
        end
        if (bindings.GlobalBindings[hotbarIndex].Slots == nil) then
            bindings.GlobalBindings[hotbarIndex].Slots = {};
        end
        if (bindings.GlobalBindings[hotbarIndex].Slots[slotIndex] == nil) then
            bindings.GlobalBindings[hotbarIndex].Slots[slotIndex] = GetDefaultSlot(hotkey);
        else
            bindings.GlobalBindings[hotbarIndex].Slots[slotIndex].Hotkey = hotkey;
        end
        WriteGlobals();
    else
        if (bindings.JobBindings[hotbarIndex] == nil) then
            bindings.JobBindings[hotbarIndex] = GetDefaultHotbar(hotbarIndex);
        end
        if (bindings.JobBindings[hotbarIndex].Slots == nil) then
            bindings.JobBindings[hotbarIndex].Slots = {};
        end
        if (bindings.JobBindings[hotbarIndex].Slots[slotIndex] == nil) then
            bindings.JobBindings[hotbarIndex].Slots[slotIndex] = GetDefaultSlot(hotkey);
        else
            bindings.JobBindings[hotbarIndex].Slots[slotIndex].Hotkey = hotkey;
        end
        WriteJob();
    end

    if gHotbarInput then
        gHotbarInput:RefreshKeybinds();
    end
end

function exposed:ClearSlot(hotbarIndex, slotIndex, isGlobal)
    if isGlobal then
        if (bindings.GlobalBindings[hotbarIndex] ~= nil) and
           (bindings.GlobalBindings[hotbarIndex].Slots ~= nil) and
           (bindings.GlobalBindings[hotbarIndex].Slots[slotIndex] ~= nil) then
            bindings.GlobalBindings[hotbarIndex].Slots[slotIndex].Binding = nil;
            WriteGlobals();
        end
    else
        if (bindings.JobBindings[hotbarIndex] ~= nil) and
           (bindings.JobBindings[hotbarIndex].Slots ~= nil) and
           (bindings.JobBindings[hotbarIndex].Slots[slotIndex] ~= nil) then
            bindings.JobBindings[hotbarIndex].Slots[slotIndex].Binding = nil;
            WriteJob();
        end
    end

    if (gHotbarDisplay) then
        gHotbarDisplay:UpdateBindings();
    end
end

function exposed:Save()
    WriteGlobals();
    WriteJob();
end

function exposed:UpdateHotbarSettings(hotbarIndex, settings)
    if (bindings.JobBindings[hotbarIndex] == nil) then
        bindings.JobBindings[hotbarIndex] = GetDefaultHotbar(hotbarIndex);
    end

    if (settings.Name ~= nil) then
        bindings.JobBindings[hotbarIndex].Name = settings.Name;
    end
    if (settings.Shared ~= nil) then
        bindings.JobBindings[hotbarIndex].Shared = settings.Shared;
    end
    if (settings.Visible ~= nil) then
        bindings.JobBindings[hotbarIndex].Visible = settings.Visible;
    end
    if (settings.Position ~= nil) then
        bindings.JobBindings[hotbarIndex].Position = settings.Position;
    end
    if (settings.Scale ~= nil) then
        bindings.JobBindings[hotbarIndex].Scale = settings.Scale;
    end
    if (settings.Layout ~= nil) then
        bindings.JobBindings[hotbarIndex].Layout = settings.Layout;
    end

    WriteJob();
end

return exposed;
