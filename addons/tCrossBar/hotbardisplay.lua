local d3d8 = require('d3d8');
local ffi = require('ffi');
local Hotbar = require('hotbar');
local scaling = require('scaling');

local HotbarDisplay = {
    Valid = false,
    Hotbars = T{},
    Layouts = {},
};

local function PrepareLayout(layout, scale)
    if (layout.Textures == nil) then
        layout.Textures = {};
    end

    if (layout.DragHandle == nil) then
        layout.DragHandle = {
            OffsetX = 0,
            OffsetY = 0,
            Texture = 'Frame',
            Width = 20,
            Height = 20,
        };
    end

    if (layout.DragHandle.Texture ~= nil) then
        local tx = layout.Textures[layout.DragHandle.Texture];
        if tx then
            layout.DragHandle.Width = tx.Width or layout.DragHandle.Width;
            layout.DragHandle.Height = tx.Height or layout.DragHandle.Height;
        end
    end

    for _, tableEntry in pairs(layout) do
        if (type(tableEntry) == 'table') then
            if (tableEntry.OffsetX ~= nil) then
                tableEntry.OffsetX = tableEntry.OffsetX * scale;
                tableEntry.OffsetY = tableEntry.OffsetY * scale;
            end
            if (tableEntry.Width ~= nil) then
                tableEntry.Width = tableEntry.Width * scale;
                tableEntry.Height = tableEntry.Height * scale;
            end
            if (tableEntry.font_height ~= nil) then
                tableEntry.font_height = math.max(5, math.floor(tableEntry.font_height * scale));
            end
            if (tableEntry.outline_width ~= nil) then
                tableEntry.outline_width = math.min(3, math.max(1, math.floor(tableEntry.outline_width * scale)));
            end
        end
    end

    if (layout.Panel ~= nil) then
        layout.Panel.Width = layout.Panel.Width * scale;
        layout.Panel.Height = layout.Panel.Height * scale;
    end

    layout.SlotWidth = (layout.SlotWidth or 40) * scale;
    layout.SlotHeight = (layout.SlotHeight or 40) * scale;
    layout.PaddingX = (layout.PaddingX or 2) * scale;
    layout.PaddingY = (layout.PaddingY or 2) * scale;

    for key, entry in pairs(layout.Textures) do
        local tx, dimensions;
        if type(entry) == 'table' then
            tx = gTextureCache:GetTexture(entry.Path);
            dimensions = { Width = entry.Width, Height = entry.Height };
        else
            tx = gTextureCache:GetTexture(entry);
            dimensions = { Width = layout.Icon.Width, Height = layout.Icon.Height };
        end

        if tx and dimensions then
            local preparedTexture = {};
            preparedTexture.Texture = tx.Texture;
            preparedTexture.Rect = ffi.new('RECT', { 0, 0, tx.Width, tx.Height });
            preparedTexture.Scale = ffi.new('D3DXVECTOR2', { dimensions.Width / tx.Width, dimensions.Height / tx.Height });
            layout.Textures[key] = preparedTexture;
        else
            layout.Textures[key] = nil;
        end
    end

    if (layout.SkillchainFrames ~= nil) then
        for key, entry in ipairs(layout.SkillchainFrames) do
            local tx = gTextureCache:GetTexture(entry);
            if tx then
                local preparedTexture = {};
                preparedTexture.Texture = tx.Texture;
                preparedTexture.Rect = ffi.new('RECT', { 0, 0, tx.Width, tx.Height });
                preparedTexture.Scale = ffi.new('D3DXVECTOR2', { layout.Icon.Width / tx.Width, layout.Icon.Height / tx.Height });
                layout.SkillchainFrames[key] = preparedTexture;
            end
        end
    end

    layout.FadeOpacity = d3d8.D3DCOLOR_ARGB(layout.FadeOpacity or 128, 255, 255, 255);
    layout.TriggerOpacity = d3d8.D3DCOLOR_ARGB(layout.TriggerOpacity or 128, 255, 255, 255);
end

