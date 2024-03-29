# tool

# class_name

# extends
extends Control

## A brief description of your script.
##
## A more detailed description of the script.
##
## @tutorial:			http://the/tutorial1/url.com
## @tutorial(Tutorial2): http://the/tutorial2/url.com


# ----- signals

# ----- enums

enum STATUS_LOCAL {
	WAIT = 0,
	
	START_REQUESTED,
	CHECK_INFO_SW_UPDATES_REQUESTED,
	SW_UPDATES_REQUESTED,

	SW_UPDATER_REQUEST_INIT,
	SW_LAUNCHER_REQUEST_INIT,
	SW_CORE_REQUEST_INIT,

	SW_INFO_REQUESTED,
	SW_INFO_UPDATER_REQUESTED,
	SW_INFO_LAUNCHER_REQUESTED,
	SW_INFO_CORE_REQUESTED,

	SW_INFO_WAIT,
	SW_INFO_UPDATER_WAIT,
	SW_INFO_LAUNCHER_WAIT,
	SW_INFO_CORE_WAIT,

	SW_DW_INFO_REQUESTED,
	SW_DW_INFO_WAIT,
	
	SW_CHECK_ULC,
	
	SW_DW_BRICKS,
	SW_DW_BRICK_WAIT,
	SW_DW_COMPLETED,
	
	MT_DW_INFO_REQUESTED,
	MT_DW_COMPLETED,
	
	MERGE_AND_MOVE,
	MERGE_AND_MOVE_ALL_BRICKS,
	MERGE_AND_MOVE_SINGLE_BRICK,
	READ_AND_SAVE,
	READ_AND_SAVE_ALL_CHUNKS,
	READ_AND_SAVE_GROUP_OF_CHUNKS,
	
	SW_DW_RENAME
}

enum OP_TYPE_LOCAL {
	NONE = 0,
	SW_DW,
	MT_DW,
}

# ----- constants
const M4DVERSION = {
	'v1': 2, 
	'v2': 0,
	'v3': 0,
	'v4': 1,
	'p': "a",
	'godot': {
		'v1': 4,
		'v2': 2,
		'v3': 1,
		'v4': 2, # dev = 0, rc = 1, stable = 2
		'p': "stable"
	}
}
const M4DNAME = "mapod4d"

# default 0 version of M4D
const M4D0VERSION = {
	'v1': 0, 
	'v2': 0,
	'v3': 0,
	'v4': 0,
	'p': "a",
	'godot': {
		'v1': 4,
		'v2': 2,
		'v3': 1,
		'v4': 2, # dev = 0, rc = 1, stable = 2
		'p': "stable"
	}
}

const WK_PATH = 'wk'
const UPDATES_DIR = "updates"
const TMP_DIR = "tmp"

## storage name for data info of current download
const DW_INFO = "download_info"

## name of software updater on the update server
const UPDATER_NAME = "updater"
## name of software updater
const UPDATER_EXE_NAME = "updater"
## storage name for data info of software updater
const UPDATER_INFO = "updater_info"
## name of software launcher on the update server
const LAUNCHER_NAME = "launcherm"
## name of software launcher
const LAUNCHER_EXE_NAME = "mapod4d"
## storage name for data info of software launcher
const LAUNCHER_INFO = "launcherm_info"
## name of software core on the update server
const CORE_NAME = "core"
## name of software core
const CORE_EXE_NAME = "core"


const MULTIVSVR = "https://sv001.mapod4d.it"
const MULTIVSVR_PORT = 80
const BUF_NAME = "buf_"
const CHUNKSIZE = 550000
const CHUNKSIZE_MULTI = 1000
const BLOCK_ISTANCE_PORT = 2000
const EDITOR_DBG_BASE_PATH = "res://test"



# ----- exported variables

# ----- public variables

# ----- private variables
## enable debug messages
var _mapod4d_debug_flag: bool = false
## enable debug status flux messages
var _mapod4d_debug_status_flag: bool = true

## this application codified version
var _m4dsversion = null

## internal configuration
var _settings = {
	"insicure": false,
	"autoupdate": false,
}

var _tls_opt = TLSOptions.client_unsafe()

# status machine
# current status
var _status = STATUS_LOCAL.WAIT
# status of request
var _entry_0_status = STATUS_LOCAL.WAIT

## dinamic paths 
var _build_updater_path = null
var _build_launcher_path = null
var _build_core_path = null
var _build_wk_path = null
var _build_updates_path = null
var _build_tmp_dir = null
var _build_dest_dw_path = null


## general
var _server = null
var _base_path = null
var _local_lock = false # future mutitread
var _op_type:OP_TYPE_LOCAL = OP_TYPE_LOCAL.NONE
var _os_info = {
	"os": null,
	"exe_ext": ""
}
var _base_dir = null

## local support
var _mapod4d_debug_line: int = 0
var _is_ready = false

## if true the module needs to be updated
var _update_updater = false
var _update_core = false
var _update_launcher = false

var _current_brick = 0
var _dw_name = null
var _download_file = null
var _info = null
var _url = null
var _dir = null
var _dest_file = null
var _input_file_data = null
var _input_file_data_read = false
var _brick_name = null
var _current_merging_brick = 0
var _current_chunk = 0
var _software_name = null
var _tmp_dir = null
var _sysop = null
var _destination = null
var _which = null

## _info data saved after info download
var _info_saved = {}

## sofware download vars
var _ext = null

## metaverse download vars
var _mapod4d_ver = null

# ----- onready variables
@onready var http_sw_info_rq = $HTTPSWRequestInfo
@onready var http_sw_dw_rq = $HTTPSWRequestDownload
@onready var http_mt_info_rq = $HTTPSWRequestInfo
@onready var http_mt_dw_rq = $HTTPSWRequestDownload
@onready var tab_container = $TabContainer
@onready var software = $TabContainer/Software
@onready var multiverse = $TabContainer/Multiverse


# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method


# Called when the node enters the scene tree for the first time.
func _ready():
	_block_istance()
	## encode application version
	_m4dsversion = _sversion(
		M4DVERSION.v1, M4DVERSION.v2, M4DVERSION.v3, M4DVERSION.v4)
	## check OS
	match OS.get_name():
		"Windows", "UWP":
			_os_info.os = "W00"
			_os_info.exe_ext = ".exe"
		"macOS":
			_os_info.os = "M00"
			_os_info.exe_ext = ""
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			_os_info.os = "L00"
			_os_info.exe_ext = ""
		"Android":
			_os_info.os = "A00"
			_os_info.exe_ext = ""
		"iOS":
			_os_info.os = "I00"
			_os_info.exe_ext = ""
		"Web":
			_os_info.os = "H00"
			_os_info.exe_ext = ""
	

	## get base path
	_base_path = OS.get_executable_path().get_base_dir()
	if OS.has_feature('editor'):
		_base_path = EDITOR_DBG_BASE_PATH
		#tab_container.set_tab_disabled(1, true)
	else:
		tab_container.set_tab_disabled(1, true)
		
	tab_container.set_tab_title(0, tr("TABSOFTWARE"))
	tab_container.set_tab_title(1, tr("TABMULTIVERSE"))
	tab_container.set_tab_title(2, tr("TABSETTINGS"))

	_build_paths()
	_build_dirs()
	_write_version()
	_load_setting()

	http_sw_info_rq.request_completed.connect(
			_on_sw_dw_info_completed)
	http_sw_dw_rq.request_completed.connect(
			_on_sw_dw_brick_completed)

	software.check_info_sw_updates_requested.connect(
			_on_check_info_sw_updates_requested)

	software.sw_search_updates_requested.connect(
			_on_sw_search_updates_requested)
	software.sw_updates_requested.connect(
			_on_sw_updates_requested)
	
	software.download_software_requested.connect(
			_on_software_dw_info_requested)
	software.info_software_requested.connect(
			_on_info_software_requested)

	multiverse.download_metaverse_requested.connect(
			_on_download_metaverse_requested)

	if _settings.autoupdate == true:
		# current status
		_set_status(STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED)
		# starting flow status
		_set_entry_0_status(STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED)
	else:
		# current status
		_set_status(STATUS_LOCAL.START_REQUESTED)
		# starting flow status
		_set_entry_0_status(STATUS_LOCAL.START_REQUESTED)
	
#	DEBUG
#	_set_status(STATUS_LOCAL.WAIT)
#	_set_entry_0_status(STATUS_LOCAL.WAIT)

	_is_ready = true


# ----- remaining built-in virtual methods

## write version file concerning this application
func _enter_tree():
	var args = OS.get_cmdline_user_args()
	if "-m4dver" in args:
		_write_version()
		get_tree().quit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# status MACHINE
	if _is_ready and _local_lock != true:
		if _status != STATUS_LOCAL.WAIT:
			match _status:
				STATUS_LOCAL.START_REQUESTED:
					_start_requested()

				STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED:
					_check_info_sw_updates_requested(software)
				
				STATUS_LOCAL.SW_UPDATES_REQUESTED:
					_sw_updates_requested(software)
				
				STATUS_LOCAL.SW_UPDATER_REQUEST_INIT, \
				STATUS_LOCAL.SW_LAUNCHER_REQUEST_INIT, \
				STATUS_LOCAL.SW_CORE_REQUEST_INIT:
					_sw_request_init()
				
				## simple file updater info request
				STATUS_LOCAL.SW_INFO_REQUESTED, \
				## updater file info request
				STATUS_LOCAL.SW_INFO_UPDATER_REQUESTED, \
				## launcher file info request
				STATUS_LOCAL.SW_INFO_LAUNCHER_REQUESTED, \
				## core file info request
				STATUS_LOCAL.SW_INFO_CORE_REQUESTED, \
				## file info request to download
				STATUS_LOCAL.SW_DW_INFO_REQUESTED:
					_sw_dw_info_requested()

				## file info request wait
				STATUS_LOCAL.SW_INFO_WAIT, \
				## updater file info request wait
				STATUS_LOCAL.SW_INFO_UPDATER_WAIT, \
				## launcher file info request wait
				STATUS_LOCAL.SW_INFO_LAUNCHER_WAIT, \
				## core file info request wait
				STATUS_LOCAL.SW_INFO_CORE_WAIT, \
				## file info request to download wait
				STATUS_LOCAL.SW_DW_INFO_WAIT:
					_update_info_wait()

				STATUS_LOCAL.SW_CHECK_ULC:
					_sw_check_ulc()

				STATUS_LOCAL.SW_DW_BRICKS:
					_sw_dw_bricks()
				STATUS_LOCAL.SW_DW_BRICK_WAIT:
					_update_info_wait()
				STATUS_LOCAL.SW_DW_COMPLETED:
					_sw_dw_completed()

				STATUS_LOCAL.MT_DW_INFO_REQUESTED:
					mt_dw_info_requested()
				STATUS_LOCAL.MT_DW_COMPLETED:
					_mt_dw_completed()

				STATUS_LOCAL.MERGE_AND_MOVE:
					_merge_and_move()
				STATUS_LOCAL.MERGE_AND_MOVE_ALL_BRICKS:
					_merge_and_move_all_bricks()
				STATUS_LOCAL.MERGE_AND_MOVE_SINGLE_BRICK:
					_merge_and_move_single_brick()
				STATUS_LOCAL.READ_AND_SAVE:
					_read_and_save()
				STATUS_LOCAL.READ_AND_SAVE_ALL_CHUNKS:
					_read_and_save_all_chunks()
				STATUS_LOCAL.READ_AND_SAVE_GROUP_OF_CHUNKS:
					_read_and_save_group_of_chunks()

				STATUS_LOCAL.SW_DW_RENAME:
					_sw_dw_rename()

