/*
Difficulty: Hard
*/

/mob/living/simple_animal/hostile/megafauna/wendigo
	name = "wendigo"
	desc = "A mythological man-eating legendary creature, you probably aren't going to survive this."
	health = 2500
	maxHealth = 2500
	icon_state = "wendigo"
	icon_living = "wendigo"
	icon_dead = "wendigo_dead"
	icon = 'icons/mob/icemoon/64x64megafauna.dmi'
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	weather_immunities = list(TRAIT_SNOWSTORM_IMMUNE)
	speak_emote = list("roars")
	armour_penetration = 40
	melee_damage_lower = 40
	melee_damage_upper = 40
	vision_range = 9
	aggro_vision_range = 18 // man-eating for a reason
	speed = 8
	move_to_delay = 8
	rapid_melee = 16 // every 1/8 second
	melee_queue_distance = 20 // as far as possible really, need this because of charging and teleports
	ranged = TRUE
	pixel_x = -16
	loot = list(/obj/item/wendigo_blood)
	crusher_loot = list(/obj/item/wendigo_blood, /obj/item/crusher_trophy/demon_claws)
	wander = FALSE
	del_on_death = TRUE
	blood_volume = BLOOD_VOLUME_NORMAL
	achievement_type = /datum/award/achievement/boss/wendigo_kill
	crusher_achievement_type = /datum/award/achievement/boss/wendigo_crusher
	score_achievement_type = /datum/award/score/wendigo_score
	deathmessage = "falls, shaking the ground around it"
	deathsound = 'sound/effects/gravhit.ogg'
	attack_action_types = list(/datum/action/innate/megafauna_attack/heavy_stomp,
							   /datum/action/innate/megafauna_attack/teleport,
							   /datum/action/innate/megafauna_attack/disorienting_scream)
	/// Saves the turf the megafauna was created at (spawns exit portal here)
	var/turf/starting
	/// Range for wendigo stomping when it moves
	var/stomp_range = 1
	/// Stores directions the mob is moving, then calls that a move has fully ended when these directions are removed in moved
	var/stored_move_dirs = 0
	/// If the wendigo is allowed to move
	var/can_move = TRUE

/datum/action/innate/megafauna_attack/heavy_stomp
	name = "Heavy Stomp"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	chosen_message = "<span class='colossus'>You are now stomping the ground around you.</span>"
	chosen_attack_num = 1

/datum/action/innate/megafauna_attack/teleport
	name = "Teleport"
	icon_icon = 'icons/effects/bubblegum.dmi'
	button_icon_state = "smack ya one"
	chosen_message = "<span class='colossus'>You are now teleporting at the target you click on.</span>"
	chosen_attack_num = 2

/datum/action/innate/megafauna_attack/disorienting_scream
	name = "Disorienting Scream"
	icon_icon = 'icons/turf/walls/wall.dmi'
	button_icon_state = "wall"
	chosen_message = "<span class='colossus'>You are now screeching, disorienting targets around you.</span>"
	chosen_attack_num = 3

/mob/living/simple_animal/hostile/megafauna/wendigo/Initialize(mapload)
	. = ..()
	starting = get_turf(src)

/mob/living/simple_animal/hostile/megafauna/wendigo/OpenFire()
	SetRecoveryTime(0, 100)
	if(health <= maxHealth*0.5)
		stomp_range = 2
		speed = 6
		move_to_delay = 6
	else
		stomp_range = initial(stomp_range)
		speed = initial(speed)
		move_to_delay = initial(move_to_delay)

	if(client)
		switch(chosen_attack)
			if(1)
				heavy_stomp()
			if(2)
				teleport()
			if(3)
				disorienting_scream()
		return

	chosen_attack = rand(1, 3)
	switch(chosen_attack)
		if(1)
			heavy_stomp()
		if(2)
			teleport()
		if(3)
			disorienting_scream()

/mob/living/simple_animal/hostile/megafauna/wendigo/Move(atom/newloc, direct)
	if(!can_move)
		return
	stored_move_dirs |= direct
	return ..()

