ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or string.lower(args[1]) ~= '/tc') then
        return;
    end
    e.blocked = true;

    if (#args == 1) then
        gConfigGUI:Show();
        return;
    end

    if (#args > 1) and (string.lower(args[2]) == 'bindmode') then        
        if (gBindingGUI:GetActive()) then
            gBindingGUI:Close();
            gController.BindMenuState.Active = false;
        elseif (not gController.BindMenuState.Active) then
            if (gSingleDisplay) then
                gController.BindMenuState.Active = true;
            else
                Error('Cannot open bind menu without a valid single display.  Please enter "/tc" to open the menu and select a valid layout.')
            end            
        else
            gController.BindMenuState.Active = false;
        end
        return;
    end

    if (#args > 1) and (string.lower(args[2]) == 'palette') then
        gBindings:HandleCommand(args);
        return;
    end

    if (#args > 1) and (string.lower(args[2]) == 'hotbar') then
        if (#args < 4) then
            if (#args == 3) and (string.lower(args[3]) == 'list') then
                local keybinds = gHotbarInput:GetRegisteredKeybinds();
                Message('Registered hotbar keybinds:');
                for key, bind in pairs(keybinds) do
                    Message(string.format('  %s -> Bar %d Slot %d', key, bind.HotbarIndex, bind.SlotIndex));
                end
                return;
            end
            Error('Hotbar command syntax: $H/tc hotbar <bar> <slot>$R or $H/tc hotbar list$R');
            return;
        end

        local subCmd = string.lower(args[3]);

        if (subCmd == 'bind') then
            if (#args < 6) then
                Error('Hotbar bind syntax: $H/tc hotbar bind <bar> <slot> <key>$R');
                return;
            end
            local barIndex = tonumber(args[4]);
            local slotIndex = tonumber(args[5]);
            local keybind = args[6];

            if (barIndex == nil) or (barIndex < 1) or (barIndex > 10) then
                Error('Bar must be a number between 1 and 10.');
                return;
            end
            if (slotIndex == nil) or (slotIndex < 1) or (slotIndex > 12) then
                Error('Slot must be a number between 1 and 12.');
                return;
            end

            local success, err = gHotbarInput:ValidateKeybind(keybind);
            if not success then
                Error(string.format('Cannot bind key %s: %s', keybind, err));
                return;
            end

            gHotbarInput:SetKeybind(barIndex, slotIndex, keybind, false);
            Message(string.format('Bound %s to Bar %d Slot %d', keybind, barIndex, slotIndex));
            return;

        elseif (subCmd == 'unbind') then
            if (#args < 5) then
                Error('Hotbar unbind syntax: $H/tc hotbar unbind <bar> <slot>$R');
                return;
            end
            local barIndex = tonumber(args[4]);
            local slotIndex = tonumber(args[5]);

            if (barIndex == nil) or (barIndex < 1) or (barIndex > 10) then
                Error('Bar must be a number between 1 and 10.');
                return;
            end
            if (slotIndex == nil) or (slotIndex < 1) or (slotIndex > 12) then
                Error('Slot must be a number between 1 and 12.');
                return;
            end

            gHotbarInput:ClearKeybind(barIndex, slotIndex);
            Message(string.format('Unbound Bar %d Slot %d', barIndex, slotIndex));
            return;

        elseif (subCmd == 'show') then
            if (#args < 5) then
                Error('Hotbar show syntax: $H/tc hotbar show <bar> <true/false>$R');
                return;
            end
            local barIndex = tonumber(args[4]);
            local visible = string.lower(args[5]) == 'true';

            if (barIndex == nil) or (barIndex < 1) or (barIndex > 10) then
                Error('Bar must be a number between 1 and 10.');
                return;
            end

            if (gSettings.Hotbars == nil) then
                gSettings.Hotbars = {};
            end
            if (gSettings.Hotbars[barIndex] == nil) then
                gSettings.Hotbars[barIndex] = {
                    Name = string.format('Bar %d', barIndex),
                    Visible = visible,
                    Scale = 1.0,
                    Layout = 'horizontal_12x1',
                    Slots = {},
                };
            else
                gSettings.Hotbars[barIndex].Visible = visible;
            end
            settings.save();
            gInitializer:ApplyHotbars();
            Message(string.format('Bar %d %s', barIndex, visible and 'shown' or 'hidden'));
            return;
        end

        local barIndex = tonumber(args[3]);
        local slotIndex = tonumber(args[4]);

        if (barIndex == nil) or (slotIndex == nil) then
            Error('Hotbar execute syntax: $H/tc hotbar <bar> <slot>$R');
            return;
        end

        if (barIndex < 1) or (barIndex > 10) then
            Error('Bar must be between 1 and 10.');
            return;
        end
        if (slotIndex < 1) or (slotIndex > 12) then
            Error('Slot must be between 1 and 12.');
            return;
        end

        gHotbarInput:HandleHotbarCommand(barIndex, slotIndex);
        return;
    end
end);