# ----- public methods

# ----- private methods

## write version file
func _write_version():
		var json_data = JSON.stringify(M4DVERSION)
		var base_dir = OS.get_executable_path().get_base_dir()
		if OS.has_feature('editor'):
			base_dir = EDITOR_DBG_BASE_PATH
		var file_name = base_dir + "/" + M4DNAME + ".json"
		var file = FileAccess.open(file_name, FileAccess.WRITE)
		if file != null:
			file.store_string(json_data)
			file.flush()


## load and update settings
func _load_setting():
	var base_dir = OS.get_executable_path().get_base_dir()
	if OS.has_feature('editor'):
			base_dir = EDITOR_DBG_BASE_PATH
	var file_name = base_dir + "/" + M4DNAME + "_conf.json"
	if FileAccess.file_exists(file_name):
		## TODO load settings
		var file = FileAccess.open(file_name, FileAccess.READ)
		if file != null:
			var settings = file.get_as_text()
			settings = JSON.parse_string(settings)
			if settings != null:
				_set_settings(settings)
			file.close()
	else:
		## create default settings
		var settings = JSON.stringify(_settings)
		var file = FileAccess.open(file_name, FileAccess.WRITE)
		if file != null:
			file.store_string(settings)
			file.flush()
			file.close()

	if _settings.insicure:
		http_sw_info_rq.set_tls_options(_tls_opt)
		http_sw_dw_rq.set_tls_options(_tls_opt)
		http_mt_info_rq.set_tls_options(_tls_opt)
		http_mt_dw_rq.set_tls_options(_tls_opt)
		## create default settings

	## update settings
	var settings = JSON.stringify(_settings)
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	if file != null:
		file.store_string(settings)
		file.flush()
		file.close()


## check and config internal settings
func _set_settings(settings):
	if "insicure" in settings:
		if typeof(_settings.insicure) == TYPE_BOOL:
			_settings.insicure = bool(settings.insicure)


## build dinamic paths
func _build_paths():
	_build_wk_path = "%s/%s" % [_base_path, WK_PATH] 
	_build_updater_path = "%s/%s" % [_build_wk_path , UPDATER_EXE_NAME]
	_build_launcher_path = "%s/%s" % [_base_path , LAUNCHER_EXE_NAME]
	_build_core_path = "%s/%s" % [_build_wk_path , CORE_EXE_NAME]
	_build_updates_path = "%s/%s" % [_build_wk_path , UPDATES_DIR]
	_build_tmp_dir = "%s/%s" % [_build_wk_path , TMP_DIR]
	_build_dest_dw_path = "%s/dw_" % [_build_updates_path]
	_mapod4d_debug(_build_wk_path)


## make directory
func _make_dir(path):
	if _base_dir != null:
		if _base_dir.dir_exists(path) == false:
			# var error = _base_dir.make_dir(path)
			pass


## build base directory structure or get it
func _build_dirs():
	if _base_path != null:
		_base_dir = DirAccess.open(_base_path)
		_make_dir(_build_wk_path)
		_make_dir(_build_updates_path)
		_make_dir(_build_tmp_dir)


func _sversion(v1, v2, v3, v4):
	return "{v1}{v2}{v3}{v4}".format({
		"v1": "%03d" % v1,
		"v2": "%03d" % v2,
		"v3": "%03d" % v3,
		"v4": "%03d" % v4,
	})


func _read_version(file_name):
	var ret_val = {
		"result": false,
		"version" : {},
		"sversion": "",
	}
	var file = FileAccess.open(file_name, FileAccess.READ)
	if file != null:
		var data = file.get_as_text()
		var data_json = JSON.parse_string(data)
		if data_json != null:
			if "v1" in data_json and \
					"v2" in data_json and \
					"v3" in data_json and \
					"v4" in data_json:
				ret_val.result = true
				ret_val.version = {
					"v1": data_json.v1,
					"v2": data_json.v2,
					"v3": data_json.v3,
					"v4": data_json.v4,
				}
				ret_val.encoded_version = _sversion(
					data_json.v1, data_json.v2, data_json.v3, data_json.v4)
	return ret_val


## write updater version json
func _write_updater_version():
	if _base_dir != null:
		if _base_dir.file_exists(_build_updater_path):
			var updater_exe = "%s%s" % [_build_updater_path, _os_info.exe_ext]
			var _exit_code = OS.execute(updater_exe, ["++", "-m4dver"])
		else:
			var version_file = "%s%s" % [_build_updater_path, ".json"]
			var json_data = JSON.stringify(M4D0VERSION)
			var file = FileAccess.open(version_file, FileAccess.WRITE)
			if file != null:
				file.store_string(json_data)
				file.flush()


## write core version json
func _write_core_version():
	if _base_dir != null:
		if _base_dir.file_exists(_build_core_path):
			var core_exe = "%s%s" % [_build_core_path, _os_info.exe_ext]
			var _exit_code = OS.execute(core_exe, ["++", "-m4dver"])
		else:
			var version_file = "%s%s" % [_build_core_path, ".json"]
			var json_data = JSON.stringify(M4D0VERSION)
			var file = FileAccess.open(version_file, FileAccess.WRITE)
			if file != null:
				file.store_string(json_data)
				file.flush()


## prevent multiple instance
func _block_istance():
	## create server and prevent multiple instance
	#_server = TCPServer.new()
	#var error = _server.listen(BLOCK_ISTANCE_PORT, "127.0.0.1")
	#if error != OK:
		#get_tree().quit()
	#var output = []
	#OS.execute("tasklist", [], output )
	#for line in output[0].split("\n"):
		#if line.begins_with("chrome"):
			#get_tree().quit()
	#https://github.com/godotengine/godot/issues/18150
	pass


