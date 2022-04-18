extends Spatial

var collect_for_next_level = 20

var levelContainer:Spatial = null

onready var ViewportContainerP1 = $ViewportContainerP1
onready var ViewportContainerP2 = $ViewportContainerP2
onready var ViewportP1:Viewport = $ViewportContainerP1/ViewportP1
onready var ViewportP2:Viewport = $ViewportContainerP2/ViewportP2
onready var cameraP1:Camera = $ViewportContainerP1/ViewportP1/CameraP1
onready var cameraP2:Camera = $ViewportContainerP2/ViewportP2/CameraP2
onready var CaptionP1:Button = $Button1
onready var CaptionP2:Button = $Button2
onready var CaptionToCollect:Button = $ButtonToCollect

onready var spawns:Array = [
	$Spawn1,
	$Spawn2,
	$Spawn3,
	$Spawn4,
	$Spawn5
]

onready var Origin = $Origin
var Dragon = preload("res://Dragon.tscn")
var Rosalina = preload("res://Rosalina.tscn")
var Luma = preload("res://Luma.tscn")
var Squirrel = preload("res://Squirrel.tscn")
var P1:KinematicBody
var P2:KinematicBody
var R:KinematicBody

var p1count_old:int = -1
var p2count_old:int = -1


func _ready():
	set_process_input(true)
	randomize()
	var _err = get_tree().get_root().connect("size_changed", self, "resize")
	OS.window_fullscreen = true
	$BackgroundSound.play()
	resize()
	newLevel()


func resize():
	var viewport_size = get_viewport().size
	var width = viewport_size.x
	var height = viewport_size.y
	var mid = int(height/2)
	
	ViewportContainerP1.margin_left = 0
	ViewportContainerP1.margin_top = 0
	ViewportContainerP1.margin_bottom =  int(height/2) - 1
	ViewportContainerP1.margin_right = width
	
	ViewportContainerP2.margin_left = 0
	ViewportContainerP2.margin_top = mid + 1
	ViewportContainerP2.margin_bottom = height
	ViewportContainerP2.margin_right = width
	
	ViewportP1.set_size_override(true, Vector2(mid, height))
	ViewportP2.set_size_override(true, Vector2(mid, height))


func _process(_delta):
	var p1count = P1.get_lumas_count()
	var p2count = P2.get_lumas_count()
	if p1count_old != p1count:
		p1count_old = p1count
		CaptionP1.text = P1.playerName + ": " + str(p1count)
		CaptionToCollect.text = "TO COLLECT: " + str(collect_for_next_level -R.get_collected_lumas() ) + "  "
	if p2count_old != p2count:
		p2count_old = p2count
		CaptionP2.text = P2.playerName + ": " + str(p2count)
		CaptionToCollect.text = "TO COLLECT: " + str(collect_for_next_level -R.get_collected_lumas() ) + "  "
	if R.goto_next_level() or Input.is_action_just_pressed("ui_select"):
		newLevel()

func newLevel():
	var p1Texture = 3
	if P1 != null: p1Texture = P1.playerTextureIX
	var p2Texture = 1
	if P2 != null: p2Texture = P2.playerTextureIX
		
	var oldLevelContainer = levelContainer
	# create level object container
	levelContainer = Spatial.new()
	add_child(levelContainer)
	
	# delete old level elements
	if oldLevelContainer != null:
		remove_child(oldLevelContainer)
		oldLevelContainer.queue_free()
		
	# add player 1
	P1 = Dragon.instance()
	P1.transform.origin = $OriginFire.transform.origin + Vector3(1, 0.5, -1)
	P1.player = "p1"
	P1.playerName = "SPARKLE"
	P1.setCamera(cameraP1)
	P1.playerTextureIX = p1Texture
	levelContainer.add_child(P1)

	# add player 2	
	P2 = Dragon.instance()
	P2.transform.origin = $OriginFire.transform.origin + Vector3(-1, 0.5, -1)
	P2.player = "p2"
	P2.playerName = "SPYRO"
	P2.setCamera(cameraP2)
	P2.playerTextureIX = p2Texture
	levelContainer.add_child(P2)

	# add Rosalina
	R = Rosalina.instance()
	R.needToCollect = collect_for_next_level
	R.transform.origin = $OriginFire.transform.origin + Vector3(0, 0.5, 1)
	R.rotate_y(PI)
	levelContainer.add_child(R)
	
	# add lumas
	for _i in range(collect_for_next_level):
		var L = Luma.instance()
		L.transform.origin = ( spawns[randi() % len(spawns)].transform.origin +  
			Vector3( 5 - 10 * randf(), 5, 8 - 16 * randf())  )
		levelContainer.add_child(L)
	
	# add squirels
	for _i in range(6):
		var S = Squirrel.instance()
		S.transform.origin = ( spawns[randi() % len(spawns)].transform.origin +  
			Vector3( 5 - 10 * randf(), 5, 8 - 16 * randf())  )
		levelContainer.add_child(S)
	p1count_old = -1
	p2count_old = -1
