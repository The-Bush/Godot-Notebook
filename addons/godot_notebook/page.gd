@tool
class_name NotePage extends Button

var page_name : String:
	set(value):
		page_name = value
		rename_page(value)
	
var page_text : String = ""

signal button_left_pressed(page : NotePage)
signal button_right_pressed(page : NotePage)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					button_left_pressed.emit(self)
				MOUSE_BUTTON_RIGHT:
					button_right_pressed.emit(self)

func rename_page(new_name : String):
	text = page_name


func highlight_button():
	disabled = true


func remove_highlight():
	disabled = false
