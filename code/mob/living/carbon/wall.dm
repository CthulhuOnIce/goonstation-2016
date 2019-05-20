/mob/living/carbon/wall
	name = "living wall"
	real_name = "living wall"
	icon = 'icons/mob/mob.dmi'
	icon_state = "livingwall"
	a_intent = "disarm" // just so they don't swap with help intent users
	health = INFINITY
	anchored = 1
	density = 1
	nodamage = 1
	opacity = 1

	//Life(datum/controller/process/mobs/parent)
		//..(parent)
		//return

	examine()
		set src in view()

		boutput(usr, "<span style=\"color:blue\">*---------*</span>")
		boutput(usr, "<span style=\"color:blue\">This is a [bicon(src)] <B>[src.name]</B>!</span>")
		if(prob(50) && ishuman(usr) && usr.bioHolder.HasEffect("clumsy"))
			boutput(usr, "<span style=\"color:red\">You can't help but laugh at it.</span>")
			usr.emote("laugh")
		else
			boutput(usr, "<span style=\"color:red\">It looks pretty disturbing.</span>")

	say_understands(var/other)
		if (ishuman(other) || isrobot(other) || isAI(other))
			return 1
		return ..()

	attack_hand(mob/user as mob)
		boutput(user, "<span style=\"color:blue\">You push the [src.name] but nothing happens!</span>")
		playsound(src.loc, "sound/weapons/Genhit.ogg", 25, 1)
		src.add_fingerprint(user)
		return

	ex_act(severity)
		..() // Logs.
		switch(severity)
			if(1.0)
				src.gib(1)
				return
			if(2.0)
				if (prob(25))
					src.gib(1)
			else
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/weldingtool) && W:welding)
			src.gib(1)
		else
			..()

/mob/living/carbon/wall/meatcube
	name = "meat cube"
	real_name = "meat cube"
	icon_state = "meatcube-squish"
	opacity = 0
	var/life_timer = 10

	Life(datum/controller/process/mobs/parent)
		if (..(parent))
			return 1

		if (src.client)
			src.antagonist_overlay_refresh(0, 0)

		if (istype(loc, /obj/machinery/deep_fryer))
			return

		if (prob(30))
			src.visible_message("<span style=\"color:red\"><b>[src] [pick("quivers","pulsates","squirms","flollops","shudders","twitches","willomies")] [pick("sadly","disgustingly","horrifically","unpleasantly","disturbingly","worryingly","pathetically","floopily")]!</b></span>")

		if (life_timer-- > 0)
			return

		for (var/i = 3, i > 0, i--)
			var/obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/meat = new /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat(src.loc)
			meat.name = "cube steak"
			meat.desc = "Grody."

		playsound(src.loc, "sound/effects/splat.ogg", 75, 1)
		src.visible_message("<span style=\"color:red\"><b>The meat cube pops!</b></span>")
		src.gib(1)
		return

	say_quote(var/text)
		if(src.emote_allowed)
			if(!(src.client && src.client.holder))
				src.emote_allowed = 0
			/*
			if(src.gender == MALE) playsound(get_turf(src), "sound/voice/male_scream.ogg", 100, 0, 0, 0.91)
			else playsound(get_turf(src), "sound/voice/female_scream.ogg", 100, 0, 0, 0.9)
			*/

			if (narrator_mode)
				playsound(src.loc, 'sound/vox/scream.ogg', 80, 0, 0, src.get_age_pitch())
			else
				if(src.gender == MALE) playsound(get_turf(src), 'sound/voice/male_scream.ogg', 80, 0, 0, src.get_age_pitch())
				else playsound(get_turf(src), 'sound/voice/female_scream.ogg', 80, 0, 0, src.get_age_pitch())

			spawn(50)
				src.emote_allowed = 1
			return "screams!"
		else
			return pick("gurgles.","shivers.","twitches.","shakes.","squirms.", "cries.")

	verb/suicide()
		set hidden = 1

		if (src.stat == 2)
			boutput(src, "You're already dead!")
			return

		if (suiciding)
			boutput(src, "You're already committing suicide! Be patient!")
			return

		suiciding = 1

		var/confirm = alert("Are you sure you want to commit suicide?", "Confirm Suicide", "Yes", "No")

		if(confirm == "Yes")
			logTheThing("combat", src, null, "commits suicide")

			var/obj/machinery/deep_fryer/fryer = locate() in orange(1, src)
			if (istype(fryer) && fryer.suicide(src))
				src.unlock_medal("Damned", 1)
				src.suiciding = 0
				return
			else
				src.visible_message("<span style=\"color:red\"><b>The meat cube pops!</b></span>")
				src.gib(1)
				src.unlock_medal("Damned", 1)
				src.suiciding = 0
				return

/mob/living/carbon/wall/meatcube/clown