## utility status to string
func _status_to_str():
	var status = _get_status()
	var ret_val = "undefined"
	match status:
		STATUS_LOCAL.WAIT:
			ret_val = "WAIT"
		STATUS_LOCAL.START_REQUESTED:
			ret_val = "START_REQUESTED"
		STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED:
			ret_val = "CHECK_INFO_SW_UPDATES_REQUESTED"
		STATUS_LOCAL.SW_UPDATES_REQUESTED:
			ret_val = "SW_UPDATES_REQUESTED"
		STATUS_LOCAL.SW_UPDATER_REQUEST_INIT:
			ret_val = "SW_UPDATER_REQUEST_INIT"
		STATUS_LOCAL.SW_LAUNCHER_REQUEST_INIT:
			ret_val = "SW_LAUNCHER_REQUEST_INIT"
		STATUS_LOCAL.SW_CORE_REQUEST_INIT:
			ret_val = "SW_CORE_REQUEST_INIT"
		STATUS_LOCAL.SW_INFO_REQUESTED:
			ret_val = "SW_INFO_REQUESTED"
		STATUS_LOCAL.SW_INFO_UPDATER_REQUESTED:
			ret_val = "SW_INFO_UPDATER_REQUESTED"
		STATUS_LOCAL.SW_INFO_LAUNCHER_REQUESTED:
			ret_val = "SW_INFO_LAUNCHER_REQUESTED"
		STATUS_LOCAL.SW_INFO_CORE_REQUESTED:
			ret_val = "SW_INFO_CORE_REQUESTED"
		STATUS_LOCAL.SW_INFO_WAIT:
			ret_val = "SW_INFO_WAIT"
		STATUS_LOCAL.SW_INFO_UPDATER_WAIT:
			ret_val = "SW_INFO_UPDATER_WAIT"
		STATUS_LOCAL.SW_INFO_LAUNCHER_WAIT:
			ret_val = "SW_INFO_LAUNCHER_WAIT"
		STATUS_LOCAL.SW_INFO_CORE_WAIT:
			ret_val = "SW_INFO_CORE_WAIT"
		STATUS_LOCAL.SW_DW_INFO_REQUESTED:
			ret_val = "SW_DW_INFO_REQUESTED"
		STATUS_LOCAL.SW_DW_INFO_WAIT:
			ret_val = "SW_DW_INFO_WAIT"
		STATUS_LOCAL.SW_CHECK_ULC:
			ret_val = "SW_CHECK_ULC"
		STATUS_LOCAL.SW_DW_BRICKS:
			ret_val = "SW_DW_BRICKS"
		STATUS_LOCAL.SW_DW_BRICK_WAIT:
			ret_val = "SW_DW_BRICK_WAIT"
		STATUS_LOCAL.SW_DW_COMPLETED:
			ret_val = "SW_DW_COMPLETED"
		STATUS_LOCAL.MT_DW_INFO_REQUESTED:
			ret_val = "MT_DW_INFO_REQUESTED"
		STATUS_LOCAL.MT_DW_COMPLETED:
			ret_val = "MT_DW_COMPLETED"
		STATUS_LOCAL.MERGE_AND_MOVE:
			ret_val = "MERGE_AND_MOVE"
		STATUS_LOCAL.MERGE_AND_MOVE_ALL_BRICKS:
			ret_val = "MERGE_AND_MOVE_ALL_BRICKS"
		STATUS_LOCAL.MERGE_AND_MOVE_SINGLE_BRICK:
			ret_val = "MERGE_AND_MOVE_SINGLE_BRICK"
		STATUS_LOCAL.READ_AND_SAVE:
			ret_val = "READ_AND_SAVE"
		STATUS_LOCAL.READ_AND_SAVE_ALL_CHUNKS:
			ret_val = "READ_AND_SAVE_ALL_CHUNKS"
		STATUS_LOCAL.READ_AND_SAVE_GROUP_OF_CHUNKS:
			ret_val = "READ_AND_SAVE_GROUP_OF_CHUNKS"
		STATUS_LOCAL.SW_DW_RENAME:
			ret_val = "SW_DW_RENAME"
	ret_val = ">>status " + ret_val
	return ret_val


## console output status iternal
func _mapod4d_debug_status():
	if _mapod4d_debug_status_flag:
		var stack = get_stack()
		if len(stack) > 1:
			stack = str(stack[1])
		else:
			stack = ""
		print("##_##{prog} {status}".format({
			"prog": _mapod4d_debug_line,
			"status": _status_to_str(),
		}))
		print("##_##{prog} +++ {stack}".format({
			"prog": _mapod4d_debug_line,
			"stack": str(stack),
		}))

		_mapod4d_debug_line += 1
		if _mapod4d_debug_line > 10000:
			_mapod4d_debug_line = 0
	

## console output iternal
func _mapod4d_debug(data):
	if _mapod4d_debug_flag:
		_mapod4d_debug_status()
		var stack = get_stack()
		if len(stack) > 1:
			stack = str(stack[1])
		else:
			stack = ""
		print("##_##{prog} {data}".format({
				"prog": _mapod4d_debug_line,
				"data": str(data),
		}))
		print("##_##{prog} +++ {stack}".format({
			"prog": _mapod4d_debug_line,
			"stack": str(stack),
		}))
	
		if _mapod4d_debug_status_flag == false:
			_mapod4d_debug_line += 1
			if _mapod4d_debug_line > 10000:
				_mapod4d_debug_line = 0


