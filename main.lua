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
local function GetCardAmount(tbl)
    local count = 0

    for _, entry in ipairs(tbl) do
        if entry[2] == true then
            count = count + 1
        end
    end

    return count
end
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
    for _, card in ipairs(deck) do
        if card:get_id() == rank or (card.base and card.base.rank == rank) then
            candidates[#candidates + 1] = card
        end
    end

    if #candidates < count then return {} end

    local picked = {}
    for i = 1, count do
        local c = pseudorandom_element(candidates, 'openingact')
        picked[#picked + 1] = c
        for idx, card in ipairs(candidates) do
            if card == c then
                table.remove(candidates, idx)
                break
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
        if card.base.suit == suit then
            candidates[#candidates + 1] = card
        end
    end

    if #candidates < count then return {} end

    local picked = {}
    for i = 1, count do
        local c = pseudorandom_element(candidates, 'openingact')
        picked[#picked + 1] = c
        for j, v in ipairs(candidates) do
            if v == c then
                table.remove(candidates, j)
                break
            end
        end
    end

    return picked
end
local function pick_random_cards_by_rank_and_suit(deck, rank, suit, count)
    local candidates = {}
    for _, card in ipairs(deck) do
        if card.base.rank == rank and card.base.suit == suit then
            candidates[#candidates + 1] = card
        end
    end

    if #candidates < count then return {} end

    local picked = {}
    for i = 1, count do
        local c = pseudorandom_element(candidates, 'openingact')
        picked[#picked + 1] = c
        for j, v in ipairs(candidates) do
            if v == c then
                table.remove(candidates, j)
                break
            end
        end
    end

    return picked
end
local openingact = SMODS.Joker {
    key = "openingact",
    cost = 5,
    rarity = 3,
    loc_txt = { name = 'Opening Act', text = { '{C:attention}Guaranteed{} to draw your', 'most played {C:attention} poker hand', 'on the {C:attention}first hand{} of round', '{C:inactive}(Currently {X:mult,C:white} #1# {C:inactive})' } },
    loc_vars = function(self)
        return { vars = { localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands') } }
    end,
    calculate = function(self, card, context)
        if context.first_hand_drawn then
            local domessage = false
            G.E_MANAGER:add_event(Event({
                func = function()
                    ---@type string
                    local hand = G.GAME.current_round.most_played_poker_hand
                    ---@type table
                    local cards = {}
                    ---@type table
                    local ranks = {}
                    ---@type table
                    local suits = {}

                    for _, playing_card in ipairs(G.playing_cards) do
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
                    local cardAmount = GetCardAmount(G.GAME.hands[hand].example)

                    for i = 1, cardAmount do
                        if G.hand.cards[i] then
                            local selected_card, card_index = pseudorandom_element(_cards, 'openingact')
                            G.hand:add_to_highlighted(selected_card, true)
                            table.remove(_cards, card_index)
                            any_selected = true
                            play_sound('card1', 1)
                        end
                    end

                    if any_selected then G.FUNCS.discard_cards_from_highlighted(nil, true) end
                    if hand == "High Card" then
                        cards = { pseudorandom_element(G.playing_cards, 'openingact') }
                    elseif hand == "Pair" then
                        local pairs = filter_min_count(rank_count, 2)
                        local pairrank = pseudorandom_element(keys(pairs), 'openingact')
                        cards = pick_random_cards_by_rank(G.playing_cards, pairrank, 2)
                    elseif hand == "Three of a Kind" then
                        local trips = filter_min_count(rank_count, 3)
                        local triprank = pseudorandom_element(keys(trips), 'openingact')
                        cards = pick_random_cards_by_rank(G.playing_cards, triprank, 3)
                    elseif hand == "Four of a Kind" then
                        local quads = filter_min_count(rank_count, 4)
                        local quadrank = pseudorandom_element(keys(quads), 'openingact')
                        cards = pick_random_cards_by_rank(G.playing_cards, quadrank, 4)
                    elseif hand == "Five of a Kind" then
                        local quints = filter_min_count(rank_count, 5)
                        local fiverank = pseudorandom_element(keys(quints), 'openingact')
                        cards = pick_random_cards_by_rank(G.playing_cards, fiverank, 5)
                    elseif hand == "Two Pair" then
                        local pairs = filter_min_count(rank_count, 2)
                        local pair_keys = keys(pairs)

                        if #pair_keys >= 2 then
                            local first_rank = pseudorandom_element(pair_keys, 'openingact')

                            local remaining = {}
                            for _, r in ipairs(pair_keys) do
                                if r ~= first_rank then
                                    remaining[#remaining + 1] = r
                                end
                            end

                            local second_rank = pseudorandom_element(remaining, 'openingact2')

                            local first_pair  = pick_random_cards_by_rank(G.playing_cards, first_rank, 2)
                            local second_pair = pick_random_cards_by_rank(G.playing_cards, second_rank, 2)

                            for _, c in ipairs(first_pair) do cards[#cards + 1] = c end
                            for _, c in ipairs(second_pair) do cards[#cards + 1] = c end
                        end
                    elseif hand == "Straight" then
                        local unique_ranks = keys(rank_count)
                        if rank_count[14] then
                            rank_count[1] = rank_count[14]
                        end
                        local straights = find_straight_sequences(unique_ranks)

                        if #straights > 0 then
                            local straight_ranks = pseudorandom_element(straights, 'openingact')

                            for _, rank in ipairs(straight_ranks) do
                                local picked = pick_random_cards_by_rank(G.playing_cards, rank, 1)
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
                            local suit = pseudorandom_element(keys(flush_suits), 'openingact')
                            cards = pick_random_cards_by_suit(G.playing_cards, suit, 5)
                        end
                    elseif hand == "Straight Flush" then
                        local flush_suits = filter_min_count(suit_count, 5)

                        if next(flush_suits) then
                            local suit = pseudorandom_element(keys(flush_suits), 'openingact')

                            local suited_ranks = {}
                            for _, card in ipairs(G.playing_cards) do
                                if card.base.suit == suit then
                                    suited_ranks[#suited_ranks + 1] = card.base.rank
                                end
                            end

                            local unique = {}
                            for _, r in ipairs(suited_ranks) do unique[r] = true end
                            local unique_ranks = keys(unique)

                            local straights = find_straight_sequences(unique_ranks)

                            if #straights > 0 then
                                local straight = pseudorandom_element(straights, 'openingact')

                                for _, rank in ipairs(straight) do
                                    local picked = pick_random_cards_by_rank(G.playing_cards, rank, 1)
                                    if #picked == 0 then
                                        cards = {}
                                        break
                                    end
                                    cards[#cards + 1] = picked[1]
                                end
                            end
                        end
                    elseif hand == "Full House" then
                        local trips = filter_min_count(rank_count, 3)
                        local pairs = filter_min_count(rank_count, 2)

                        if next(trips) then
                            local triprank = pseudorandom_element(keys(trips), 'openingact')

                            pairs[triprank] = nil

                            if next(pairs) then
                                local pairrank = pseudorandom_element(keys(pairs), 'openingact')

                                local trip_cards = pick_random_cards_by_rank(G.playing_cards, triprank, 3)
                                local pair_cards = pick_random_cards_by_rank(G.playing_cards, pairrank, 2)

                                if #trip_cards == 3 and #pair_cards == 2 then
                                    for _, c in ipairs(trip_cards) do cards[#cards + 1] = c end
                                    for _, c in ipairs(pair_cards) do cards[#cards + 1] = c end
                                else
                                    cards = {}
                                end
                            end
                        end
                    elseif hand == "Flush House" then
                        local flush_suits = filter_min_count(suit_count, 5)

                        if next(flush_suits) then
                            local suit = pseudorandom_element(keys(flush_suits), 'openingact')

                            local suited_ranks = {}
                            for _, card in ipairs(G.playing_cards) do
                                if card.base.suit == suit then
                                    suited_ranks[#suited_ranks + 1] = card.base.rank
                                end
                            end

                            local suited_rank_count = count_ranks(suited_ranks)
                            local trips = filter_min_count(suited_rank_count, 3)
                            local pairs = filter_min_count(suited_rank_count, 2)

                            if next(trips) then
                                local triprank = pseudorandom_element(keys(trips), 'openingact')
                                pairs[triprank] = nil

                                if next(pairs) then
                                    local pairrank = pseudorandom_element(keys(pairs), 'openingact')

                                    local trip_cards = pick_random_cards_by_rank_and_suit(
                                        G.playing_cards, triprank, suit, 3
                                    )
                                    local pair_cards = pick_random_cards_by_rank_and_suit(
                                        G.playing_cards, pairrank, suit, 2
                                    )

                                    if #trip_cards == 3 and #pair_cards == 2 then
                                        for _, c in ipairs(trip_cards) do cards[#cards + 1] = c end
                                        for _, c in ipairs(pair_cards) do cards[#cards + 1] = c end
                                    else
                                        cards = {}
                                    end
                                end
                            end
                        end
                    elseif hand == "Flush Five" then
                        local flush_suits = filter_min_count(suit_count, 5)

                        if next(flush_suits) then
                            local suit = pseudorandom_element(keys(flush_suits), 'openingact')

                            local suited_ranks = {}
                            for _, card in ipairs(G.playing_cards) do
                                if card.base.suit == suit then
                                    suited_ranks[#suited_ranks + 1] = card.base.rank
                                end
                            end

                            local suited_rank_count = count_ranks(suited_ranks)
                            local fives = filter_min_count(suited_rank_count, 5)

                            if next(fives) then
                                local rank = pseudorandom_element(keys(fives), 'openingact')

                                cards = pick_random_cards_by_rank_and_suit(
                                    G.playing_cards, rank, suit, 5
                                )
                            end
                        end
                    end
                    if cards == {} then
                        return true
                    end
                    domessage = true
                    for _, card in ipairs(cards) do
                        G.hand:emplace(card)
                        card.states.visible = nil
                        card:start_materialize()
                    end
                    return true
                end
            }))
            if domessage then
                return {
                    message = "Rigged!"
                }
            end
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
                return true
            end
        }))
    end
}
-- local openingact = SMODS.Joker {
--     key = "openingact",
--     cost = 5,
--     rarity = 3,
--     loc_txt = { name = 'Opening Act', text = { '{C:attention}Guaranteed{} to draw your', 'most played {C:attention} poker hand', 'on the {C:attention}first hand{} of round', '{C:inactive}(Currently {X:mult,C:white} #1# {C:inactive})' } },
--     loc_vars = function(self)
--         return { vars = { localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands') } }
--     end,
--     calculate = function(self, card, context)
--         if context.first_hand_drawn then
--             G.E_MANAGER:add_event(Event({
--                 func = function()
--                     ---@type string
--                     local hand = G.GAME.current_round.most_played_poker_hand
--                     if hand == "High Card" then
--                         return true
--                     end

--                     local any_selected = nil
--                     local _cards = {}
--                     for _, playing_card in ipairs(G.hand.cards) do
--                         _cards[#_cards + 1] = playing_card
--                     end
--                     ---@type number
--                     local cardAmount = GetCardAmount(G.GAME.hands[hand].example)

--                     for i = 1, cardAmount do
--                         if G.hand.cards[i] then
--                             local selected_card, card_index = pseudorandom_element(_cards, 'openingact')
--                             G.hand:add_to_highlighted(selected_card, true)
--                             table.remove(_cards, card_index)
--                             any_selected = true
--                             play_sound('card1', 1)
--                         end
--                     end

--                     if hand == "Pair" then
--                         return
--                     end

--                     if any_selected then G.FUNCS.discard_cards_from_highlighted(nil, true) end
--                     return true
--                 end
--             }))
--         end
--     end
-- }
