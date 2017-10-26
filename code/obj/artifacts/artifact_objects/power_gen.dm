/obj/machinery/artifact/power_gen
	name = "artifact power generator"
	associated_datum = /datum/artifact/power_gen
	var/datum/light/light

	New()
		..()
		light = new /datum/light/point
		light.set_brightness(1)
		light.set_color(0, 1, 1)
		light.attach(src)

/datum/artifact/power_gen
	associated_object = /obj/machinery/artifact/power_gen
	rarity_class = 4
	validtypes = list("ancient")
	validtriggers = list(/datum/artifact_trigger/electric,/datum/artifact_trigger/carbon_touch,/datum/artifact_trigger/silicon_touch)
	activated = 0
	activ_text = "begins to emit an electric hum!"
	deact_text = "shuts down, returning gravity to normal!"
	examine_hint = "It is sparking with electricity."
	deact_sound = 'sound/effects/singsuck.ogg'
	react_xray = list(10,90,80,10,"NONE")
	touch_descriptors = list("You can feel the electricity flowing through this thing.")
	var/gen_rate = 0
	var/gen_level = 0
	var/mode = 0
	var/obj/cable/attached
	var/list/spark_sounds = list('sound/effects/sparks1.ogg','sound/effects/sparks2.ogg','sound/effects/sparks3.ogg','sound/effects/sparks4.ogg','sound/effects/sparks5.ogg','sound/effects/sparks6.ogg')

	New()
		..()
		gen_rate = rand(500000,5000000) // max 5MW
		gen_level = round(gen_rate / 500000) // levels from 1-10

	effect_touch(var/obj/O,var/mob/living/user)
		if (..())
			return
		var/datum/effects/system/spark_spread/s = unpool(/datum/effects/system/spark_spread)
		s.set_up(4, 1, user)
		s.start()
		user.shock(O, rand(5000, gen_rate / 4))
		if(mode == 0)
			var/turf/T = get_turf(O)
			if(isturf(T) && !T.intact)
				attached = locate() in T
				if(!attached)
					boutput(user, "No exposed data terminal here to attach to.")
				else
					O.anchored = 1
					mode = 2
					boutput(user, "[O] connects itself to the terminal. Weird.")
					playsound(O, "sound/effects/ship_charge.ogg", 200, 1)
					var/obj/machinery/artifact/power_gen/L = O
					if (L.light)
						L.light.enable()
			else
				boutput(user, "[O] must be placed over a data terminal to attach to it.")
		else
			O.anchored = 0
			mode = 0
			attached = 0
			boutput(user, "[O] disconnects itself from the terminal.")
			playsound(O, "sound/effects/shielddown2.ogg", 200, 1, 0, 2)
			var/obj/machinery/artifact/power_gen/L = O
			if (L.light)
				L.light.disable()

	effect_process(var/obj/O)
		if (..())
			return
		if(attached)
			var/datum/powernet/PN = attached.get_powernet()
			if(PN)
				PN.newavail += gen_rate
				var/turf/T = get_turf(O)
				playsound(O, "sound/machines/engine_highpower.ogg", 100, 1, 0, 1)
				if (prob(10))
					playsound(O, "sound/effects/screech2.ogg", 200, 1)
					fireflash(O, rand(1,max(2,gen_level)))
					O.visible_message("<span style=\"color:red\">[O] erupts in flame!</span>")
				if (prob(5))
					playsound(O, "sound/effects/screech2.ogg", 200, 1)
					O.visible_message("<span style=\"color:red\">[O] rumbles!</span>")
					for (var/mob/M in range(gen_level+3,T))
						shake_camera(M, 5, 1)
						M.weakened += rand(2,4)
					for (var/turf/TF in range(max(2,gen_level),T))
						animate_shake(TF,5,1 * get_dist(TF,T),1 * get_dist(TF,T))
					if (gen_level >= 5)
						for (var/obj/window/W in range(gen_level-4, T))
							W.health = 0
							W.smash()
				if (prob(5))
					playsound(O, "sound/effects/screech2.ogg", 200, 1)
					O.visible_message("<span style=\"color:red\">[O] sparks violently!</span>")
					for (var/mob/M in range(gen_level+3,T))
						arcFlash(O, M, gen_rate/2)
		else
			playsound(O, pick(spark_sounds), 200, 1)