## reset info status
func _reset_info_and_wait(error=null):
	_mapod4d_debug_status()
	_end_of_flow(error)
	# reset
	_op_type = OP_TYPE_LOCAL.NONE
	_current_brick = 0
	_dw_name = null
	_download_file = null
	_info = null
	_url = null
	_dir = null
	if _dest_file != null:
		_dest_file.close()
		_dest_file = null
	if _input_file_data != null:
		_input_file_data.close()
		_input_file_data = null
	_input_file_data_read = false
	_brick_name = null
	_current_merging_brick = 0
	_current_chunk = 0
	_software_name = null
	_tmp_dir = null
	_sysop = null
	_destination = null
	_which = null

	## sofware download vars
	_ext = null

	## metaverse download vars
	_mapod4d_ver = null
	_set_entry_0_status(STATUS_LOCAL.WAIT)
	_set_status(STATUS_LOCAL.WAIT)
	_mapod4d_debug_status()


## end of flow
func _end_of_flow(error):
	var entry_0_status = _get_entry_0_status()
	var status = _get_status()
	match entry_0_status:
		STATUS_LOCAL.WAIT:
			pass
		STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED:
			if error == null:
				if status == STATUS_LOCAL.SW_CHECK_ULC:
					if _update_core or _update_launcher or _update_updater:
						_child_update_msg(tr("UPDFOUND"))
						software.enable_update_button()
						software.disable_src_button()
					else:
						software.disable_update_button()
						software.enable_src_button()
						_child_update_msg(tr("NOUPDFOUND"))
			else:
				_child_update_msg(tr(error))


## set new status
func _set_status(status:STATUS_LOCAL):
	_status = status


## return current status
func _get_status():
	return _status


## set new status
func _set_entry_0_status(status:STATUS_LOCAL):
	_entry_0_status = status


## return current status
func _get_entry_0_status():
	return _entry_0_status


## send info to child
func _child_update_msg(msg):
	if _which != null:
		_which.update_msg(msg)


## send info to child
func _child_update_merge_info(data):
	if _which != null:
		_which.update_merge_info(data)


## update child info general download
func _update_info_wait():
	if http_sw_dw_rq.get_http_client_status() == 7:
		var bs = http_sw_dw_rq.get_downloaded_bytes() 
		var db = http_sw_dw_rq.get_body_size()
		var perc = "%.2f" % 0
		if db > 0:
			perc = "%.2f" % ((float(bs) / float(db)) * 100.0)
			var data = {
				"bs": str(bs),
				"db": str(db),
				"perc": str(perc),
				"info": str(_info),
				"bricks": str(_info.bricks),
				"brick": _current_brick + 1,
			}
			if _which != null:
				_which.update_download_info(data)



## SOFTWARES SECTION

## DA NON FARE ENTRY 0 start software simple info request
func _on_info_software_requested(
		software_name, ext, sysop, tmp_dir, destination, which):
	_reset_info_and_wait()
	_mapod4d_debug_status()
	_op_type = OP_TYPE_LOCAL.SW_DW
	_software_name = software_name
	_ext = ext
	_sysop = sysop
	_tmp_dir = tmp_dir
	_destination = destination
	_which = which
	_set_status(STATUS_LOCAL.SW_INFO_REQUESTED)


## ENTRY 0 start software download
func _on_software_dw_info_requested(
		software_name, ext, sysop, tmp_dir, destination, which):
	_reset_info_and_wait()
	_set_entry_0_status(STATUS_LOCAL.SW_DW_INFO_REQUESTED)
	_mapod4d_debug_status()
	_op_type = OP_TYPE_LOCAL.SW_DW
	_software_name = software_name
	_ext = ext
	_sysop = sysop
	_tmp_dir = tmp_dir
	_destination = destination
	_which = which
	_set_status(STATUS_LOCAL.SW_DW_INFO_REQUESTED)


## -------------------------------------- REORDER

## event request start software check updates
func _on_check_info_sw_updates_requested(which):
	_check_info_sw_updates_requested(which)


## event request start searchsoftware updates
func _on_sw_search_updates_requested(which):
	_sw_search_updates_requested(which)

## event request start software updates
func _on_sw_updates_requested(which):
	_sw_updates_requested(which)

## ENTRY 0 base start (no actions)
func _start_requested():
	_reset_info_and_wait()
	software.enable_src_button()
	# starting status
	#_set_entry_0_status(STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED)
	#_mapod4d_debug_status()
	#_which = which
	#_child_update_msg(tr("LOOKFORUPD"))
	#_set_status(STATUS_LOCAL.SW_UPDATER_REQUEST_INIT)


## ENTRY 0 start software check updates
func _check_info_sw_updates_requested(which):
	_reset_info_and_wait()
	# starting status
	_set_entry_0_status(STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED)
	_mapod4d_debug_status()
	_which = which
	_child_update_msg(tr("LOOKFORUPD"))
	_set_status(STATUS_LOCAL.SW_UPDATER_REQUEST_INIT)



## ENTRY 0 start search software updates
func _sw_search_updates_requested(which):
	_reset_info_and_wait()
	_set_entry_0_status(STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED)
	_mapod4d_debug_status()
	_which = which
	_child_update_msg(tr("LOOKFORUPD"))
	_set_status(STATUS_LOCAL.CHECK_INFO_SW_UPDATES_REQUESTED)


## ENTRY 0 start software updates
func _sw_updates_requested(which):
	_reset_info_and_wait()
	_set_entry_0_status(STATUS_LOCAL.SW_UPDATES_REQUESTED)
	_mapod4d_debug_status()
	_which = which
	_child_update_msg(tr("LOOKFORUPD"))
	if _update_updater == true:
		_set_status(STATUS_LOCAL.SW_UPDATER_REQUEST_INIT)
	elif _update_launcher == true:
		_set_status(STATUS_LOCAL.SW_LAUNCHER_REQUEST_INIT)
	elif _update_core == true:
		_set_status(STATUS_LOCAL.SW_CORE_REQUEST_INIT)
	else:
		## no updates found
		pass


