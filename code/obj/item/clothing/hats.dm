// HATS. OH MY WHAT A FINE CHAPEAU, GOOD SIR.

/obj/item/clothing/head
	name = "hat"
	desc = "For your head!"
	icon = 'icons/obj/clothing/item_hats.dmi'
	wear_image_icon = 'icons/mob/head.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_headgear.dmi'
	body_parts_covered = HEAD
	compatible_species = list("human", "monkey")
	armor_value_melee = 1
	var/seal_hair = 0 // best variable name I could come up with, if 1 it forms a seal with a suit so no hair can stick out
	cold_resistance = 10
	heat_resistance = 5

	//add lot or cash to a hat
	attackby(obj/item/O as obj, mob/user as mob)
		if (!user.find_in_hand(src))
			boutput(user, "Trying to put something into a hat that you're not holding? Science hasn't come that far yet.")
		else

			if (istype(O, /obj/item/paper) || istype(O, /obj/item/spacecash))
				if (src.contents.len < 20)
					src.contents += O
					user.u_equip(O)
					user.visible_message("<span style=\"color:blue\">[user] adds [O] to [src].</span>")
				else
					boutput(user, "You can't fit anything else into [src].")
			else
				..()


	//remove lot from hat
	attack_hand(mob/user as mob)
		if (user.find_in_hand(src))
			if (src.contents.len > 0)
				var/obj/O = pick(src.contents)
				user.put_in_hand_or_drop(O)
				user.visible_message("<span style=\"color:red\">[user] draws [O] out of [src]!</span>")
				src.contents -= O
			else
				..()
		else
			..()

	//empty out hat
	attack_self(mob/user as mob)
		if (src.contents.len > 0)
			user.visible_message("<span style=\"color:red\">[user] empties the contents of [src].</span>")
			for (var/obj/item/O in src.contents)
				O.set_loc(get_turf(src))
				src.contents -= O
		else
			..()

/obj/item/clothing/head/red
	desc = "A knit cap in red."
	icon_state = "red"
	item_state = "rgloves"

/obj/item/clothing/head/blue
	desc = "A knit cap in blue."
	icon_state = "blue"
	item_state = "bgloves"

/obj/item/clothing/head/yellow
	desc = "A knit cap in yellow."
	icon_state = "yellow"
	item_state = "ygloves"

/obj/item/clothing/head/dolan
	name = "Dolan's Hat"
	desc = "A plsing hat."
	icon_state = "dolan"
	item_state = "dolan"

/obj/item/clothing/head/green
	desc = "A knit cap in green."
	icon_state = "green"
	item_state = "ggloves"

/obj/item/clothing/head/black
	desc = "A knit cap in black."
	icon_state = "black"
	item_state = "swat_gl"

/obj/item/clothing/head/white
	desc = "A knit cap in white."
	icon_state = "white"
	item_state = "lgloves"

/obj/item/clothing/head/psyche
	desc = "A knit cap in...what the hell?"
	icon_state = "psyche"
	item_state = "bgloves"

/obj/item/clothing/head/serpico
	icon_state = "serpico"
	item_state = "serpico"

/obj/item/clothing/head/bio_hood
	name = "bio hood"
	icon_state = "bio"
	permeability_coefficient = 0.01
	c_flags = SPACEWEAR | COVERSEYES | COVERSMOUTH
	desc = "This hood protects you from harmful biological contaminants."
	disease_resistance = 50
	armor_value_melee = 3
	seal_hair = 1
	cold_resistance = 10
	heat_resistance = 10

/obj/item/clothing/head/bio_hood/nt
	name = "NT bio hood"
	icon_state = "ntbiohood"
	armor_value_melee = 5

/obj/item/clothing/head/emerg
	name = "Emergency Hood"
	icon_state = "emerg"
	permeability_coefficient = 0.25
	c_flags = SPACEWEAR | COVERSEYES | COVERSMOUTH
	desc = "Helps protect from vacuum for a short period of time."

