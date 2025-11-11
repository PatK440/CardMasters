extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1

var screen_size: Vector2
var card_being_dragged: Node2D = null
var drag_offset: Vector2 = Vector2.ZERO
var is_hovering_on_card: bool = false
var player_hand_reference
var played_card_this_turn = false


func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)


func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos: Vector2 = get_global_mouse_position()
		
		# Apply the stored offset so the card doesn't snap its origin to the mouse
		var target_pos: Vector2 = mouse_pos + drag_offset
		
		# Clamp inside screen
		target_pos.x = clamp(target_pos.x, 0, screen_size.x)
		target_pos.y = clamp(target_pos.y, 0, screen_size.y)
		
		# Use global_position to match the global mouse coordinates
		card_being_dragged.global_position = target_pos


func start_drag(card: Node2D) -> void:
	card_being_dragged = card
	card.scale = Vector2(1, 1)
	
	# Store where on the card we grabbed it (offset from mouse to card position)
	drag_offset = card.global_position - get_global_mouse_position()


func finish_drag() -> void:
	# Small hover/selected scale
	card_being_dragged.scale = Vector2(1.05, 1.05)
	
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot and !played_card_this_turn:
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		#Check if a card has been played
		played_card_this_turn = true
		# Drop directly into slot – assumes same parent / compatible coords
		card_being_dragged.global_position = card_slot_found.global_position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		card_slot_found.card_in_slot = true
		$"../BattleManager".player_cards_on_field.append(card_being_dragged)
		
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
		card_being_dragged = null
	
	card_being_dragged = null
	drag_offset = Vector2.ZERO


func connect_card_signals(card):
	card.connect("hovered", on_howered_over_card)
	card.connect("hovered_off", on_howered_off_card)


func on_left_click_released():
	if card_being_dragged:
		finish_drag() 


func on_howered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)


func on_howered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false


func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1


func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null


func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null


func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card


func reset_played_card():
	played_card_this_turn = false
