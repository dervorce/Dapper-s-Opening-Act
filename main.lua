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

---@return string

local function most_played_hand()
    local hands = G.GAME.hands

    local mostPlayedHand = 'High Card'
    local maxPlayed = -math.huge

    for k, hand in pairs(G.GAME.hands) do
        if hand.played > maxPlayed then
            maxPlayed = hand.played
            mostPlayedHand = k
        end
    end
    return mostPlayedHand
end

local openingact = SMODS.Joker {
    key = "openingact",
    cost = 5,
    rarity = 3,
    loc_txt = { name = 'Opening Act', text = { '{C:attention}Guaranteed{} to draw your', 'most played {C:attention} poker hand', 'on the {C:attention}first hand{} of round', '{C:inactive}(Currently {X:mult,C:white} #1# {C:inactive})' } },
    loc_vars = function(self)
        return { vars = { most_played_hand() } }
    end,
    calculate = function(self, card, context)
        if context.first_hand_drawn then
            ---@type string

            local hand = most_played_hand()

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
                    local straight_ranks = prandomifitwasgood(straights, 'openingact')

                    for _, rank in ipairs(straight_ranks) do
                        local picked = pick_random_cards_by_rank(G.deck.cards, rank, 1)
                        if #picked == 0 then
                            cards = {}
                            break
                        end
                        cards[#cards + 1] = picked[1]
                    end
                end
            elseif hand == "Flush" then
                local flush_suits = filter_min_count(suit_count, 5)

                if next(flush_suits) then
                    local suit_keys = keys(flush_suits)
                    local suit = nil
                    if #suit_keys > 0 then suit = prandomifitwasgood(suit_keys, 'openingact') end
                    cards = pick_random_cards_by_suit(G.deck.cards, suit, 5)
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
                    local trip_keys = keys(trips)
                    local triprank = nil
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

                                local ok = true
                                local chosen_trip = {}

                                for i = 1, 3 do
                                    if #trip_pool == 0 then
                                        ok = false; break
                                    end
                                    local picked, idx = prandomifitwasgood(trip_pool, 'openingact')
                                    if not picked or not idx then
                                        ok = false; break
                                    end
                                    chosen_trip[#chosen_trip + 1] = picked
                                    table.remove(trip_pool, idx)
                                end

                                if not ok then goto continue_pair end

                                local chosen_pair = {}

                                for i = 1, 2 do
                                    if #pair_pool == 0 then
                                        ok = false; break
                                    end
                                    local picked, idx = prandomifitwasgood(pair_pool, 'openingact')
                                    if not picked or not idx then
                                        ok = false; break
                                    end
                                    chosen_pair[#chosen_pair + 1] = picked
                                    table.remove(pair_pool, idx)
                                end

                                if ok and #chosen_trip == 3 and #chosen_pair == 2 then
                                    potential_fh[#potential_fh + 1] = {
                                        chosen_trip[1], chosen_trip[2], chosen_trip[3],
                                        chosen_pair[1], chosen_pair[2]
                                    }
                                end
                            end
                            ::continue_pair::
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
                                five_cards[i], idx = prandomifitwasgood(cards_of_rank, 'openingact')

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
            for i = 1, cardAmount do
                if G.hand.cards[i] then
                    local selected_card, card_index = prandomifitwasgood(_cards, 'openingact')
                    G.hand:add_to_highlighted(selected_card, true)
                    if card_index then
                        table.remove(_cards, card_index)
                    else
                        for j, v in ipairs(_cards) do
                            if v == selected_card then
                                table.remove(_cards, j)
                                break
                            end
                        end
                    end
                    any_selected = true
                    play_sound('card1', 1)
                end
            end

            if any_selected then G.FUNCS.discard_cards_from_highlighted(nil, true) end
            for _, card in ipairs(cards) do
                draw_card(G.deck, G.hand, 90, 'up', false, card)
            end
            return {
                message = "Rigged!"
            }
        end
    end
}

local deck = SMODS.Back {
    loc_txt = {
        name = 'Test Deck',
        text = {
            "Start run with",
            "{C:attention}Hieroglyph{} and {C:attention}Petroglyph"
        }
    },
    key = "TestDick89",
    atlas = 'Joker',
    prefix_config = { atlas = false },
    pos = G.P_CENTERS.j_ancient.pos,
    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                SMODS.add_card({ key = 'j_Dapper_openingact', edition = 'e_negative', stickers = { 'eternal' }, force_stickers = true })
                SMODS.add_card({ key = 'j_four_fingers', edition = 'e_negative', stickers = { 'eternal' }, force_stickers = true })
                SMODS.add_card({ key = 'j_shortcut', edition = 'e_negative', stickers = { 'eternal' }, force_stickers = true })
                for i = 1, 20 do
                    v = G.playing_cards[i]
                    v:change_suit('Hearts')
                    if i <= 15 then
                        assert(SMODS.modify_rank(v, 14 - v:get_id()))
                    else
                        assert(SMODS.modify_rank(v, 13 - v:get_id()))
                    end
                end
                return true
            end
        }))
    end,
}
