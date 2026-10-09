-- Execute the real server script against a small deterministic Roblox service harness.
-- This exercises remote authorization and state transitions, not rendering or live DataStores.
local now = 1000
os.clock = function() return now end
os.time = function() return now end
math.clamp = function(x, low, high) return math.max(low, math.min(high, x)) end
local function event()
    return {Connect = function(self, fn) self.fn = fn end, fire = function(self, ...) if self.fn then self.fn(...) end end}
end
local vector = {}
vector.__index = function(v, k) if k == 'Magnitude' then return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end end
vector.__add = function(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z}, vector) end
vector.__sub = function(a,b) return setmetatable({x=a.x-b.x,y=a.y-b.y,z=a.z-b.z}, vector) end
Vector3 = {new = function(x,y,z) return setmetatable({x=x,y=y,z=z}, vector) end}
UDim2 = {fromOffset = function() return {} end, fromScale = function() return {} end}
Color3 = {fromRGB = function() return {} end, new = function() return {} end}
Enum = {SurfaceType = {Smooth = 1}}
workspace = {}
local remote
Instance = {new = function(class)
    local o = {ClassName = class}
    if class == 'RemoteFunction' then remote = o end
    if class == 'ProximityPrompt' then o.Triggered = event() end
    return o
end}
local players = {PlayerAdded = event(), PlayerRemoving = event(), all = {}}
function players:GetPlayerByUserId(id) return self.all[id] end
local replicated = {Shared = {Config = 'Config'}}
local guid = 0
local http = {GenerateGUID = function() guid = guid + 1; return 'artist-' .. guid end}
local services = {Players = players, ReplicatedStorage = replicated, HttpService = http, RunService = {IsStudio = function() return true end}}
game = {GetService = function(_, name) return assert(services[name], name) end, BindToClose = function() end}
script = {Parent = {Economy = 'Economy', ProfileStore = 'Store', TradeStore = 'Trade', Settlement = 'Settlement'}}
local captured, savedCalls, failSaveAt = {}, 0, nil
local function clone(t)
    if type(t) ~= 'table' then return t end
    local r = {}; for k, v in pairs(t) do r[k] = clone(v) end; return r
end
http.JSONEncode = function(_, t) return clone(t) end
http.JSONDecode = function(_, t) return clone(t) end
local journal = {}
local tradeMock = {
    begin = function() guid = guid + 1; local id = 'tx-' .. guid; journal[id] = 'pending'; return id end,
    finish = function(id, status) journal[id] = status; return status end,
    status = function(id) return journal[id] end,
}
local modules = {Trade = tradeMock, Settlement = dofile('src/server/Settlement.lua'), Config = dofile('src/shared/Config.lua'), Economy = dofile('src/server/Economy.lua'),
    Store = {load = function(id, defaults) captured[id] = defaults; return defaults, id > 2 end, save = function() savedCalls = savedCalls + 1; return savedCalls ~= failSaveAt end}}
require = function(name) return assert(modules[name], tostring(name)) end
local threads = {}
task = {wait = function() coroutine.yield() end, spawn = function(fn, ...)
    local co = coroutine.create(fn); local ok, err = coroutine.resume(co, ...); assert(ok, err)
    if coroutine.status(co) ~= 'dead' then table.insert(threads, co) end
end}
dofile('src/server/Main.server.lua')
local function player(id)
    local p = {UserId = id, DisplayName = 'Label' .. id, Parent = players, Kick = function(_, msg) error(msg) end}
    players.all[id] = p; players.PlayerAdded:fire(p); return p
end
local alice, bob = player(1), player(2)
local checks = 0
local function check(v, msg) assert(v, msg); checks = checks + 1 end
local function invoke(p, verb, args)
    now = now + 1
    return remote.OnServerInvoke(p, verb, args)