## init software requested
func _sw_request_init():
	_mapod4d_debug_status()
	_op_type = OP_TYPE_LOCAL.SW_DW
	_tmp_dir = _build_tmp_dir
	var status = _get_status()
	match status:
		STATUS_LOCAL.SW_UPDATER_REQUEST_INIT:
			_software_name = UPDATER_NAME
			_ext = _os_info.exe_ext
			_sysop = _os_info.os
			# TODO prima era cosi'
			#_destination = _build_updater_path
			## used only for download
			_destination = "%s%s.bin" % [_build_dest_dw_path, _software_name]
			var entry_0_status = _get_entry_0_status()
			if entry_0_status == STATUS_LOCAL.SW_UPDATES_REQUESTED:
				_set_status(STATUS_LOCAL.SW_DW_INFO_REQUESTED)
			else:
				_set_status(STATUS_LOCAL.SW_INFO_UPDATER_REQUESTED)
		STATUS_LOCAL.SW_LAUNCHER_REQUEST_INIT:
			_software_name = LAUNCHER_NAME
			_ext = _os_info.exe_ext
			_sysop = _os_info.os
			#_destination = "files/launcher"
			## used only for download
			_destination = "%s%s.bin" % [_build_dest_dw_path, _software_name]
			var entry_0_status = _get_entry_0_status()
			if entry_0_status == STATUS_LOCAL.SW_UPDATES_REQUESTED:
				_set_status(STATUS_LOCAL.SW_DW_INFO_REQUESTED)
			else:
				_set_status(STATUS_LOCAL.SW_INFO_LAUNCHER_REQUESTED)
		STATUS_LOCAL.SW_CORE_REQUEST_INIT:
			_software_name = CORE_NAME
			_ext = _os_info.exe_ext
			_sysop = _os_info.os
			#_destination = "files/core"
			## used only for download
			_destination = "%s%s.bin" % [_build_dest_dw_path, _software_name]
			var entry_0_status = _get_entry_0_status()
			if entry_0_status == STATUS_LOCAL.SW_UPDATES_REQUESTED:
				_set_status(STATUS_LOCAL.SW_DW_INFO_REQUESTED)
			else:
				_set_status(STATUS_LOCAL.SW_INFO_CORE_REQUESTED)


## download software requested
func _sw_dw_info_requested():
	_mapod4d_debug_status()
	_url = MULTIVSVR + "/api/software/"
	_url += _software_name + "/" + _sysop + "?format=json"
	_mapod4d_debug(_url)
	var headers = ["Content-Type: application/json"]
	_download_file = _tmp_dir + "/" + BUF_NAME
	http_sw_info_rq.request(_url, headers, HTTPClient.METHOD_GET)
	var status = _get_status()
	if status == STATUS_LOCAL.SW_INFO_REQUESTED:
		_set_status(STATUS_LOCAL.SW_INFO_WAIT)
	elif status == STATUS_LOCAL.SW_INFO_UPDATER_REQUESTED:
		_set_status(STATUS_LOCAL.SW_INFO_UPDATER_WAIT)
	elif status == STATUS_LOCAL.SW_INFO_LAUNCHER_REQUESTED:
		_set_status(STATUS_LOCAL.SW_INFO_LAUNCHER_WAIT)
	elif status == STATUS_LOCAL.SW_INFO_CORE_REQUESTED:
		_set_status(STATUS_LOCAL.SW_INFO_CORE_WAIT)
	else:
		_set_status(STATUS_LOCAL.SW_DW_INFO_WAIT)


## info software download ended
func _on_sw_dw_info_completed(result, _response_code, _headers, body):
	_mapod4d_debug_status()
	_mapod4d_debug("progress")
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		_mapod4d_debug("BODY" + str(body.get_string_from_utf8()))
		_mapod4d_debug("JSON" + str(json.get_data()))
		_info = json.get_data()
		if _info != null:
			if 'detail' in _info:
				_child_update_msg("ERROR " + _info.detail)
				_reset_info_and_wait()
			else:
				var status = _get_status()
				if status == STATUS_LOCAL.SW_DW_INFO_WAIT:
					_mapod4d_debug(_info.bricks)
					_dw_name = _info.link + "_"
					_current_brick = 0
					# SOLO DEBUG
					#_info.bricks = 1
					#_info.compressed = false
					# SOLO DEBUG FINE
					#if _info.bricks == 0:
					#	_reset_info_and_wait()
					#else:
					#	_set_status(STATUS_LOCAL.SW_DW_BRICKS)
					_info_saved[DW_INFO] = _info
					_set_status(STATUS_LOCAL.SW_DW_BRICKS)
				elif status == STATUS_LOCAL.SW_INFO_WAIT:
					_info_saved[DW_INFO] = _info
					_mapod4d_debug("SAVED INFO" + str(_info_saved))
					_reset_info_and_wait()
				elif status == STATUS_LOCAL.SW_INFO_UPDATER_WAIT:
					_info_saved[UPDATER_INFO] = _info
					_set_status(STATUS_LOCAL.SW_LAUNCHER_REQUEST_INIT)
				elif status == STATUS_LOCAL.SW_INFO_LAUNCHER_WAIT:
					_info_saved[LAUNCHER_INFO] = _info
					_set_status(STATUS_LOCAL.SW_CORE_REQUEST_INIT)
				elif status == STATUS_LOCAL.SW_INFO_CORE_WAIT:
					_info_saved['core'] = _info
					_mapod4d_debug("SAVED INFO" + str(_info_saved))
					_set_status(STATUS_LOCAL.SW_CHECK_ULC)
		else:
			_child_update_msg("ERROR API NOT FOUND")
			_reset_info_and_wait()
	else:
		_child_update_msg("HTTPS REQUEST ERROR")
		_reset_info_and_wait()


