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
signal check_info_software_updates_requested(which)
## sotware updates
signal software_updates_requested(which)

# ----- enums

# ----- constants

# ----- exported variables

# ----- public variables
var c = 0

# ----- private variables

# ----- onready variables
@onready var info = %SoftwareInfo
@onready var update_button = %UpdateSoftware

# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method

# Called when the node enters the scene tree for the first time.
func _ready():
	update_button.pressed.connect(_on_update_software_pressed)

# ----- remaining built-in virtual methods

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass # Replace with function body.


# ----- public methods
func update_download_info(data):
	#print("{info} BS {bs} DB {db} P {perc} BRS {bricks} BR {brick}".format(
	#		data))
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

# ----- private methods

func _on_update_software_pressed():
	info.text = ""
	emit_signal(
			"software_updates_requested",
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
