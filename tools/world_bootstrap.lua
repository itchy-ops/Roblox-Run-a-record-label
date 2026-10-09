-- Independent map startup: this script never requires profile or DataStore modules.
local Players = game:GetService("Players")
local mapVersion = "Map fix 3"
local definitions = __PART_DEFINITIONS__
local locations = {"Your Studio", "Open Mic", "Park Stage", "Music Cafe"}
local town = workspace:FindFirstChild("Town")
local function validMap(model)
    if not model then return false end
    for _, d in ipairs(definitions) do
        local p = model:FindFirstChild(d.name)
        if not p or not p:IsA("BasePart") then return false end
    end
    return true
end
local repaired = not validMap(town)
if not town then
    town = Instance.new("Model")
    town.Name = "Town"
    town.Parent = workspace
end
for _, d in ipairs(definitions) do
    local p = town:FindFirstChild(d.name)
    if p and not p:IsA("BasePart") then
        warn("RecordLabel map name collision: " .. d.name)
        p.Name = d.name .. " preserved"
        p = nil
    end
    if not p then
        p = Instance.new(d.kind)
        p.Name = d.name
        p.Parent = town
    end
    p.Anchored = true
    p.CanCollide = true
    p.Transparency = 0
    p.Size = Vector3.new(d.size[1], d.size[2], d.size[3])
    p.CFrame = CFrame.new(d.position[1], d.position[2], d.position[3])
    p.Color = Color3.fromRGB(d.color[1], d.color[2], d.color[3])
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    if d.kind == "SpawnLocation" then p.Enabled = true; p.Neutral = true; p.Duration = 0 end
end
for index, name in ipairs(locations) do
    local booth = town:FindFirstChild(name .. " booth")
    local prompt = booth:FindFirstChild("ProximityPrompt")
    if not prompt then prompt = Instance.new("ProximityPrompt"); prompt.Name = "ProximityPrompt"; prompt.Parent = booth end
    prompt.Enabled = true
    prompt.ActionText = index == 1 and "Check studio" or "Discover local talent"
    prompt.ObjectText = name
    prompt.MaxActivationDistance = 10
    local floor = town:FindFirstChild(name)
    if not floor:FindFirstChild("Location Sign") then
        local sign = Instance.new("BillboardGui")
        sign.Name = "Location Sign"; sign.Size = UDim2.fromOffset(220, 50)
        sign.StudsOffset = Vector3.new(0, 13, 0); sign.AlwaysOnTop = true; sign.Parent = floor
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
        label.Text = name; label.TextColor3 = Color3.new(1, 1, 1); label.TextScaled = true; label.Parent = sign
    end
end
local spawn = town:FindFirstChild("Town Spawn")
town:SetAttribute("MapVersion", mapVersion)
-- Use this map's spawn explicitly, including for players already present at startup.
local function bind(player)
    player.RespawnLocation = spawn
    local function characterReady(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not root or player.Character ~= character then return end
        if repaired or root.Position.Y < -10 or math.abs(root.Position.X) > 110 or math.abs(root.Position.Z) > 110 then
            character:PivotTo(spawn.CFrame * CFrame.new(0, 5, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
    player.CharacterAdded:Connect(characterReady)
    if player.Character then task.spawn(characterReady, player.Character) end
end
Players.PlayerAdded:Connect(bind)
for _, player in ipairs(Players:GetPlayers()) do bind(player) end
print("RecordLabel " .. mapVersion .. ": " .. #definitions .. " anchored map parts ready; spawn at (0, 1, 65).")
