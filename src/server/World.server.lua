-- Independent map startup: this script never requires profile or DataStore modules.
local Players = game:GetService("Players")
local mapVersion = "Map fix 3"
local definitions = {{name="Town Ground",size={240,1,240},position={0,-1,0},color={63,91,77},kind="Part"},{name="Main Street",size={22,0.2,200},position={0,-0.35,0},color={42,44,54},kind="Part"},{name="Town Spawn",size={8,1,8},position={0,1,65},color={112,82,213},kind="SpawnLocation"},{name="Your Studio",size={30,1,26},position={-40,0,45},color={85,62,94},kind="Part"},{name="Your Studio rear wall",size={30,12,1},position={-40,6,32},color={44,49,65},kind="Part"},{name="Your Studio left wall",size={1,12,26},position={-55,6,45},color={44,49,65},kind="Part"},{name="Your Studio right wall",size={1,12,26},position={-25,6,45},color={44,49,65},kind="Part"},{name="Your Studio path",size={18,0.2,8},position={-20,-0.25,53},color={140,143,151},kind="Part"},{name="Your Studio booth",size={5,3,3},position={-40,2,38},color={117,82,165},kind="Part"},{name="Battered mixing desk",size={8,2,4},position={-47,2,48},color={75,65,57},kind="Part"},{name="Old microphone",size={0.4,5,0.4},position={-33,3,45},color={105,105,105},kind="Part"},{name="Open Mic",size={30,1,26},position={40,0,25},color={105,62,94},kind="Part"},{name="Open Mic rear wall",size={30,12,1},position={40,6,12},color={44,49,65},kind="Part"},{name="Open Mic left wall",size={1,12,26},position={25,6,25},color={44,49,65},kind="Part"},{name="Open Mic right wall",size={1,12,26},position={55,6,25},color={44,49,65},kind="Part"},{name="Open Mic path",size={18,0.2,8},position={20,-0.25,33},color={140,143,151},kind="Part"},{name="Open Mic booth",size={5,3,3},position={40,2,18},color={117,82,165},kind="Part"},{name="Open Mic stage",size={12,1,6},position={40,1,21},color={94,82,115},kind="Part"},{name="Park Stage",size={30,1,26},position={-40,0,-25},color={125,62,94},kind="Part"},{name="Park Stage rear wall",size={30,12,1},position={-40,6,-38},color={44,49,65},kind="Part"},{name="Park Stage left wall",size={1,12,26},position={-55,6,-25},color={44,49,65},kind="Part"},{name="Park Stage right wall",size={1,12,26},position={-25,6,-25},color={44,49,65},kind="Part"},{name="Park Stage path",size={18,0.2,8},position={-20,-0.25,-17},color={140,143,151},kind="Part"},{name="Park Stage booth",size={5,3,3},position={-40,2,-32},color={117,82,165},kind="Part"},{name="Park Stage stage",size={12,1,6},position={-40,1,-29},color={94,82,115},kind="Part"},{name="Music Cafe",size={30,1,26},position={40,0,-55},color={145,62,94},kind="Part"},{name="Music Cafe rear wall",size={30,12,1},position={40,6,-68},color={44,49,65},kind="Part"},{name="Music Cafe left wall",size={1,12,26},position={25,6,-55},color={44,49,65},kind="Part"},{name="Music Cafe right wall",size={1,12,26},position={55,6,-55},color={44,49,65},kind="Part"},{name="Music Cafe path",size={18,0.2,8},position={20,-0.25,-47},color={140,143,151},kind="Part"},{name="Music Cafe booth",size={5,3,3},position={40,2,-62},color={117,82,165},kind="Part"},{name="Music Cafe stage",size={12,1,6},position={40,1,-59},color={94,82,115},kind="Part"}}
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
