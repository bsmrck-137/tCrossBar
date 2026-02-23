# Keyboard Hotbars Implementation Plan

## Summary of Decisions
- **Input Mode**: Keyboard hotbars coexist with controller crossbars
- **Scope**: Separate binding system (hotbars independent from palettes)
- **Key Handling**: Ashita native keybinds with warning on conflicts
- **Visual**: FFXIV-style horizontal/vertical hotbars
- **Defaults**: Pre-configured keybinds for bars 1-2 (Ctrl/Alt + number keys)
- **Empty Slots**: Display empty slots for visual consistency

---

## Detailed Architecture

### File Structure
```
addons/tCrossBar/
├── hotbar.lua              -- Single hotbar display (renders 12 slots)
├── hotbardisplay.lua       -- Manager for all 10 hotbars
├── hotbarbindings.lua      -- Binding storage/loading/saving
├── hotbarinput.lua         -- Keybind registration/management
├── hotbargui.lua           -- Hotbar binding configuration UI
├── resources/
│   └── hotbarlayouts/
│       ├── horizontal_12x1.lua
│       ├── horizontal_6x2.lua
│       ├── horizontal_4x3.lua
│       ├── vertical_1x12.lua
│       ├── vertical_2x6.lua
│       └── vertical_3x4.lua
```

### Data Structures
```lua
-- gSettings.Hotbars
{
    ShowHotbars = true,
    Hotbars = {
        [1] = {
            Name = 'Bar 1',
            Shared = false,           -- false = job-specific
            Visible = true,
            Position = { 100, 500 },
            Scale = 1.0,
            Layout = 'horizontal_12x1',
            Slots = {
                [1] = { Hotkey = '^1', Binding = {...} },
                [2] = { Hotkey = '^2', Binding = {...} },
                -- ... 3-12
            }
        },
        [2] = {
            Name = 'Bar 2',
            Shared = false,
            Visible = true,
            Position = { 100, 550 },
            Scale = 1.0,
            Layout = 'horizontal_12x1',
            Slots = {
                [1] = { Hotkey = '!1', Binding = {...} },  -- Alt+1
                -- ...
            }
        },
        -- ... [3..10] (no default keybinds)
    }
}
```

### Default Keybinds (Bars 1-2)
| Bar | Keys |
|-----|------|
| 1 | Ctrl+1, Ctrl+2... Ctrl+0, Ctrl+-, Ctrl+= (12 keys) |
| 2 | Alt+1, Alt+2... Alt+0, Alt+-, Alt+= (12 keys) |
| 3-10 | No defaults (user-configured) |

---

## Implementation Phases

### Phase 1: Core Modules
1. Create `hotbarbindings.lua` with storage logic
2. Create `hotbar.lua` single hotbar renderer
3. Create `hotbardisplay.lua` manager
4. Add hotbar settings to `initializer.lua`

### Phase 2: Input System
1. Create `hotbarinput.lua` with Ashita keybind integration
2. Add conflict detection with warning messages
3. Extend `commands.lua` for `/tc hotbar` commands
4. Test keybind registration/unregistration

### Phase 3: Visual Display
1. Create layout files in `resources/hotbarlayouts/`
2. Implement hotbar rendering in `callbacks.lua`
3. Add mouse interaction (click to activate, drag to move)
4. Test with various layouts and scales

### Phase 4: Storage
1. Implement save/load for hotbar bindings
2. Handle shared vs job-specific bars
3. Migrate settings on version upgrade

### Phase 5: UI Integration
1. Create `hotbargui.lua` for binding UI
2. Add "Hotbars" tab to `configgui.lua`
3. Add keybind capture functionality
4. Add bar visibility/layout/scale controls

### Phase 6: Polish
1. Test with controller mode active simultaneously
2. Handle edge cases (zoning, cutscenes, menus)
3. Documentation updates
