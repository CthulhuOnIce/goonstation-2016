/obj/surgery_tray
	name = "tray"
	desc = "A lightweight tray with little wheels on it. You can place stuff on this and then move the stuff elsewhere! Isn't that totally amazing??"
	// icon = 'icons/obj/surgery.dmi'
	// icon_state = "tray"
	icon = 'icons/obj/objects.dmi'
	icon_state = "rack"

	density = 1
	anchored = 0
	appearance_flags = KEEP_TOGETHER

	// var/list/stuff_to_move = null
	var/max_to_move = 10

	New()
		..()
		if (!ticker) // pre-roundstart, this is a thing made on the map so we want to grab whatever's been placed on top of us automatically
			spawn(0)
				var/stuff_added = 0
				for (var/obj/item/I in src.loc.contents)
					if (I.anchored || I.layer < src.layer)
						continue
					else
						src.contents += I
						src.vis_contents += I
						stuff_added++
						if (stuff_added >= src.max_to_move)
							break

 	//this might not be necessary, I'm not sure. but it can't hurt
	Del()
		src.vis_contents = null
		src.contents = null

	Move(NewLoc,Dir)
		. = ..()
		if (.)
			if (prob(75))
				playsound(get_turf(src), "sound/misc/chair/office/scoot[rand(1,5)].ogg", 40, 1)


			//if we're over the max amount a table can fit, have a chance to drop an item. Chance increases with items on tray
			if (prob((src.contents.len-max_to_move)*1.5))
				var/obj/item/falling = pick(src.contents)
				// src.visible_message("[falling] falls off of [src]!")

				var/target = get_offset_target_turf(get_turf(src), rand(5)-rand(5), rand(5)-rand(5))
				falling.set_loc(get_turf(src))
				src.vis_contents -= falling

				spawn(1)
					if(falling)
						falling.throw_at(target, 1, 1)


	attackby(obj/item/W as obj, mob/user as mob, params)
		// if (iswrenchingtool(W))
		// 	actions.start(new /datum/action/bar/icon/furniture_deconstruct(src, W, 30), user)
		// 	return
		// if (src.place_on(W, user, params))
		user.show_text("You place [W] on [src].")

		if (!isrobot(user))
			user.drop_item()
			if (W && W.loc && !(W.cant_drop || W.cant_self_remove))
				W.set_loc(src.loc)
				if (islist(params) && params["icon-y"] && params["icon-x"])
					W.pixel_x = text2num(params["icon-x"]) - 16
					W.pixel_y = text2num(params["icon-y"]) - 16
		
			W.set_loc(src)
			src.contents += W
			src.vis_contents += W
			return
		else
			return ..()

	hitby(atom/movable/AM as mob|obj)
		..()
		if (isitem(AM))
			var/obj/item/I = AM
			src.visible_message("[I] lands on [src]!")

			I.set_loc(src)
			src.contents += I
			src.vis_contents += I

	// proc/deconstruct()
	// 	var/obj/item/furniture_parts/surgery_tray/P = new /obj/item/furniture_parts/surgery_tray(src.loc)
	// 	if (P && src.material)
	// 		P.setMaterial(src.material)
	// 	qdel(src)
	// 	return
