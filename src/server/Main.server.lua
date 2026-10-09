local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local C = require(RS.Shared.Config)
local E = require(script.Parent.Economy)
local Store = require(script.Parent.ProfileStore)
local Trade = require(script.Parent.TradeStore)
local Settlement = require(script.Parent.Settlement)
local remote = Instance.new("RemoteFunction")
remote.Name = "LabelAction"; remote.Parent = RS
local profiles, sessions, lastRequest, bids, trends = {}, {}, {}, {}, {}
for _, genre in ipairs(C.Genres) do trends[genre] = 1 end
local function artist()
    local members = math.random(1, 5)
    local names = {"Velvet", "Neon", "Midnight", "Golden", "Static", "Silver", "Echo", "Lunar"}
    return {id = Http:GenerateGUID(false), name = names[math.random(#names)] .. " " .. (members == 1 and "Voice" or "Collective"),
        members = members, genre = C.Genres[math.random(#C.Genres)], popularity = math.random(5, 40),
        potential = math.random(20, 100), skill = math.random(25, 90), consistency = math.random(20, 95),
        motivation = math.random(40, 100), patience = 4, location = C.Locations[math.random(#C.Locations)],
        rate = 0, event = "Awaiting a release", experience = 0}
end
local function defaults()
    local p = {cash = C.StartingCash, studio = 0, scout = 0, artists = {}, messages = {"Welcome! Discover talent, sign a deal, and repair your studio."}}
    for _ = 1, 12 do table.insert(p.artists, artist()) end
    return p
end
local function note(p, message)
    table.insert(p.messages, 1, message)
    while #p.messages > 20 do table.remove(p.messages) end
end
local function find(p, id)
    for i, a in ipairs(p.artists) do if a.id == id then return a, i end end
end
local function count(p)
    local n = 0
    for _, a in ipairs(p.artists) do if a.contract then n = n + 1 end end
    return n
end
local function spend(p, cost)
    if p.cash < cost then error("Not enough cash.", 0) end
    p.cash = p.cash - cost
end
local function number(v, low, high)
    if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge or v < low or v > high then
        error("Enter a number between " .. low .. " and " .. high .. ".", 0)
    end
    return math.floor(v)
end
local function publicArtist(a, p)
    return {id = a.id, name = a.name, genre = a.genre, members = a.members, popularity = math.floor(a.popularity),
        potential = E.range(a.potential, a.scouted and p.scout or 0), location = a.location,
        skill = a.scouted and (a.skill >= 65 and "Strong" or "Developing") or "Unscouted",
        motivation = a.motivation >= 65 and "Driven" or "Reserved", consistency = a.experience >= 3 and a.consistency or "Unknown",
        contract = a.contract, rate = a.rate, event = a.event, asking = E.ask(a),
        patience = a.patience, blockedUntil = a.blockedUntil, buyout = a.buyout}
end
local function snapshot(player)
    local p = profiles[player]; if not p then return nil end
    local result = {cash = math.floor(p.cash), studio = p.studio, scout = p.scout, capacity = C.Capacity[p.studio + 1],
        messages = p.messages, artists = {}, trends = trends, marketplace = {}, bids = {}, saving = sessions[player].persistent,
        studioCost = C.StudioCosts[p.studio + 1], scoutCost = C.ScoutCosts[p.scout + 1],
        playerTrades = true}
    for _, a in ipairs(p.artists) do
        if a.discovered or a.contract then table.insert(result.artists, publicArtist(a, p)) end
    end
    for other, otherP in pairs(profiles) do
        if other ~= player then
            for _, a in ipairs(otherP.artists) do
                if a.contract then table.insert(result.marketplace, {id = a.id, owner = other.UserId, label = other.DisplayName,
                    name = a.name, popularity = math.floor(a.popularity), contract = a.contract}) end
            end
        end
    end
    for id, b in pairs(bids) do
        if b.seller == player then table.insert(result.bids, {id = id, name = b.name, amount = b.amount, buyer = b.buyer.DisplayName}) end
    end
    return result
end
local function action(player, verb, args)
    local p = profiles[player]
    if not p then error("Profile is still loading.", 0) end
    if sessions[player].frozen then error("Saving unavailable. Rejoin later.", 0) end
    if sessions[player].trading and verb ~= "State" then error("A transfer is settling. Please wait.", 0) end
    args = type(args) == "table" and args or {}
    if verb == "State" then return end
    if verb == "Discover" then
        local n = 0
        for _, a in ipairs(p.artists) do
            if not a.discovered then a.discovered = true; n = n + 1 end
            if n == 3 then break end
        end
        note(p, n > 0 and "Your social feed found " .. n .. " new artists." or "All local artists discovered."); return
    end
    if verb == "Studio" or verb == "ScoutUpgrade" then
        local field = verb == "Studio" and "studio" or "scout"
        local costs = verb == "Studio" and C.StudioCosts or C.ScoutCosts
        local cost = costs[p[field] + 1]
        if not cost then error("Fully upgraded.", 0) end
        spend(p, cost); p[field] = p[field] + 1
        note(p, field .. " upgraded to level " .. p[field]); return
    end
    if verb == "Bid" then
        local seller = Players:GetPlayerByUserId(number(args.owner, -1e16, 1e16))
        if not seller or seller == player or not profiles[seller] or sessions[seller].frozen then error("Seller unavailable.", 0) end
        if sessions[seller].persistent ~= sessions[player].persistent then error("Cannot trade between practice and saved labels.", 0) end
        local a = find(profiles[seller], args.id)
        if not a or not a.contract then error("Contract unavailable.", 0) end
        local amount = number(args.amount, 1, 10000000)
        if p.cash < amount then error("Not enough cash.", 0) end
        -- One outstanding offer per buyer keeps the inbox bounded.
        for id, b in pairs(bids) do if b.buyer == player then bids[id] = nil end end
        bids[Http:GenerateGUID(false)] = {buyer = player, seller = seller, artist = a.id, name = a.name, amount = amount, expires = os.time() + 120}
        note(profiles[seller], player.DisplayName .. " offered $" .. amount .. " for " .. a.name); return
    end
    if verb == "AcceptBid" or verb == "RejectBid" then
        local b = bids[args.id]
        if not b or b.seller ~= player then error("Offer unavailable.", 0) end
        if verb == "RejectBid" then bids[args.id] = nil; return end
        local buyerP = profiles[b.buyer]
        local a, index = find(p, b.artist)
        if b.expires < os.time() or not buyerP or not a or not a.contract or a.contract.expires <= os.time() then
            bids[args.id] = nil; error("Offer expired.", 0)
        end
        if count(buyerP) >= C.Capacity[buyerP.studio + 1] then error("Buyer has no studio space.", 0) end
        local buyerS, sellerS = sessions[b.buyer], sessions[player]
        if not buyerS or buyerS.frozen or buyerS.trading or buyerS.saving or sellerS.saving then error("Labels are busy. Try again.", 0) end
        if buyerP.cash < b.amount then error("Buyer no longer has enough cash.", 0) end
        if buyerS.persistent ~= sellerS.persistent then error("Incompatible save modes.", 0) end
        if not sellerS.persistent then
            spend(buyerP, b.amount); p.cash = p.cash + b.amount
            table.remove(p.artists, index); a.buyout = nil; table.insert(buyerP.artists, a)
        else
            -- Block actions, career updates, disconnect saves, and autosaves until
            -- both reservations are durable and the journal decision is known.
            buyerS.trading, sellerS.trading = true, true
            local id = Trade.begin(b.buyer.UserId, player.UserId)
            if not id then
                buyerS.trading, sellerS.trading = false, false
                error("Trade storage unavailable. No funds moved.", 0)
            end
            a.buyout = nil
            p.escrows = p.escrows or {}; buyerP.escrows = buyerP.escrows or {}
            local copy = Http:JSONDecode(Http:JSONEncode(a))
            p.escrows[id] = {role = "seller", amount = b.amount, artist = copy}
            buyerP.escrows[id] = {role = "buyer", amount = b.amount, artist = copy}
            table.remove(p.artists, index); spend(buyerP, b.amount)
            local sellerSaved = Store.save(player.UserId, Http:JSONDecode(Http:JSONEncode(p)), false)
            local buyerSaved = sellerSaved and Store.save(b.buyer.UserId, Http:JSONDecode(Http:JSONEncode(buyerP)), false)
            local status = Trade.finish(id, sellerSaved and buyerSaved and "committed" or "aborted")
            if not status then status = Trade.status(id) end
            if status ~= "committed" and status ~= "aborted" then
                buyerS.frozen, sellerS.frozen = true, true
                buyerS.trading, sellerS.trading = false, false
                bids[args.id] = nil
                b.buyer:Kick("Transfer recovery required. Rejoin in three minutes.")
                player:Kick("Transfer recovery required. Rejoin in three minutes.")
                error("Transfer decision unavailable. Reserved assets will recover on rejoin.", 0)
            end
            Settlement.apply(p, id, status); Settlement.apply(buyerP, id, status)
            local finalSeller = Store.save(player.UserId, Http:JSONDecode(Http:JSONEncode(p)), false)
            local finalBuyer = Store.save(b.buyer.UserId, Http:JSONDecode(Http:JSONEncode(buyerP)), false)
            buyerS.trading, sellerS.trading = false, false
            bids[args.id] = nil
            if not finalSeller or not finalBuyer then
                -- Replaying from a durable escrow on next load applies the same
                -- terminal decision once; do not allow subsequent mutations now.
                buyerS.frozen, sellerS.frozen = true, true
                b.buyer:Kick("Transfer saved in recovery journal. Please rejoin shortly.")
                player:Kick("Transfer saved in recovery journal. Please rejoin shortly.")
                error("Transfer requires save recovery on rejoin.", 0)
            end
            buyerS.lastSaved, sellerS.lastSaved = os.time(), os.time()
            if status == "aborted" then error("Transfer aborted; reserved funds and artist restored.", 0) end
        end
        bids[args.id] = nil
        note(p, "Sold " .. a.name .. " for $" .. b.amount)
        note(buyerP, "Acquired " .. a.name .. " with its remaining contract."); return
    end
    local a, index = find(p, args.id)
    if not a or not a.discovered then error("Artist unavailable.", 0) end
    if verb == "Scout" then
        spend(p, 100); a.scouted = true
        note(p, "Scouting: " .. a.name .. " — " .. E.range(a.potential, p.scout)); return
    end
    if verb == "Negotiate" then
        if a.contract then error("Already signed.", 0) end
        if a.blockedUntil and a.blockedUntil > os.time() then error("Artist cooling off. Try again later.", 0) end
        if a.patience <= 0 then a.patience = 4 end
        if count(p) >= C.Capacity[p.studio + 1] then error("Upgrade your studio for more space.", 0) end
        local t = {bonus = number(args.bonus, 0, 1000000), royalty = number(args.royalty, 0, 80),
            duration = number(args.duration, 5, C.MaxContractMinutes), promotion = number(args.promotion, 0, 1000000)}
        if p.cash < t.bonus + t.promotion then error("Cannot fund bonus and promotion commitment.", 0) end
        if E.accepts(a, t) then
            spend(p, t.bonus + t.promotion); t.expires = os.time() + t.duration * 60
            a.contract = t; a.buyout = nil
            note(p, a.name .. " signed! Record a single to build their audience.")
        else
            a.patience = a.patience - 1
            if a.patience == 0 then a.blockedUntil = os.time() + 120 end
            note(p, a.name .. ": Offer too low. Increase bonus, royalty, or promotion. Patience: " .. a.patience)
        end
        return
    end
    if not a.contract or a.contract.expires <= os.time() then error("Active contract required.", 0) end
    if verb == "Single" or verb == "Album" or verb == "Tour" or verb == "Promote" then
        if p.studio == 0 and verb ~= "Promote" then error("Repair your studio first.", 0) end
        if a.releaseUntil and a.releaseUntil > os.time() and (verb == "Single" or verb == "Album") then error("Release already in progress.", 0) end
        if verb == "Tour" and a.tourUntil and a.tourUntil > os.time() then error("Already touring.", 0) end
        local costs = {Single = 200, Album = 650, Tour = 450, Promote = 250}
        spend(p, costs[verb])
        if verb == "Tour" then a.tourUntil = os.time() + 180
        elseif verb ~= "Promote" then a.releaseUntil = os.time() + (verb == "Album" and 300 or 120) end
        a.popularity = math.min(100, a.popularity + (verb == "Album" and 8 or 3))
        a.event = verb .. " campaign launched"; note(p, a.name .. ": " .. a.event); return
    end
    if verb == "AcceptAI" then
        if not a.buyout or a.buyout.expires <= os.time() then error("Buyout expired.", 0) end
        p.cash = p.cash + a.buyout.amount
        note(p, a.name .. " sold to " .. a.buyout.label .. " for $" .. a.buyout.amount)
        table.remove(p.artists, index); table.insert(p.artists, artist()); return
    end
    if verb == "RejectAI" then a.buyout = nil; return end
    error("Unknown action.", 0)
end
remote.OnServerInvoke = function(player, verb, args)
    local now = os.clock()
    if now - (lastRequest[player] or 0) < 0.15 then return {ok = false, message = "Please wait a moment."} end
    lastRequest[player] = now
    local ok, err = pcall(action, player, verb, args)
    return {ok = ok, message = not ok and tostring(err) or nil, state = snapshot(player)}
end
Players.PlayerAdded:Connect(function(player)
    local p, persistent = Store.load(player.UserId, defaults())
    if not p then player:Kick("Your label could not be safely loaded. Rejoin in a few minutes."); return end
    if player.Parent ~= Players then if persistent then Store.save(player.UserId, p, true) end; return end
    profiles[player] = p; sessions[player] = {persistent = persistent, lastSaved = os.time()}
    for _, a in ipairs(p.artists) do a.rate = 0 end
end)
local function save(player, release)
    local p, s = profiles[player], sessions[player]
    if not p or not s or not s.persistent then return end
    if s.trading then
        if release then while s.trading do task.wait(0.1) end else return end
    end
    if s.saving then
        if release then while s.saving do task.wait(0.1) end else return end
    end
    s.saving = true
    local copy = Http:JSONDecode(Http:JSONEncode(p))
    local ok = Store.save(player.UserId, copy, release)
    s.saving = false
    if ok then s.lastSaved = os.time()
    elseif os.time() - s.lastSaved > 100 then s.frozen = true; player:Kick("Saving unavailable. Rejoin later to protect progress.") end
end
Players.PlayerRemoving:Connect(function(player)
    save(player, true)
    profiles[player], sessions[player], lastRequest[player] = nil, nil, nil
    for id, b in pairs(bids) do if b.buyer == player or b.seller == player then bids[id] = nil end end
end)
game:BindToClose(function()
    local pending = 0
    for player in pairs(profiles) do pending = pending + 1; task.spawn(function() save(player, true); pending = pending - 1 end) end
    while pending > 0 do task.wait(0.1) end
end)
local function career(p, a)
    a.experience = a.experience + 1
    local roll = math.random()
    local growth = a.potential / 100 * a.motivation / 100 * 2 + (roll - 0.55) * (5 - a.consistency / 25)
    a.popularity = math.clamp(a.popularity + growth, 0, 100)
    a.rate, a.event = E.rate(a, p.studio, trends[a.genre], roll)
    -- Promotion is reserved on signing; avoid charging the amortized cost twice.
    a.rate = a.rate + a.contract.promotion / (a.contract.duration * 60)
    if a.popularity >= 50 and not a.buyout and math.random() < 0.35 then
        a.buyout = {amount = math.floor(E.ask(a) * (2 + math.random() * 3)), label = "Horizon Records", expires = os.time() + 120}
        note(p, "Horizon Records wants " .. a.name .. "! Check your offers.")
    end
end
task.spawn(function()
    local last, elapsed, autosave = os.clock(), 60, 0
    while true do
        task.wait(1)
        local now = os.clock()
        local delta = math.min(now - last, 5); last = now
        elapsed, autosave = elapsed + delta, autosave + delta
        local refresh = elapsed >= 60
        if refresh then elapsed = 0; for _, g in ipairs(C.Genres) do trends[g] = math.random(70, 140) / 100 end end
        for player, p in pairs(profiles) do
            if not sessions[player].frozen and not sessions[player].trading then
                for _, a in ipairs(p.artists) do
                    if a.buyout and a.buyout.expires <= os.time() then a.buyout = nil end
                    if a.contract then
                        if a.contract.expires <= os.time() then
                            a.contract, a.buyout, a.rate = nil, nil, 0; a.patience = 4
                            note(p, a.name .. "'s contract expired. Negotiate again.")
                        else
                            if refresh then career(p, a) end
                            p.cash = math.max(-10000, p.cash + a.rate * delta)
                        end
                    end
                end
                if p.cash < 100 and count(p) == 0 then p.cash = p.cash + 5 * delta end
            end
            if autosave >= 45 then task.spawn(save, player, false) end
        end
        if autosave >= 45 then autosave = 0 end
        for id, bid in pairs(bids) do if bid.expires <= os.time() then bids[id] = nil end end
    end
end)
-- The town is serialized in Workspace, so it also appears in Studio edit mode.
local town = workspace:WaitForChild("Town")
for index, name in ipairs({"Your Studio", "Open Mic", "Park Stage", "Music Cafe"}) do
    local booth = town:WaitForChild(name .. " booth")
    local prompt = booth:WaitForChild("ProximityPrompt")
    prompt.Triggered:Connect(function(player)
        local p = profiles[player]; if not p then return end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root or (root.Position - booth.Position).Magnitude > 15 then return end
        if index == 1 then
            note(p, "Studio level " .. p.studio .. ". Open your phone to repair and manage artists.")
            return
        end
        local n = 0
        for _, a in ipairs(p.artists) do
            if a.location == name and not a.discovered then a.discovered = true; n = n + 1 end
        end
        note(p, "Discovered " .. n .. " artists at " .. name .. ". Open your phone.")
    end)
end
