extends Node3D

func _ready():
	var e = Expression.new()
	e.parse("Phone.open_phone()")
	e.execute([], self)
