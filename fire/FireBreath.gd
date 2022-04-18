extends Spatial

var speed = 5
var velocity:Vector3

func start(tf):
	transform = tf
	velocity = transform.basis.z * speed

func _process(delta):
	transform.origin += velocity * delta

func _on_Timer_timeout():
	queue_free()
