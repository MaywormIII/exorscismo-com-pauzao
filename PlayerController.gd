extends KinematicBody

var currentAnim = null
var facing = Vector3(0, 0, -1)

var airAccelRate = 0.5
var maxSpd = 10

var moveVec = Vector3()
var tiltVec = Vector3()
var analogVec = Vector3()

var friction = 2.5
var accelRate = 2 + friction
var gravity = 0.8
var jumpSpd = 20

var coyoteJump = null
var wasOnFloor = false

onready var anim = $MonotoriTestBuneco/AnimationPlayer

func _ready():
	
	anim.get_animation("run").set_loop(true)
	coyoteJump = get_node("CoyoteJump")

func _physics_process(delta):

	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().get_root().queue_free()
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

	#DIreção
	var mv = Vector3()
	#Viradinha
	var tiltMagnitude = 0
	
	var targetAnim = null
	
	#INPUT
	if Input.is_action_pressed("move_r"):
		mv.x -= 1
	if Input.is_action_pressed("move_l"):
		mv.x += 1
		
	if Input.is_action_pressed("move_fw"):
		mv.z += 1
	if Input.is_action_pressed("move_bw"):
		mv.z -= 1
		
	#O tanto q vc aumenta o vector da direção é o quanto ele da a viradinha
	tiltMagnitude = mv.length()
		
	#SENSITIVE CONTROLLER INPUT
	if Input.get_joy_name(0) != null and mv.length() == 0:
		
		mv.x = -Input.get_joy_axis(0, 0)
		mv.z = -Input.get_joy_axis(0, 1)
		#O tanto q vc aumenta o vector da direção é o quanto ele da a viradinha
		tiltMagnitude = mv.length()
		
		#Acho que é uma dead zone. Ainda tenho que experimentar sem isso
		if tiltMagnitude <= 0.1:
			mv.x = 0
			mv.z = 0
		
	mv = mv.normalized()
	
	#Pega direção da camera
	var b = Basis(get_viewport().get_camera().global_transform.basis)
	b.z.y = 0 # Crush Y so movement doesn't go into ground
	b.z = b.z.normalized()
	mv = b.xform(mv)
	
	mv.z *= -1
	mv.x *= -1
	
	if mv.length() > 0:
		analogVec = mv
	
	if is_on_floor():
		if mv.length() > 0:
			targetAnim = "run"
		else:
			targetAnim = "idle"
	else:
		targetAnim = "jump"
	
	facing += (analogVec.normalized() - facing) * .25
	facing = facing.normalized()
	facing.y = 0
	get_node("MonotoriTestBuneco").look_at(translation - facing, Vector3(0, 1, 0) + (tiltVec * .25))
	
	#uns negcio aí de fisica de fricção aí. tendi mt bem n. Sem isso ele não se move.
	if is_on_floor():
		var mt = Vector3(moveVec.x, moveVec.y, moveVec.z)
		mt.y = 0
		if mt.length() > friction:
			var frict = moveVec.normalized() * friction
			frict.y = 0
			moveVec -= frict
		else:
			moveVec.x = 0
			moveVec.z = 0

		if mv.length() > 0:
			moveVec += mv * accelRate
	elif mv.length() > 0:
			moveVec += mv * airAccelRate
	
	#Gravidade
	var yspd = moveVec.y
	moveVec.y = 0
		
	#COMENTA ISSO AQUI E OLHA A DIFERENÇA
	var mSpd = maxSpd
	if is_on_floor():
		mSpd *= tiltMagnitude
	if moveVec.length() > mSpd:
		moveVec = moveVec.normalized() * mSpd
	#ATÉ AQUI
	
	#Gravidade
	moveVec.y = yspd - gravity
	
	if is_on_floor():
		coyoteJump.start()
#		letGoPosition = translation
		if not wasOnFloor:
			print("puerinha")
#			spawnDust()
	
	#Jump Input
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyoteJump.get_time_left() > 0):
		moveVec.y = jumpSpd
		coyoteJump.stop()
	
	wasOnFloor = is_on_floor()
	
	var prevPos = translation
	
	
	
	#Faz ele simexer
	moveVec = move_and_slide(moveVec, Vector3(0, 1, 0))
	
	if not anim.is_playing() or currentAnim != targetAnim:
#		if targetAnim == "PopRun-loop":
#			$DustAnimation.play("PopRunDust")
#		else:
#			$DustAnimation.stop()
		anim.play(targetAnim, 0.1)
		currentAnim = targetAnim
	
	var t = moveVec.normalized()
	if moveVec.length() > 0.01:
		tiltVec += (moveVec.normalized() - tiltVec) * .1
	else:
		tiltVec.x -= tiltVec.x * .1
		tiltVec.y -= tiltVec.y * .1
		tiltVec.z -= tiltVec.z * .1
