-- Execute independent world startup with an empty Workspace and an existing falling
-- character; no DataStore or gameplay services are available in this harness.
local checks = 0
local function check(v, msg) assert(v, msg); checks = checks + 1 end
local function event() return {Connect = function(self, fn) self.fn = fn end} end
local methods = {}
local meta = {__index = methods, __newindex = function(self, key, value)
    rawset(self, key, value)
    if key == 'Parent' then table.insert(value.children, self) end
end}
local function object(kind) return setmetatable({ClassName = kind, children = {}}, meta) end
function methods:FindFirstChild(name)
    for _, child in ipairs(self.children) do if child.Name == name then return child end end
end
function methods:IsA(kind) return self.ClassName == kind or kind == 'BasePart' and (self.ClassName == 'Part' or self.ClassName == 'SpawnLocation') end
function methods:SetAttribute(name, value) self[name] = value end
Instance = {new = function(kind) return object(kind) end}
workspace = object('Workspace')
local cfMeta = {__mul = function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z}, cfMeta) end}
CFrame = {new = function(x,y,z) return setmetatable({X=x,Y=y,Z=z},cfMeta) end}
Vector3 = {new = function(x,y,z) return {X=x,Y=y,Z=z} end, zero = {X=0,Y=0,Z=0}}
Color3 = {fromRGB = function(r,g,b) return {r,g,b} end, new = function() return {} end}
UDim2 = {fromOffset = function() return {} end, fromScale = function() return {} end}
Enum = {SurfaceType = {Smooth = 0}}
warn = function() end
task = {spawn = function(fn, ...) fn(...) end}
local root = {Position = {X=0,Y=-100,Z=0}, AssemblyLinearVelocity={Y=-100}}
local character = {WaitForChild = function() return root end, PivotTo = function(_, cf) root.Position = cf end}
local player = {Character = character, CharacterAdded=event()}
local players = {PlayerAdded=event(), GetPlayers=function() return {player} end}
game = {GetService = function(_, name) assert(name=='Players', 'World must not depend on DataStore'); return players end}
dofile('src/server/World.server.lua')
local town = workspace:FindFirstChild('Town')
check(town ~= nil, 'empty Workspace gets a town')
local parts = 0
for _, p in ipairs(town.children) do
    if p:IsA('BasePart') then
        parts = parts + 1
        check(p.Anchored and p.CanCollide and p.Transparency == 0, 'solid visible anchored part: ' .. p.Name)
    end
end
check(parts == 32, 'all map parts recreated')
local ground = town:FindFirstChild('Town Ground')
check(ground.Size.X == 240 and ground.Size.Z == 240 and ground.CFrame.Y == -1, 'ground supports full town footprint')
local spawn = town:FindFirstChild('Town Spawn')
check(spawn.Enabled and spawn.Neutral and spawn.CFrame.Z == 65, 'spawn enabled over ground')
check(player.RespawnLocation == spawn, 'existing player uses correct spawn')
check(root.Position.Y == 6 and root.Position.Z == 65 and root.AssemblyLinearVelocity.Y == 0, 'falling character rescued onto map')
for _, name in ipairs({'Your Studio','Open Mic','Park Stage','Music Cafe'}) do
    check(town:FindFirstChild(name .. ' booth'):FindFirstChild('ProximityPrompt').Enabled, 'booth usable: ' .. name)
end
local before = #town.children
ground.CanCollide = false; ground.Anchored = false; ground.Transparency = 1
dofile('src/server/World.server.lua')
check(#town.children == before, 'startup is repeatable without duplicate geometry')
check(ground.CanCollide and ground.Anchored and ground.Transparency == 0, 'startup repairs broken ground properties')
print('World: ' .. checks .. ' checks passed')
