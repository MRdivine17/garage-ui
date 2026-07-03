-- Qbox (qbx_core) server adapter.
-- Qbox ships no `qb-core` resource, so the qb adapter never loads on a Qbox
-- server. This adapter targets qbx_core natively but reports itself as
-- 'qb-core' so the shared data path (player_vehicles / citizenid) in db.lua,
-- server/main.lua and server/admin_commands.lua is reused unchanged.
if GetResourceState('qbx_core') ~= 'started' then return end
if GetResourceState('qb-core') == 'started' then return end -- let the real qb adapter win if both exist

Framework = { name = 'qb-core' }

local core = exports.qbx_core
local ox_inventory = GetResourceState('ox_inventory') == 'started'
local player = {}

---@param id number
function Framework.getPlayerFromId(id)
    local self = setmetatable({}, { __index = player })
    self.QBPlayer = core:GetPlayer(id)
    if not self.QBPlayer then return end
    self.source = id
    return self
end

function Framework.registerUsableItem(item, cb)
    core:CreateUseableItem(item, cb)
end

function Framework.getPlayers()
    return core:GetQBPlayers()
end

function Framework.getItemLabel(item)
    if ox_inventory then
        local data = exports.ox_inventory:Items()[item]
        return data and data.label
    end
end

-- The resource uses the ESX-style account name 'money' for cash.
local function moneyType(account)
    return account == 'money' and 'cash' or account
end

function player:hasGroup(name)
    return core:HasGroup(self.source, name) == true
end

function player:hasOneOfGroups(groups)
    for key in pairs(groups) do
        if core:HasGroup(self.source, key) then
            return true
        end
    end
    return false
end

function player:addItem(name, count)
    if ox_inventory then
        exports.ox_inventory:AddItem(self.source, name, count)
    else
        self.QBPlayer.Functions.AddItem(name, count)
    end
end

function player:removeItem(name, count)
    if ox_inventory then
        exports.ox_inventory:RemoveItem(self.source, name, count)
    else
        self.QBPlayer.Functions.RemoveItem(name, count)
    end
end

function player:canCarryItem(name, count)
    if ox_inventory then
        return exports.ox_inventory:CanCarryItem(self.source, name, count)
    end
    return true
end

function player:getItemCount(name)
    if ox_inventory then
        return exports.ox_inventory:GetItem(self.source, name, nil, true) or 0
    end
    return self.QBPlayer.Functions.GetItemByName(name)?.amount or 0
end

function player:getAccountMoney(account)
    return self.QBPlayer.Functions.GetMoney(moneyType(account)) or 0
end

function player:addAccountMoney(account, amount)
    return self.QBPlayer.Functions.AddMoney(moneyType(account), amount, 'lunar_garage')
end

function player:removeAccountMoney(account, amount)
    return self.QBPlayer.Functions.RemoveMoney(moneyType(account), amount, 'lunar_garage')
end

function player:getJob()
    return self.QBPlayer.PlayerData.job.name
end

function player:getIdentifier()
    return self.QBPlayer.PlayerData.citizenid
end

function player:getFirstName()
    return self.QBPlayer.PlayerData.charinfo.firstname
end

function player:getLastName()
    return self.QBPlayer.PlayerData.charinfo.lastname
end
