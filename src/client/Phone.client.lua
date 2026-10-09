local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local remote = RS:WaitForChild("LabelAction")
local gui = Instance.new("ScreenGui")
gui.Name = "LabelPhone"; gui.ResetOnSpawn = false; gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local colors = {bg = Color3.fromRGB(19, 23, 35), card = Color3.fromRGB(31, 37, 53), accent = Color3.fromRGB(112, 82, 213), text = Color3.fromRGB(236, 239, 248)}
local function corner(obj) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = obj end
local function label(parent, text, height)
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, 0, 0, height or 32); v.BackgroundTransparency = 1
    v.Text = text; v.TextColor3 = colors.text; v.TextSize = 15; v.Font = Enum.Font.Gotham
    v.TextWrapped = true; v.TextXAlignment = Enum.TextXAlignment.Left; v.Parent = parent
    return v
end
local function button(parent, text, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 36); b.BackgroundColor3 = colors.accent
    b.TextColor3 = colors.text; b.TextSize = 14; b.Font = Enum.Font.GothamMedium; b.Text = text; b.Parent = parent
    corner(b); b.Activated:Connect(fn); return b
end
local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.9, 0.82); frame.Position = UDim2.fromScale(0.5, 0.5); frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = colors.bg; frame.Parent = gui; corner(frame)
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(740, 820); constraint.Parent = frame
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 14); padding.PaddingRight = UDim.new(0, 14); padding.Parent = frame
local title = label(frame, "RECORD LABEL  /  FROM NOTHING", 36)
local status = label(frame, "Loading your label…", 46); status.Position = UDim2.fromOffset(0, 36)
local notice = label(frame, "Explore town or use your social feed to discover talent.", 42); notice.Position = UDim2.fromOffset(0, 82)
local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, 0, 0, 38); tabs.Position = UDim2.fromOffset(0, 126); tabs.BackgroundTransparency = 1; tabs.Parent = frame
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 4); tabLayout.Parent = tabs
local content = Instance.new("ScrollingFrame")
content.Position = UDim2.fromOffset(0, 176); content.Size = UDim2.new(1, 0, 1, -190)
content.BackgroundTransparency = 1; content.BorderSizePixel = 0; content.ScrollBarThickness = 5
content.AutomaticCanvasSize = Enum.AutomaticSize.Y; content.CanvasSize = UDim2.new(); content.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = content
local toggle = button(gui, "Phone [P]", function() frame.Visible = not frame.Visible end)
toggle.Size = UDim2.fromOffset(120, 36); toggle.Position = UDim2.new(1, -132, 0, 12)
UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.P then frame.Visible = not frame.Visible end
end)
local state, tab, busy, drafts = nil, "Feed", false, {}
local render
local function request(verb, args, redraw)
    if busy then return end
    busy = true
    local ok, response = pcall(function() return remote:InvokeServer(verb, args) end)
    busy = false
    if not ok then notice.Text = "Connection interrupted. Try again."; return end
    if response.state then state = response.state end
    if not response.ok then notice.Text = response.message or "Action failed."
    elseif verb ~= "State" then notice.Text = state and state.messages[1] or "Done." end
    if state then
        local desk = workspace:FindFirstChild("Battered mixing desk", true)
        if desk then desk.Color = state.studio > 0 and Color3.fromRGB(102, 91, 173) or Color3.fromRGB(75, 65, 57) end
        status.Text = string.format("$%s  |  Studio %d  |  Scouting %d  |  Slots %d\n%s", state.cash, state.studio, state.scout, state.capacity,
            state.saving and "Progress saving enabled" or "PRACTICE MODE — progress will not save")
    end
    if redraw and render then render() end
end
local function card()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 0); f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = colors.card; f.Parent = content; corner(f)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 10); p.PaddingBottom = UDim.new(0, 10)
    p.PaddingLeft = UDim.new(0, 10); p.PaddingRight = UDim.new(0, 10); p.Parent = f
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = f
    return f
end
local function field(parent, caption, initial, callback)
    label(parent, caption, 24)
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, 0, 0, 34); input.BackgroundColor3 = colors.bg
    input.TextColor3 = colors.text; input.Font = Enum.Font.Gotham; input.TextSize = 15
    input.ClearTextOnFocus = false; input.Text = tostring(initial); input.Parent = parent; corner(input)
    input.FocusLost:Connect(function() callback(input.Text) end)
    return input
