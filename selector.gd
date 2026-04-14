extends Control

var delta = Vector2.ZERO
var i = 7

func _draw() -> void:
	draw_arc(Vector2(200, 200), 240, 0, 2 * PI, 60, Color(0, 0, 0, .5), 160)
	var total_segments = 8
	var start = i * 2 * PI / total_segments + PI / 8
	var end = start + 2 * PI / total_segments
	var middle = start + (end - start) / 2
	draw_arc(Vector2(200, 200), 240, start, end, 60, Color(0, 1, 0, .7), 160 + 1)
	draw_circle(Vector2(200 + 240 * cos(middle), 200 + 240 * sin(middle)), 10, Color.RED)

func redraw():
	var a = 5
	match delta:
		[var x, var y] when y <= -1 * a and x == 0:
			# UP
			i = 5
		[var x, var y] when y >= 1 * a and x == 0:
			# DOWN
			i = 9
		[var x, var y] when x >= 1 * a and y == 0:
			# RIGHT
			i = 7
		[var x, var y] when x <= -1 * a and y == 0:
			# LEFT
			i = 3
		[var x, var y] when x <= -1 * a and y <= -1 * a:
			# UP LEFT
			i = 4
		[var x, var y] when x <= -1 * a and y >= 1 * a:
			# DOWN LEFT
			i = 2
		[var x, var y] when x >= 1 * a and y <= -1 * a:
			# UP RIGHT
			i = 6
		[var x, var y] when x >= 1 * a and y >= 1 * a:
			# DOWN RIGHT
			i = 8
	queue_redraw()
