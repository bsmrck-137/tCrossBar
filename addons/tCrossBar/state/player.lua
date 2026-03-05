local chat = require('chat');
local playerData = {
    Abilities = T{},
    Spells = T{},
    Id = 0,
    Name = 'Unknown',
    MeritCount = {},
    JobPoints = {},
    JobPointInit = { Categories = false, Totals = false, Timer = os.clock() + 3 },
    LoggedIn = false,
};

local function ReloadHotbars(name, id, job)
    if (gHotbarBindings == nil) or (gHotbarBindings.LoadDefaults == nil) then
        return false;
    end

    gHotbarBindings:LoadDefaults(name, id, job);
    return true;
end

local startupInitialized = false;
local hotbarStartupSyncPending = true;

local function TryFinalizeHotbarStartupSync()
    if (hotbarStartupSyncPending == false) then
        return;
    end
    if (playerData.LoggedIn == false) then
        return;
    end
    if (playerData.Job == nil) or (playerData.Job.MainJob == nil) then
        return;
    end
    if (playerData.Name == nil) or (playerData.Name == '') or (playerData.Id == 0) or (playerData.Job.MainJob == 0) then
        return;
    end

    if (ReloadHotbars(playerData.Name, playerData.Id, playerData.Job.MainJob) == false) then
        return;
    end

    if (gInitializer ~= nil) and (gInitializer.ApplyHotbars ~= nil) then
        gInitializer:ApplyHotbars();
    end

    hotbarStartupSyncPending = false;
end

local function LoadMerits()
    local pInventory = AshitaCore:GetPointerManager():Get('inventory');
    if (pInventory > 0) then
        local ptr = ashita.memory.read_uint32(pInventory);
        if (ptr ~= 0) then
            ptr = ashita.memory.read_uint32(ptr);
            if (ptr ~= 0) then
                ptr = ptr + 0x2CFF4;
                local count = ashita.memory.read_uint16(ptr + 2);
                local meritptr = ashita.memory.read_uint32(ptr + 4);
                if (count > 0) then
                    for i = 1,count do
                        local meritId = ashita.memory.read_uint16(meritptr + 0);
                        local meritCount = ashita.memory.read_uint8(meritptr + 3);
                        playerData.MeritCount[meritId] = meritCount;
                        meritptr = meritptr + 4;
                    end
                end
            end
        end
    end
end

local function LoadKnownActions(player)
    for i = 1,1024 do
        playerData.Spells[i] = player:HasSpell(i);
    end
    for i = 1,1792 do
        playerData.Abilities[i] = player:HasAbility(i);
    end
end

local function TryInitializeFromMemory()
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

    local flags = entity:GetRenderFlags0(playerIndex);
    if (bit.band(flags, 0x200) ~= 0x200) or (bit.band(flags, 0x4000) == 0x4000) then
        return false;
    end

    local player = AshitaCore:GetMemoryManager():GetPlayer();
    if (player == nil) then
        return false;
    end

    local name = entity:GetName(playerIndex);
    local id = entity:GetServerId(playerIndex);
    local job = player:GetMainJob();
    if (name == nil) or (name == '') or (id == 0) or (job == 0) then
        return false;
    end

    local sub = player:GetSubJob();
    local changedIdentity = (id ~= playerData.Id) or (name ~= playerData.Name);
    local changedJob = (playerData.Job == nil) or (job ~= playerData.Job.MainJob) or (sub ~= playerData.Job.SubJob);

    if (changedIdentity) then
        playerData = {
            Abilities = T{},
            Spells = T{},
            Id = id,
            Name = name,
            MeritCount = {},
            Job = {
                MainJob = job,
                MainJobLevel = player:GetMainJobLevel(),
                SubJob = sub,
                SubJobLevel = player:GetSubJobLevel()
            },
            JobPoints = {},
            JobPointInit = { Categories = false, Totals = false, Timer = os.clock() + 3 },
            LoggedIn = true,
        };
    else
        if (playerData.Job == nil) then
            playerData.Job = {};
        end
        playerData.Id = id;
        playerData.Name = name;
        playerData.Job.MainJob = job;
        playerData.Job.MainJobLevel = player:GetMainJobLevel();
        playerData.Job.SubJob = sub;
        playerData.Job.SubJobLevel = player:GetSubJobLevel();
        playerData.LoggedIn = true;
    end

    if (changedIdentity) or (changedJob) or (startupInitialized == false) then
        gBindings:LoadDefaults(playerData.Name, playerData.Id, playerData.Job.MainJob);
        hotbarStartupSyncPending = (ReloadHotbars(playerData.Name, playerData.Id, playerData.Job.MainJob) == false);
    end

    LoadMerits();
    LoadKnownActions(player);

    TryFinalizeHotbarStartupSync();

    return true;