end
local function artistCard(a)
    local f = card()
    label(f, a.name .. "  /  " .. a.genre .. "  /  " .. a.members .. " member(s)", 36)
    label(f, "Popularity " .. a.popularity .. "/100  •  " .. a.potential, 36)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 7); bar.BackgroundColor3 = colors.bg; bar.Parent = f; corner(bar)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(a.popularity / 100, 1); fill.BackgroundColor3 = colors.accent; fill.Parent = bar; corner(fill)
    label(f, "Skill: " .. a.skill .. "  |  Consistency: " .. a.consistency .. "  |  Motivation: " .. a.motivation, 42)
    button(f, "Scout report — $100", function() request("Scout", {id = a.id}, true) end)
    if a.contract then
        local c = a.contract
        label(f, string.format("Net cash $%.2f/sec • %s\nRoyalty %d%% • %d min remaining", a.rate, a.event, c.royalty, math.max(0, math.ceil((c.expires - os.time()) / 60))), 58)
        for _, campaign in ipairs({{"Single", 200}, {"Album", 650}, {"Tour", 450}, {"Promote", 250}}) do
            local verb = campaign[1]
            button(f, verb .. " — $" .. campaign[2], function() request(verb, {id = a.id}, true) end)
        end
        if a.buyout then
            label(f, a.buyout.label .. " offers $" .. a.buyout.amount .. " for this contract.", 40)
            button(f, "Accept AI buyout", function() request("AcceptAI", {id = a.id}, true) end)
            button(f, "Decline AI buyout", function() request("RejectAI", {id = a.id}, true) end)
        end
    else
        label(f, "Contact via email / DM • Asking bonus $" .. a.asking .. " • Patience " .. a.patience, 42)
        drafts[a.id] = drafts[a.id] or {bonus = tostring(a.asking), royalty = "20", duration = "10", promotion = "100"}
        local d = drafts[a.id]
        local inputs = {}
        for _, item in ipairs({{"bonus", "Signing bonus ($)"}, {"royalty", "Artist royalty (0–80%)"}, {"duration", "Duration (5–60 minutes)"}, {"promotion", "Prepaid promotion commitment ($)"}}) do
            local key = item[1]
            inputs[key] = field(f, item[2], d[key], function(value) d[key] = value end)
        end
        button(f, "Send contract offer", function()
            local args = {id = a.id}
            for key, input in pairs(inputs) do d[key] = input.Text; args[key] = tonumber(input.Text) end
            request("Negotiate", args, true)
        end)
    end
end
render = function()
    for _, child in ipairs(content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    if not state then label(card(), "Loading…"); return end
    if tab == "Feed" or tab == "Roster" then
        if tab == "Feed" then button(card(), "Search social media for talent", function() request("Discover", {}, true) end) end
        local n = 0
        for _, a in ipairs(state.artists) do
            if (tab == "Roster" and a.contract) or (tab == "Feed" and not a.contract) then artistCard(a); n = n + 1 end
        end
        if n == 0 then label(card(), tab == "Feed" and "Search your feed or visit discovery booths around town." or "No signed artists yet.", 48) end
    elseif tab == "Studio" then
        local f = card()
        label(f, "Start with broken equipment and one artist slot. Repairs improve recording quality and capacity.", 60)
        button(f, state.studioCost and "Repair / upgrade studio — $" .. state.studioCost or "Studio fully upgraded", function() request("Studio", {}, true) end)
        button(f, state.scoutCost and "Upgrade scouting — $" .. state.scoutCost or "Scouting fully upgraded", function() request("ScoutUpgrade", {}, true) end)
        label(f, "Genre trends change each minute:", 32)
        for genre, trend in pairs(state.trends) do label(f, genre .. ": " .. math.floor(trend * 100) .. "% demand", 28) end
        label(f, "Promotion is paid upfront. Earnings can be negative. Rates update every minute; cash updates each second. Expired artists can negotiate again. Insolvent empty labels earn recovery income.", 100)
    elseif tab == "Inbox" then
        for _, b in ipairs(state.bids) do
            local f = card(); label(f, b.buyer .. " offers $" .. b.amount .. " for " .. b.name, 48)
            button(f, "Accept transfer", function() request("AcceptBid", {id = b.id}, true) end)
            button(f, "Decline", function() request("RejectBid", {id = b.id}, true) end)
        end
        for _, message in ipairs(state.messages) do label(card(), message, 64) end
    elseif tab == "Market" then
        label(card(), state.playerTrades and "Marketplace: transfers keep royalties and expiration. Seller approval is required. Offers expire after 2 minutes." or "Marketplace currently unavailable.", 100)
        for _, listing in ipairs(state.marketplace) do
            local f = card()
            label(f, listing.name .. " / " .. listing.label .. " / Popularity " .. listing.popularity, 42)
            label(f, "Royalty " .. listing.contract.royalty .. "% • " .. math.max(0, math.ceil((listing.contract.expires - os.time()) / 60)) .. " minutes remaining", 36)
            if state.playerTrades then
                local input = field(f, "Buyout offer ($)", 2000, function() end)
                button(f, "Send offer", function() request("Bid", {id = listing.id, owner = listing.owner, amount = tonumber(input.Text)}, true) end)
            end
        end
    end
end
for _, name in ipairs({"Feed", "Roster", "Studio", "Inbox", "Market"}) do
    local b = button(tabs, name, function() tab = name; content.CanvasPosition = Vector2.new(); request("State", {}, true) end)
    b.Size = UDim2.new(0.2, -4, 1, 0)
end
request("State", {}, true)
task.spawn(function()
    while true do
        task.wait(2)
        -- Keep editable forms stable while refreshing cash and server state.
        request("State", {}, not state)
        if frame.Visible and (tab == "Inbox" or tab == "Studio" or tab == "Roster") and not UIS:GetFocusedTextBox() then render() end
    end
end)