end
local initial = invoke(alice, 'State').state
check(initial.cash == 5000 and initial.studio == 0 and initial.capacity == 1, 'starting label')
check(#initial.artists == 0, 'undiscovered artists hidden')
local found = invoke(alice, 'Discover').state
check(#found.artists == 3, 'social media discovery')
local a = found.artists[1]
check(a.potential == 'Uncertain potential' and a.consistency == 'Unknown', 'hidden stats filtered')
check(a.skill == 'Unscouted' and a.potential ~= captured[1].artists[1].potential, 'no raw talent stats exposed')
local bad = invoke(alice, 'Negotiate', {id = a.id, bonus = 0/0, royalty = 20, duration = 10, promotion = 100})
check(not bad.ok and bad.state.cash == 5000, 'reject NaN without spending')
check(not invoke(bob, 'Scout', {id = a.id}).ok, 'cannot act on another label artist')
check(invoke(alice, 'ScoutUpgrade').ok, 'upgrade scouting')
local scouted = invoke(alice, 'Scout', {id = a.id})
check(scouted.ok and scouted.state.artists[1].potential ~= 'Uncertain potential', 'paid scouting reveals range')
local low = invoke(alice, 'Negotiate', {id = a.id, bonus = 0, royalty = 0, duration = 5, promotion = 0})
check(low.ok and low.state.artists[1].patience == 3 and not low.state.artists[1].contract, 'lowball consumes patience')
local deal = invoke(alice, 'Negotiate', {id = a.id, bonus = 2000, royalty = 20, duration = 10, promotion = 100})
check(deal.ok and deal.state.artists[1].contract ~= nil, 'sign accepted deal')
check(deal.state.cash == 2200, 'bonus and promotion paid once')
local c = deal.state.artists[1].contract
check(not invoke(alice, 'Single', {id = a.id}).ok, 'broken studio blocks recording')
check(invoke(alice, 'Studio').ok, 'repair studio')
check(invoke(alice, 'Single', {id = a.id}).ok, 'release single')
check(not invoke(alice, 'Album', {id = a.id}).ok, 'no overlapping release')
check(invoke(alice, 'Tour', {id = a.id}).ok, 'start tour')
check(not invoke(alice, 'Tour', {id = a.id}).ok, 'no overlapping tour')
check(invoke(alice, 'Promote', {id = a.id}).ok, 'promotion campaign')
local extra = found.artists[2]
check(not invoke(alice, 'Negotiate', {id = extra.id, bonus = 1000000, royalty = 20, duration = 10, promotion = 0}).ok, 'cannot sign unaffordable deal')
local offer = invoke(bob, 'Bid', {id = a.id, owner = 1, amount = 500})
check(offer.ok, 'player can offer buyout in practice mode')
local inbox = invoke(alice, 'State').state
local bid = inbox.bids[1]
check(bid and bid.amount == 500, 'seller receives offer')
check(not invoke(bob, 'AcceptBid', {id = bid.id}).ok, 'only seller can approve')
local accepted = invoke(alice, 'AcceptBid', {id = bid.id})
check(accepted.ok and not accepted.state.artists[1].contract, 'seller loses contract on transfer')
local buyer = invoke(bob, 'State').state
local owned
for _, item in ipairs(buyer.artists) do if item.id == a.id then owned = item end end
check(owned and owned.contract.expires == c.expires and owned.contract.royalty == c.royalty, 'transfer preserves remaining terms')
check(buyer.cash == 4500, 'buyer pays transfer price')
check(not invoke(alice, 'AcceptBid', {id = bid.id}).ok, 'offer cannot settle twice')
-- Resume the real earnings loop to verify rates and expiration.
now = now + 61
for _, co in ipairs(threads) do local ok, err = coroutine.resume(co); assert(ok, err) end
local earning = invoke(bob, 'State').state
for _, item in ipairs(earning.artists) do if item.id == a.id then check(item.rate ~= 0, 'minute refresh calculates earnings') end end
now = c.expires + 1
for _, co in ipairs(threads) do local ok, err = coroutine.resume(co); assert(ok, err) end
local expired = invoke(bob, 'State').state
for _, item in ipairs(expired.artists) do if item.id == a.id then check(not item.contract and item.rate == 0, 'expired contracts stop earning') end end
-- AI offers must require consent and cannot be replayed.
local ownedReal = captured[2].artists[1]
for _, item in ipairs(captured[2].artists) do if item.id == a.id then ownedReal = item end end
ownedReal.contract = {royalty = 20, duration = 10, promotion = 0, expires = now + 600}
ownedReal.buyout = {amount = 4000, label = 'Horizon Records', expires = now + 120}
local aiBefore = invoke(bob, 'State').state.cash
check(invoke(bob, 'AcceptAI', {id = a.id}).ok, 'accept AI buyout')
check(invoke(bob, 'State').state.cash == aiBefore + 4000, 'AI pays agreed amount')
check(not invoke(bob, 'AcceptAI', {id = a.id}).ok, 'AI sale cannot replay')
local carol, dan = player(3), player(4)
local talent = invoke(carol, 'Discover').state.artists[1]
check(invoke(carol, 'Negotiate', {id = talent.id, bonus = 2000, royalty = 20, duration = 10, promotion = 100}).ok, 'persistent seller signs')
check(invoke(dan, 'Bid', {id = talent.id, owner = 3, amount = 500}).ok, 'persistent buyer bids')
local durableBid = invoke(carol, 'State').state.bids[1]
check(invoke(carol, 'AcceptBid', {id = durableBid.id}).ok, 'persistent journal transfer completes')
check(savedCalls == 4, 'both reservations and settlements saved')
check(captured[4].cash == 4500 and captured[3].cash == 3400, 'persistent transfer cash settles')
check(not next(captured[3].escrows) and not next(captured[4].escrows), 'completed escrows cleared')
check(invoke(carol, 'Bid', {id = talent.id, owner = 4, amount = 400}).ok, 'seller can receive resale offer')
local abortBid = invoke(dan, 'State').state.bids[1]
failSaveAt = savedCalls + 1
check(not invoke(dan, 'AcceptBid', {id = abortBid.id}).ok, 'failed reservation aborts transaction')
check(captured[4].cash == 4500 and captured[3].cash == 3400, 'aborted reservation refunds buyer')
local stillOwned = false
for _, item in ipairs(captured[4].artists) do if item.id == talent.id and item.contract then stillOwned = true end end
check(stillOwned, 'aborted reservation restores seller artist')
print('Server: ' .. checks .. ' checks passed')