/obj/item/clothing/head/rad_hood
	name = "Class II Radiation Hood"
	icon_state = "radiation"
	permeability_coefficient = 0.01
	heat_transfer_coefficient = 0.10
	c_flags = COVERSEYES | COVERSMOUTH
	desc = "Asbestos, right near your face. Perfect!"
	armor_value_melee = 5
	radproof = 1
	seal_hair = 1

/obj/item/clothing/head/cakehat
	name = "cakehat"
	desc = "It is a cakehat"
	icon_state = "cake0"
	var/status = 0
	var/processing = 0
	c_flags = SPACEWEAR | COVERSEYES
	var/fire_resist = T0C+1300	//this is the max temp it can stand before you start to cook. although it might not burn away, you take damage
	var/datum/light/light
	var/on = 0

	New()
		..()
		light = new /datum/light/point
		light.set_brightness(0.6)
		light.set_height(1.8)
		light.set_color(0.94, 0.69, 0.27)
		light.attach(src)

	pickup(mob/user)
		..()
		light.attach(user)

	dropped(mob/user)
		..()
		spawn(0)
			if (src.loc != user)
				light.attach(src)

	attack_self(mob/user)
		src.flashlight_toggle(user)
		return

	proc/flashlight_toggle(var/mob/user, var/force_on = 0)
		if (!src || !user || !ismob(user)) return

		if (status > 1)
			return

		if (force_on)
			src.on = 1
		else
			src.on = !src.on

		if (src.on)
			src.force = 10
			src.damtype = "fire"
			src.icon_state = "cake1"
			light.enable()
			if (!(src in processing_items))
				processing_items.Add(src)
		else
			src.force = 3
			src.damtype = "brute"
			src.icon_state = "cake0"
			light.disable()

		user.update_clothing()
		src.add_fingerprint(user)
		return

	process()
		if (!src.on)
			processing_items.Remove(src)
			return

		var/turf/location = src.loc
		if (istype(location, /mob/))
			var/mob/living/carbon/human/M = location
			if (M.l_hand == src || M.r_hand == src || M.head == src)
				location = M.loc

		if (istype(location, /turf))
			location.hotspot_expose(700, 1)
		return

	afterattack(atom/target, mob/user as mob)
		..()
		if (src.on && !ismob(target) && target.reagents)
			boutput(usr, "<span style=\"color:blue\">You heat \the [target.name]</span>")
			target.reagents.temperature_reagents(2500,10)
		return

/obj/item/clothing/head/caphat
	name = "Captain's hat"
	icon_state = "captain"
	c_flags = SPACEWEAR
	item_state = "caphat"
	desc = "A symbol of the captain's rank, and the source of all his power."
	armor_value_melee = 5

/obj/item/clothing/head/centhat
	name = "Cent. Comm. hat"
	icon_state = "centcom"
	c_flags = SPACEWEAR
	item_state = "centcom"
	armor_value_melee = 5

	red
		icon_state = "centcom-red"
		item_state = "centcom-red"

/obj/item/clothing/head/det_hat
	name = "hat"
	desc = "Someone who wears this will look very smart"
	icon_state = "detective"
	armor_value_melee = 3

