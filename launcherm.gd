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
	
	CHECK_INFO_SOFTWARE_UPDATES_REQUESTED,

	SW_UPDATER_REQUEST_LOAD,
	SW_LAUNCHER_REQUEST_LOAD,
	SW_CORE_REQUEST_LOAD,

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
	
	SW_DOWNLOAD_ULC,
	
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
	READ_AND_SAVE_GROUP_OF_CHUNKS
}

enum OP_TYPE_LOCAL {
	NONE = 0,
	SW_DW,
	MT_DW,
}

# ----- constants
const MULTIVSVR = "https://sv001.mapod4d.it"
const MULTIVSVR_PORT = 80
const BUF_NAME = "buf_"
const CHUNKSIZE = 550000
const CHUNKSIZE_MULTI = 1000

# ----- exported variables

# ----- public variables

# ----- private variables

# ----- onready variables
@onready var http_sw_info_rq = $HTTPSWRequestInfo
@onready var http_sw_dw_rq = $HTTPSWRequestDownload
@onready var http_mt_info_rq = $HTTPSWRequestInfo
@onready var http_mt_dw_rq = $HTTPSWRequestDownload
@onready var software = $TabContainer/Software
@onready var metaverse = $TabContainer/Metaverse


# ----- optional built-in virtual _init method

# ----- built-in virtual _ready method
var _status = STATUS_LOCAL.WAIT
var _local_lock = false # future mutitread
var _op_type:OP_TYPE_LOCAL = OP_TYPE_LOCAL.NONE

## local support
var _mapod4d_debug_flag: bool = false
var _mapod4d_debug_status_flag: bool = true
var _mapod4d_debug_line: int = 0
var _is_ready = false

## commons
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
var _sysop = null
var _tmp_dir = null
var _destination = null
var _which = null

## _info data saved after info download
var _info_saved = {}

## sofware download vars
var _ext = null

## metaverse download vars
var _mapod4d_ver = null


# Called when the node enters the scene tree for the first time.
func _ready():
	http_sw_info_rq.request_completed.connect(
			_on_sw_dw_info_completed)
	http_sw_dw_rq.request_completed.connect(
			_on_sw_dw_brick_completed)

	software.check_info_software_updates_requested.connect(
			_on_check_info_software_updates_requested)
	software.download_software_requested.connect(
			_on_download_software_requested)
	software.info_software_requested.connect(
			_on_info_software_requested)

	metaverse.download_metaverse_requested.connect(
			_on_download_metaverse_requested)
	
	#_set_status(STATUS_LOCAL.CHECK_INFO_SOFTWARE_UPDATES_REQUESTED)
	_set_status(STATUS_LOCAL.WAIT)
	_is_ready = true
	

# ----- remaining built-in virtual methods

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# status MACHINE
	if _is_ready and _local_lock != true:
		if _status != STATUS_LOCAL.WAIT:
			match _status:
				STATUS_LOCAL.CHECK_INFO_SOFTWARE_UPDATES_REQUESTED:
					_on_check_info_software_updates_requested(software)
				
				STATUS_LOCAL.SW_UPDATER_REQUEST_LOAD, \
				STATUS_LOCAL.SW_LAUNCHER_REQUEST_LOAD, \
				STATUS_LOCAL.SW_CORE_REQUEST_LOAD:
					_sw_info_request_load()
				
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
					_child_update_download_info()

				STATUS_LOCAL.SW_DOWNLOAD_ULC:
					_sw_download_ulc()

				STATUS_LOCAL.SW_DW_BRICKS:
					_sw_dw_bricks()
				STATUS_LOCAL.SW_DW_BRICK_WAIT:
					_child_update_download_info()
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

# ----- public methods

# ----- private methods

## utility status to string
func _status_to_str():
	var status = _get_status()
	var ret_val = "undefined"
	match status:
		STATUS_LOCAL.WAIT:
			ret_val = "WAIT"
		STATUS_LOCAL.CHECK_INFO_SOFTWARE_UPDATES_REQUESTED:
			ret_val = "CHECK_INFO_SOFTWARE_UPDATES_REQUESTED"
		STATUS_LOCAL.SW_UPDATER_REQUEST_LOAD:
			ret_val = "SW_UPDATER_REQUEST_LOAD"
		STATUS_LOCAL.SW_LAUNCHER_REQUEST_LOAD:
			ret_val = "SW_LAUNCHER_REQUEST_LOAD"
		STATUS_LOCAL.SW_CORE_REQUEST_LOAD:
			ret_val = "SW_CORE_REQUEST_LOAD"
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
		STATUS_LOCAL.SW_DOWNLOAD_ULC:
			ret_val = "SW_DOWNLOAD_ULC"
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
func _reset_info_and_wait():
	_mapod4d_debug_status()
	# commons
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
	_sysop = null
	_tmp_dir = null
	_destination = null
	_which = null

	## sofware download vars
	_ext = null

	## metaverse download vars
	_mapod4d_ver = null
	_set_status(STATUS_LOCAL.WAIT)
	_mapod4d_debug_status()


