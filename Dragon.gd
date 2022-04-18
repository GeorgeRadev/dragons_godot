extends KinematicBody

export(String, "", "p1", "p2") var player
export (String) var playerName
export (int) var playerTextureIX = 0

var gravity : Vector3 = Vector3.DOWN * 14
var velocity : Vector3 = Vector3()
var rotation_factor : float = PI
var camera:Camera = null
var button:Button = null

onready var playerAnimation: AnimationPlayer  =  $Dragon/AnimationPlayer
onready var camera_pivot = $CameraPivot
onready var camera_spring = $CameraPivot/CameraSpring
onready var camera_spacial = $CameraPivot/CameraSpring/CameraSpacial


var fire_breath = preload("res://fire/FireBreath.tscn")
var ice_breath = preload("res://fire/IceBreath.tscn")

# player states
enum STATE {
	IDLE, # on ground
	WALK, # on ground
	WALK_BACK, # on the ground
	RUN, # on ground
	JUMP, # from ground to air
	FALL, # in air, until on the floor
	FLY, # in air, until on the floor
	GLIDE, # in air, until on the floor
	FIRE
}
var playerStateOld = STATE.IDLE
var playerState = STATE.IDLE
var playerStateBeforeFire = playerState

var playerTextures:Array = [
	"res://images/fairy_adult.png",
	"res://images/fairy_adult_b.png",
	"res://images/fairy_adult_e.png",
	"res://images/fairy_adult_p.png",
]


# Called when the node enters the scene tree for the first time.
func _ready():
	var __ = playerAnimation.connect("animation_finished", self, "animation_finished")
	playerAnimation.get_animation("idle").set_loop(true)
	playerAnimation.get_animation("walk").set_loop(true)
	playerAnimation.get_animation("run").set_loop(true)
	playerAnimation.get_animation("glide").set_loop(true)
	playerAnimation.get_animation("fall").set_loop(true)
	playerAnimation.get_animation("hover").set_loop(true)
	playerAnimation.play("idle")
	playerState = STATE.IDLE
	apply_texture($Dragon/Armature/Skeleton/drg_fairy_adult_mesh_0, playerTextures[playerTextureIX])


func apply_texture_color(mesh_instance_node, color):
	var material = SpatialMaterial.new()
	material.albedo_color = Color(color)
	mesh_instance_node.set_material_override(material)


func apply_texture(mesh_instance_node, texture_path):
	var material = SpatialMaterial.new()
	material.albedo_color = Color(0xffffffff)
	mesh_instance_node.set_material_override(material)
	var texture = ImageTexture.new()
	var image = Image.new()
	image.load(texture_path)
	texture.create_from_image(image)
	if mesh_instance_node.material_override:
		mesh_instance_node.material_override.albedo_texture = texture  


func setCamera(c:Camera):
	camera = c


func setButton(b: Button):
	button = b


func signp(f:float):
	if f<0:
		return -1.0
	else:
		return 1.0 


func _physics_process(delta):
	# set camera to follow the player
	var trans = camera_spacial.get_global_transform()
	camera.set_global_transform(trans)
	
	# selecting different dragon
	if Input.is_action_just_pressed(player +"_select") :
		playerTextureIX = ( playerTextureIX + 1 ) % len(playerTextures)
		apply_texture($Dragon/Armature/Skeleton/drg_fairy_adult_mesh_0, playerTextures[playerTextureIX])

	# flying or gliding
	if playerState == STATE.GLIDE:
		velocity += (gravity / 4) * delta
	else: # on the ground or fall
		velocity += gravity * delta
	
	var onGround : bool = is_on_floor()
	var speed : float = 0.0
	var direction = Vector3()
	
	# keep  gravity
	var velocity_y = velocity.y
	velocity = Vector3.ZERO
	velocity.z = 0
	if Input.is_action_pressed(player +"_up"):
		if onGround: 
			playerState = STATE.RUN
			speed = 1.8
		else:
			speed = 2.4
		direction += transform.basis.z
	if Input.is_action_pressed(player +"_down"):
		speed = 0.5
		if onGround: playerState = STATE.WALK_BACK
		direction -= transform.basis.z
	if Input.is_action_pressed(player +"_left"):
		camera_pivot.rotation_degrees.y += signp(speed) * rotation_factor/2
	if Input.is_action_pressed(player +"_right"):
		camera_pivot.rotation_degrees.y -= signp(speed) * rotation_factor/2

	direction = direction.normalized()
	
	velocity = direction * speed
	# rotate camera till it aligned with direction
	if abs(speed) > 0.1 :
		var roty=camera_pivot.rotation_degrees.y
		if abs(roty) > rotation_factor:
			var rotate = sign(roty)*rotation_factor
			rotation_degrees.y += rotate
			camera_pivot.rotation_degrees.y -= rotate
		else:
			rotation_degrees.y += camera_pivot.rotation_degrees.y
			camera_pivot.rotation_degrees.y = 0
	
	#velocity = velocity.linear_interpolate(direction * speed, delta)
	
	if Input.is_action_just_pressed(player +"_B") :
		if onGround:
			velocity_y = 8
			playerState = STATE.JUMP
		else:
			velocity_y = 4
			playerState = STATE.FLY
		$Wings.play()
	
	if Input.is_action_just_pressed(player +"_A") :
		var a 
		if playerTextureIX == 3: a = ice_breath.instance()
		else: a = fire_breath.instance()
		a.start($Position3D.global_transform)
		get_parent().add_child(a)
		playerStateBeforeFire = playerState
		playerState = STATE.FIRE
		$Fire.play()
	
	# restore gravity
	velocity.y = velocity_y
	
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if onGround and velocity.length() < 0.2 and playerState != STATE.FIRE:
		playerState = STATE.IDLE
	
	# if fall off - keep on zero
	if transform.origin.y < 0:
		transform.origin.y = 0

	# set animation
	updateAnimation()


func updateAnimation():
	if(playerStateOld != playerState):
		playerStateOld = playerState
		match playerState:
			STATE.IDLE: 
				playerAnimation.play("idle")
			STATE.WALK:
				playerAnimation.play("walk")
			STATE.WALK_BACK:
				playerAnimation.play_backwards("walk")
			STATE.RUN:
				playerAnimation.play("run", -1, 1.6)
			STATE.JUMP:
				playerAnimation.play("jump")
			STATE.FALL:
				playerAnimation.play("fall")
			STATE.FLY:
				playerAnimation.play("fly")
			STATE.GLIDE:
				playerAnimation.play("glide")
			STATE.FIRE:
				playerAnimation.play("fire")


func animation_finished(anim_name : String):
	if "fly" == anim_name:
		playerState = STATE.GLIDE
	elif "jump" == anim_name:
		playerState = STATE.FALL
	elif "fire" == anim_name:
		playerState = playerStateBeforeFire
	else:
		playerState = STATE.IDLE
	updateAnimation()


func is_dragon():
	pass


var lumas: Array = []


func add_luma(o):
	lumas.append(o)

func get_lumas_count():
	return len(lumas)

func move_lumas(o):
	for l in lumas:
		l.set_final(o)
		lumas = []
