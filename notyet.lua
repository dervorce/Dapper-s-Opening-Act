-- A version that rigs the deck instead of discarding then drawing, but due to an issue in SMODS itself it doesnt work, when the smods update fixes this, this will be the main version
-- but for now, ignore this, its time is not yet
-- well you could if you got the dev version of smods from going to current smods page and downloading the main branch as zip from the green code button since that has the fix for this

local function prandomifitwasgood(tbl, tag)
    local a, b = pseudorandom_element(tbl, tag)
    if a ~= nil and b ~= nil then return a, b end
    if a == nil then return nil, nil end
    for i, v in ipairs(tbl) do
        if v == a then return a, i end
    end
    for k, v in pairs(tbl) do
        if v == a then return a, k end
    end
    return a, nil
end

local function count_ranks(rank_table)
    local counts = {}
    for _, r in ipairs(rank_table) do
        counts[r] = (counts[r] or 0) + 1
    end
    return counts
end

local function count_suits(suit_table)
    local counts = {}
    for _, s in ipairs(suit_table) do
        counts[s] = (counts[s] or 0) + 1
    end
    return counts
end

handAmount = {
    ["Flush Five"] = 5,
    ["Flush House"] = 5,
    ["Five of a Kind"] = 5,
    ["Straight Flush"] = 5,
    ["Four of a Kind"] = 4,
    ["Full House"] = 5,
    ["Flush"] = 5,
    ["Straight"] = 5,
    ["Three of a Kind"] = 3,
    ["Two Pair"] = 4,
    ["Pair"] = 2,
    ["High Card"] = 1
}

local function filter_min_count(tbl, n)
    local out = {}
    for k, v in pairs(tbl) do
        if v >= n then
            out[k] = v
        end
    end
    return out
end

