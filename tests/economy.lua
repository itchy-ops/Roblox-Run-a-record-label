local E = dofile('src/server/Economy.lua')
local n = 0
local function check(condition, name)
    assert(condition, name); n = n + 1
end
local a = {popularity = 20, potential = 70, members = 1, skill = 60, contract = {royalty = 20, promotion = 100, duration = 10}}
check(E.ask(a) == 830, 'asking price includes popularity and members')
check(not E.accepts(a, {bonus = 0, royalty = 0, promotion = 0, duration = 5}), 'reject lowball')
check(E.accepts(a, {bonus = 2000, royalty = 20, promotion = 100, duration = 10}), 'accept funded fair offer')
local small = E.ask(a); a.members = 5
check(E.ask(a) > small, 'bands demand more')
local bad, event = E.rate(a, 0, 0.7, 0.01)
check(bad < 0 and event == 'New single underperformed', 'careers can lose money')
local normal = E.rate(a, 1, 1, 0.5)
local viral, viralEvent = E.rate(a, 1, 1, 0.99)
check(viral > normal and viralEvent == 'Viral hit!', 'viral outcome boosts earnings')
local improved = E.rate(a, 3, 1.4, 0.5)
check(improved > normal, 'studio and genre trends matter')
a.contract.royalty = 80
check(E.rate(a, 1, 1, 0.5) < normal, 'royalties reduce label profit')
check(E.range(70, 0) == 'Uncertain potential', 'unscouted potential hidden')
check(E.range(70, 1) == E.range(71, 1), 'repeated estimates do not expose exact stats')
check(E.range(100, 3) == '98–100', 'range clamped at upper boundary')
check(E.range(0, 3) == '0–6', 'range clamped at lower boundary')
print('Economy: ' .. n .. ' checks passed')