/mob/living/simple_animal/hostile/megafauna/wendigo/Moved(atom/oldloc, direct)
	. = ..()
	stored_move_dirs &= ~direct
	if(!stored_move_dirs)
		INVOKE_ASYNC(src, PROC_REF(ground_slam), stomp_range, 1)

/// Slams the ground around the wendigo throwing back enemies caught nearby
/mob/living/simple_animal/hostile/megafauna/wendigo/proc/ground_slam(range, delay)
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(range, orgin)
	for(var/i = 0 to range)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			playsound(T,'sound/effects/bamf.ogg', 600, TRUE, 10)
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/L in T)
				if(L == src || L.throwing)
					continue
				to_chat(L, "<span class='userdanger'>[src]'s ground slam shockwave sends you flying!</span>")
				var/turf/thrownat = get_ranged_target_turf_direct(src, L, 8, rand(-10, 10))
				L.throw_at(thrownat, 8, 2, src, TRUE)		//, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
				L.apply_damage(20, BRUTE, wound_bonus=10)
				shake_camera(L, 2, 1)
			all_turfs -= T
		sleep(delay)

/// Larger but slower ground stomp
/mob/living/simple_animal/hostile/megafauna/wendigo/proc/heavy_stomp()
	can_move = FALSE
	ground_slam(5, 2)
	SetRecoveryTime(0, 0)
	can_move = TRUE

/// Teleports to a location 4 turfs away from the enemy in view
/mob/living/simple_animal/hostile/megafauna/wendigo/proc/teleport()
	var/list/possible_ends = list()
	for(var/turf/T in view(4, target.loc) - view(3, target.loc))
		if(isclosedturf(T))
			continue
		possible_ends |= T
	var/turf/end = pick(possible_ends)
	do_teleport(src, end, 0,  channel=TELEPORT_CHANNEL_BLUESPACE, forced = TRUE)
	SetRecoveryTime(20, 0)

/// Shakes all nearby enemies screens and animates the wendigo shaking up and down
/mob/living/simple_animal/hostile/megafauna/wendigo/proc/disorienting_scream()
	can_move = FALSE
	playsound(src, 'sound/magic/demon_dies.ogg', 600, FALSE, 10)
	animate(src, pixel_z = rand(5, 15), time = 1, loop = 6)
	animate(pixel_z = 0, time = 1)
	for(var/mob/living/L in get_hearers_in_view(7, src) - src)
		shake_camera(L, 30, 1)
		to_chat(L, "<span class='danger'>The wendigo screams loudly!</span>")
	SetRecoveryTime(30, 0)
	SLEEP_CHECK_DEATH(12)
	can_move = TRUE
	return

/mob/living/simple_animal/hostile/megafauna/wendigo/death(gibbed, list/force_grant)
	if(health > 0)
		return
	var/obj/effect/portal/permanent/one_way/exit = new /obj/effect/portal/permanent/one_way(starting)
	exit.id = "wendigo arena exit"
	exit.add_atom_colour(COLOR_RED_LIGHT, ADMIN_COLOUR_PRIORITY)
	exit.set_light(20, 1, LIGHT_COLOR_RED)
	return ..()

/obj/item/wendigo_blood
	name = "bottle of wendigo blood"
	desc = "You're not actually going to drink this, are you?"
	icon = 'icons/obj/wizard.dmi'
	icon_state = "vial"

/obj/item/wendigo_blood/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(!H.mind)
		return
	to_chat(H, "<span class='danger'>Power courses through you! You can now shift your form at will.</span>")
	var/obj/effect/proc_holder/spell/targeted/shapeshift/polar_bear/P = new
	H.mind.AddSpell(P)
	playsound(H.loc,'sound/items/drink.ogg', rand(10,50), TRUE)
	qdel(src)

/obj/effect/proc_holder/spell/targeted/shapeshift/polar_bear
	name = "Polar Bear Form"
	desc = "Take on the shape of a polar bear."
	invocation = "RAAAAAAAAWR!"
	convert_damage = FALSE

	shapeshift_type = /mob/living/simple_animal/hostile/asteroid/polarbear


//// ERP Vendiga (👁,‿,👁)

