local d3d8 = require('d3d8');
local Element = require('element');
local ffi = require('ffi');
local gdi = require('gdifonts.include');

local Hotbar = { Valid = false };

function Hotbar:New(index)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.Index = index;
    o.Elements = T{};
    o.Layout = nil;
    o.HotkeyLabels = {};
    o.Valid = false;
    o.DragActive = false;
    o.DragPosition = { 0, 0 };
    return o;
end

function Hotbar:Destroy()
    self.Elements = T{};
    self.Layout = nil;
    self.Valid = false;
end

function Hotbar:Initialize(layout, settings)
    self.Layout = layout;
    self.Settings = settings;
    self.Elements = T{};

    local scale = settings.Scale or 1.0;
    local position = settings.Position or { 0, 0 };

    self.HotkeyLabels = {};
    if (settings.Slots ~= nil) then
        for slotIndex, slot in pairs(settings.Slots) do
            if (slot.Hotkey ~= nil) then
                self.HotkeyLabels[slotIndex] = self:FormatHotkey(slot.Hotkey);
            end
        end
    end

    for slot = 1, 12 do
        local hotkey = string.format('HB%d:%d', self.Index, slot);
        local hotkeyLabel = self.HotkeyLabels[slot] or '';
        local newElement = Element:New(hotkey, layout, hotkeyLabel);

        local slotX, slotY = self:GetSlotPosition(slot);
        newElement.OffsetX = slotX;
        newElement.OffsetY = slotY;
        newElement:SetPosition(position);

        self.Elements:append(newElement);
    end

    if (self.Sprite == nil) then
        local sprite = ffi.new('ID3DXSprite*[1]');
        if (ffi.C.D3DXCreateSprite(d3d8.get_device(), sprite) == ffi.C.S_OK) then
            self.Sprite = d3d8.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
        else
            Error('Failed to create Sprite in Hotbar:Initialize.');
        end
    end

    self.Valid = (self.Sprite ~= nil);
end

function Hotbar:FormatHotkey(hotkey)
    if (hotkey == nil) then
        return '';
    end

    local result = hotkey;
    result = string.gsub(result, '%^', 'Ctrl+');
    result = string.gsub(result, '!', 'Alt+');
    result = string.gsub(result, '%+', 'Shift+');
    result = string.gsub(result, '#', 'Apps+');

    return result;
end

function Hotbar:GetSlotPosition(slot)
    if (self.Layout == nil) then
        return 0, 0;
    end

    local layout = self.Layout;
    local columns = layout.Columns or 12;
    local rows = layout.Rows or 1;
    local slotWidth = layout.SlotWidth or 40;
    local slotHeight = layout.SlotHeight or 40;
    local paddingX = layout.PaddingX or 2;
    local paddingY = layout.PaddingY or 2;

    local col = (slot - 1) % columns;
    local row = math.floor((slot - 1) / columns);

    local x = col * (slotWidth + paddingX);
    local y = row * (slotHeight + paddingY);

    return x, y;
end

function Hotbar:GetElement(slot)
    if (self.Valid == false) then
        return nil;
    end
    return self.Elements[slot];
end

function Hotbar:Activate(slot)
    if (self.Valid == false) then
        return;
    end

    local element = self.Elements[slot];
    if (element ~= nil) then
        element:Activate();
    end
end

local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local vec_font_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0 });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0 });

function Hotbar:Render()
    if (self.Valid == false) then
        return;
    end

    local pos = self.Settings.Position or { 0, 0 };
    local sprite = self.Sprite;
    sprite:Begin();

    for _, element in ipairs(self.Elements) do
        element:RenderIcon(sprite);
    end

    for _, element in ipairs(self.Elements) do
        element:RenderText(sprite);
    end

    if (self.AllowDrag) then
        local component = self.Layout.Textures[self.Layout.DragHandle and self.Layout.DragHandle.Texture];
        if component then
            vec_position.x = pos[1] + (self.Layout.DragHandle.OffsetX or 0);
            vec_position.y = pos[2] + (self.Layout.DragHandle.OffsetY or 0);
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    sprite:End();
end

function Hotbar:DragTest(e)
    local handle = self.Layout and self.Layout.DragHandle;
    if (handle == nil) then
        return false;
    end

    local pos = self.Settings.Position or { 0, 0 };
    local minX = pos[1] + (handle.OffsetX or 0);
    local maxX = minX + (handle.Width or 20);
    if (e.x < minX) or (e.x > maxX) then
        return false;
    end

    local minY = pos[2] + (handle.OffsetY or 0);
    local maxY = minY + (handle.Height or 20);
    return (e.y >= minY) and (e.y <= maxY);
end

function Hotbar:HandleMouse(e)
    if (self.Valid == false) then
        return;
    end

    if self.DragActive then
        local pos = self.Settings.Position;
        pos[1] = pos[1] + (e.x - self.DragPosition[1]);
        pos[2] = pos[2] + (e.y - self.DragPosition[2]);
        self.DragPosition[1] = e.x;
        self.DragPosition[2] = e.y;
        self:UpdatePosition();
        if (e.message == 514) or (not self.AllowDrag) then
            self.DragActive = false;
            settings.save();
        end
    elseif (self.AllowDrag) and (e.message == 513) and self:DragTest(e) then
        self.DragActive = true;
        self.DragPosition[1] = e.x;
        self.DragPosition[2] = e.y;
        e.blocked = true;
        return;
    end

    if (e.message == 513) and (gSettings.ClickToActivate) then
        local hit, element = self:HitTest(e.x, e.y);
        if element ~= nil then
            self:Activate(element);
            e.blocked = true;
        end
    end
end

function Hotbar:HitTest(x, y)
    if (self.Valid == false) then
        return false, nil;
    end

    local pos = self.Settings.Position or { 0, 0 };
    local layout = self.Layout;

    if layout == nil then
        return false, nil;
    end

    local panelWidth = layout.Panel and layout.Panel.Width or 500;
    local panelHeight = layout.Panel and layout.Panel.Height or 50;

    if (x < pos[1]) or (y < pos[2]) then
        return false, nil;
    end

    if (x > (pos[1] + panelWidth)) then
        return false, nil;
    end

    if (y > (pos[2] + panelHeight)) then
        return false, nil;
    end

    local selectedElement = 0;
    for index, element in ipairs(self.Elements) do
        if (element:HitTest(x, y)) then
            selectedElement = index;
        end
    end

    return true, selectedElement;
end

function Hotbar:UpdateBindings(bindings)
    if (self.Valid == false) then
        return;
    end

    for slot = 1, 12 do
        local element = self.Elements[slot];
        if element then
            local hotkey = string.format('HB%d:%d', self.Index, slot);
            element:UpdateBinding(bindings[hotkey]);
        end
    end
end

function Hotbar:UpdatePosition()
    if (self.Valid == false) then
        return;
    end

    local position = self.Settings.Position or { 0, 0 };

    for _, element in ipairs(self.Elements) do
        element:SetPosition(position);
    end
end

function Hotbar:UpdateSlotBinding(slot, binding)
    if (self.Valid == false) then
        return;
    end

    local element = self.Elements[slot];
    if element then
        element:UpdateBinding(binding);
    end
end

return Hotbar;
