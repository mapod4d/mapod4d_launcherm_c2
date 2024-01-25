# tool

# class_name

# extends
extends Panel

## A brief description of your script.
##
## A more detailed description of the script.
##
## @tutorial:			http://the/tutorial1/url.com
## @tutorial(Tutorial2): http://the/tutorial2/url.com


# ----- signals
signal download_software_requested(
		software_name, ext, sysop, tmp_dir, destination, which)
signal info_software_requested(
		software_name, ext, sysop, tmp_dir, destination, which)
## base check for sotware updates
signal check_info_sw_updates_requested(which)

## software updates
signal sw_updates_requested(which)
## search software updates
signal sw_search_updates_requested(which)


# ----- enums

# ----- constants

# ----- exported variables

# ----- public variables
var c = 0

# ----- private variables

# ----- onready variables
@onready var info = %SoftwareInfo
@onready var update_button = %UpdateSoftware
@onready var src_updates = %SearchSoftwareUpdates

# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method

# Called when the node enters the scene tree for the first time.
func _ready():
	update_button.pressed.connect(_on_update_software_pressed)
	src_updates.pressed.connect(_on_search_software_updates_pressed)

# ----- remaining built-in virtual methods

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass # Replace with function body.


# ----- public methods
func update_download_info(data):
	info.set_text(
			"BS {bs} DB {db} P {perc} BRS {bricks} BR {brick}".format(data))


func update_merge_info(data):
	# "file_name" "brick" "bricks" "chunk" "chunks"
	info.set_text("{file_name} {brick} {bricks} {chunk} {chunks}".format(data))


func update_msg(msg_data):
	#print(str(msg_data))
	info.set_text(str(msg_data))


func enable_update_button():
	update_button.disabled = false
	update_button.focus_mode = FOCUS_ALL


func disable_update_button():
	update_button.disabled = true
	update_button.focus_mode = FOCUS_NONE


func enable_src_button():
	src_updates.disabled = false
	src_updates.focus_mode = FOCUS_ALL


func disable_src_button():
	src_updates.disabled = true
	src_updates.focus_mode = FOCUS_NONE

# ----- private methods

func _on_update_software_pressed():
	info.text = ""
	disable_update_button()
	disable_src_button()
	emit_signal(
			"sw_updates_requested",
			self
	)

func _on_search_software_updates_pressed():
	info.text = ""
	disable_update_button()
	disable_src_button()
	emit_signal(
			"sw_search_updates_requested",
			self
	)



func _on_download_pressed():
	info.text = ""
	emit_signal(
			"download_software_requested",
			"softwaretest",
			".exe",
			"L00",
			"files/tmp",
			"files/test_merged",
			self
	)
