extends Node

var hours = 0
var minutes = 0

var trigger_callback = func(): pass

func trigger_update():
	trigger_callback.call()
