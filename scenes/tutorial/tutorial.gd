## Don't work now
## This is Ren'GD tutorial scene script##
## Ren'GD is Ren'Py for Godot ##
## version: 0.6 ##
## License MIT ##


extends Node

## it's how import rengd framework when res://scenes/gui/Window.tscn is loaded as singleton
onready var ren = get_node("/root/Window/RenEasy") 

var another_time = false

func _ready():

	# if not another_time:
	# 	another_time = true
	# 	first()

	first()
	
	ren.start_ren()
	## This must be at end of code.
	## this start ren "magic" ;)
	

func first():
	var tscn_path = "res://scenes/tutorial_2d_api/tutorial_2d_api.tscn"
	ren.label("tutorial_2d_api", tscn_path, "first")
	## It add this scene func to know labels
	## It allows later to easy swich between scenes and thier labels
	## It allows also to reuse scene with different labels
	## using: ren.jump(label_name, [func_args_if_any])
	## You must labeled func before 'jumping' to it!
	
	## ren.set_label_current_label("tutorial_2d_api")
	## beacose it is first label in game I must write above method to get next things work

	ren.define("guest") ## it add 'guest' var to 'keywords' dict that is global and will be saved
	ren.input("guest", "What is your name?", "Godot Developer")
	## ren.input will set guest var as what you type after pressing enter key
	## It use renpy markup format iI discribed it more under first use of ren.say
	
	var jer = ren.Character("Jeremi360", "#25c33e")
	ren.define("jer", jer)
	## This is how you declare a new Character

	ren.say("jer", """Hi! My name is [jer.name]. Welcome [guest] to Ren'GD [version] Tutorial. Press MLB, Enter or Space to continue.""")
	## It will set 'Jeremi360' in root/Window/Say/NameBox and second arg in root/Window/Say/Dialog
	## It has markup format like in Ren'Py it means that all godot bbcode '[]' become '{}'
	## '[guest]' will add guest var to your string and do the same for version var
	## you can disabled it set 3rd argumet as 'false'

	# var test_list = ["test", "TEST"]
	# ren.define_list("test_list", test_list)
	# ren.say("jer","Test of list [test_list[1]].")

	var topics = [
		"Basic",
		"Say",
		"Character",
		"Input",
		"Menu",
		"Label",
		"Node"
	]


	ren.menu(topics, "What you want to know?", self, "topic_choice")

	ren.define("ex_path", tscn_path)
	ren.say("jer", """It's end for now to see how it is done see: {tab}- [ex_path].gd {tab}- [ex_path].tscn""")
	
	ren.say("jer", "Goodbye, [guest].")
	#ren.godot_line("ren.use_statement", [0])
	

func topic_choice(choice):
	ren.before_menu()

	#if choice == 0: #Basic


	if choice == 1: #Say
		ren.say("jer", "Say statment/func is make character speaks.")
		ren.say("jer", "The GDScript way to call it is: {code}ren.say('how','what'){/code}")
		ren.say("jer", "The Ren'GD Script way to call it is: {code}how' 'what'{/code}")
	
	#if choice == 2: #Character

	elif choice == 3: #Input
		ren.say("jer", "Input statment/func is way to provide text input file for player.")
		ren.say("jer", "The GDScript way to call it is: {code}ren.input('var','what','temp'){/code}")
		ren.say("jer", "The Ren'GD Script way to call it is: {code}g: ren.input('var','what','temp'){/code}")
	
	#elif choice == 4: #Menu

	#elif choice == 5: #Label

	#elif choice == 6: # Node
		
	
	else:
		ren.say('', "To be done :(.")
	
	ren.after_menu()
		