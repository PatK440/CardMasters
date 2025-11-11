extends Node

const CARD_MOVE_SPEED = 0.2

var battle_timer
var empty_card_slots = []
var opponent_cards_on_field = []
var player_cards_on_field = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0 #AI Turn duration
	
	empty_card_slots.append($"../Cardslots/OppCardSlot")
	empty_card_slots.append($"../Cardslots/OppCardSlot2")
	empty_card_slots.append($"../Cardslots/OppCardSlot3")

func _on_end_turn_button_pressed() -> void:
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	opponent_turn()

func opponent_turn():
	battle_timer.start()
	await battle_timer.timeout
	
	if $"../OppDeck".opponent_deck.size() != 0:
		$"../OppDeck".draw_card()
		battle_timer.start()
		await battle_timer.timeout
	
	#Check if any slot is free
	if empty_card_slots.size() != 0:
		await try_play_card_with_highest_atk()

	#Try attack
	#Cards on battlefield?
	if opponent_cards_on_field.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_field.duplicate()
		for c in enemy_cards_to_attack:
			if player_cards_on_field.size() == 0:
				#Perform direct attack(s)
				direct_attack()

	#End enemy turn
	end_opponent_turn()

func try_play_card_with_highest_atk():
		#Play card
	#Get random slot where to play card
	var opponent_hand = $"../OppHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
		
	var random_empty_card_slot = empty_card_slots[randi_range(0, empty_card_slots.size()-1)] #-1 mayybeee?
	empty_card_slots.erase(random_empty_card_slot)
	
	#play a card with highest attack
	var card_with_highest_atk = opponent_hand[0]
	for c in opponent_hand:
		if c.attack > card_with_highest_atk.attack:
			card_with_highest_atk = c
			
	#Animate to position
	var tween = get_tree().create_tween()
	var target_pos_in_parent = card_with_highest_atk.get_parent().to_local(
		random_empty_card_slot.global_position
	)
	tween.tween_property(
		card_with_highest_atk,
		"position",
		target_pos_in_parent,
		CARD_MOVE_SPEED
	)
	card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")
	
	#Remove played card from enemy hand
	$"../OppHand".remove_card_from_hand(card_with_highest_atk)
	
	opponent_cards_on_field.append(card_with_highest_atk)
	
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	#Reset player deck draw and play limit
	$"../Deck".reset_draw() 
	$"../CardManager".reset_played_card()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
