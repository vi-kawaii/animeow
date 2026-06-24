extends Node3D

@onready var name_label = find_child("CharacterLabel")
@onready var text_label = find_child("DialogueLabel")
@onready var response_example = find_child("ResponseExample")
@onready var responses_menu = find_child("ResponsesMenu")
@onready var _responses = find_child("Responses")
@onready var dialogue = find_child("ExampleBalloon")

var text = ""
var i = 0
var title = ""
var showing_response = false
var responses = []
var response_i = 0
var is_dialog = false
var callback = func(): pass

var end_callback = func(): pass

func set_end_callback(c):
	end_callback = c

@export var dialog_data: Dialog

func _ready() -> void:
	pass

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("next_text") and text:
		next()
	if Input.is_action_just_pressed("mouse_scroll_up") and showing_response:
		up()
	if Input.is_action_just_pressed("mouse_scroll_down") and showing_response:
		down()
	if Input.is_action_just_pressed("prev_response") and showing_response:
		up()
	if Input.is_action_just_pressed("next_response") and showing_response:
		down()

func start(t):
	is_dialog = true
	title = t
	text = dialog_data.data.filter(func(x): return x.title == title)[0].sentences
	next()
	dialogue.set_visible(true)

func next():
	if showing_response:
		select_response()
		return

	if i == len(text):
		if any_responses():
			show_responses()
		else:
			end()
		return

	name_label.text = text[i].name
	text_label.text = text[i].text

	i += 1

func any_responses():
	if dialog_data.data.filter(func(x): return x.title == title)[0].responses:
		return true
	else:
		return false

func set_callback(x):
	callback = x

func end():
	is_dialog = false
	dialogue.set_visible(false)
	i = 0
	text = ""
	callback.call()
	end_callback.call()

func show_responses():
	showing_response = true

	var r = dialog_data.data.filter(func(x): return x.title == title)[0].responses
	for x in r:
		var c = response_example.duplicate()
		responses_menu.add_child(c)
		c.get_node("MarginContainer/Label").text = x
		c.set_visible(true)
		responses.append(c)

	responses[response_i].get_node("MarginContainer/Label").text = "> " + responses[response_i].get_node("MarginContainer/Label").text

	responses_menu.set_visible(true)
	#_responses.set_visible(true)
	#dialogue.set_visible(false)

func up():
	if response_i == 0:
		return

	responses[response_i].get_node("MarginContainer/Label").text = responses[response_i].get_node("MarginContainer/Label").text.erase(0, 2)
	response_i -= 1
	responses[response_i].get_node("MarginContainer/Label").text = "> " + responses[response_i].get_node("MarginContainer/Label").text

func down():
	if response_i == len(responses) - 1:
		return

	responses[response_i].get_node("MarginContainer/Label").text = responses[response_i].get_node("MarginContainer/Label").text.erase(0, 2)
	response_i += 1
	responses[response_i].get_node("MarginContainer/Label").text = "> " + responses[response_i].get_node("MarginContainer/Label").text

func select_response():
	var s = responses[response_i].get_node("MarginContainer/Label").text.erase(0, 2)

	#dialogue.set_visible(true)
	responses_menu.set_visible(false)
	#_responses.set_visible(false)

	for x in responses:
		responses_menu.remove_child(x)
	responses.resize(0)

	showing_response = false
	i = 0
	response_i = 0
	start(s)