/mob/living/simple_animal/wendigo
	name = "wendigo"
	desc = "A mythological man-eating legendary creature, you probably aren't going to survive this."
	health = 2500
	maxHealth = 2500
	icon_state = "wendigo_noblood"
	icon_living = "wendigo_noblood"
	icon_dead = "wendigo_dead"
	icon = 'icons/mob/icemoon/64x64megafauna.dmi'
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	weather_immunities = list(TRAIT_SNOWSTORM_IMMUNE) // to ADD: Trait lewd summon
	speak_emote = list("roars")
	melee_damage_lower = 10
	melee_damage_upper = 20
	obj_damage = 20
	pixel_x = -16
	loot = list(/obj/item/wendigo_blood)
	blood_volume = BLOOD_VOLUME_NORMAL
	deathmessage = "falls, shaking the ground around it"
	deathsound = 'sound/effects/gravhit.ogg'
	/// Saves the turf the megafauna was created at (spawns exit portal here)
	var/turf/starting
	/// Range for wendigo stomping when it moves
	var/stomp_range = 1
	/// Stores directions the mob is moving, then calls that a move has fully ended when these directions are removed in moved
	var/stored_move_dirs = 0
	/// If the wendigo is allowed to move
	var/can_move = TRUE

/mob/living/simple_animal/wendigo/Initialize(mapload)
	. = ..()
	AddSpell(new /obj/effect/proc_holder/spell/targeted/night_vision/qareen(null))
	AddSpell(new /obj/effect/proc_holder/spell/targeted/telepathy/qareen(null))
	START_PROCESSING(SSobj, src)

/mob/living/simple_animal/wendigo/verb/switch_gender()
	set name = "Switch Gender"
	set desc = "Allows you to set your gender."
	set category = "Wendigo"

	if(stat != CONSCIOUS)
		to_chat(usr, span_warning("You cannot toggle your gender while unconcious!"))
		return

	var/choice = tgui_alert(usr, "Select Gender.", "Gender", list("Both", "Male", "Female", "None"))

	switch(choice)
		if("Both")
			has_penis = TRUE
			has_balls = TRUE
			has_vagina = TRUE
			gender = PLURAL
		if("Male")
			has_penis = TRUE
			has_balls = TRUE
			has_vagina = FALSE
			gender = MALE
		if("Female")
			has_penis = FALSE
			has_balls = FALSE
			has_vagina = TRUE
			gender = FEMALE
		if("None")
			has_penis = FALSE
			has_balls = FALSE
			has_vagina = FALSE
			gender = NEUTER

/// открывашка


/mob/living/simple_animal/wendigo/UnarmedAttack(atom/A, proximity, intent = a_intent, flags = NONE)
	if(istype(A, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/B = A
		try_open_airlock(B)
	else
		..()


/mob/living/simple_animal/wendigo/proc/try_open_airlock(obj/machinery/door/airlock/D)
	if(D.operating)
		return
	if(D.welded)
		to_chat(src, "<span class='warning'>The door is welded.</span>")
	else if(D.locked)
		to_chat(src, "<span class='warning'>The door is bolted.</span>")
	else if(D.allowed(src))
		if(D.density)
			D.open(TRUE)
		else
			D.close(TRUE)
		return TRUE
	else
		visible_message("<span class='danger'>[src] forces the door!</span>")
		playsound(src.loc, "sparks", 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		if(D.density)
			D.open(TRUE)
		else
			D.close(TRUE)
		return TRUE

/mob/living/simple_animal/wendigo/ObjBump(obj/O)
	if(istype(O, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/L = O
		if(L.density) // must check density here, to avoid rapid bumping of an airlock that is in the process of opening, instantly forcing it closed
			return try_open_airlock(L)
	if(istype(O, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/F = O
		if(F.density && !F.welded)
			F.open()
			return 1
	. = ..()

//// невидимость в тени (-(-_-(-_(-_(-_-)_-)-_-)_-)_-)-)

/mob/living/simple_animal/wendigo/process(delta_time)
	var/turf/T = src.loc
	if(istype(T))
		var/light_amount = T.get_lumcount()

		if(light_amount < 0.3)
			//src.alpha = max(0, src.alpha - 55)
			animate(src, alpha = 0, time = 10)
		else
			//src.alpha = min(255, src.alpha + 55)
			animate(src, alpha = 255, time = 30)
