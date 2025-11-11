extends Node

const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 10
const BATTLE_POSITION_OFFSET = 85

var battle_timer
var empty_card_slots = []
var opponent_cards_on_field = []
var player_cards_on_field = []
var player_health
var opponent_health

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0 #AI Turn duration
	
	empty_card_slots.append($"../Cardslots/OppCardSlot")
	empty_card_slots.append($"../Cardslots/OppCardSlot2")
	empty_card_slots.append($"../Cardslots/OppCardSlot3")
	
	player_health = STARTING_HEALTH
	$"../PlayerHealth".text = str(player_health)
	opponent_health = STARTING_HEALTH
	$"../OpponentHealth".text = str(opponent_health)

func _on_end_turn_button_pressed() -> void:
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	opponent_turn()

func opponent_turn():
	battle_timer.start()
	await battle_timer.timeout
	
	if $"../OppDeck".opponent_deck.size() != 0:
		$"../OppDeck".draw_card()
		await wait(1)
	
	#Check if any slot is free
	if empty_card_slots.size() != 0:
		await try_play_card_with_highest_atk()

	#Try attack
	#Cards on battlefield?
	if opponent_cards_on_field.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_field.duplicate()
		for c in enemy_cards_to_attack:
			if player_cards_on_field.size() != 0:
				var card_to_attack = player_cards_on_field.pick_random()
				await attack(c, card_to_attack, "opponent")
			else:
				#Perform direct attack(s)
				direct_attack(c, "opponent")

	#End enemy turn
	end_opponent_turn()

func direct_attack(attacking_card, attacker):
	var new_position_y
	
	# You call this with "opponent", so check for "opponent" (lowercase)
	if attacker == "opponent":
		new_position_y = 1080
	else: 
		new_position_y = 0
	
	# Use GLOBAL x so the card moves straight up/down in world space
	var new_position = Vector2(attacking_card.global_position.x, new_position_y)
	
	attacking_card.z_index = 5
	
	# Move card to attack position
	var tween = get_tree().create_tween()
	var target_pos_in_parent = attacking_card.get_parent().to_local(new_position)
	tween.tween_property(
		attacking_card,
		"position",
		target_pos_in_parent,
		CARD_MOVE_SPEED
	)
	await wait(0.2)
	print("Direct hit!")
	
	# Damage dealing logic (unchanged)
	if attacker == "opponent":
		player_health = max(0, player_health - attacking_card.attack)
		$"../PlayerHealth".text = str(player_health)
	else:
		opponent_health = max(0, opponent_health - attacking_card.attack)
		$"../OpponentHealth".text = str(opponent_health)
	
	# Move card back to its slot (CRUCIAL PART THAT FIXES MISALIGNMENT)
	var tween2 = get_tree().create_tween()
	var slot_global_pos = attacking_card.card_slot_card_is_in.global_position
	var slot_pos_in_parent = attacking_card.get_parent().to_local(slot_global_pos)
	tween2.tween_property(
		attacking_card,
		"position",
		slot_pos_in_parent,
		CARD_MOVE_SPEED
	)
	attacking_card.z_index = 0
	await wait(0.25)
	

func attack(attacking_card, defending_card, attacker):
	attacking_card.z_index = 5
	var new_position = Vector2(defending_card.position.x - 50, defending_card.position.y - BATTLE_POSITION_OFFSET)
	var tween = get_tree().create_tween()
	var target_pos_in_parent = attacking_card.get_parent().to_local(new_position)
	tween.tween_property(
		attacking_card,
		"position",
		target_pos_in_parent,
		CARD_MOVE_SPEED
	)
	await wait(0.75)

	var tween2 = get_tree().create_tween()
	var slot_global_pos = attacking_card.card_slot_card_is_in.global_position
	var slot_pos_in_parent = attacking_card.get_parent().to_local(slot_global_pos)
	tween2.tween_property(
		attacking_card,
		"position",
		slot_pos_in_parent,
		CARD_MOVE_SPEED
	)
	
	#Damage
	defending_card.health = max(0, defending_card.health - attacking_card.attack)

func try_play_card_with_highest_atk():
		#Play card
	#Get random slot where to play card
	var opponent_hand = $"../OppHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
		
	var random_empty_card_slot = empty_card_slots.pick_random() 
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
	card_with_highest_atk.card_slot_card_is_in = random_empty_card_slot
	opponent_cards_on_field.append(card_with_highest_atk)
	
	await wait(1.0)

func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	#Reset player deck draw and play limit
	$"../Deck".reset_draw() 
	$"../CardManager".reset_played_card()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
