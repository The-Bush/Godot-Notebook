@tool
extends EditorPlugin

const version: String = "1.0"
const savePath: String = "res://addons/godot_notebook/notebook.json"

var dock = preload("res://addons/godot_notebook/notebook.tscn").instantiate()
var page_button = preload("res://addons/godot_notebook/btn_page.tscn")
var delete_dialog = preload("res://addons/godot_notebook/confirm_delete_dialog.tscn")
var textedit = dock.get_node("textEdit")
var btn_add_page = dock.get_node("tools_container/btn_add_page")
var btn_del_page = dock.get_node("tools_container/btn_del_page")
var btn_save = dock.get_node("tools_container/btn_save")
var page_name_edit = dock.get_node("page_name_text_edit")
var page_btn_container = dock.get_node("scroll_container/btn_container")
var status_label : RichTextLabel = dock.get_node("tools_container/status_label")

var pages: Array[NotePage]
var current_page: NotePage
var current_page_index: int
var unsaved : bool = false

var plugin_control
func _enter_tree() -> void:
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	textedit.connect("text_changed", _text_change)
	btn_add_page.connect("pressed", _add_page)
	btn_del_page.connect("pressed", _delete_page)
	btn_save.connect("pressed", save)
	page_name_edit.connect("text_changed", _page_name_change)
	
	load_notes()


func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()


func _get_unsaved_status(for_scene):
	if not unsaved:
		return ""
	return "Your notes have unsaved changes. Save before closing?"


func _save_external_data() -> void:
	save()


func save() -> void:
	# Save the current page's text content
	if current_page:
		current_page.page_text = textedit.text

	## Generate JSON string from Array set
	## Schema is as follows:
	## [
	##     ["Page Name 1", "Page Text 1"],
	##     ["Page Name 2", "Page Text 2"],
	##     ...
	## ]
	var all_data: Array[Array]
	for page in pages:
		page = page as NotePage
		var data = [page.page_name, page.page_text]
		all_data.append(data)
	var json_string = JSON.stringify(all_data)
	var file = FileAccess.open(savePath, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	unsaved = false
	status_label.text = "Notebook: Saved"


func _btn_reload_click() -> void:
	load_notes()


func load_notes() -> void:
	if FileAccess.file_exists(savePath):
		var file = FileAccess.open(savePath, FileAccess.READ)
		var json_string = file.get_as_text()
		var json = JSON.new()
		json.parse(json_string)
		file.close()
		for page in json.data:
			var new_page = _add_page()
			new_page.page_name = str(page[0])
			new_page.page_text = page[1]
		switch_page(pages[0])
	else:
		_add_page()


func _text_change() -> void:
	unsaved = true
	status_label.text = "Notebook: [pulse freq=0.5]unsaved changes"


func _page_name_change(new_text: String) -> void:
	current_page.page_name = new_text
	save()


func _add_page() -> NotePage:
	var new_page: NotePage = page_button.instantiate()
	new_page.button_left_pressed.connect(switch_page)
	pages.append(new_page)
	new_page.page_name = "Page " + str(pages.find(new_page))
	page_btn_container.add_child(new_page)
	switch_page(new_page)
	save()
	return new_page


func _delete_page():
	# Create confirmation dialog
	var dialog: AcceptDialog = delete_dialog.instantiate()
	dialog.dialog_text = "Are you sure you want to delete page: %s?" % current_page.page_name
	dialog.add_cancel_button("Cancel")
	dock.add_child(dialog)
	dialog.visible = true

	# Await signal and continue only if confirmed.
	# My testing shows this should not result in a memory leak.
	# When the dialog is freed from a cancelled dialog
	# this appears to also be freed in memory
	await dialog.confirmed

	# Delete the current page and move the view to a new page
	var previous_page_index: int = pages.find(current_page)
	if current_page:
		pages.erase(current_page)
		current_page.queue_free()
	if previous_page_index == 0 and pages.size() > 0:
		switch_page(pages[0])
		save()
	elif pages.size() > 0:
		switch_page(pages[previous_page_index - 1])
		save()
	else:
		_add_page()


func switch_page(page: NotePage) -> void:
	if unsaved:
		save()
	if current_page:
		current_page.remove_highlight()
	current_page = page
	current_page.highlight_button()
	
	page_name_edit.text = current_page.page_name
	textedit.text = page.page_text
