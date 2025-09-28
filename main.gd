extends Node

var base_cards = ["Taco", "Bat", "Soap", "Cheese", "Pizza", "Cow", "Monke"] # Blahaj handled separately
var chant = ["Taco", "Bat", "Soap", "Cheese", "Pizza"]

var players = []
var pile = []
var turn_index = 0
var chant_index = 0
var slap_order = []
var spam_counts = {} # Track Q/P spams per player
var spamming = false

var spam_timer : Timer

func _ready():
	randomize()
	start_game()

	# Setup Timer node for Monke spam
	spam_timer = Timer.new()
	spam_timer.wait_time = 5.0
	spam_timer.one_shot = true
	add_child(spam_timer)
	spam_timer.timeout.connect(_on_SpamTimer_timeout)

func start_game():
	players.clear()
	pile.clear()
	turn_index = 0
	chant_index = 0
	slap_order.clear()
	spam_counts.clear()
	spamming = false

	var num_players = 4
	var hand_size = 8
	var total_needed = num_players * hand_size
	var deck = []

	# Add multiple copies of base cards
	var copies_per_card = int(ceil((total_needed - 1) / float(base_cards.size())))
	for card in base_cards:
		for i in range(copies_per_card):
			deck.append(card)

	# Add exactly one Blahaj at random
	var blahaj_pos = randi() % total_needed
	deck.insert(blahaj_pos, "Blahaj")

	# Trim and shuffle
	deck = deck.slice(0, total_needed)
	deck.shuffle()

	# Deal cards
	for i in range(num_players):
		players.append([])
	var p = 0
	for card in deck:
		players[p].append(card)
		p = (p + 1) % num_players

	print("Game ready! Chant with T/B/S/C/P, slap with SPACE, spam Q/P on Monke!")

func _input(event):
	if event is InputEventKey and event.pressed:
		# Reliable uppercase character detection
		var pressed_key = char(event.keycode).to_upper()

		if spamming:
			if pressed_key == "Q" or pressed_key == "P":
				var current_player = slap_order.size() % players.size()
				spam_counts[current_player] = spam_counts.get(current_player, 0) + 1
				print("Player %d spams (%s) total: %d" % [current_player + 1, pressed_key, spam_counts[current_player]])
		else:
			var expected_word = chant[chant_index]
			var expected_key = expected_word.substr(0, 1).to_upper()

			if pressed_key == expected_key:
				play_card()
			elif pressed_key == " ":
				if pile.size() > 0 and slap_order.find(turn_index) == -1:
					slap_order.append(turn_index)
					print("Player %d slapped!" % [turn_index + 1])
					if slap_order.size() == players.size():
						resolve_slap()
			else:
				print("Wrong key! Expected %s for %s" % [expected_key, expected_word])

func play_card():
	var player_hand = players[turn_index]
	if player_hand.size() == 0:
		print("Player %d has no cards left!" % [turn_index + 1])
		return

	var card = player_hand.pop_front()
	pile.append(card)

	var word = chant[chant_index]
	print("Player %d plays %s and says %s" % [turn_index + 1, card, word])

	if card == word:
		print("MATCH! Everyone slap with SPACE!")
		slap_order.clear()
	elif card == "Monke":
		print("MONKE played! Everyone spam Q and P!")
		start_monke_spam()

	# Advance turn + chant
	turn_index = (turn_index + 1) % players.size()
	chant_index = (chant_index + 1) % chant.size()

	check_victory()

func start_monke_spam():
	spamming = true
	spam_counts.clear()
	slap_order.clear()
	spam_timer.start()

func _on_SpamTimer_timeout():
	end_monke_spam()

func end_monke_spam():
	spamming = false
	var lowest = INF
	var loser_id = null

	for i in range(players.size()):
		var count = spam_counts.get(i, 0)
		if count < lowest:
			lowest = count
			loser_id = i

	if loser_id != null:
		players[loser_id] += pile
		pile.clear()
		print("Player %d spammed least (%d)! They take the pile!" % [loser_id + 1, lowest])

	check_victory()

func resolve_slap():
	var loser_id = slap_order[-1]
	players[loser_id] += pile
	pile.clear()
	print("Player %d was last! They take the pile!" % [loser_id + 1])

	check_victory()

# --- Victory & Play Again ---

func check_victory():
	for i in range(players.size()):
		# Victory if player has all cards
		var total_cards = 4 * 8 # 4 players × 8 cards
		if players[i].size() == total_cards:
			show_victory(i)
			return true
	return false

func show_victory(player_id):
	$VictoryLabel.text = "Player %d Wins!" % [player_id + 1]
	$VictoryLabel.visible = true
	$PlayAgainButton.visible = true

func _on_PlayAgainButton_pressed():
	$VictoryLabel.visible = false
	$PlayAgainButton.visible = false
	start_game()
