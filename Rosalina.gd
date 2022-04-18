extends KinematicBody


export (int) var needToCollect = 20

# player states
enum STATE {
	IDLE,
	TALK,
	BRAVO
}
var playerStateOld = STATE.IDLE
var playerState = STATE.IDLE
var collectedLumas:int = 0

var velocity : Vector3 = Vector3.DOWN * 0.2

onready var playerAnimation: AnimationPlayer  =  $Rosalina/AnimationPlayer

onready var eyes:Array = [
	$Rosalina/Armature/Skeleton/eyes,
	$Rosalina/Armature/Skeleton/eyes_closed,
	$Rosalina/Armature/Skeleton/eyes_closed_smile,
	$Rosalina/Armature/Skeleton/eyes_down,
	$Rosalina/Armature/Skeleton/eyes_left,
	$Rosalina/Armature/Skeleton/eyes_right,
	$Rosalina/Armature/Skeleton/eyes_open,
	$Rosalina/Armature/Skeleton/eyes_suspicious,
	$Rosalina/Armature/Skeleton/eyes_up
]
onready var eyelashes:Array = [
	$Rosalina/Armature/Skeleton/eyelashes_closed_smile,
	$Rosalina/Armature/Skeleton/eyelashes_open,
	$Rosalina/Armature/Skeleton/eyelashes_down,
]
onready var mouth:Array = [
	$Rosalina/Armature/Skeleton/mouth,
	$Rosalina/Armature/Skeleton/mouth_smile,
	$Rosalina/Armature/Skeleton/mouth_open_smile,
	$Rosalina/Armature/Skeleton/mouth_a,
	$Rosalina/Armature/Skeleton/mouth_e,
	$Rosalina/Armature/Skeleton/mouth_i,
	$Rosalina/Armature/Skeleton/mouth_o,
	$Rosalina/Armature/Skeleton/mouth_u
]

func _ready():
	var __ = playerAnimation.connect("animation_finished", self, "animation_finished")
	playerAnimation.get_animation("idle").set_loop(true)
	playerAnimation.get_animation("talk").set_loop(true)
	playerAnimation.get_animation("bravo").set_loop(true)
	playerAnimation.play("idle")
	playerState = STATE.IDLE
	
	for o in eyelashes: o.hide()
	for o in eyes: o.hide()
	eyes[0].show()
	speakOff()
	$Find.play()


func speakOff():
	speakOn = false
	for o in mouth: o.hide()
	mouth[0].show()


var blink:float = 0
var blinkOpen:bool = false
var speak:float = 0
var speakOn:bool = false
var speakIX:int = 0


func _physics_process(delta):
	velocity = move_and_slide(velocity, Vector3.UP)
	# rotate to the nearest player
	if blinkOpen:
		if blink > 2:
			blink = 0
			blinkOpen = not blinkOpen
			eyes[0].hide()
			eyes[1].show()
	else:
		if blink > 0.8:
			blink = 0
			blinkOpen = not blinkOpen
			eyes[0].show()
			eyes[1].hide()
	blink += delta
	
	if speakOn:
		if speak > 0.1:
			speak = 0
			mouth[speakIX].hide()
			speakIX = (speakIX + 1) % len(mouth)
			mouth[speakIX].show()
		speak += delta
	
	# if fall off - keep on zero
	if transform.origin.y < 0:
		transform.origin.y = 0
	
	updateAnimation()


func updateAnimation():
	if(playerStateOld != playerState):
		playerStateOld = playerState
		match playerState:
			STATE.IDLE: 
				playerAnimation.play("idle")
			STATE.TALK:
				playerAnimation.play("talk", 0.5)
			STATE.BRAVO:
				playerAnimation.play("bravo", 0.1)


func animation_finished(anim_name : String):
	if "bravo" == anim_name:
		playerState = STATE.IDLE
	updateAnimation()


func is_rosalina():
	pass


func get_collected_lumas():
	return collectedLumas

var gotoNextLevel:bool = false
func goto_next_level():
	return gotoNextLevel

func _on_RosalinaArea_body_entered(body):
	if body.has_method("is_dragon") and speakOn == false:
		if body.get_lumas_count() > 0:
			collectedLumas += body.get_lumas_count()
			body.move_lumas(self)
			playerState = STATE.BRAVO
			speakOn = true
			$ThankYou.play()
			yield(get_tree().create_timer(3.3), "timeout")
			playerState = STATE.IDLE
			speakOff()
			if collectedLumas >= needToCollect:
				yield(get_tree().create_timer(2), "timeout")
				gotoNextLevel = true
		elif playerState == STATE.IDLE:
			playerState = STATE.TALK
			speakOn = true
			$Find.play()
			yield(get_tree().create_timer(3.9), "timeout")
			playerState = STATE.IDLE
			speakOff()
	
			
