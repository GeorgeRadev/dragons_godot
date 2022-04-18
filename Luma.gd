extends KinematicBody

var rotate : Vector3 = Vector3.FORWARD
var followBody : KinematicBody = null

func _ready():
	var color:int = Color.from_hsv(randf(), 0.30, 0.90, 1.0).to_rgba32()
	var material = SpatialMaterial.new()
	material.albedo_color = Color(color)
	$Luma/Luma/Skeleton/Body.set_material_override(material)
	$Luma/AnimationPlayer.get_animation("LumaRig|Luma Idle|Luma Idle").set_loop(true)
	$Luma/AnimationPlayer.play("LumaRig|Luma Idle|Luma Idle",-1, 1 + 0.2 * randf())


func _physics_process(delta):
	if followBody != null:
		var currentPos = transform.origin
		rotate = rotate.rotated(Vector3.UP, delta *  PI).normalized()
		var destinationPos = followBody.transform.origin + (2.5 * rotate)
		var direction = (destinationPos - currentPos)
		# move to destination
		transform.origin += delta * direction
		rotation.y += delta *  PI
	else:
		move_and_collide(Vector3.DOWN)
		rotation.y += delta * abs(randf()) *  2 * PI
	# if fall off - keep on zero
	if transform.origin.y < 0:
		transform.origin.y = 0


func follow(o: KinematicBody):
	followBody = o


func is_luma():
	pass


func set_final(body: KinematicBody):
	followBody = body


func _on_LumaArea_body_entered(body):
	if followBody == null and body.has_method("is_dragon"):
		body.add_luma(self)
		followBody = body
		$Pick.play()
