extends Node
class_name Dialogue, "res://addons/Rakugo/icons/dialogue.svg"

onready var _class_script_version = _get_dialogue_script_hash()
onready var _script_version = _get_script_hash()

export var default_starting_event = ""
export var auto_start = false
export var version_control = false

var exiting = false

#Those are only used as analogues of arguments
var target = 0
var condition_stack = []


var event_stack = []#LIFO stack of elements [event_name, current_counter, target, condition_stack(FIFO stack)]

var var_access = Mutex.new()#That mutex is probably completely useless
var menu_lock = Semaphore.new()
var thread = Thread.new()
var step_semaphore = Semaphore.new()

var menu_return = null

func reset(): ## Need to check if this is actually needed.
	#print("Resetting dialogue")
	exiting = false
	thread = Thread.new()
	step_semaphore = Semaphore.new()
	var_access = Mutex.new()
	if self.has_method(default_starting_event):
		event_stack = [[default_starting_event, 0, 0, []]]


func _ready():
	if self.auto_start and not Rakugo.current_dialogue:
		start()

func _store(save):
	if Rakugo.current_dialogue == self:
		#print("Storing dialogue ",self.name, "  ", self.event_stack)
		save.current_dialogue = self.name
		save.current_dialogue_event_stack = self.event_stack.duplicate(true)
		save.current_dialogue_script_version = _script_version
		save.dialogue_class_script_version = _class_script_version

func _restore(save):
	if save.current_dialogue == self.name:
		if check_for_version_error(save):
			return
		#print("Restoring dialogue ", self.name, self,"  ", save.current_dialogue_event_stack)
		self.exit()
		if not is_ended():
			#print("Waiting for the thread to finish")
			thread.wait_to_finish()
			#print("Thread finished")
		self.reset()
	
		#print("Setting event_stack to  ", save.current_dialogue_event_stack)
		var_access.lock()
		event_stack = save.current_dialogue_event_stack.duplicate(true)
		var_access.unlock()
		Rakugo.current_dialogue = self
		#print("Setting Rakugo.current_dialogue to  ",self, "  ", (Rakugo.current_dialogue == self))
		thread.start(self, "dialogue_loop")

func _step():
	#print("_step received")
	if thread.is_active():
		self.step_semaphore.post()

func start(event_name=''):
	var_access.lock()
	if event_name:
		event_stack = [[event_name, 0, 0, []]]
	elif self.has_method(default_starting_event):
		event_stack = [[default_starting_event, 0, 0, []]]
	else:
		push_error("Dialog '"+self.name+"' started without given event nor default event.")
	var_access.unlock()
	Rakugo.current_dialogue = self
	thread.start(self, "dialogue_loop")



## Thread life cycle

func dialogue_loop(_a):
	#print("Starting threaded dialog ", self, " ", event_stack)
	while event_stack:
		var_access.lock()
		var e = event_stack.pop_front()
		var_access.unlock()
		#print("Calling event ",e)
		self.call_event(e[0], e[1], e[3])
		if self.exiting:
			break

	#print("Ending threaded dialog")
	thread.call_deferred('wait_to_finish')


func exit():
	if not is_ended():## Not checking for active thread makes the mutex deadlocks somehow
		#print("Exitting Dialogue")
		self.exiting = true
		step_semaphore.post()
		menu_lock.post()


func is_ended():
	return not thread or not thread.is_active()



## Events Flow control and Administration

func call_event(event, _target = 0, _condition_stack = []):
	if is_active():
		#Using class vars to make event methods argument less.
		self.target = _target
		self.condition_stack = _condition_stack.duplicate()
		self.call(event)

func start_event(event_name):
	if event_stack:
		event_stack[0][1] += 1# Disalign step counter in case of saving before returning
	var_access.lock()
	if not is_active():
		event_stack.push_front([event_name, 0, INF, self.condition_stack])
	else:
		event_stack.push_front([event_name, 0, self.target, self.condition_stack])#Should be "get_stack()[1]['function']" instead of passing event_name, if get_stack() worked
	var_access.unlock()

