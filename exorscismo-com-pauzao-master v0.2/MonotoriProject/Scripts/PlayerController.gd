extends KinematicBody

var currentAnim = null
var facing = Vector3(0, 0, -1)

var airAccelRate = 0.4
var maxSpd = 8

var moveVec = Vector3()
var tiltVec = Vector3()
var analogVec = Vector3()

var friction = 2.5
var accelRate = 0.5 + friction
var gravity = 1
#QUASE ENUM MAS N É PQ PREGUIÇA
var state = "IDLE"
var jumpSpd = 12
#time of the jump
const fullJump= 20
#if != 0 is jumping
var varJump = 0
var jumpLock = false
var jump
var coyoteJump = null
var wasOnFloor = false

onready var anim = $MonotoriTestBuneco/AnimationPlayer

func _ready():
	
	anim.get_animation("run").set_loop(true)
	coyoteJump = get_node("CoyoteJump")

func _physics_process(delta):
	var grounded = is_on_floor()
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
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
		if tiltMagnitude <= 0.3:
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
#	vira pra onde anda,mude o * para mexer na velocidade de girar
	if(grounded):
		facing += (analogVec.normalized() - facing) * .2
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

	
#JUMP	
#Logica de jumplock para evitar pulo continuo Se segurar espaço 
	
	if Input.is_action_pressed("jump") and grounded and !jumpLock:
		jump = true
	else:
		jump = false
	if !Input.is_action_pressed("jump") and grounded:
		jumpLock = false
	if(varJump != 0 and Input.is_action_pressed("jump") and varJump < fullJump):
		varJump += 1
		moveVec.y = jumpSpd
	if !Input.is_action_pressed("jump"):
		varJump = 0
		
	if varJump == 0 and jump and (grounded or coyoteJump.get_time_left() > 0):
		moveVec.y = jumpSpd
		varJump = 1
		coyoteJump.stop()
		jumpLock = true	
	
	wasOnFloor = is_on_floor()
	
	var prevPos = translation
	
	
	
	#Faz ele simexer
	moveVec = move_and_slide(moveVec, Vector3(0, 1, 0),true)
	
	if not anim.is_playing() or currentAnim != targetAnim:
#		if targetAnim == "PopRun-loop":
#			$DustAnimation.play("PopRunDust")
#		else:
#			$DustAnimation.stop()
		anim.play(targetAnim, 0.1)
		currentAnim = targetAnim
	
	var t = moveVec.normalized()
	if moveVec.length() > 0.01:
		tiltVec += (moveVec.normalized() - tiltVec) * 1
	else:
		tiltVec.x -= tiltVec.x * .5
		tiltVec.y -= tiltVec.y * .5
		tiltVec.z -= tiltVec.z * .5
#STATE CHOOSER
	if(grounded):
		if stepify(moveVec.x, 0.1) == 0 and stepify(moveVec.z, 0.1) == 0:
			state = "IDLE"
		else:
			state = "MOVING"
	else:
		state = "JUMPING"                                                                                      
	print(state)
