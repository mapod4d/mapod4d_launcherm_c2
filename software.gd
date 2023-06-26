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

# ----- enums

# ----- constants

# ----- exported variables

# ----- public variables
var c = 0

# ----- private variables

# ----- onready variables
@onready var info = $Info
@onready var info1 = $Info1

# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

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
	info1.set_text(
			"BS {bs} DB {db} P {perc} BRS {bricks} BR {brick}".format(data))


func update_merge_info(data):
	# "file_name" "brick" "bricks" "chunk" "chunks"
	info.set_text("{file_name} {brick} {bricks} {chunk} {chunks}".format(data))
	info1.set_text("{file_name} {brick} {bricks} {chunk} {chunks}".format(data))


func update_msg(msg_data):
	#print(str(msg_data))
	info.set_text(str(msg_data))
	info1.set_text(str(msg_data))

# ----- private methods


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


func _on_check_info_pressed():
	pass
