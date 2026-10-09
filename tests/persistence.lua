-- In-memory DataStore model: real Store, TradeStore and Settlement modules, with
-- persistence and failure injection. Live Roblox behavior is a separate smoke test.
local now, count = 1000, 0
os.time = function() return now end
warn = function() end
local function check(v, msg) assert(v, msg); count = count + 1 end
local function clone(t)
    if type(t) ~= 'table' then return t end
    local result = {}; for k, v in pairs(t) do result[k] = clone(v) end; return result
end
local stores, fail = {}, false
local DS = {}
function DS:GetDataStore(name)
    stores[name] = stores[name] or {}
    local data = stores[name]
    return {
        UpdateAsync = function(_, key, fn)
            if fail then error('injected unavailable DataStore') end
            local value = fn(clone(data[key]))
            if value == nil then return nil end
            data[key] = clone(value); return clone(value)
        end,
        GetAsync = function(_, key)
            if fail then error('injected unavailable DataStore') end
            return clone(data[key])
        end,
    }
end
local guid = 0
local services = {DataStoreService = DS, HttpService = {GenerateGUID = function() guid=guid+1; return 'tx-' .. guid end}, RunService = {IsStudio = function() return false end}}
game = {JobId = 'server-one', GetService = function(_, name) return services[name] end}
script = {Parent = {TradeStore = 'Trade', Settlement = 'Settlement'}}
local Settlement = dofile('src/server/Settlement.lua')
local Trade = dofile('src/server/TradeStore.lua')
require = function(name) return name == 'Trade' and Trade or Settlement end
local Store = dofile('src/server/ProfileStore.lua')
local function newProfile() return {cash = 5000, artists = {}, escrows = {}} end
local p, persistent = Store.load(1, newProfile())
check(persistent and p.cash == 5000, 'new profile saved and locked')
p.cash = 4100
check(Store.save(1, p, false), 'save succeeds under owned lock')
game.JobId = 'server-two'
local Other = dofile('src/server/ProfileStore.lua')
check(not Other.load(1, newProfile()), 'active foreign session denied')
check(not Other.save(1, newProfile(), false), 'foreign session cannot overwrite')
check(Store.save(1, p, true), 'release lease')
local loaded = Other.load(1, newProfile())
check(loaded.cash == 4100, 'reload retains cash')
local id = Trade.begin(2, 1)
check(id and Trade.status(id) == 'pending', 'create durable pending journal')
local a = {id = 'test-artist', contract = {royalty = 20, expires = 2000}}
local seller = {cash = 1000, artists = {}, escrows = {[id] = {role = 'seller', artist = a, amount = 700}}}
local buyer = {cash = 4300, artists = {}, escrows = {[id] = {role = 'buyer', artist = a, amount = 700}}}
check(Trade.finish(id, 'committed') == 'committed', 'commit journal')
check(Settlement.apply(seller, id, 'committed') and seller.cash == 1700, 'credit seller')
check(Settlement.apply(buyer, id, 'committed') and #buyer.artists == 1, 'transfer artist')
check(not Settlement.apply(seller, id, 'committed') and seller.cash == 1700, 'seller settlement idempotent')
check(not Settlement.apply(buyer, id, 'committed') and #buyer.artists == 1, 'buyer settlement idempotent')
check(Trade.finish(id, 'aborted') == 'committed', 'terminal commit cannot be reversed')
local aborted = Trade.begin(2, 1)
now = now + 121
check(Trade.status(aborted) == 'aborted', 'expired pending journal aborts')
local reservedSeller = {cash = 1000, artists = {}, escrows = {[aborted] = {role = 'seller', artist = a, amount = 700}}}
local reservedBuyer = {cash = 4300, artists = {}, escrows = {[aborted] = {role = 'buyer', artist = a, amount = 700}}}
Settlement.apply(reservedSeller, aborted, 'aborted'); Settlement.apply(reservedBuyer, aborted, 'aborted')
check(#reservedSeller.artists == 1 and reservedSeller.cash == 1000, 'abort restores seller artist')
check(reservedBuyer.cash == 5000 and #reservedBuyer.artists == 0, 'abort refunds buyer')
-- Crash after commitment, before final profile save: reload resolves escrow once.
local tx = Trade.begin(3, 4)
local crashBuyer = newProfile(); crashBuyer.cash = 4300
crashBuyer.escrows[tx] = {role = 'buyer', artist = a, amount = 700}
local crashSeller = newProfile(); crashSeller.cash = 1000
crashSeller.escrows[tx] = {role = 'seller', artist = a, amount = 700}
Store.load(3, newProfile()); Store.load(4, newProfile())
check(Store.save(3, crashBuyer, true) and Store.save(4, crashSeller, true), 'reservations persist before decision')
Trade.finish(tx, 'committed')
local recoveredBuyer = Other.load(3, newProfile())
local recoveredSeller = Other.load(4, newProfile())
check(#recoveredBuyer.artists == 1 and recoveredBuyer.cash == 4300, 'load recovers committed buyer')
check(recoveredSeller.cash == 1700 and #recoveredSeller.artists == 0, 'load recovers committed seller')
Other.save(3, recoveredBuyer, true); Other.save(4, recoveredSeller, true)
check(#Store.load(3, newProfile()).artists == 1, 'second reload does not duplicate artist')
check(Store.load(4, newProfile()).cash == 1700, 'second reload does not duplicate money')
local unresolved = Trade.begin(5, 6)
local unsafe = newProfile(); unsafe.escrows[unresolved] = {role = 'buyer', artist = a, amount = 700}
Store.load(5, newProfile()); Store.save(5, unsafe, true)
check(not Other.load(5, newProfile()), 'pending active trade blocks unsafe recovery')
fail = true
check(not Store.save(4, newProfile(), false), 'failed storage is reported')
check(not Store.load(10, newProfile()), 'live load failure never falls back to empty profile')
-- An unpublished Studio place can throw during GetDataStore itself.
-- Importing modules must still work, and load must enter explicit practice mode.
fail = false
DS.GetDataStore = function() error('You must publish this place to access DataStore') end
services.RunService.IsStudio = function() return true end
game.JobId = ''
local UnpublishedTrade = dofile('src/server/TradeStore.lua')
check(UnpublishedTrade ~= nil, 'trade module loads without accessing DataStore')
require = function(name) return name == 'Trade' and UnpublishedTrade or Settlement end
local UnpublishedStore = dofile('src/server/ProfileStore.lua')
check(UnpublishedStore ~= nil, 'profile module loads without accessing DataStore')
local practice, isSaved = UnpublishedStore.load(99, newProfile())
check(practice and practice.cash == 5000 and not isSaved, 'unpublished Studio uses unsaved practice mode')
check(not UnpublishedTrade.begin(1, 2), 'unavailable trade storage returns failure without throwing')
print('Persistence: ' .. count .. ' checks passed')
