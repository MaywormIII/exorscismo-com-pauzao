extends KinematicBody

var currentAnim = null
var facing = Vector3(0, 0, -1)

var airAccelRate = 2
var maxSpd = 8

var moveVec = Vector3()
var tiltVec = Vector3()
var analogVec = Vector3()

var friction = 0.5
var accelRate = 0.25+ friction
var gravity = 1.5
#QUASE ENUM MAS N É PQ PREGUIÇA
var state = "IDLE"
var jumpSpd = 12
#time of the jump
const fullJump= 60
#if != 0 is jumping

var varJump = 0
var grabLock = false
var wall_jumps = 0
var tripleJump = 0
var airTime = 10
var max_wall_jumps = 1
var jumpLock = false
var jump
var coyoteJump = null
var wasOnFloor = false
var grab = false
onready var anim = $MonotoriTestBuneco/AnimationPlayer
onready var ground_ray = get_node("Ground_Ray")
onready var front_ray = get_node("MonotoriTestBuneco/Front_Ray")
onready var upper_front_ray = get_node("MonotoriTestBuneco/Upper_Front_Ray")

func _ready():
	
	anim.get_animation("run").set_loop(true)
	coyoteJump = get_node("CoyoteJump")

func _physics_process(delta):
	upper_front_ray.force_raycast_update ( )
	front_ray.force_raycast_update ( )
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
		airTime = 0
		if mv.length() > 0.5:
			targetAnim = "run"
		else:
			targetAnim = "idle"
	else:
		airTime+= 10*delta
		if(varJump> 0 and varJump < fullJump):
			targetAnim = "jumping"
		elif(airTime>2):
			targetAnim = "jump"
		else:
			targetAnim = "run"
#	vira pra onde anda,mude o * para mexer na velocidade de girar
	if(grounded):
		facing += (analogVec.normalized() - facing) * 15 * delta
		facing = facing.normalized()
	facing.y = 0
	get_node("MonotoriTestBuneco").look_at(translation - facing, Vector3(0, 1, 0) + (tiltVec * 0.25))
	
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
		

	var mSpd = maxSpd
	if is_on_floor():
		mSpd *= tiltMagnitude
	if moveVec.length() > mSpd:
		moveVec = moveVec.normalized() * mSpd

	#Gravidade 

#	GRAB
#	exits grab 
	var grabLedge
	if(airTime>1 and !upper_front_ray.is_colliding() and front_ray.is_colliding()):
		jump = false
		grab = true
		grabLedge = true
	if !Input.is_action_pressed("grab") and !grabLedge:
		grab = false
		grabLock = false
	if Input.is_action_just_released("grab"):
		grab = false
		grabLock = false
#	grabLock logic for jumping while grabbed
	if is_on_wall() and Input.is_action_pressed("grab") and !grabLock:
		grab = true
	
#	grabbed state freezes movement
	if(grab):
	
		moveVec = Vector3(0,0,0)
		
#		exits grab and jump
		if Input.is_action_just_pressed("jump"):
			grabLock = true
			grab = false
	if(!grab):
		moveVec.y = yspd - gravity
		
	
	if is_on_floor() || grab:
		coyoteJump.start()
#		letGoPosition = translation
		if not wasOnFloor:
			pass
#			spawnDust()
	
#JUMP	
#Logica de jumplock para evitar pulo continuo Se segurar espaço 
	if(grounded):
		wall_jumps = max_wall_jumps
	if Input.is_action_pressed("jump") and (ground_ray.is_colliding() or grounded or coyoteJump.get_time_left() > 0 or is_on_wall() ) and !jumpLock:
		if is_on_wall():
			wall_jumps-=1
		jump = true
	else:
		jump = false
	if !Input.is_action_pressed("jump") and (ground_ray.is_colliding() or grounded or coyoteJump.get_time_left() > 0 or is_on_wall() ):
		jumpLock = false
#	jump until varjump reaches 20 OR player releases jump
	if(varJump != 0 and Input.is_action_pressed("jump") and varJump < fullJump):
		varJump += 1
		if varJump<fullJump/2:
			moveVec.y = jumpSpd
		else:
			moveVec.y = jumpSpd/4
	if !Input.is_action_pressed("jump") or is_on_ceiling():
		varJump = 0
# jumpar
	if varJump == 0 and jump and (ground_ray.is_colliding() or grounded or coyoteJump.get_time_left() > 0 or is_on_wall() ):
		moveVec.y = jumpSpd
		varJump = 1
		coyoteJump.stop()
		jumpLock = true	
	
	wasOnFloor = is_on_floor()
	
	var prevPos = translation
#	print( get_floor_normal( ))
	#Faz ele simexer
	moveVec = move_and_slide(moveVec, Vector3(0, 1, 0),false,4,0.6)
	
	if not anim.is_playing() or currentAnim != targetAnim:
#		if targetAnim == "PopRun-loop":
#			$DustAnimation.play("PopRunDust")
#		else:
#			$DustAnimation.stop()
		if(!grab):
			anim.play(targetAnim, 0.15)
		currentAnim = targetAnim

	if(state == "MOVING"):
		anim.playback_speed = stepify(tiltMagnitude,0.01)*1.7;
	else:
		anim.playback_speed = 1
	if(grab):
		anim.stop()
		
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
	
func mirror_vel():
	
	
	pass
