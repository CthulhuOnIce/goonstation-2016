/obj/artifact/monkeyfier
	name = "artifact human2monkey converter"
	associated_datum = /datum/artifact/monkeyfier

/datum/artifact/monkeyfier
	associated_object = /obj/artifact/monkeyfier
	rarity_class = 3
	validtypes = list("martian")
	validtriggers = list(/datum/artifact_trigger/carbon_touch)
	react_xray = list(15,90,90,11,"HOLLOW")
	touch_descriptors = list("As you put your ear closer you can hear monkey noises inside, what the heck?.")
	var/mob/living/prisoner = null
	var/list/work_sounds = list('sound/misc/burp.ogg','sound/items/bikehorn.ogg','sound/misc/poo2.ogg','sound/effects/splat.ogg','sound/misc/dogbark.ogg','sound/voice/monkey_scream.ogg')

	effect_touch(var/obj/O,var/mob/living/user)
		if (..())
			return
		if (!user)
			return
		if (prisoner)
			return
		if (istype(user,/mob/living/carbon/human/) && !ismonkey(user))
			O.visible_message("<span style=\"color:red\"><b>[O]</b> suddenly pulls [user.name] inside and slams shut!</span>")
			user.emote("scream")
			user.set_loc(O)
			prisoner = user
			var/loops = rand(15,25)
			while (loops > 0)
				loops--
				user.paralysis = 3
				playsound(user.loc, pick(work_sounds), 50, 1, -1)
				sleep(5)
			ArtifactLogs(user, null, O, "touched", "monkeying user", 0) // Added (Convair880).
			random_brute_damage(user, 15)
			var/mob/living/carbon/human/M = user
			M.monkeyize()
			M.bioHolder.AddEffect("monkey_speak")
			for(var/obj/I in O.contents)
				I.set_loc(get_turf(O))
			prisoner.set_loc(get_turf(O))
			prisoner = null
			O.visible_message("<span style=\"color:red\"><b>[O]</b> releases [user.name] and shuts down!</span>")
			O.ArtifactDeactivated()
		else
			return