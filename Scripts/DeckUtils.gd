extends Node
class_name DeckUtils

static func generate_random_deck(card_db: Dictionary, deck_size: int = 15, max_copies_per_card: int = 3) -> Array:
	var all_cards := card_db.keys()
	var card_counts := {}
	for name in all_cards:
		card_counts[name] = 0

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var deck: Array = []
	while deck.size() < deck_size:
		var pick = all_cards[rng.randi_range(0, all_cards.size() - 1)]
		if card_counts[pick] < max_copies_per_card:
			deck.append(pick)
			card_counts[pick] += 1
	return deck
