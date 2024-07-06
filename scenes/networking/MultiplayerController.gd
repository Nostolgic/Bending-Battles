extends Control

@export var port = 7777
@export var play_scene: PackedScene

var peer

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connected_failed)

func peer_connected(id):
	print("Player Connected " + str(id))
	
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
		
func connected_to_server():
	print("Connected to server!")
	SendPlayerInformation.rpc_id(1, "Bob", multiplayer.get_unique_id())
	
func connected_failed():
	print("Connection failed!")
	
@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"id": id,
			"name": name
		}
	
	if multiplayer.is_server():
		for player_id in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[player_id].name, player_id)
	
@rpc("any_peer", "call_local")
func StartGame():
	get_tree().root.add_child(play_scene.instantiate())
	self.hide()
	

func _on_join_button_down():
	var address = $TargetIP.text
	print("New player joining!")
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.set_multiplayer_peer(peer)


func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()
	var status = peer.create_server(port, 2)
	if status != OK:
		print("Cannot host: " + str(status))
		return
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players...")
	SendPlayerInformation("Host_Bob", multiplayer.get_unique_id())

func _on_start_button_down():
	StartGame.rpc()