//THE ONE AND ONLY.... GO GO GADGET DETECTIVE HAT!!!
/obj/item/clothing/head/det_hat/gadget
	name = "DetGadget hat"
	desc = "Detective's special hat you can outfit with various items for easy retrieval!"
	var/phrase = "go go gadget"

	var/list/items = list("bodybag" = /obj/item/body_bag, "scanner" = /obj/item/device/detective_scanner, "lighter" = /obj/item/zippo,\
							"spray" = /obj/item/spraybottle, "monitor" = /obj/item/device/camera_viewer, "camera" = /obj/item/camera_test,\
							"audiolog" = /obj/item/device/audio_log , "flashlight" = /obj/item/device/flashlight, "glasses" = /obj/item/clothing/glasses)

	var/max_cigs = 15
	var/list/cigs = list()

	examine()
		set src in view()
		set category = "Local"

		..()
		var/str = "<span style=\"color:blue\">Current activation phrase is <b>\"[phrase]\"</b>.</span>"
		for (var/name in items)
			var/type = items[name]
			var/obj/item/I = locate(type) in contents
			if(I)
				str += "<br><span style=\"color:blue\">[bicon(I)][I] is ready and bound to the word \"[name]\"!</span>"
			else
				str += "<br>There is no [name]!"
		if (cigs.len)
			str += "<br><span style=\"color:blue\">It contains <b>[cigs.len]</b> cigarettes!</span>"

		usr.show_message(str)
		return

	hear_talk(mob/M as mob, msg, real_name, lang_id)
		var/turf/T = get_turf(src)
		if (M in range(1, T))
			src.talk_into(M, msg, null, real_name, lang_id)

	talk_into(mob/M as mob, messages, param, real_name, lang_id)
		var/gadget = findtext(messages[1], src.phrase) //check the spoken phrase
		if(gadget)
			gadget = replacetext(copytext(messages[1], gadget + length(src.phrase)), " ", "") //get rid of spaces as well
			for (var/name in items)
				var/type = items[name]
				var/obj/item/I = locate(type) in contents
				if(findtext(gadget, name) && I)
					M.put_in_hand_or_drop(I)
					M.visible_message("<span style=\"color:red\"><b>[M]</b>'s hat snaps open and pulls out \the [I]!</span>")
					return

			if(findtext(gadget, "cigarette"))
				if (!cigs.len)
					M.show_text("You're out of cigs, shit! How you gonna get through the rest of the day?", "red")
					return
				else
					var/obj/item/clothing/mask/cigarette/W = cigs[cigs.len] //Grab the last cig entry
					cigs.Cut(cigs.len) //Get that cig outta there
					var/boop = "hand"
					if(ishuman(M))
						var/mob/living/carbon/human/H = M
						if (H.equip_if_possible(W, H.slot_wear_mask))
							boop = "mouth"
						else
							H.put_in_hand_or_drop(W) //Put it in their hand
					else
						M.put_in_hand_or_drop(W) //Put it in their hand
						//can't bother to do a "ground" boop case for some dumbass flavor text ok

					M.visible_message("<span style=\"color:red\"><b>[M]</b>'s hat snaps open and puts \the [W] in [his_or_her(M)] [boop]!</span>")
			else
				M.show_text("Requested object missing or nonexistant!", "red")
				return

	attackby(obj/item/W as obj, mob/M as mob)
		var/success = 0
		for (var/name in items)
			var/type = items[name]
			if(istype(W, type) && !(locate(type) in contents))
				success = 1
				M.drop_item()
				W.set_loc(src)
				break
		if (cigs.len < src.max_cigs && istype(W, /obj/item/clothing/mask/cigarette)) //cigarette
			success = 1
			M.drop_item()
			W.set_loc(src)
			cigs.Add(W)
		if (cigs.len < src.max_cigs && istype(W, /obj/item/cigpacket)) //cigarette packet
			var/obj/item/cigpacket/packet = W
			if(packet.cigcount == 0)
				M.show_text("Oh no! There's no more cigs in [packet]!", "red")
				return
			else
				var/count = packet.cigcount
				for(var/i=0, i<count, i++) //not sure if "-1" cigcount packets will work.
					if(cigs.len >= src.max_cigs)
						break
					var/obj/item/clothing/mask/cigarette/C = new packet.cigtype(src)
					C.set_loc(src)
					cigs.Add(C)
					packet.cigcount--
				success = 1

		if(success)
			M.visible_message("<span style=\"color:red\"><b>[M]</b> [pick("awkwardly", "comically", "impossibly", "cartoonishly")] stuffs [W] into [src]!</span>")
			return

		return ..()

	verb/set_phrase()
		set name = "Set Activation Phrase"
		set desc = "Change the activation phrase for the DetGadget hat!"
		set category = "Local"

		set src in usr
		var/n_name = input(usr, "What would you like to set the activation phrase to?", "Activation Phrase", null) as null|text
		if (!n_name)
			return
		n_name = copytext(html_encode(n_name), 1, 32)
		if (((src.loc == usr || (src.loc && src.loc.loc == usr)) && usr.stat == 0))
			src.phrase = n_name
			logTheThing("say", usr, null, "sets the activation phrase on DetGadget hat: [n_name]")
		src.add_fingerprint(usr)