local function GetDefaultPosition(layout, index)
    if ((scaling.window.w == -1) or (scaling.window.h == -1)) then
        return { 10 + (index - 1) * 60, 10 };
    end

    local panelWidth = layout.Panel.Width or 500;
    local panelHeight = layout.Panel.Height or 50;

    if (index == 1) then
        return {
            (scaling.window.w - panelWidth) / 2,
            scaling.window.h - panelHeight - 150
        };
    elseif (index == 2) then
        return {
            (scaling.window.w - panelWidth) / 2,
            scaling.window.h - panelHeight * 2 - 155
        };
    else
        local col = (index - 3) % 3;
        local row = math.floor((index - 3) / 3);
        return {
            10 + col * (panelWidth + 10),
            10 + row * (panelHeight + 10)
        };
    end
end

function HotbarDisplay:Destroy()
    for _, hotbar in ipairs(self.Hotbars) do
        hotbar:Destroy();
    end
    self.Hotbars = T{};
    self.Layouts = {};
    self.Valid = false;
end

function HotbarDisplay:Initialize(hotbarSettings)
    self.Hotbars = T{};

    for i = 1, 10 do
        local settings = hotbarSettings and hotbarSettings[i];
        if (settings ~= nil) and (settings.Visible == true) then
            local hotbar = Hotbar:New(i);

            local layoutName = settings.Layout or 'horizontal_12x1';
            local layout = LoadFile_s(GetResourcePath('hotbarlayouts/' .. layoutName));

            if layout then
                local scale = settings.Scale or 1.0;
                PrepareLayout(layout, scale);

                if (settings.Position == nil) then
                    settings.Position = GetDefaultPosition(layout, i);
                end

                hotbar:Initialize(layout, settings);
                self.Hotbars:append(hotbar);

                if (self.Layouts[layoutName] == nil) then
                    self.Layouts[layoutName] = layout;
                end
            end
        end
    end

    self.Valid = true;
    self:UpdateBindings();
end

function HotbarDisplay:GetHotbar(index)
    return self.Hotbars[index];
end

function HotbarDisplay:Activate(hotbarIndex, slotIndex)
    local hotbar = self.Hotbars[hotbarIndex];
    if (hotbar == nil) then
        return;
    end
    hotbar:Activate(slotIndex);
end

function HotbarDisplay:Render()
    if (self.Valid == false) then
        return;
    end

    for _, hotbar in ipairs(self.Hotbars) do
        if (hotbar.Valid) and (hotbar.Settings.Visible ~= false) then
            hotbar:Render();
        end
    end
end

function HotbarDisplay:HandleMouse(e)
    if (self.Valid == false) then
        return;
    end

    for _, hotbar in ipairs(self.Hotbars) do
        if (hotbar.Valid) then
            hotbar:HandleMouse(e);
            if (e.blocked) then
                return;
            end
        end
    end
end

function HotbarDisplay:UpdateBindings()
    if (self.Valid == false) then
        return;
    end

    local bindings = gHotbarBindings:GetMergedHotbars();

    for _, hotbar in ipairs(self.Hotbars) do
        if (hotbar.Valid) then
            local hotbarBindings = bindings[hotbar.Index];
            if (hotbarBindings ~= nil) and (hotbarBindings.Slots ~= nil) then
                local slotBindings = {};
                for slotIndex, slot in pairs(hotbarBindings.Slots) do
                    local hotkey = string.format('HB%d:%d', hotbar.Index, slotIndex);
                    slotBindings[hotkey] = slot.Binding;
                end
                hotbar:UpdateBindings(slotBindings);
            end
        end
    end
end

function HotbarDisplay:UpdatePosition()
    if (self.Valid == false) then
        return;
    end

    for _, hotbar in ipairs(self.Hotbars) do
        hotbar:UpdatePosition();
    end
end

function HotbarDisplay:ReloadLayouts()
    self:Destroy();
    self:Initialize(gSettings.Hotbars);
end

function HotbarDisplay:GetLayouts()
    local layouts = T{};

    local layoutPaths = T{
        string.format('%sconfig/addons/%s/resources/hotbarlayouts/', AshitaCore:GetInstallPath(), addon.name),
        string.format('%saddons/%s/resources/hotbarlayouts/', AshitaCore:GetInstallPath(), addon.name),
    };

    for _, path in ipairs(layoutPaths) do
        if not (ashita.fs.exists(path)) then
            ashita.fs.create_directory(path);
        end
        local contents = ashita.fs.get_directory(path, '.*\\.lua');
        for _, file in pairs(contents) do
            file = string.sub(file, 1, -5);
            if not layouts:contains(file) then
                layouts:append(file);
            end
        end
    end

    return layouts;
end

return HotbarDisplay;
