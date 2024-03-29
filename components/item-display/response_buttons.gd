extends Node3D

# this defines that an item display will be created
# preload makes sure the item display is already in memory
var connectedItemDisplay := preload("res://components/item-display/item_display.tscn").instantiate()

###################################################################################################

# as soon as the button is spawned, create the corresponding item display
func _ready() -> void:
	# instantiate the item display
	$ItemDisplayLocation.add_child(connectedItemDisplay)
	# instantiate the objects from the current trial (which is still in the nexttrial group at this point)
	var objects = ExperimentLogic.getNextTrial().get_node("ObjectLayout").duplicate()
	# make the objects visible
	objects.visible = true
	# add the objects as child of the display, to get the corretc position
	$ItemDisplayLocation.get_child(0).add_child(objects)
	# reset all button's glow effects
	$AnswerButtons/SameButton/SameButton/ButtonMesh.material_override.emission_enabled = false
	$AnswerButtons/DifferentButton/DifferentButton/ButtonMesh.material_override.emission_enabled = false
	
	$ConfidenceButtons/Conf_wrong2/Conf_wrong2/ButtonMesh.material_override.emission_enabled = false
	$ConfidenceButtons/Conf_wrong1/Conf_wrong1/ButtonMesh.material_override.emission_enabled = false
	$ConfidenceButtons/Conf_correct1/Conf_correct1/ButtonMesh.material_override.emission_enabled = false
	$ConfidenceButtons/Conf_correct2/Conf_correct2/ButtonMesh.material_override.emission_enabled = false
	# also deactivate the response buttons until they are needed
	$AnswerButtons/SameButton/SameButton.monitoring = false
	$AnswerButtons/DifferentButton/DifferentButton.monitoring = false
	
# switch two objects in the layout
func switch() -> String:
	# get the object locations in an array
	var object_locations = $ItemDisplayLocation.get_node("ItemDisplay").get_node("ObjectLayout")
	
	var hasEmptyLocation = true
	var loc1 : String = ""
	var loc2 : String = ""
	
	# this loop makes sure we only chose non-empty locations
	while hasEmptyLocation:
		# draw two different random numbers
		var IDs = [1, 2, 3, 4, 5, 6, 7]
		IDs.shuffle()
		var ID1 = IDs.pop_front()
		var ID2 = IDs.pop_front()

		# create the location node names
		loc1 = "Location" + str(ID1)
		loc2 = "Location" + str(ID2)

		# stop the loop if both have a object
		if object_locations.get_node(loc1).get_child_count() != 0:
			if object_locations.get_node(loc2).get_child_count() != 0:
				hasEmptyLocation = false
	
	# now do the switch
	# use "reparent(... FALSE)" to actually update the locations
	var temp = Node3D.new()
	object_locations.add_child(temp)
	object_locations.get_node(loc1).get_child(0).reparent(temp, false)
	object_locations.get_node(loc2).get_child(0).reparent(object_locations.get_node(loc1), false)
	temp.get_child(0).reparent(object_locations.get_node(loc2), false)
	temp.queue_free()
	
	return loc1 + loc2

func presentObjectsAfterTimer() -> void:
	# get the item display and show the objects
	$ItemDisplayLocation.get_child(0).present_objects()
	# only from now on the response buttons are registering, so they are not accidentally triggered before
	$AnswerButtons/SameButton/SameButton.monitoring = true
	$AnswerButtons/DifferentButton/DifferentButton.monitoring = true
	# start measuring response time
	ExperimentLogic.getCurrentTrial().get_node("ResponseTimer").start()
	
###################################################################################################

func _response_given(has_changed: bool) -> void:
	var RT : float = 0
	# get the reaction time by calculating how much time has passed since starting the timer
	RT = ExperimentLogic.MAX_RESPONSE_TIME - ExperimentLogic.getCurrentTrial().get_node("ResponseTimer").time_left
	# stop the timer so it does not trigger a slow response error
	ExperimentLogic.getCurrentTrial().get_node("ResponseTimer").stop()
	# put the rt and response correctness into the current trial data
	ExperimentLogic.getCurrentTrial().respone_objects_have_changed = has_changed
	ExperimentLogic.getCurrentTrial().response_time = RT
	# hide the response buttons and show the confidence buttons
	$AnswerButtons/HideResponseButtons.play("hide")

func _confidence_given(conf: int = 0) -> void:
	# get the confidence reaction time
	var conf_RT : float = 0
	# get the reaction time by calculating how much time has passed since starting the timer
	conf_RT = ExperimentLogic.MAX_CONFIDENCE_TIME - ExperimentLogic.getCurrentTrial().get_node("ConfidenceTimer").time_left
	# stop the timer so it does not trigger a slow confidence error
	ExperimentLogic.getCurrentTrial().get_node("ConfidenceTimer").stop()
	# save given confidence response into current trial
	ExperimentLogic.getCurrentTrial().confidence = conf
	ExperimentLogic.getCurrentTrial().confidence_time = conf_RT
	# hide the confidence buttons
	$ConfidenceButtons/ShowConfidenceButtons.play_backwards("show_confidence_buttons")
	# also, since this was the last response, the trial is now finished
	#await get_tree().create_timer(1.0).timeout
	ExperimentLogic.getCurrentTrial().validTrial()
	
###################################################################################################
	
