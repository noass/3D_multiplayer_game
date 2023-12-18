extends Node3D

var peer
var ip_address
var port = 1080

@export var PlayerScene : PackedScene

var isFullscreen = false
@onready var fullscreenCheckbox = $Menu/MenuMenu/CheckBox
var sens = 1
@onready var sensSlider = $Menu/MenuMenu/HSlider
var isMenuOpen = false
var exited = false

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		hostgame()
	$Menu/HostJoinMenu/ServerBrowser.joinGame.connect(JoinByIP)

func peer_connected(id):
	print("Player connected ID: " + str(id))
	
func peer_disconnected(id):
	print("Player disconnected ID: " + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
	
func connected_to_server():
	print("Connected to server!")
	SendPlayerInfo.rpc_id(1, $Menu/HostJoinMenu/LineEdit.text, multiplayer.get_unique_id())
	
func connection_failed():
	print("Connection failed!")
	
func _process(delta):
	ip_address = $Menu/HostJoinMenu/LineEdit2.text
	sens = sensSlider.value
	if (Input.is_action_just_pressed("ESC") and !isMenuOpen and $Menu/HostJoinMenu.visible == false):
		$Menu/MenuMenu.show()
		isMenuOpen = true
		PlayerScene.instantiate().canMove = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif (Input.is_action_just_pressed("ESC") and isMenuOpen and $Menu/HostJoinMenu.visible == false):
		$Menu/MenuMenu.hide()
		isMenuOpen = false
		PlayerScene.instantiate().canMove = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if (str($Menu/HostJoinMenu/LineEdit.text).length() >= 3 and str($Menu/HostJoinMenu/LineEdit.text).length() <= 20):
		$Menu/HostJoinMenu/Host.disabled = false
	else:
		$Menu/HostJoinMenu/Host.disabled = true
	
@rpc("any_peer")
func SendPlayerInfo(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] ={
			"name" : name,
			"id" : id
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInfo.rpc(GameManager.Players[i].name, i)

func hostgame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		print("Cannot host game ERROR: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Server started! Waiting for players...")

func _on_host_pressed():
	hostgame()
	multiplayer.peer_connected.connect(add_player)
	add_player()
	SendPlayerInfo($Menu/HostJoinMenu/LineEdit.text, multiplayer.get_unique_id())
	$Menu/HostJoinMenu/ServerBrowser.setUpBroadCast($Menu/HostJoinMenu/LineEdit.text + "'s server")
	$Menu/HostJoinMenu.hide()
	
func add_player(id = 1):
	var player = PlayerScene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	sens = player.camera_sens

func _on_join_pressed():
	JoinByIP(ip_address)
	$Menu/HostJoinMenu.hide()
	
func JoinByIP(ip):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	$Menu/HostJoinMenu.hide()
	
func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)
	
@rpc("any_peer", "call_local")
func _del_player(id):
	get_node(str(id)).queue_free()

func _on_check_box_toggled(button_pressed):
	isFullscreen = button_pressed
	if isFullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_exit_pressed():
	exited = true
	get_tree().quit()