/obj/item/clothing/head/powdered_wig
	name = "powdered wig"
	desc = "A powdered wig"
	icon_state = "pwig"
	item_state = "pwig"

/obj/item/clothing/head/that
	name = "hat"
	desc = "An stylish looking hat"
	icon_state = "tophat"
	item_state = "that"

/obj/item/clothing/head/that/purple
	name = "purple hat"
	desc = "A purple tophat."
	icon_state = "ptophat"
	item_state = "pthat"
	c_flags = SPACEWEAR

	protective_temperature = 500
	heat_transfer_coefficient = 0.10

/obj/item/clothing/head/chefhat
	name = "Chef's hat"
	icon_state = "chef"
	item_state = "chef"
	desc = "Your toque blanche, coloured as such so that your poor sanitation is obvious, and the blood shows up nice and crazy."
	c_flags = SPACEWEAR

/obj/item/clothing/head/souschefhat
	name = "Sous-Chef's hat"
	icon_state = "souschef"
	item_state = "souschef"
	c_flags = SPACEWEAR

/obj/item/clothing/head/mailcap
	name = "Mailman's Hat"
	desc = "The hat of a mailman."
	icon_state = "mailcap"
	item_state = "mailcap"
	c_flags = SPACEWEAR

/obj/item/clothing/head/policecap
	name = "Police Hat"
	desc = "An old surplus-issue police hat."
	icon_state = "mailcap"
	item_state = "mailcap"
	c_flags = SPACEWEAR

/obj/item/clothing/head/plunger
	name = "plunger"
	desc = "get dat fukken clog"
	icon_state = "plunger"
	item_state = "plunger"
	armor_value_melee = 2

/obj/item/clothing/head/hosberet
	name = "HoS Beret"
	desc = "This makes you feel like Che Guevara."
	icon_state = "hosberet"
	item_state = "hosberet"
	c_flags = SPACEWEAR

/obj/item/clothing/head/NTberet
	name = "Nanotrasen Beret"
	desc = "For the inner dictator in you."
	icon_state = "ntberet"
	item_state = "ntberet"
	c_flags = SPACEWEAR

/obj/item/clothing/head/XComHair
	name = "Rookie Scalp"
	desc = "Some unfortunate soldier's charred scalp. The hair is intact."
	icon_state = "xcomhair"
	item_state = "xcomhair"
	c_flags = SPACEWEAR

/obj/item/clothing/head/apprentice
	name = "Apprentice's Cap"
	desc = "Legends tell about space sorcerors taking on apprentices. Such apprentices would wear a magical cap, and this is one such ite- hey! This is just a cardboard cone with wrapping paper on it!"
	icon_state = "apprentice"
	item_state = "apprentice"
	c_flags = SPACEWEAR

/obj/item/clothing/head/snake
	name = "Dirty Rag"
	desc = "A rag that looks like it was dragged through the jungle. Yuck."
	icon_state = "snake"
	item_state = "snake"
	c_flags = SPACEWEAR

// Chaplain Hats

/obj/item/clothing/head/rabbihat
	name = "rabbi's hat"
	desc = "Complete with jewcurls. Oy vey!"
	icon_state = "rabbihat"
	item_state = "that"

/obj/item/clothing/head/formal_turban
	name = "formal turban"
	desc = "A very stylish formal turban."
	icon_state = "formal_turban"
	item_state = "egg5"
	cold_resistance = 15
	heat_resistance = 10

