extends Control

signal found_server(ip, port, roomInfo)
signal update_server(ip, port, roomInfo)
signal joinGame(ip)

var broadcastTimer : Timer

var RoomInfo = {"name":"name", "playerCount": 0}
var broadcaster : PacketPeerUDP
var listener : PacketPeerUDP
@export var listenPort : int = 1081
@export var broadcastPort : int = 1082
@export var broadcastAddress : String = '255.255.255.255'

@export var serverInfo : PackedScene

@onready var usernameLineEdit = $/root/World/Menu/HostJoinMenu/LineEdit

func _ready():
	broadcastTimer = $BroadcastTimer
	setUp()
	
func setUp():
	listener = PacketPeerUDP.new()
	var ok = listener.bind(listenPort)
	
	if ok == OK:
		print("Bound to listen Port "  + str(listenPort) +  " Successful!")
		$Label4.text="Bound To Listen Port: true"
	else:
		print("Failed to bind to listen port!")
		$Label4.text="Bound To Listen Port: false"
		

func setUpBroadCast(name):
	RoomInfo.name = name
	RoomInfo.playerCount = GameManager.Players.size()
	
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcastAddress, listenPort)
	
	var ok = broadcaster.bind(broadcastPort)
	
	if ok == OK:
		print("Bound to Broadcast Port "  + str(broadcastPort) +  " Successful!")
	else:
		print("Failed to bind to broadcast port!")
		
	broadcastTimer.start()
	
func _process(delta):
	if listener.get_available_packet_count() > 0:
		var serverip = listener.get_packet_ip()
		var serverport = listener.get_packet_port()
		var bytes = listener.get_packet()
		var data = bytes.get_string_from_ascii()
		var roomInfo = JSON.parse_string(data)
		
		print("Server IP: " + serverip + ", Server port: " + str(serverport) + ", Room info: " + str(roomInfo))
		
		for i in $Panel/ScrollContainer/VBoxContainer.get_children():
			if i.name == roomInfo.name:
				update_server.emit(serverip, serverport, roomInfo)
				i.get_node("IP").text = serverip
				i.get_node("PlayerCount").text = str(roomInfo.playerCount)
				return
				
		var currentInfo = serverInfo.instantiate()
		currentInfo.name = roomInfo.name
		currentInfo.get_node("Name").text = roomInfo.name
		currentInfo.get_node("IP").text = serverip
		currentInfo.get_node("PlayerCount").text = str(roomInfo.playerCount)
		$Panel/ScrollContainer/VBoxContainer.add_child(currentInfo)
		currentInfo.joinGame.connect(joinByIP)
		found_server.emit(serverip, serverport, roomInfo)

func _on_broadcast_timer_timeout():
	print("Broadcasting game...")
	RoomInfo.playerCount = GameManager.Players.size()
	var data = JSON.stringify(RoomInfo)
	var packet = data.to_ascii_buffer()
	broadcaster.put_packet(packet)

func cleanUp():
	listener.close()
	broadcastTimer.stop()
	if broadcaster != null:
		broadcaster.close()

func _exit_tree():
	cleanUp()
	
func joinByIP(ip):
	joinGame.emit(ip)

