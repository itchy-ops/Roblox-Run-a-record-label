local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local store = DataStoreService:GetDataStore("RecordLabel_v1")
local Trade = require(script.Parent.TradeStore)
local Settlement = require(script.Parent.Settlement)
local Store = {}
local session = game.JobId ~= "" and game.JobId or HttpService:GenerateGUID(false)
local function key(id) return "player_" .. id end
function Store.load(id, defaults)
    local result
    local ok, err = pcall(function()
        result = store:UpdateAsync(key(id), function(old)
            if old and old.lock and old.lock.session ~= session and old.lock.expires > os.time() then
                return nil
            end
            local data = old and old.data or defaults
            return {data = data, lock = {session = session, expires = os.time() + 180}}
        end)
    end)
    if ok and result then
        local data = result.data
        for id in pairs(data.escrows or {}) do
            local status = Trade.status(id)
            if status ~= "committed" and status ~= "aborted" then
                warn("Trade recovery unavailable; refusing profile load", id)
                return nil, false
            end
            Settlement.apply(data, id, status)
        end
        if not Store.save(id, data, false) then return nil, false end
        return data, true
    end
    if RunService:IsStudio() and not ok then
        warn("DataStore unavailable: Studio practice mode; progress will not save.")
        return defaults, false
    end
    warn("Profile load refused", id, tostring(err))
    return nil, false
end
function Store.save(id, data, release)
    local result
    local ok, err = pcall(function()
        result = store:UpdateAsync(key(id), function(old)
            if not old or not old.lock or old.lock.session ~= session then return nil end
            return {data = data, lock = not release and {session = session, expires = os.time() + 180} or nil}
        end)
    end)
    if not ok then warn("Profile save failed", id, tostring(err)) end
    return ok and result ~= nil
end
return Store