# deactivates bpth response buttons
func _deactivateResponseButtons() -> void:
	$AnswerButtons/SameButton/SameButton.set_deferred("monitoring", false)
	$AnswerButtons/DifferentButton/DifferentButton.set_deferred("monitoring",  false)
	
func _on_same_button_button_pressed(button: Variant) -> void:
	# make the button glow
	$AnswerButtons/SameButton/SameButton/ButtonMesh.material_override.emission_enabled = true
	# register response and go to confidence buttons
	if $AnswerButtons/SameButton/SameButton.monitoring == true:
		_response_given(false)
	# immediately deactivate both buttons to prevent accidental triggering
	_deactivateResponseButtons()
	
############################### ALERT ALERT ALERT ALERT ALERT ALERT ###############################
# the buttons are labelled 'same' and 'different'
# the response_given function expects a true/false answer to !!!whether or not the layout has changed!!!
# so the SAME button should return FALSE (layout has NOT changed)
# and the DIFFERENT button should return TRUE (layout HAS changed)
#
# this is because initially, I wanted the responses to be saved as same/different instead of a 
# true/false boolean. this would have enabled me to easier replicate the buttons to give response
# options the participant to indicate which exact location has changed. since this is however not 
# necessary for my project, I changed this. but renaming all the buttons would be tedious right now,
# so I did not do this... sorry^^
############################### ALERT ALERT ALERT ALERT ALERT ALERT ###############################


func _on_different_button_button_pressed(button: Variant) -> void:
	# make the button glow
	$AnswerButtons/DifferentButton/DifferentButton/ButtonMesh.material_override.emission_enabled = true
	# register response and go to confidence buttons
	if $AnswerButtons/DifferentButton/DifferentButton.monitoring == true:
		_response_given(true)
	# immediately deactivate both buttons to prevent accidental triggering
	_deactivateResponseButtons()
	

# as soon as the response buttons are hidden, reveal the confidence buttons
func _on_hide_response_buttons_animation_finished(anim_name: StringName) -> void:
	$ConfidenceButtons/ShowConfidenceButtons.play("show_confidence_buttons")

# onlly start registering answers once the buttons stopped moving
func _on_show_confidence_buttons_animation_finished(anim_name: StringName) -> void:
	# once the confidence buttons are completely visible and stopped moving, start confidence timer
	ExperimentLogic.getCurrentTrial().get_node("ConfidenceTimer").start()
	# enable the buttons (so earlier responses while still moving are not counted)
	$ConfidenceButtons/Conf_wrong2/Conf_wrong2.set_deferred("monitoring", true)
	$ConfidenceButtons/Conf_wrong1/Conf_wrong1.set_deferred("monitoring", true)
	$ConfidenceButtons/Conf_correct1/Conf_correct1.set_deferred("monitoring", true)
	$ConfidenceButtons/Conf_correct2/Conf_correct2.set_deferred("monitoring", true)

# in case multiple confidence buttons are triggered, there will be 2 trials in current trial
# to prevent this, immediately disable all buttons after one collision was detected
func _deactivateConfidenceButtons() -> void:
	$ConfidenceButtons/Conf_wrong2/Conf_wrong2.set_deferred("monitoring", false)
	$ConfidenceButtons/Conf_wrong1/Conf_wrong1.set_deferred("monitoring", false)
	$ConfidenceButtons/Conf_correct1/Conf_correct1.set_deferred("monitoring", false)
	$ConfidenceButtons/Conf_correct2/Conf_correct2.set_deferred("monitoring", false)

func _on_conf_wrong_2_button_pressed(_button: Variant) -> void: 
	# make the button glow
	$ConfidenceButtons/Conf_wrong2/Conf_wrong2/ButtonMesh.material_override.emission_enabled = true
	# only register an answer and proceed if we actually exppect an answer
	if $ConfidenceButtons/Conf_wrong2/Conf_wrong2.monitoring == true:
		_confidence_given(-2)
	# now deactivate all buttons
	_deactivateConfidenceButtons()

func _on_conf_wrong_1_button_pressed(_button: Variant) -> void:
	$ConfidenceButtons/Conf_wrong1/Conf_wrong1/ButtonMesh.material_override.emission_enabled = true
	# only register an answer and proceed if we actually exppect an answer
	if $ConfidenceButtons/Conf_wrong1/Conf_wrong1.monitoring == true:
		_confidence_given(-1)
	_deactivateConfidenceButtons()

func _on_conf_correct_1_button_pressed(_button: Variant) -> void:
	$ConfidenceButtons/Conf_correct1/Conf_correct1/ButtonMesh.material_override.emission_enabled = true
	# only register an answer and proceed if we actually exppect an answer
	if $ConfidenceButtons/Conf_correct1/Conf_correct1.monitoring == true:
		_confidence_given(1)
	_deactivateConfidenceButtons()

func _on_conf_correct_2_button_pressed(_button: Variant) -> void:
	$ConfidenceButtons/Conf_correct2/Conf_correct2/ButtonMesh.material_override.emission_enabled = true
	# only register an answer and proceed if we actually exppect an answer
	if $ConfidenceButtons/Conf_correct2/Conf_correct2.monitoring == true:
		_confidence_given(2)
	_deactivateConfidenceButtons()

# haptic feedback responses for pressed buttons
# make sure that all buttons connect to this signal
func _on_ANY_button_body_entered(body: Node3D) -> void:
	body.find_parent("XRController*").trigger_haptic_pulse("haptic", 10, 15, 0.1, 0.1)