## software download bricks X
func _sw_dw_bricks():
	_mapod4d_debug_status()
	_mapod4d_debug("brick " + str(_current_brick))
	if _current_brick >= _info.bricks:
		_child_update_msg("END DOWNLOAD " + _dw_name)
		_set_status(STATUS_LOCAL.MERGE_AND_MOVE)
	else:
		## download next brick
		http_sw_dw_rq.download_file = _download_file + str(_current_brick)
		_mapod4d_debug(http_sw_dw_rq.download_file)
		var url = _dw_name + str(_current_brick)
		_mapod4d_debug(url + " status:" + str(_status))
		http_sw_dw_rq.request(url)
		_set_status(STATUS_LOCAL.SW_DW_BRICK_WAIT)


## software download single brick X
func _on_sw_dw_brick_completed(result, response_code, _headers, _body):
	_mapod4d_debug_status()
	_mapod4d_debug(response_code)
	if result == HTTPRequest.RESULT_SUCCESS:
		if response_code == 200:
			_child_update_msg("BICK OK")
			_current_brick += 1
			_set_status(STATUS_LOCAL.SW_DW_BRICKS)
		else:
			## download error
			_child_update_msg("ERROR " + str(response_code))
			_reset_info_and_wait()
	else:
		## htpp error
		_child_update_msg("ERROR HTTP")
		_reset_info_and_wait()


## write updater software version and core software version
func _sw_check_ulc():
	var version = {}
	_update_updater = false
	_update_launcher = false
	_update_core = false
	
	_write_updater_version()
	version = _read_version(_build_updater_path + ".json")
	if version.result == true:
		if version.sversion < _info_saved[UPDATER_INFO].sversion:
			_update_updater = true

	if _m4dsversion < _info_saved[LAUNCHER_INFO].sversion:
		_update_launcher = true

	_write_core_version()
	version = _read_version(_build_core_path + ".json")
	if version.result == true:
		if version.sversion <  _info_saved["core"].sversion:
			_update_core = true

	_mapod4d_debug(
		"updater:{uv} launcher:{lv} core:{cv}".format({
			"uv": _update_updater,
			"lv": _update_launcher,
			"cv": _update_core,
		}))

	_reset_info_and_wait()


## software downloaded end, rename and move to updates area
func _sw_dw_completed():
	# TODO other software download
	_child_update_msg("SOFTWARE DOWNLOAD COMPLETED")
	# TODO check if an update is really required and no error happened
	_set_status(STATUS_LOCAL.SW_DW_RENAME)


## merge and move current software downloaded to correct position
func _sw_dw_rename():
	# TODO write rename procedures
	var from_name = "%s%s.bin" % [_build_dest_dw_path, _software_name]
	if _software_name == UPDATER_NAME:
		## only rename
		var to_name = _build_updater_path + str(_ext)
		DirAccess.rename_absolute(from_name, to_name)
		_update_updater = false
		if _update_launcher == true:
			_set_status(STATUS_LOCAL.SW_LAUNCHER_REQUEST_INIT)
		elif _update_core == true:
			_set_status(STATUS_LOCAL.SW_CORE_REQUEST_INIT)
		else:
			_reset_info_and_wait()
	elif _software_name == LAUNCHER_NAME:
		## run updater
		if OS.has_feature('editor'):
			if _update_core == true:
				_set_status(STATUS_LOCAL.SW_CORE_REQUEST_INIT)
			else:
				_reset_info_and_wait()
		else:
			if _dir.file_exists(from_name):
				var updater_exe = _build_updater_path + str(_ext)
				if _dir.file_exists(updater_exe):
					## run updater
					OS.create_process(updater_exe,  ["++", "-m4dupdate"])
					## quit form the launcher
					get_tree().quit()
				else:
					## error updater exe not found
					_reset_info_and_wait()
			else:
				## error downloaded luncher not found
				_reset_info_and_wait()
		_update_launcher = false
	elif _software_name == CORE_NAME:
		## only rename
		var to_name = _build_updater_path + str(_ext)
		DirAccess.rename_absolute(from_name, to_name)
		_update_core = false
		_reset_info_and_wait()
	else:
		## nothing to do
		software.disable_update_button()
		software.enable_src_button()
		_reset_info_and_wait()
	
	if (_update_launcher or _update_updater or _update_core) == false:
		software.disable_update_button()
		software.enable_src_button()




## METAVERSES SECTION

func _mt_dw_completed():
	_mapod4d_debug_status()
	_child_update_msg("METAVERSE DOWNLOAD COMPLETED")
	_reset_info_and_wait()


## ENTRY 0 start metaverse download
func _on_download_metaverse_requested(
		software_name, mapod4d_ver, sysop, tmp_dir, destination, which):
	# https://sv001.mapod4d.it/api/multiverse/lastmetaverse/metaversetest/002000000002
	_mapod4d_debug_status()
	_op_type = OP_TYPE_LOCAL.MT_DW
	_software_name = software_name
	_mapod4d_ver = mapod4d_ver
	_sysop = sysop
	_tmp_dir = tmp_dir
	_destination = destination
	_which = which
	_set_status(STATUS_LOCAL.MT_DW_INFO_REQUESTED)


## download metaverse requested
func mt_dw_info_requested():
	_mapod4d_debug_status()
	_url = MULTIVSVR + "/api/multiverse/lastmetaverse/"
	_url += _software_name + "/" + _mapod4d_ver + "?format=json"
	_mapod4d_debug(_url)
	var headers = ["Content-Type: application/json"]
	_download_file = _tmp_dir + "/" + BUF_NAME
	http_sw_info_rq.request(_url, headers, HTTPClient.METHOD_GET)
	_set_status(STATUS_LOCAL.SW_DW_INFO_WAIT)


## COMMON SECTION

## create the destination file and set status to merge bricks
func _merge_and_move():
	_mapod4d_debug_status()
	_dir = DirAccess.open(_tmp_dir)
	if _ext == null:
		_dest_file = FileAccess.open(
				_destination, FileAccess.WRITE)
	else:
		_dest_file = FileAccess.open(
				_destination, FileAccess.WRITE)
	_current_merging_brick = -1
	_set_status(STATUS_LOCAL.MERGE_AND_MOVE_ALL_BRICKS)