## set new status
func _set_status(status):
	_status = status


## return current status
func _get_status():
	return _status

## send info to child
func _child_update_msg(msg):
	if _which != null:
		_which.update_msg(msg)


## send info to child
func _child_update_merge_info(data):
	if _which != null:
		_which.update_merge_info(data)


func _child_update_download_info():
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

func _sw_dw_completed():
	_child_update_msg("SOFTWARE DOWNLOAD COMPLETED")
	_reset_info_and_wait()


## ENTRY 0 start software simple info request
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
func _on_download_software_requested(
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
	_set_status(STATUS_LOCAL.SW_DW_INFO_REQUESTED)


## ENTRY 0 start software check updates download
func _on_check_info_software_updates_requested(which):
	_reset_info_and_wait()
	_mapod4d_debug_status()
	_which = which
	_set_status(STATUS_LOCAL.SW_UPDATER_REQUEST_LOAD)

## download software requested
func _sw_info_request_load():
	_mapod4d_debug_status()
	_op_type = OP_TYPE_LOCAL.SW_DW
	_tmp_dir = "files/tmp"
	var status = _get_status()
	match status:
		STATUS_LOCAL.SW_UPDATER_REQUEST_LOAD:
			_software_name = "softwaretest"
			_ext = ".exe"
			_sysop = "L00"
			_destination = "files/updater"
			_set_status(STATUS_LOCAL.SW_INFO_UPDATER_REQUESTED)
		STATUS_LOCAL.SW_LAUNCHER_REQUEST_LOAD:
			_software_name = "softwaretest"
			_ext = ".exe"
			_sysop = "L00"
			_destination = "files/launcher"
			_set_status(STATUS_LOCAL.SW_INFO_LAUNCHER_REQUESTED)
		STATUS_LOCAL.SW_CORE_REQUEST_LOAD:
			_software_name = "softwaretest"
			_ext = ".exe"
			_sysop = "L00"
			_destination = "files/core"
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
					_set_status(STATUS_LOCAL.SW_DW_BRICKS)
				elif status == STATUS_LOCAL.SW_INFO_WAIT:
					_info_saved['none'] = _info
					_mapod4d_debug("SAVED INFO" + str(_info_saved))
					_reset_info_and_wait()
				elif status == STATUS_LOCAL.SW_INFO_UPDATER_WAIT:
					_info_saved['updater'] = _info
					_set_status(STATUS_LOCAL.SW_LAUNCHER_REQUEST_LOAD)
				elif status == STATUS_LOCAL.SW_INFO_LAUNCHER_WAIT:
					_info_saved['launcher'] = _info
					_set_status(STATUS_LOCAL.SW_CORE_REQUEST_LOAD)
				elif status == STATUS_LOCAL.SW_INFO_CORE_WAIT:
					_info_saved['core'] = _info
					_mapod4d_debug("SAVED INFO" + str(_info_saved))
					_set_status(STATUS_LOCAL.SW_DOWNLOAD_ULC)
		else:
			_child_update_msg("ERROR API NOT FOUND")
			_reset_info_and_wait()
	else:
		_child_update_msg("HTTPS REQUEST ERROR")
		_reset_info_and_wait()


## software updater, launcher and core decide to download
func _sw_download_ulc():
	# if updater is new copy it
	# if launcher is new exit and exec launcher
	# if core is new  copy it
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

func _merge_and_move():
	_mapod4d_debug_status()
	_dir = DirAccess.open(_tmp_dir)
	if _ext == null:
		_dest_file = FileAccess.open(
				_destination, FileAccess.WRITE)
	else:
		_dest_file = FileAccess.open(
				_destination + str(_ext), FileAccess.WRITE)
	_current_merging_brick = -1
	_set_status(STATUS_LOCAL.MERGE_AND_MOVE_ALL_BRICKS)


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











## da vedere





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