name = "clown cube"
	real_name = "clown cube"
	icon_state = "clowncube-squish" //be sure to actually, ya know, put the sprites in
	opacity = 0
	var/life_timer = 10

	Life(datum/controller/process/mobs/parent)
		if (..(parent))
			return 1

		if (src.client)
			src.antagonist_overlay_refresh(0, 0)

		if (istype(loc, /obj/machinery/deep_fryer))
			return

		if (prob(30))
			src.visible_message("<span style=\"color:red\"><b>[src] [pick("quivers","pulsates","squirms","flollops","shudders","twitches","willomies","squeaks","giggles")] [pick("sadly","disgustingly","horrifically","unpleasantly","disturbingly","worryingly","pathetically","floopily","comedically","funnily","morbidly")]!</b></span>")

		if (life_timer-- > 0)
			return

		for (var/i = 3, i > 0, i--)
			var/obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/meat = new /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat(src.loc)
			meat.name = "cube steak"
			meat.desc = "It smells like banana... What the fuck?"

		playsound(src.loc, "sound/effects/splat.ogg", 75, 1)
		src.visible_message("<span style=\"color:red\"><b>The clown cube pops!</b></span>")
		src.gib(1)
		return

	say_quote(var/text)
		if(src.emote_allowed)
			if(!(src.client && src.client.holder))
				src.emote_allowed = 0
			
			
			if (narrator_mode)
				playsound(src.loc, 'sound/vox/honk.ogg', 80, 0, 0, src.get_age_pitch())
			else
				playsound(get_turf(src), 'sound/item/bikehorn.ogg', 50, 1)

			spawn(50)
				src.emote_allowed = 1
			return "honks!"
		else
			return pick("gurgles.","shivers.","twitches.","shakes.","squirms.","cries.","squeaks.","giggles.")

	verb/suicide()
		set hidden = 1

		if (src.stat == 2)
			boutput(src, "You're already dead!")
			return

		if (suiciding)
			boutput(src, "You're already committing suicide! Be patient!")
			return

		suiciding = 1

		var/confirm = alert("Are you sure you want to commit suicide?", "Confirm Suicide", "Yes", "No")

		if(confirm == "Yes")
			logTheThing("combat", src, null, "commits suicide")

			var/obj/machinery/deep_fryer/fryer = locate() in orange(1, src)
			if (istype(fryer) && fryer.suicide(src))
				src.unlock_medal("Damned", 1)
				src.suiciding = 0
				return
			else
				src.visible_message("<span style=\"color:red\"><b>The clown cube pops!</b></span>")
				src.gib(1)
				/obj/item/clothing/mask/clown_hat.set_loc(get_turf(src))
				src.unlock_medal("Damned", 1)
				src.suiciding = 0
				return

name = "cluwne cube"
	real_name = "cluwne cube"
	icon_state = "cluwnecube-squish" //be sure to actually, ya know, put the sprites in
	opacity = 0
	var/life_timer = 10

	Life(datum/controller/process/mobs/parent)
		if (..(parent))
			return 1

		if (src.client)
			src.antagonist_overlay_refresh(0, 0)

		if (istype(loc, /obj/machinery/deep_fryer))
			return

		if (prob(30))
			src.visible_message("<span style=\"color:red\"><b>[src] [pick("quivers","pulsates","squirms","flollops","shudders","twitches","willomies","squeaks","giggles","hyperventilates","panics")] [pick("sadly","disgustingly","horrifically","unpleasantly","disturbingly","worryingly","pathetically","floopily","comedically","funnily","cursedly","distressingly")]!</b></span>")

		if (life_timer-- > 0)
			return

		for (var/i = 3, i > 0, i--)
			var/obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/meat = new /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat(src.loc)
			meat.name = "cube steak"
			meat.desc = "Well, at least they're out of their misery..."

		playsound(src.loc, "sound/effects/splat.ogg", 75, 1)
		src.visible_message("<span style=\"color:red\"><b>The cluwne cube pops!</b></span>")
		src.gib(1)
		return

	say_quote(var/text)
		if(src.emote_allowed)
			if(!(src.client && src.client.holder))
				src.emote_allowed = 0
			
			
			if (narrator_mode)
				playsound(src.loc, 'sound/vox/honk.ogg', 80, 0, 0, src.get_age_pitch())
			else
				var/CluwneNoise = pick('sound/items/hellhorn_0','sound/items/hellhorn_1','sound/items/hellhorn_2','sound/items/hellhorn_3','sound/items/hellhorn_4','sound/items/hellhorn_5','sound/items/hellhorn_6','sound/items/hellhorn_7','sound/items/hellhorn_8','sound/items/hellhorn_9','sound/items/hellhorn_10','sound/items/hellhorn_11','sound/items/hellhorn_12')
				playsound(get_turf(src),var/CluwneNoise, 50, 1)

			spawn(50)
				src.emote_allowed = 1
			return "makes a distressingly weird noise!"
		else
			return pick("gurgles.","shivers.","twitches.","shakes.","squirms.","cries.","squeaks.","giggles.","suffers.","visually begs for mercy")

	verb/suicide()
		set hidden = 1

		if (src.stat == 2)
			boutput(src, "You're already dead!")
			return

		if (suiciding)
			boutput(src, "You're already committing suicide! Be patient!")
			return

		suiciding = 1

		var/confirm = alert("Are you sure you want to commit suicide?", "Confirm Suicide", "Yes", "No")

		if(confirm == "Yes")
			logTheThing("combat", src, null, "commits suicide")

			var/obj/machinery/deep_fryer/fryer = locate() in orange(1, src)
			if (istype(fryer) && fryer.suicide(src))
				src.unlock_medal("Damned", 1)
				src.suiciding = 0
				return
			else
				src.visible_message("<span style=\"color:red\"><b>The meat cube pops!</b></span>")
				src.gib(1)
				/obj/item/clothing/mask/cursedclown_hat.set_loc(get_turf(src))
				src.unlock_medal("Damned", 1)
				src.suiciding = 0
				return


/mob/living/carbon/wall/meatcube/krampus
	name = "Krampus 2.0"
	life_timer = INFINITY
	icon_state = "krampus2-squish"

	New()
		..()
		real_name = pick("Krampus", "Krampus 2.0", "The Krampmeister", "The Krampster") //For deadchat
		spawn(20) //I do not know where the hell you get a bioholder from =I
			if(src.bioHolder) src.bioHolder.age = 110


	attackby(obj/item/W as obj, mob/user as mob)
		user.visible_message("<span class='combat'><B>[user] pokes [src] with \the [W]!</B></span>") //No weldergibs. Krampus is truly a fiend.
