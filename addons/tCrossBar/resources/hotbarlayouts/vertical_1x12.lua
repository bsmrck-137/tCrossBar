return {
    Name = 'Vertical 1x12',
    Orientation = 'vertical',
    Columns = 1,
    Rows = 12,
    SlotWidth = 40,
    SlotHeight = 40,
    PaddingX = 2,
    PaddingY = 2,

    Panel = {
        Width = 40,
        Height = (40 + 2) * 12 - 2,
    },

    Frame = {
        OffsetX = 0,
        OffsetY = 0,
    },

    Icon = {
        OffsetX = 2,
        OffsetY = 2,
        Width = 36,
        Height = 36,
    },

    Hotkey = {
        box_height = 0,
        box_width = 0,
        font_alignment = 0,
        font_color = 0xFFFFFFFF,
        font_family = 'Arial',
        font_flags = 0,
        font_height = 10,
        gradient_color = 0x00000000,
        gradient_style = 0,
        outline_color = 0xFF000000,
        outline_width = 1,
        OffsetX = 2,
        OffsetY = 2,
    },

    Cost = {
        box_height = 0,
        box_width = 0,
        font_alignment = 2,
        font_color = 0xFF389609,
        font_family = 'Arial',
        font_flags = 0,
        font_height = 8,
        gradient_color = 0x00000000,
        gradient_style = 0,
        outline_color = 0xFF000000,
        outline_width = 1,
        OffsetX = 36,
        OffsetY = 28,
    },

    Recast = {
        box_height = 0,
        box_width = 0,
        font_alignment = 0,
        font_color = 0xFFBFCC04,
        font_family = 'Arial',
        font_flags = 0,
        font_height = 8,
        gradient_color = 0x00000000,
        gradient_style = 0,
        outline_color = 0xFF000000,
        outline_width = 1,
        OffsetX = 2,
        OffsetY = 28,
    },

    Name = {
        box_height = 0,
        box_width = 0,
        font_alignment = 0,
        font_color = 0xFFFFFFFF,
        font_family = 'Arial',
        font_flags = 0,
        font_height = 8,
        gradient_color = 0x00000000,
        gradient_style = 0,
        outline_color = 0xFF000000,
        outline_width = 1,
        OffsetX = 42,
        OffsetY = 15,
    },

    Textures = {
        Cross = 'misc/cross.png',
        Frame = { Path = 'misc/frame.png', Width = 40, Height = 40 },
        Trigger = 'misc/trigger.png',
    },

    FadeOpacity = 128,
    TriggerOpacity = 128,

    SkillchainFrames = T{
        'misc/crawl1.png',
        'misc/crawl2.png',
        'misc/crawl3.png',
        'misc/crawl4.png',
        'misc/crawl5.png',
        'misc/crawl6.png',
        'misc/crawl7.png'
    },

    SkillchainFrameLength = 0.08,
};
