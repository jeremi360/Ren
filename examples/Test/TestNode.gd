extends Sprite

## This is small extra script that shows
## how to make node save/load
## we also call "test_func" for dialog

var is_show : RakugoVar

func _ready():
	Rakugo.node_link(self, name)
	is_show = Rakugo.define("test_node_is_show", visible)
	connect("visibility_changed", self, "_on_vis_changed")

func _on_vis_changed():
	is_show.v = visible;

func _on_load(version):
	visible = is_show.v

func test_func(some_text):
	print(some_text)
	show()

