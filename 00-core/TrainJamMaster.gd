extends Node

var microgame_index = 0

export(PackedScene)var test_microgame_scene: PackedScene = null
export(bool)var test_microgame_repeating = true
export(Array, Resource)var microgames = []

var current_microgame: MicrogameMetadata = null
var preloaded_microgame: MicrogameMetadata = null
export(Curve)var viewport_slide_in
export(Curve)var viewport_slide_out
var slide_progress = 0
var sliding_in = false
var sliding_out = false

func _ready():
	load_next_microgame()
	slide_progress = 1

func load_next_microgame():
	if test_microgame_scene:
		var test_microgame = MicrogameMetadata.new()
		test_microgame.microgame_name = "Test"
		test_microgame.microgame_name = "YOU"
		test_microgame.microgame_scene = test_microgame_scene
		if not test_microgame_repeating:
			test_microgame_scene = null
		load_microgame(test_microgame)
	else:
		load_microgame(microgames[microgame_index])
		microgame_index += 1
		if microgame_index >= len(microgames):
			microgame_index = 0

func load_microgame(mg: MicrogameMetadata):
	preloaded_microgame = mg
	$"../TrainCar".close_doors();
	sliding_in = false
	sliding_out = true
	slide_progress = 0

func unload_current_scene():
	var vpc = $"../MarginContainer/NavdiViewerWindow/ViewportContainer"
	var vp = $"../MarginContainer/NavdiViewerWindow/ViewportContainer/Viewport"
	vpc.hide()
	for child in vp.get_children():
		vp.remove_child(child)
		child.queue_free()
	self.current_microgame = null

func set_current_microgame(mg: MicrogameMetadata):
	unload_current_scene()
	self.current_microgame = mg
	var nvw = $"../MarginContainer/NavdiViewerWindow"
	var vpc = $"../MarginContainer/NavdiViewerWindow/ViewportContainer"
	var vp = $"../MarginContainer/NavdiViewerWindow/ViewportContainer/Viewport"
	var scene = current_microgame.microgame_scene.instance()
	vp.add_child(scene)
	scene.owner = vp.owner
	vpc.show()
	
	scene.connect("player_won", self, "load_next_microgame")
	scene.connect("player_lost", self, "load_next_microgame")
	
	nvw.match_board_size()
	

func _process(delta):
	if preloaded_microgame:
		if sliding_out:
			slide_progress += delta * 0.85
			if slide_progress >= 1:
				set_current_microgame(preloaded_microgame)
				$"../TrainCar".open_doors();
				sliding_out = false
				sliding_in = true
				slide_progress = 0
			_update_slide_position()
		elif sliding_in:
			slide_progress += delta * 0.5
			_update_slide_position()
			if slide_progress >= 1:
				preloaded_microgame = null
				sliding_in = false
#				_update_slide_position()

func _update_slide_position():
	var nvw = $"../MarginContainer/NavdiViewerWindow"
	var window_size = $"../MarginContainer".rect_size
	var offset = Vector2.ZERO
	if sliding_in:
		offset = Vector2.RIGHT * window_size * viewport_slide_in.interpolate(slide_progress)
	elif sliding_out:
		offset = Vector2.LEFT * window_size * viewport_slide_out.interpolate(slide_progress)
	nvw.refresh()
	for child in nvw.get_children():
		child.rect_position += offset
#	vpc.rect_position = Vector2.ZERO + offset

func show_error(msg):
	print("TrainJamMaster load error: %s" % msg)