## check current brick and if it is the last then close the destination
## file and set status to downloading complete
func _merge_and_move_all_bricks():
	_mapod4d_debug_status()
	_mapod4d_debug("_merge_and_move_all_blocks")
	_current_merging_brick += 1
	if _current_merging_brick >= _info.bricks:
		_dest_file.close()
		_child_update_msg("END MERGE AND MOVE")
		_set_status(STATUS_LOCAL.SW_DW_COMPLETED)
	else:
		_set_status(STATUS_LOCAL.MERGE_AND_MOVE_SINGLE_BRICK)


## open the brick and set status to "read and save it"
func _merge_and_move_single_brick():
	_mapod4d_debug_status()
	_mapod4d_debug("_merge_and_move_single_block")
	_brick_name = _download_file + str(_current_merging_brick)
	if FileAccess.file_exists(_brick_name) == false:
		_dest_file.close()
		_dest_file = null
		_child_update_msg("ERROR MERGE AN MOVE BLOCK " + _brick_name)
		_reset_info_and_wait()
	else:
		_set_status(STATUS_LOCAL.READ_AND_SAVE)


## 
func _read_and_save():
	_mapod4d_debug_status()
	_mapod4d_debug("_read_and_save " + str(_current_merging_brick))
	if _info.compressed == true:
		_input_file_data = FileAccess.open_compressed(
				_brick_name, 
				FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
	else:
		_input_file_data = FileAccess.open(
				_brick_name,
				FileAccess.READ)
	_mapod4d_debug("_input_file_data code:" + str(FileAccess.get_open_error()))
	_current_chunk = 0
	_input_file_data_read = false
	_set_status(STATUS_LOCAL.READ_AND_SAVE_ALL_CHUNKS)


func _read_and_save_all_chunks():
	_mapod4d_debug_status()
	if _input_file_data_read == false:
		_set_status(STATUS_LOCAL.READ_AND_SAVE_GROUP_OF_CHUNKS)
	else:
		_input_file_data.close()
		_input_file_data = null
		_set_status(STATUS_LOCAL.MERGE_AND_MOVE_ALL_BRICKS)


func _read_and_save_group_of_chunks():
	_mapod4d_debug_status()
	var group_size = 100
	var current_group = 0
	var data_read = null
	while current_group < group_size:
		if _current_chunk > CHUNKSIZE_MULTI:
			_input_file_data_read = true
			break
		if _input_file_data.eof_reached() == true:
			_input_file_data_read = true
			break
		data_read = _input_file_data.get_buffer(CHUNKSIZE)
		_dest_file.store_buffer(data_read)
		current_group += 1
		_current_chunk += 1
	var info ={
		"file_name": _brick_name, 
		"brick": _current_merging_brick,
		"bricks": _info.bricks,
		"chunk": CHUNKSIZE_MULTI - _current_chunk,
		"chunks":  CHUNKSIZE_MULTI,
	}
	_child_update_merge_info(info)
	_set_status(STATUS_LOCAL.READ_AND_SAVE_ALL_CHUNKS)













## roba da vedere





func _read_and_save_execute(from_file, to_file, msg_info):
	var count = CHUNKSIZE_MULTI
	var data_read = null
	while from_file.eof_reached() == false:
		if count == 0:
			break
		msg_info.block = count
		if (count % 100) == 0:
			_child_update_merge_info(msg_info)
			#await RenderingServer.frame_post_draw
		data_read = from_file.get_buffer(CHUNKSIZE)
		# _mapod4d_debug(str(count) + "-" + str(data_read.size()))
		to_file.store_buffer(data_read)
		count -= 1


#func _merge_and_move():
#	var dest = null
#	var dir = DirAccess.open(_tmp_dir)
#	var file_name = null
#	var file_data = null
#	var count = 0
#	var msg_info = null
#
#	if _ext == null:
#		dest = FileAccess.open(_destination, FileAccess.WRITE)
#	else:
#		dest = FileAccess.open(_destination + str(_ext), FileAccess.WRITE)
#
#	while true:
#		file_name = _download_file + str(count)
#		msg_info = {
#			"file_name" = file_name,
#			"count" = count,
#			"blocks" = 0,
#			"block" = 0,
#		}
#		_mapod4d_debug(msg_info)
#		if FileAccess.file_exists(file_name) == false:
#			dest.close()
#			if count < _info.bricks:
#				_child_update_msg("error")
#			else:
#				_child_update_msg("END MERGE")
#			break
#		_child_update_merge_info(msg_info)
#		#await RenderingServer.frame_post_draw
#		if _info.compressed == true:
#			file_data = FileAccess.open_compressed(
#					file_name, 
#					FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
#		else:
#			file_data = FileAccess.open(file_name, FileAccess.READ)
#		_mapod4d_debug(FileAccess.get_open_error())
#		## read and write buffer
#		_mapod4d_debug(file_data.get_error())
#		_read_and_save_start(file_data, dest, msg_info)
#		file_data.close()
#		## remove buffer
##		dir.remove(BUF_NAME + str(count))
#		count += 1

func _merge_and_move_start():
	pass

#func _read_and_save(from_file, to_file, msg_info):
#	var count = CHUNKSIZE_MULTI
#	var data_read = null
#	while from_file.eof_reached() == false:
#		if count == 0:
#			break
#		msg_info.block = count
#		if (count % 100) == 0:
#			_child_update_merge_info(msg_info)
#			#await RenderingServer.frame_post_draw
#		data_read = from_file.get_buffer(CHUNKSIZE)
#		# _mapod4d_debug(str(count) + "-" + str(data_read.size()))
#		to_file.store_buffer(data_read)
#		count -= 1

func _read_and_save_start(_from_file, _to_file, _msg_info):
	pass


