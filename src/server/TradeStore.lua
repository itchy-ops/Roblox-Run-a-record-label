-- A durable journal coordinates two independently saved profiles. Funds and the
-- artist are reserved before commitment; profile loading resolves interrupted trades.
local DS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local journal = DS:GetDataStore("RecordLabel_trades_v1")
local Trade = {}
function Trade.begin(buyer, seller)
    local id = Http:GenerateGUID(false)
    local ok, result = pcall(function()
        return journal:UpdateAsync(id, function(old)
            if old then return nil end
            return {status = "pending", buyer = buyer, seller = seller, expires = os.time() + 120}
        end)
    end)
    if ok and result then return id end
    return nil
end
function Trade.finish(id, desired)
    local ok, result = pcall(function()
        return journal:UpdateAsync(id, function(old)
            if not old then return nil end
            if old.status == "pending" then
                old.status = desired == "committed" and old.expires > os.time() and "committed" or "aborted"
            end
            return old
        end)
    end)
    return ok and result and result.status or nil
end
function Trade.status(id)
    local ok, result = pcall(function() return journal:GetAsync(id) end)
    if not ok or not result then return nil end
    if result.status == "pending" and result.expires <= os.time() then return Trade.finish(id, "aborted") end
    return result.status
end
return Trade