/obj/item/clothing/head/turban
	name = "turban"
	desc = "A very comfortable cotton turban."
	icon_state = "turban"
	item_state = "that"
	cold_resistance = 15
	heat_resistance = 10

/obj/item/clothing/head/rastacap
	name = "rastafarian cap"
	desc = "Comes with pre-attached dreadlocks for that authentic look."
	icon_state = "rastacap"
	item_state = "that"

/obj/item/clothing/head/fedora
	name = "fedora"
	desc = "Tip your fedora to the fair maiden and win her heart. A foolproof plan."
	icon_state = "fdora"
	item_state = "fdora"

	New()
		..()
		src.name = "[pick("fancy", "suave", "manly", "sexerific", "sextacular", "intellectual", "majestic", "euphoric")] fedora"

/obj/item/clothing/head/fruithat
	name = "fruit basket hat"
	desc = "Where do these things even come from?"
	wear_image_icon = 'icons/mob/fruithat.dmi'
	icon_state = "fruithat"

/obj/item/clothing/head/cowboy
	name = "cowboy hat"
	desc = "Yeehaw!"
	icon_state = "cowboy"
	item_state = "cowboy"
	c_flags = SPACEWEAR

/obj/item/clothing/head/fancy/captain
	name = "captain's hat"
	icon_state = "captain-fancy"
	armor_value_melee = 3
	c_flags = SPACEWEAR

/obj/item/clothing/head/fancy/rank
	name = "hat"
	icon_state = "rank-fancy"
	armor_value_melee = 3
	c_flags = SPACEWEAR

/obj/item/clothing/head/wizard
	name = "blue wizard hat"
	desc = "A slightly crumply and foldy blue hat. Every self-respecting Wizard has one of these."
	icon_state = "wizard"
	item_state = "wizard"
	magical = 1
	var/ready = 1

	handle_other_remove(var/mob/source, var/mob/living/carbon/human/target)
		. = ..()
		if (prob(75))
			source.show_message(text("<span style=\"color:red\">\The [src] writhes in your hands as though it is alive! It just barely wriggles out of your grip!</span>"), 1)
			. = 0

	attack_hand(mob/user as mob)

		//if it has something in it, do normal stuff
		if (src.contents.len > 0 || !user.find_in_hand(src))
			..()
			
		else if (iswizard(user))
			if (ready)
				ready = 0
				user.say("Hocus Pocus!")
				spawn (10)
					user.visible_message("<span style=\"color:red\">[user] pulls a rabbit from [src] and it \"hops\" onto the floor!</span>")
					new /obj/item/photo/rabbit(get_turf(src))
					playsound(user.loc, "sound/effects/mag_teleport.ogg", 25, 1, -1)

				//create dumb rabbit critter/sprite for comedy
				spawn (600)
					ready = 1
			else
				boutput(user, "<span style=\"color:red\">You don't feel powerful enough to conjure a rabbit from your hat just yet.</span>")
		else
			..()
/obj/item/photo/rabbit
	name = "photo of a rabbit"
	desc = "You can see a rabbit on the photo. You feel let down?"
	icon_state = "photo-rabbit"

/obj/item/clothing/head/wizard/red
	name = "red wizard hat"
	desc = "An elegant red hat with some nice gold trim on it."
	icon_state = "wizardred"
	item_state = "wizardred"

/obj/item/clothing/head/wizard/purple
	name = "purple wizard hat"
	desc = "A very nice purple hat with a big, sassy buckle on it!"
	icon_state = "wizardpurple"
	item_state = "wizardpurple"

/obj/item/clothing/head/wizard/necro
	name = "necromancer hood"
	desc = "Good god, this thing STINKS. Is that mold on the inner lining? Ugh."
	icon_state = "wizardnec"
	item_state = "wizardnec"
	see_face = 0

/obj/item/clothing/head/paper_hat
	name = "Paper"
	desc = "A knit cap in white."
	icon_state = "paper"
	item_state = "lgloves"
	see_face = 1
	body_parts_covered = HEAD