end

startupInitialized = TryInitializeFromMemory();

ashita.events.register('d3d_present', 'player_tracker_startup_init', function ()
    if (startupInitialized == false) then
        startupInitialized = TryInitializeFromMemory();
    end
    TryFinalizeHotbarStartupSync();
end);


local knownSpells = T{};
local unbridledSpells = T{ 736, 737, 738, 739, 740, 741, 742, 743, 744, 745, 746, 747, 748, 749, 750, 751, 752, 753 };
local bluOffset = ashita.memory.read_uint32(ashita.memory.find('FFXiMain.dll', 0, 'C1E1032BC8B0018D????????????B9????????F3A55F5E5B', 10, 0));
local function UpdateBLUSpells()
    knownSpells = T{};
    local ptr = ashita.memory.read_uint32(AshitaCore:GetPointerManager():Get('inventory'));
    if (ptr == 0) then
        return T{ };
    end
    ptr = ashita.memory.read_uint32(ptr);
    if (ptr == 0) then
        return T{ };
    end
    local spells = T(ashita.memory.read_array((ptr + bluOffset) + ((playerData.Job.MainJob == 16) and 0x04 or 0xA0), 0x14));
    for _,entry in pairs(spells) do
        local spell = AshitaCore:GetResourceManager():GetSpellById(entry + 512);
        if (spell ~= nil) then
            knownSpells:append(spell.Index);
        end
    end
end

ashita.events.register('packet_in', 'player_tracker_handleincomingpacket', function (e)
    if (e.id == 0x00A) then
        local id = struct.unpack('L', e.data, 0x04 + 1);
        local name = struct.unpack('c16', e.data, 0x84 + 1);
        local job = struct.unpack('B', e.data, 0xB4 + 1);
        local sub = struct.unpack('B', e.data, 0xB7 + 1);
        local i,j = string.find(name, '\0');
        if (i ~= nil) then
            name = string.sub(name, 1, i - 1);
        end

        local changedIdentity = (id ~= playerData.Id) or (name ~= playerData.Name);
        local changedJob = (playerData.Job == nil) or (job ~= playerData.Job.MainJob) or (sub ~= playerData.Job.SubJob);

        if (changedIdentity) then
            playerData = {
                Abilities = T{},
                Spells = T{},
                Id = id,
                Name = name,
                MeritCount = {},
                Job = {
                    MainJob = job,
                    MainJobLevel = 0,
                    SubJob = sub,
                    SubJobLevel = 0
                },
                JobPoints = {},
                JobPointInit = { Categories = false, Totals = false, Timer = os.clock() + 3 }
            };
        end

        if (changedIdentity) or (changedJob) or (startupInitialized == false) then
            playerData.Job.MainJob = job;
            playerData.Job.SubJob = sub;
            gBindings:LoadDefaults(playerData.Name, playerData.Id, playerData.Job.MainJob);
            hotbarStartupSyncPending = (ReloadHotbars(playerData.Name, playerData.Id, playerData.Job.MainJob) == false);
        end

        playerData.LoggedIn = true;
        startupInitialized = true;
    elseif (e.id == 0x00B) then
        playerData.LoggedIn = false;
        startupInitialized = false;
        hotbarStartupSyncPending = true;
    elseif (e.id == 0x01B) then
        local job = struct.unpack('B', e.data, 0x08 + 1);
        local sub = struct.unpack('B', e.data, 0x0B + 1);
        if (((job ~= playerData.Job.MainJob) or (sub ~= playerData.Job.SubJob) or (startupInitialized == false)) and (playerData.Id ~= 0)) then
            playerData.Job.MainJob = job;
            playerData.Job.SubJob = sub;
            gBindings:LoadDefaults(playerData.Name, playerData.Id, playerData.Job.MainJob);
            hotbarStartupSyncPending = (ReloadHotbars(playerData.Name, playerData.Id, playerData.Job.MainJob) == false);
        end
        startupInitialized = true;
    elseif (e.id == 0x061) then
        local job = struct.unpack('B', e.data, 0x0C + 1);
        local mainLevel = struct.unpack('B', e.data, 0x0D + 1);
        local sub = struct.unpack('B', e.data, 0x0E + 1);
        local subLevel = struct.unpack('B', e.data, 0x0F + 1);
        if (((job ~= playerData.Job.MainJob) or (sub ~= playerData.Job.SubJob) or (startupInitialized == false)) and (playerData.Id ~= 0)) then
            playerData.Job.MainJob = job;
            playerData.Job.SubJob = sub;
            gBindings:LoadDefaults(playerData.Name, playerData.Id, playerData.Job.MainJob);
            hotbarStartupSyncPending = (ReloadHotbars(playerData.Name, playerData.Id, playerData.Job.MainJob) == false);
        end
        playerData.Job.MainJobLevel = mainLevel;
        playerData.Job.SubJobLevel = subLevel;
        startupInitialized = true;
    elseif (e.id == 0x63) then
        if struct.unpack('B', e.data, 0x04 + 1) == 5 then
            for i = 1,22,1 do
                if playerData.JobPoints[i] == nil then
                    playerData.JobPoints[i] = {};
                end
                playerData.JobPoints[i].Total = struct.unpack('H', e.data, 0x0C + 0x04 + (6 * i) + 1);
            end
            playerData.JobPointInit.Totals = true;
        end
    elseif (e.id == 0x0AA) then
        for i = 1,1024 do
            playerData.Spells[i] = (ashita.bits.unpack_be(e.data_raw, 4, i, 1) == 1);
        end
    elseif (e.id == 0x0AC) then
        for i = 1,1792 do
            playerData.Abilities[i] = (ashita.bits.unpack_be(e.data_raw, 4, i, 1) == 1);
        end
    elseif (e.id == 0x08C) then
        local meritNum = struct.unpack('B', e.data, 0x04 + 1);
        for i = 1,meritNum,1 do
            local meritId = struct.unpack('H', e.data, 0x04 + (4 * i) + 1);
            local meritCount = struct.unpack('B', e.data, 0x04 + (4 * i) + 0x03 + 1);
            playerData.MeritCount[meritId] = meritCount;
        end        
    elseif (e.id == 0x08D) then        
        local jobPointCount = (e.size / 4) - 1;
        for i = 1,jobPointCount,1 do
            local offset = i * 4;
            local index = ashita.bits.unpack_be(e.data_raw, offset, 0, 5);
            local job = ashita.bits.unpack_be(e.data_raw, offset, 5, 11);
            local count = ashita.bits.unpack_be(e.data_raw, offset + 3, 2, 6);
            if job ~= 0 then
                if playerData.JobPoints[job] == nil then
                    playerData.JobPoints[job] = {};
                end
                if playerData.JobPoints[job].Categories == nil then
                    playerData.JobPoints[job].Categories = {};
                end
                playerData.JobPoints[job].Categories[index + 1] = count;
            end
            playerData.JobPointInit.Categories = true;
        end
    end
end);