local function pick_random_cards_by_rank(deck, rank, count)
    local candidates = {}
    local target = (rank ~= nil) and tostring(rank) or nil
    for _, card in ipairs(deck) do
        local cr = nil
        if card.get_id then cr = card:get_id() end
        if cr == nil and card.base and card.base.rank ~= nil then cr = card.base.rank end
        if cr ~= nil and tostring(cr) == target then
            candidates[#candidates + 1] = card
        end
    end

    if #candidates < count then return {} end

    local picked = {}
    for i = 1, count do
        local c, idx = prandomifitwasgood(candidates, 'openingact')
        if not c then
            return {}
        end
        picked[#picked + 1] = c
        if idx then
            table.remove(candidates, idx)
        else
            for j, v in ipairs(candidates) do
                if v == c then
                    table.remove(candidates, j)
                    break
                end
            end
        end
    end

    return picked
end

local function keys(tbl)
    local out = {}
    for k, _ in pairs(tbl) do
        out[#out + 1] = k
    end
    return out
end

local function find_straight_sequences(ranks)
    table.sort(ranks)

    local sequences = {}
    for i = 1, #ranks - 4 do
        local ok = true
        for j = 1, 4 do
            if ranks[i + j] ~= ranks[i] + j then
                ok = false
                break
            end
        end
        if ok then
            sequences[#sequences + 1] = {
                ranks[i],
                ranks[i + 1],
                ranks[i + 2],
                ranks[i + 3],
                ranks[i + 4]
            }
        end
    end

    return sequences
end

local function pick_random_cards_by_suit(deck, suit, count)
    local candidates = {}
    for _, card in ipairs(deck) do
        if card.base and card.base.suit == suit then
            candidates[#candidates + 1] = card
        end
    end

    if #candidates < count then return {} end

    local picked = {}
    for i = 1, count do
        local c, idx = prandomifitwasgood(candidates, 'openingact')
        if not c then return {} end
        picked[#picked + 1] = c
        if idx then
            table.remove(candidates, idx)
        else
            for j, v in ipairs(candidates) do
                if v == c then
                    table.remove(candidates, j)
                    break
                end
            end
        end
    end

    return picked
end

local function is_all_same_suit(cards)
    if not cards or #cards == 0 then return false end
    local s = cards[1].base and cards[1].base.suit
    for i = 2, #cards do
        if not cards[i].base or cards[i].base.suit ~= s then return false end
    end
    return true
end

local function is_all_same_rank(cards)
    if not cards or #cards == 0 then return false end
    local r = cards[1].get_id and cards[1]:get_id() or (cards[1].base and cards[1].base.rank)
    for i = 2, #cards do
        local rr = cards[i].get_id and cards[i]:get_id() or (cards[i].base and cards[i].base.rank)
        if rr ~= r then return false end
    end
    return true
end

local function is_straight_cards(cards)
    local ranks = {}
    for _, c in ipairs(cards) do
        local r = c.get_id and c:get_id() or (c.base and c.base.rank)
        ranks[#ranks + 1] = tonumber(r) or r
    end
    local uniq = {}
    for _, v in ipairs(ranks) do uniq[v] = true end
    local ulist = {}
    for k, _ in pairs(uniq) do ulist[#ulist + 1] = k end
    if #ulist ~= 5 then return false end
    table.sort(ulist)
    local minv = ulist[1]
    if ulist[5] - ulist[1] == 4 then
        for i = 2, 5 do if ulist[i] ~= minv + (i - 1) then return false end end
        return true
    end
    local ace_low = { 2, 3, 4, 5, 14 }
    table.sort(ace_low)
    table.sort(ulist)
    for i = 1, 5 do if ulist[i] ~= ace_low[i] then return false end end
    return true
end

local function is_full_house_cards(cards)
    local counts = {}
    for _, c in ipairs(cards) do
        local r = c.get_id and c:get_id() or (c.base and c.base.rank)
        counts[tostring(r)] = (counts[tostring(r)] or 0) + 1
    end
    local has3, has2 = false, false
    for _, v in pairs(counts) do
        if v == 3 then
            has3 = true
        elseif v == 2 then
            has2 = true
        end
    end
    return has3 and has2
end

local function combinations_indices(n, k)
    local out = {}
    if k > n or k <= 0 then return out end
    local idx = {}
    for i = 1, k do idx[i] = i end
    while true do
        local combo = {}
        for i = 1, k do combo[#combo + 1] = idx[i] end
        out[#out + 1] = combo
        local i = k
        while i >= 1 do
            idx[i] = idx[i] + 1
            if idx[i] <= n - (k - i) then
                for j = i + 1, k do
                    idx[j] = idx[j - 1] + 1
                end
                break
            end
            i = i - 1
        end
        if i < 1 then break end
    end
    return out
end

---@return string

local function most_played_hand()
    local hands = G.GAME.hands

    local mostPlayedHandName = 'High Card'
    local mostPlayedHandTimes = 0
    local maxPlayed = -math.huge

    for k, hand in pairs(G.GAME.hands) do
        if hand.played > maxPlayed then
            maxPlayed = hand.played
            mostPlayedHandName = k
            mostPlayedHandTimes = hand.played
        end
    end
    if mostPlayedHandTimes == 0 then mostPlayedHandName = 'High Card' end
    return mostPlayedHandName
end

local openingact = SMODS.Joker {
    key = "openingact",
    cost = 5,
    rarity = 3,
    config = { inblind = false },
    loc_txt = { name = 'Opening Act', text = { '{C:attention}Guaranteed{} to draw your', 'most played {C:attention} poker hand', 'on the {C:attention}first hand{} of round', '{C:inactive}(Currently {X:mult,C:white} #1# {C:inactive})' } },
    loc_vars = function(self)
        return { vars = { most_played_hand() } }
    end,
    atlas = 'Joker',
    prefix_config = { atlas = false },
    pos = G.P_CENTERS.j_hack.pos,
    calculate = function(self, card, context)
        if context.setting_blind then card.ability.inblind = true end
        if context.drawing_cards then
            if not card.ability.inblind then return end
            card.ability.inblind = false
            ---@type string

            local hand = most_played_hand()
            hand = "Straight"
            ---@type table

            local cards = {}

            ---@type table

            local ranks = {}

            ---@type table

            local suits = {}

            ---@type table

            local rankssuits = {}

            for _, playing_card in ipairs(G.deck.cards) do
                if not SMODS.has_no_suit(playing_card) then
                    suits[#suits + 1] = playing_card.base.suit
                end
                if not SMODS.has_no_rank(playing_card) then
                    ranks[#ranks + 1] = playing_card:get_id()
                end
            end

            ---@type table

            local rank_count = count_ranks(ranks)

            ---@type table

            local suit_count = count_suits(suits)

            local any_selected = nil
            local _cards = {}
            for _, playing_card in ipairs(G.hand.cards) do
                _cards[#_cards + 1] = playing_card
            end

            ---@type number

            local cardAmount = handAmount[hand]
            if cardAmount == nil then
                cardAmount = 0
            end

            if hand == "High Card" then
                local picked = prandomifitwasgood(G.deck.cards, 'openingact')
                cards = { picked }
            elseif hand == "Pair" then
                local pairs = filter_min_count(rank_count, 2)
                local pair_keys = keys(pairs)
                local pairrank = nil
                if #pair_keys > 0 then
                    pairrank = prandomifitwasgood(pair_keys, 'openingact')
                end
                cards = pick_random_cards_by_rank(G.deck.cards, pairrank, 2)
            elseif hand == "Three of a Kind" then
                local trips = filter_min_count(rank_count, 3)
                local trip_keys = keys(trips)
                local triprank = nil
                if #trip_keys > 0 then
                    triprank = prandomifitwasgood(trip_keys, 'openingact')
                end
                cards = pick_random_cards_by_rank(G.deck.cards, triprank, 3)
            elseif hand == "Four of a Kind" then
                local quads = filter_min_count(rank_count, 4)
                local quad_keys = keys(quads)
                local quadrank = nil
                if #quad_keys > 0 then
                    quadrank = prandomifitwasgood(quad_keys, 'openingact')
                end
                cards = pick_random_cards_by_rank(G.deck.cards, quadrank, 4)
            elseif hand == "Five of a Kind" then
                local quints = filter_min_count(rank_count, 5)
                local quint_keys = keys(quints)
                local fiverank = nil
                if #quint_keys > 0 then
                    fiverank = prandomifitwasgood(quint_keys, 'openingact')
                end
                cards = pick_random_cards_by_rank(G.deck.cards, fiverank, 5)
            elseif hand == "Two Pair" then
                local pairs = filter_min_count(rank_count, 2)
                local pair_keys = keys(pairs)

                if #pair_keys >= 2 then
                    local first_rank = prandomifitwasgood(pair_keys, 'openingact')

                    local remaining = {}
                    for _, r in ipairs(pair_keys) do
                        if tostring(r) ~= tostring(first_rank) then
                            remaining[#remaining + 1] = r
                        end
                    end

                    local second_rank = nil
                    if #remaining > 0 then
                        second_rank = prandomifitwasgood(remaining, 'openingact2')
                    end

                    local first_pair  = pick_random_cards_by_rank(G.deck.cards, first_rank, 2)
                    local second_pair = pick_random_cards_by_rank(G.deck.cards, second_rank, 2)

                    for _, c in ipairs(first_pair) do cards[#cards + 1] = c end
                    for _, c in ipairs(second_pair) do cards[#cards + 1] = c end
                end
            elseif hand == "Straight" then
                local unique_ranks = keys(rank_count)
                if rank_count[14] then
                    rank_count[1] = rank_count[14]
                end

                local numeric_unique = {}
                for _, k in ipairs(unique_ranks) do
                    local n = tonumber(k) or k
                    numeric_unique[#numeric_unique + 1] = n
                end
                local straights = find_straight_sequences(numeric_unique)

                if #straights > 0 then
                    local valid_straights = {}
                    for _, seq in ipairs(straights) do
                        local pools = {}
                        local ok_pool = true
                        for _, rank in ipairs(seq) do
                            local pool = {}
                            for _, c in ipairs(G.deck.cards) do
                                if (c.get_id and c:get_id() == rank) or (c.base and c.base.rank == rank) then
                                    pool[#pool + 1] = c
                                end
                            end
                            if #pool == 0 then
                                ok_pool = false; break
                            end
                            pools[#pools + 1] = pool
                        end
                        if not ok_pool then goto continue_seq_straight end

                        for attempt = 1, 30 do
                            local picked_set = {}
                            local suits_seen = {}
                            for _, pool in ipairs(pools) do
                                local c, idx = prandomifitwasgood(pool, 'openingact')
                                if not c then goto attempt_fail end
                                picked_set[#picked_set + 1] = c
                                suits_seen[c.base and c.base.suit] = (suits_seen[c.base and c.base.suit] or 0) + 1
                            end
                            local suit_count_seen = 0
                            for _k, _v in pairs(suits_seen) do suit_count_seen = suit_count_seen + 1 end
                            if suit_count_seen == 1 then
                            else
                                valid_straights[#valid_straights + 1] = picked_set
                                break
                            end
                            ::attempt_fail::
                        end

                        ::continue_seq_straight::
                    end

                    if #valid_straights > 0 then
                        cards = prandomifitwasgood(valid_straights, 'openingact')
                    end
                end
            elseif hand == "Flush" then
                local flush_suits = filter_min_count(suit_count, 5)

                if next(flush_suits) then
                    local suit_keys = keys(flush_suits)
                    local valid_flush_combos = {}

                    for _, suit in ipairs(suit_keys) do
                        local pool = {}
                        for _, c in ipairs(G.deck.cards) do
                            if c.base and tostring(c.base.suit) == tostring(suit) then
                                pool[#pool + 1] = c
                            end
                        end
                        if #pool < 5 then goto continue_suit_flush end

                        local combs = combinations_indices(#pool, 5)
                        for _, comb in ipairs(combs) do
                            local combo = {}
                            for i, idx in ipairs(comb) do combo[#combo + 1] = pool[idx] end
                            if not is_all_same_rank(combo) and not is_full_house_cards(combo) and not is_straight_cards(combo) then
                                valid_flush_combos[#valid_flush_combos + 1] = combo
                            end
                        end

                        ::continue_suit_flush::
                    end

                    if #valid_flush_combos > 0 then
                        cards = prandomifitwasgood(valid_flush_combos, 'openingact')
                    else
                        local suit = nil
                        if #suit_keys > 0 then suit = prandomifitwasgood(suit_keys, 'openingact') end
                        cards = pick_random_cards_by_suit(G.deck.cards, suit, 5)
                    end
                end
            elseif hand == "Straight Flush" then
                local flush_suits = filter_min_count(suit_count, 5)
                if next(flush_suits) then
                    local suit_keys = keys(flush_suits)
                    local potential_sf = {}

                    for _, suit in ipairs(suit_keys) do
                        local ranks_map = {}
                        for _, c in ipairs(G.deck.cards) do
                            if c.base and tostring(c.base.suit) == tostring(suit) then
                                local r = c:get_id()
                                ranks_map[r] = ranks_map[r] or {}
                                ranks_map[r][#ranks_map[r] + 1] = c
                            end
                        end

                        local seen = {}
                        for rk, _ in pairs(ranks_map) do
                            local rn = tonumber(rk) or rk
                            seen[rn] = true
                        end
                        if seen[14] then seen[1] = true end
                        local unique_ranks = {}
                        for rn, _ in pairs(seen) do unique_ranks[#unique_ranks + 1] = rn end
                        table.sort(unique_ranks)

                        local straights = find_straight_sequences(unique_ranks)
                        if #straights > 0 then
                            for _, seq in ipairs(straights) do
                                local temp_pools = {}
                                local ok = true
                                for _, rank in ipairs(seq) do
                                    local rank_key = rank
                                    if rank == 1 and ranks_map[14] and not ranks_map[1] then
                                        rank_key = 14
                                    end
                                    local pool = ranks_map[rank_key]
                                    if not pool or #pool == 0 then
                                        ok = false; break
                                    end
                                    local copy = {}
                                    for i, v in ipairs(pool) do copy[i] = v end
                                    temp_pools[#temp_pools + 1] = { rank = rank_key, pool = copy }
                                end

                                if not ok then goto continue_seq end

                                local chosen = {}

                                for _, entry in ipairs(temp_pools) do
                                    local pool = entry.pool
                                    local picked, idx = prandomifitwasgood(pool, 'openingact')
                                    if not picked or not idx then
                                        ok = false; break
                                    end
                                    chosen[#chosen + 1] = picked
                                    table.remove(pool, idx)
                                end

                                if ok and #chosen == 5 then
                                    potential_sf[#potential_sf + 1] = chosen
                                end
                                ::continue_seq::
                            end
                        end
                    end

                    if #potential_sf > 0 then
                        cards = prandomifitwasgood(potential_sf, 'openingact')
                    end
                end
            elseif hand == "Full House" then
                local trips = filter_min_count(rank_count, 3)
                local pairs = filter_min_count(rank_count, 2)

                if next(trips) then
                    local potential_fullhouses = {}
                    local trip_keys = keys(trips)
                    local pair_keys = keys(pairs)
                    for _, trip_rank in ipairs(trip_keys) do
                        for _, pair_rank in ipairs(pair_keys) do
                            if tostring(trip_rank) == tostring(pair_rank) then
                            else
                                local trip_pool = {}
                                local pair_pool = {}
                                for _, c in ipairs(G.deck.cards) do
                                    if (c.get_id and c:get_id() == trip_rank) or (c.base and tostring(c.base.rank) == tostring(trip_rank)) then
                                        trip_pool[#trip_pool + 1] = c
                                    end
                                    if (c.get_id and c:get_id() == pair_rank) or (c.base and tostring(c.base.rank) == tostring(pair_rank)) then
                                        pair_pool[#pair_pool + 1] = c
                                    end
                                end
                                if #trip_pool >= 3 and #pair_pool >= 2 then
                                    local trip_combs = combinations_indices(#trip_pool, 3)
                                    local pair_combs = combinations_indices(#pair_pool, 2)
                                    for _, tc in ipairs(trip_combs) do
                                        for _, pc in ipairs(pair_combs) do
                                            local chosen = {}
                                            for _, idx in ipairs(tc) do chosen[#chosen + 1] = trip_pool[idx] end
                                            for _, idx in ipairs(pc) do chosen[#chosen + 1] = pair_pool[idx] end
                                            if not is_all_same_suit(chosen) then
                                                potential_fullhouses[#potential_fullhouses + 1] = chosen
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if #potential_fullhouses > 0 then
                        cards = prandomifitwasgood(potential_fullhouses, 'openingact')
                    else
                        local triprank = nil
                        local trip_keys = keys(trips)
                        if #trip_keys > 0 then triprank = prandomifitwasgood(trip_keys, 'openingact') end
                        pairs[triprank] = nil
                        if next(pairs) then
                            local pair_keys = keys(pairs)
                            local pairrank = nil
                            if #pair_keys > 0 then pairrank = prandomifitwasgood(pair_keys, 'openingact') end
                            local trip_cards = pick_random_cards_by_rank(G.deck.cards, triprank, 3)
                            local pair_cards = pick_random_cards_by_rank(G.deck.cards, pairrank, 2)
                            if #trip_cards == 3 and #pair_cards == 2 then
                                for _, c in ipairs(trip_cards) do cards[#cards + 1] = c end
                                for _, c in ipairs(pair_cards) do cards[#cards + 1] = c end
                            else
                                cards = {}
                            end
                        end
                    end
                end
            elseif hand == "Flush House" then
                local segregation = {}
                local flush_suits = filter_min_count(suit_count, 5)

                local suit_keys = keys(flush_suits)
                for _, suit in ipairs(suit_keys) do
                    segregation[suit] = {}
                end

                for _, playing_card in ipairs(G.deck.cards) do
                    local suit = playing_card.base and playing_card.base.suit
                    local rank = playing_card:get_id()
                    if segregation[suit] then
                        segregation[suit][rank] = segregation[suit][rank] or {}
                        table.insert(segregation[suit][rank], playing_card)
                    end
                end

                local potential_fh = {}
                for _, suit in ipairs(suit_keys) do
                    local ranks_map = segregation[suit]
                    if not ranks_map then goto continue_suit end

                    local trip_ranks = {}
                    local pair_ranks = {}
                    for rank, cards_of_rank in pairs(ranks_map) do
                        if #cards_of_rank >= 3 then trip_ranks[#trip_ranks + 1] = rank end
                        if #cards_of_rank >= 2 then pair_ranks[#pair_ranks + 1] = rank end
                    end

                    for _, trip_rank in ipairs(trip_ranks) do
                        for _, pair_rank in ipairs(pair_ranks) do
                            if tostring(trip_rank) == tostring(pair_rank) then
                            else
                                local trip_pool = {}
                                for _, c in ipairs(ranks_map[trip_rank]) do trip_pool[#trip_pool + 1] = c end
                                local pair_pool = {}
                                for _, c in ipairs(ranks_map[pair_rank]) do pair_pool[#pair_pool + 1] = c end

                                local trip_combs = combinations_indices(#trip_pool, 3)
                                local pair_combs = combinations_indices(#pair_pool, 2)
                                for _, tc in ipairs(trip_combs) do
                                    for _, pc in ipairs(pair_combs) do
                                        local chosen = {}
                                        for _, idx in ipairs(tc) do chosen[#chosen + 1] = trip_pool[idx] end
                                        for _, idx in ipairs(pc) do chosen[#chosen + 1] = pair_pool[idx] end
                                        if is_all_same_suit(chosen) then
                                            potential_fh[#potential_fh + 1] = chosen
                                        end
                                    end
                                end
                            end
                        end
                    end

                    ::continue_suit::
                end

                if #potential_fh > 0 then
                    cards = prandomifitwasgood(potential_fh, 'openingact')
                end
            elseif hand == "Flush Five" then
                local segregation = {}
                local flush_suits = filter_min_count(suit_count, 5)

                local suit_keys = keys(flush_suits)
                for _, suit in ipairs(suit_keys) do
                    segregation[suit] = {}
                end

                for _, playing_card in ipairs(G.deck.cards) do
                    local suit = playing_card.base.suit
                    local rank = playing_card:get_id()
                    if segregation[suit] then
                        segregation[suit][rank] = segregation[suit][rank] or {}
                        table.insert(segregation[suit][rank], playing_card)
                    end
                end

                local potential_f5 = {}
                for _, suit in ipairs(suit_keys) do
                    for rank, cards_of_rank in pairs(segregation[suit]) do
                        if #cards_of_rank >= 5 then
                            local five_cards = {}
                            for i = 1, 5 do
                                local picked, idx = prandomifitwasgood(cards_of_rank, 'openingact')
                                five_cards[i] = picked
                                table.remove(cards_of_rank, idx)
                            end
                            potential_f5[#potential_f5 + 1] = five_cards
                        end
                    end
                end

                if #potential_f5 > 0 then
                    cards = prandomifitwasgood(potential_f5, 'openingact')
                end
            end

            if next(cards) == nil then
                return
            end

            for _, _c in ipairs(cards) do
                _c.rigged = true
            end

            for i = #G.deck.cards, 1, -1 do
                local _c = G.deck.cards[i]
                if _c.rigged then
                    _c.rigged = false
                    table.remove(G.deck.cards, i)
                    table.insert(G.deck.cards, _c)
                end
            end
            return {
                message = "Rigged!"
            }
        end
    end
}
