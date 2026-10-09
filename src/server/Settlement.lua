-- Idempotent settlement through saved escrow records. Removing an escrow and applying
-- its result are persisted together in one profile UpdateAsync.
local Settlement = {}
function Settlement.apply(profile, id, status)
    local escrow = profile.escrows and profile.escrows[id]
    if not escrow then return false end
    assert(status == "committed" or status == "aborted", "Settlement must be terminal")
    local receiveArtist = (status == "committed" and escrow.role == "buyer")
        or (status == "aborted" and escrow.role == "seller")
    if receiveArtist then
        local exists = false
        for _, a in ipairs(profile.artists) do if a.id == escrow.artist.id then exists = true end end
        if not exists then table.insert(profile.artists, escrow.artist) end
    else
        profile.cash = profile.cash + escrow.amount
    end
    profile.escrows[id] = nil
    return true
end
return Settlement