ashita.events.register('packet_out', 'player_tracker_handleoutgoingpacket', function (e)
    if (e.id == 0x61) or (e.id == 0xC0) then
        playerData.JobPointInit.Timer = os.clock() + 15;
    end
    
    if (e.id == 0x15) and (os.clock() > playerData.JobPointInit.Timer) and (AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel() == 99) then
        if (playerData.JobPointInit.Totals == false) then
            local packet = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
            AshitaCore:GetPacketManager():AddOutgoingPacket(0x61, packet);        
            Message('Sending main menu packet to initialize job point totals.');
        end
        if (playerData.JobPointInit.Categories == false) then
            local packet = { 0x00, 0x00, 0x00, 0x00 };
            AshitaCore:GetPacketManager():AddOutgoingPacket(0xC0, packet);
            Message('Sending job point menu packet to initialize job point categories.');
        end
        playerData.JobPointInit.Timer = os.clock() + 15;
    end
end);

local exports = {};

function exports:GetMeritCount(meritId)
    local count = playerData.MeritCount[meritId];
    if not count then
        return 0;
    else
        return count;
    end
end

function exports:GetJobData()
    return playerData.Job;
end

function exports:GetJobPointCount(job, category)
    local jobTable = playerData.JobPoints[job];
    if not jobTable then
        return 0;
    end

    local categories = jobTable.Categories;
    if not categories then
        return 0;
    end

    local count = categories[category + 1];
    if not count then
        return 0;
    else
        return count;
    end
end

function exports:GetJobPointTotal(job)
    local jobTable = playerData.JobPoints[job];
    if not jobTable then
        return 0;
    end

    local total = jobTable.Total;
    if not total then
        return 0;
    else
        return total;
    end
end

function exports:GetLoggedIn()
    return (playerData.LoggedIn == true);
end

function exports:KnowsAbility(index)
    return (playerData.Abilities[index] == true);
end

function exports:HasSpell(spell)
    if (spell.Skill == 43) then
        if (not unbridledSpells:contains(spell.Index)) then
            return knownSpells:contains(spell.Index);
        end
    end
    return AshitaCore:GetMemoryManager():GetPlayer():HasSpell(spell.Index);
end

function exports:KnowsSpell(spell)
    return (playerData.Spells[spell.Index] == true);
end

function exports:UpdateBLUSpells()
    if (playerData.Job ~= nil) then
        UpdateBLUSpells();
    end
end

return exports;
