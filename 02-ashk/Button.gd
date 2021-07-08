extends Button

# animation curve
export (Curve) var jiggle
var time_since_press = 0
var was_pressed = false


func _process(delta):
	if was_pressed:
		# if jiggle animation is playing
		# advance where we are in the animation
		time_since_press += delta
		# scale visual component of button according to animation curve
		$"done button".scale.x = jiggle.interpolate(time_since_press)
		$"done button".scale.y = 1/jiggle.interpolate(time_since_press)
	pass


func _on_Button_pressed():
	# start the jiggle animation
	was_pressed = true
	time_since_press = 0
	pass
