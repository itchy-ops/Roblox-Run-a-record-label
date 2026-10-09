local Economy = {}
function Economy.ask(a)
    return math.floor(250 + a.popularity * 22 + a.members * 140)
end
function Economy.value(bonus, royalty, duration, promotion)
    return bonus + royalty * duration * 18 + promotion * 0.6
end
function Economy.accepts(a, terms)
    return Economy.value(terms.bonus, terms.royalty, terms.duration, terms.promotion)
        >= Economy.ask(a) * (0.65 + a.potential / 400)
end
function Economy.rate(a, studio, trend, roll)
    local event, multiplier = "Steady streams", 1
    if roll < 0.12 then event, multiplier = "New single underperformed", 0.2
    elseif roll > 0.94 then event, multiplier = "Viral hit!", 3
    elseif roll > 0.72 then event, multiplier = "Song gaining traction", 1.5 end
    local release = a.releaseUntil and a.releaseUntil > os.time() and 1.45 or 1
    local tour = a.tourUntil and a.tourUntil > os.time() and 1.3 or 1
    local promotion = 1 + math.min(1, a.contract.promotion / a.contract.duration / 100)
    local gross = (1 + a.popularity * 0.18) * (0.4 + a.skill / 100)
        * (0.65 + studio * 0.25) * trend * multiplier * release * tour * promotion
    local expense = a.members * 0.7 + a.contract.promotion / (a.contract.duration * 60)
    return gross * (1 - a.contract.royalty / 100) - expense, event
end
function Economy.range(potential, level)
    if level == 0 then return "Uncertain potential" end
    local width = ({25, 12, 4})[level]
    -- Fixed buckets do not leak the exact hidden stat through repeated scouting.
    local center = math.floor(potential / width) * width + math.floor(width / 2)
    return tostring(math.max(0, center - width)) .. "–" .. tostring(math.min(100, center + width))
end
return Economy