func cond(condition):
	if condition:#transform 'condition' into a bool
		condition = true
	else:
		condition = false
	
	if is_active(true):
		event_stack[0][3].push_front(condition)
	else:
		condition = event_stack[0][3].pop_back()
	return condition

func step():
	if is_active():
		step_semaphore.wait()
	event_stack[0][1] += 1

func end_event():
	var_access.lock()
	event_stack.pop_front()
	event_stack[0][1] -= 1# Realign step counter before returning
	var_access.unlock()


func is_active(_strict=false):
	var output:bool = not self.exiting
	if event_stack:
		if _strict:# Allow to check if it's the last step until waiting for semaphore
			output = output and event_stack[0][1] > event_stack[0][2]
		else:
			output = output and event_stack[0][1] >= event_stack[0][2]
	return output



## The "Framework" section
# ,the section of methods there "just in case" that should probably be removed

func get_event_stack():
	var output
	var_access.lock()
	output = event_stack.duplicate(true)
	var_access.unlock()
	return output

func get_event_name():
	var output = ""
	if event_stack:
		output = event_stack[0][0]
	return output

func get_event_step():
	var output = -1
	if event_stack:
		output = event_stack[0][1]
	return output


func get_parent_event_name():
	var output = ''
	if event_stack.size() > 1:
		output = event_stack[1][0]
	return output


func story_step() -> void:
	Rakugo.story_step()#Don't remember why I put that here, probably a leftover from the old system

## Version control
# 

func _get_dialogue_script_hash():
	return load("res://addons/Rakugo/nodes/dialogue.gd").new()._get_script_hash()

func _get_script_hash(object=self):
	return object.get_script().source_code.hash()

func check_for_version_error(store):
	if store.dialogue_class_script_version != _class_script_version:
		push_warning("Dialogue class script mismatched.")
	if store.current_dialogue_script_version != _script_version:
		if version_control:
			push_error("The loaded save is not compatible with this version of the game.")
			return true
		else:
			push_warning("Dialogue script mismatched, that may corrupt the game state.")
	return false


## Rakugo statement wrap

func set_var(var_name: String, value):
	if is_active():
		return Rakugo.set_var(var_name, value)
	return null


func say(character, text:String, parameters: Dictionary = {}) -> void:
	if is_active():
		Rakugo.call_deferred('say', character, text, parameters)


func ask(variable_name:String, parameters: Dictionary = {}) -> void:
	if is_active():
		Rakugo.call_deferred('ask', variable_name, parameters)


func menu(choices:Array, parameters: Dictionary = {}):
	if is_active():
		Rakugo.call_deferred('menu', choices, parameters)
		menu_lock = Semaphore.new()#In case the semaphore had multiple .post() done.
		_menu_yield()
		menu_lock.wait()
		return menu_return
	return null

func _menu_yield():
	menu_return = yield(Rakugo, "menu_return")
	menu_lock.post()


func show(node_id: String, parameters := {}):
	if is_active():
		Rakugo.call_deferred('show', node_id, parameters)


func hide(node_id: String) -> void:
	if is_active():
		Rakugo.call_deferred('hide', node_id)


func notify(info: String, length: int = -1) -> void:
	if is_active():
		Rakugo.call_deferred('notify', info, length)


func play_anim( node_id: String, anim_name: String) -> void:
	if is_active():
		Rakugo.call_deferred('play_anim', node_id, anim_name)


func stop_anim(node_id: String, reset := true) -> void:
	if is_active():
		Rakugo.call_deferred('stop_anim', node_id, reset)


func play_audio(node_id: String, from_pos := 0.0) -> void:
	if is_active():
		Rakugo.call_deferred('play_audio', node_id, from_pos)


func stop_audio(node_id: String) -> void:
	if is_active():
		Rakugo.call_deferred('stop_audio', node_id)


func call_node(node_id: String, func_name: String, args := []) -> void:
	if is_active():
		Rakugo.call_deferred('call_node', node_id, func_name, args)


func jump(scene_id: String, dialogue_name: String, event_name: String) -> void:
	if is_active():
		Rakugo.call_deferred('jump', scene_id, dialogue_name, event_name)
