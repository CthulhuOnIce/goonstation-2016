//makes multiple Spatial Tears
/datum/random_event/major/spatial_tears
	name = "Multiple Spatial Tears"
	centcom_headline = "Spatial Anomaly"
	centcom_message = "A very severe spatial anomaly has been detected near the station. Personnel are advised to avoid any unusual phenomenae."
	required_elapsed_round_time = 6000 // 10m
	var/list/tears = new()

	event_effect(var/source)
		..()
		var/r = rand(3, 7)
		for (var/i = 0 to r)
			var/datum/spatial_tears/tear/tear = new(source)
			tears.Add(tear)

//makes a single spatial tear
/datum/random_event/major/spatial_tear
	name = "Spatial Tear"
	centcom_headline = "Spatial Anomaly"
	centcom_message = "A severe spatial anomaly has been detected near the station. Personnel are advised to avoid any unusual phenomenae."
	required_elapsed_round_time = 6000 // 10m
	var/list/tears = new()

	event_effect(var/source)
		..()
		var/datum/spatial_tears/tear/tear = new(source)

		tears.Add(tear)

//Named so because I don't want this induvidual tear being triggered by events, 
// and I didn't want to mess with the admin spawn and major events code. 
/datum/spatial_tears/tear
	//turfs North/East and South/West of corresponding tears stored for player teleportation
	var/list/turfsSW = new()
	var/list/turfsNE = new()
	var/btype
	var/barrier_duration

	New(var/source)
		barrier_duration = rand(600, 3000)
		var/pickx = rand(40,175)
		var/picky = rand(75,140)
		btype = rand(1,2)
		var/count = btype == 1 ? world.maxy : world.maxx
		if (btype == 1)
			// Vertical
			while (count > 0)
				var/obj/forcefield/event/B = new /obj/forcefield/event(locate(pickx,count,1),barrier_duration, src)
				B.icon_state = "spat-v"
				count -= 1
				
				turfsSW.Add(locate(B.x-1, B.y, 1))
				turfsNE.Add(locate(B.x+1, B.y, 1))

		else
			// Horizontal
			while (count > 0)
				var/obj/forcefield/event/B = new /obj/forcefield/event(locate(count,picky,1),barrier_duration, src)
				B.icon_state = "spat-h"
				count -= 1

				turfsSW.Add(locate(B.x, B.y-1, 1))
				turfsNE.Add(locate(B.x, B.y+1, 1))

		if (turfsSW && turfsNE)
			remove_bad_turfs(turfsSW)
			remove_bad_turfs(turfsNE)

		spawnCritters()

	//loops through the list of all turfs and removes any that are dense or space
	proc/remove_bad_turfs(var/list/turfs)
		for(var/turf/T in turfs)
			if(istype(T,/turf/space) || (T.density))
				turfs.Remove(T)

		return turfs

	// selects a random amount of times to spawn critter
	proc/spawnCritters()
		var/amountSpawned = rand(4, 12)
		while(amountSpawned > 0)
			var/r = rand(0,1)
			if (r && src.turfsNE && src.turfsNE.len > 0)
				pick_critter_to_spawn(pick(src.turfsNE))
			else if (src.turfsSW && src.turfsSW.len > 0)
				pick_critter_to_spawn(pick(src.turfsSW))
			amountSpawned--

	proc/pick_critter_to_spawn(turf/T)
		pick(
			prob(20)
				new /obj/critter/wendigo(T),
			prob(30)
				new /obj/critter/maneater(T);
			prob(30)
				new /obj/critter/spider/spacerachnid(T),
			prob(30)
				new /obj/critter/spider/ice(T),
			prob(40)
				new /obj/critter/martian/soldier(T),
			prob(40)
				new /obj/critter/martian/warrior(T),
			prob(50)
				new /obj/critter/magiczombie(T), //Skeleton
			prob(80)
				new /obj/critter/bear(T),
			prob(100)
				new /obj/critter/floateye(T),
			prob(100)
				new /obj/critter/spacebee(T),
		)

		//originally wanted to pick from list of critters, but problems abound.
		//leaving this here if someone more knowledgable than I wants to make it work
		// var/datum/adventure_submode/critter/adv = new() // instantiating for statics grghhgh.
		// var/type = pick(adv.critters)
		// new type(T)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/obj/forcefield/event
	name = "Spatial Tear"
	desc = "A breach in the spatial fabric. Extremely difficult to pass."
	icon = 'icons/effects/effects.dmi'
	icon_state = "spat-h"
	anchored = 1.0
	opacity = 1
	density = 0
	layer = NOLIGHT_EFFECTS_LAYER_BASE
	var/datum/spatial_tears/tear/tear

	New(loc,duration, datum/spatial_tears/tear/spatialTear)
		..()
		tear = spatialTear
		spawn(duration)
			qdel(src)
			if (src.tear != null)
				src.tear = null

	//Critters can't pass through the tear, unfair I know.
	CanPass(atom/movable/A, turf/target)
		if (ishuman(A)) return 1
		if (issilicon(A)) return 1

		return 0

	HasEntered(atom/A, turf/OldLoc)
		if (istype(A, /mob/living))
			var/mob/living/M = A
			if (istype(tear, /datum/spatial_tears/tear))
				var/datum/spatial_tears/tear/T = tear
				handle_damage(M)
				handle_teleport(T, M, OldLoc)

	//Handle assigning damage to various mobs that can pass through, currently only humans and cyborgs can pass
	proc/handle_damage(mob/living/M)
		var/damage = rand(10, 40)
		if (istype(M, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = M
			H.remove_stamina(50)
			var/damage_zone = pick(H.organs)
			var/brute = 0
			var/burn = 0
			var/tox = 0
			pick(
				prob(100)
					brute = do_brute_and_sever(H, damage),
				prob(75)
					burn = damage,
				prob(75)
					tox = damage,
				)
			H.TakeDamage(damage_zone, brute, burn, tox, 0, 0)

		else if (istype(M, /mob/living/silicon))
			var/mob/living/silicon/robot/S = M
			//stolen from robot.dm not sure how else to damage silicons. I guess the other silicons like the AI get a free pass
			//Honestly at first I was considering making silicons take no damage, so I don't know if we even want this
			for (var/obj/item/parts/robot_parts/RP in S.contents)
				if (RP.ropart_take_damage(damage,damage) == 1) S.compborg_lose_limb(RP)

	//limb loss stolen from bigfart.dm
	//I couldn't find any proc for a mob that sever's a limb that you provide, if such a thing exists then this should be removed since copying code is bad,
	//but this works for severing a limb for now and adding a proc to human.dm for removing a limb is beyond the scope of changing spatial tears.
	proc/do_brute_and_sever(mob/living/carbon/human/H, var/damage)
		var/list/possible_limbs = list()
		var/static/limbloss_prob = 50

		if (H.limbs.l_arm)
			possible_limbs += H.limbs.l_arm
		if (H.limbs.r_arm)
			possible_limbs += H.limbs.r_arm
		if (H.limbs.l_leg)
			possible_limbs += H.limbs.l_leg
		if (H.limbs.r_leg)
			possible_limbs += H.limbs.r_leg

		if (possible_limbs.len)

			//loop through, only sever one limb though, don't want to go too crazy
			for (var/obj/item/parts/P in possible_limbs)
				if (prob(limbloss_prob))
					H.show_text("Your [P] was severed while trying to cross the Spatial Tear!", "red")
					P.sever()
					break;
		return damage

	//Detemines which way to teleport the mob to
	proc/handle_teleport(datum/spatial_tears/tear/T, var/mob/living/M, var/turf/OldLoc)
		if (T == null)
			//Something's broken. Are there asset statements or error logs to print this error to?
			return
		if (T.btype == 1)
			//user entered from the West
			if (OldLoc.x < src.x)
				teleport(M, T.turfsNE)
			//user entered from the East
			else
				teleport(M, T.turfsSW)
		else
			//user entered from the South
			if (OldLoc.y < src.y)
				teleport(M, T.turfsNE)
			//user entered from the North
			else
				teleport(M, T.turfsSW)

	//Selects a random turf from the list and teleports the Human to that turf.
	proc/teleport(mob/living/M as mob, var/list/L)
		//stolen sound from wizard Blink ability.
		playsound(M.loc, "sound/effects/mag_teleport.ogg", 25, 1, -1)

		var/turf/picked = null
		if (L.len) 
			picked = pick(L)
		if(!isturf(picked))
			boutput(M, "<span style=\"color:red\">You can't pass through, there must be nowhere to go.</span>")
			return
		M.set_loc(picked)
