// Contains:
// - Sliding door parent
// - Brig door
// - Opaque door
// - Generic door

////////////////////////////////////////////////////// Sliding door parent ////////////////////////////////////

/obj/machinery/door/window
	name = "interior door"
	icon = 'icons/obj/doors/windoor.dmi'
	icon_state = "left"
	var/base_state = "left"
	visible = 0
	flags = ON_BORDER
	opacity = 0
	brainloss_stumble = 1
	autoclose = 1
	power_usage = 30		//more efficient than airlocks
	var/disabled = 0
	var/shield = 0			//defined here to prevent runtimes

	New()
		..()

		if (src.req_access && src.req_access.len)
			src.icon_state = "[src.icon_state]"
			src.base_state = src.icon_state
		return

	attack_hand(mob/user as mob)
		if (issilicon(user) && src.hardened == 1)
			user.show_text("You cannot control this door.", "red")
			return
		else
			return src.attackby(null, user)

	attackby(obj/item/I as obj, mob/user as mob)
		if (user.stunned || user.weakened || user.stat || user.restrained())
			return

		if (istype(I, /obj/item/screwdriver))
			src.p_open = !(src.p_open)
			user.show_text("You [src.p_open ? "open" : "close"] the access panel of [src].", "blue")
			return

		if (istype(I, /obj/item/wirecutters) && src.p_open)
			if (istype(src, /obj/machinery/door/window/brigdoor) && src.shield)
				user.show_text("The protective shield is up!", "red")
				return
			src.disabled = !(src.disabled)
			if (!src.disabled)
				src.power_usage = 30
				user.show_text("You mend [src] with [I].", "red")
				user.visible_message("<span style=\"color:red\"><b>[user]</b> repairs [src]'s power wire.</span>")
			else
				src.power_usage = 0
				user.show_text("You disable [src] with [I].", "red")
				user.visible_message("<span style=\"color:red\"><b>[user]</b> cuts [src]'s power wire.</span>")
			return

		if (istype(I, /obj/item/wrench) && src.p_open && !(src.shield) && src.disabled)
			user.show_text("You start to unwrench the main bolts.", "red")
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			if (do_after(user, 30))
				user.show_text("You unsecure the bolts holding [src] together.", "red")
				user.visible_message("<span style=\"color:red\"><b>[user]</b> deconstructs [src] into a frame.</span>")
				if (istype(src, /obj/machinery/door/window/brigdoor))
					var/obj/structure/windoor_frame/reinforced/D = new /obj/structure/windoor_frame/reinforced(src.loc)
					D.stage = 2
					D.dir = src.dir
					D.accessbuffer = src.req_access
					if (src.material)
						D.setMaterial(src.material)
					else
						var/datum/material/M = getCachedMaterial("glass")
						D.setMaterial(M)

					D.dir = src.dir
					D.accessbuffer = src.req_access
				else
					var/obj/structure/windoor_frame/D = new /obj/structure/windoor_frame(src.loc)
					D.stage = 2
					D.dir = src.dir
					D.accessbuffer = src.req_access
					if (src.material)
						D.setMaterial(src.material)
					else
						var/datum/material/M = getCachedMaterial("glass")
						D.setMaterial(M)

					D.dir = src.dir
					D.accessbuffer = src.req_access

				qdel(src)
			return
		if (istype(I, /obj/item/crowbar))
			src.unpowered_open_close(user)
			return

		if (istype(src, /obj/machinery/door/window/brigdoor) && istype(I, /obj/item/weldingtool) && src.p_open)
			var/obj/item/weldingtool/W = I
			if (!(W.welding))
				return
			if (W.get_fuel() < 2)
				user.show_text("Need more fuel!", "red")
				return
			W.eyecheck(user)
			user.show_text("You start to [src.shield ? "cut" : "repair"] the protective shield.", "red")
			playsound(src.loc, "sound/items/Welder.ogg", 75, 1)
			if (do_after(user, 30))
				W.use_fuel(2)
				src.shield = !src.shield
				user.show_text("You [src.shield ? "repair" : "slice open"] the protective shield.", "red")
				user.visible_message("<span style=\"color:red\"><b>[user]</b> [src.shield ? "repairs" : "slices open"] [src]'s shield.</span>")
				return
			return

		if (src.isblocked() == 1)
			return
		if (src.operating)
			return

		src.add_fingerprint(user)

		if (src.density && src.brainloss_stumble && src.do_brainstumble(user) == 1)
			return

		if (!src.requiresID())
			if (src.density)
				src.open()
			else
				src.close()
			return

		if (src.allowed(user, req_only_one_required))
			if (src.density)
				src.open()
			else
				src.close()
		else
			if (src.density)
				flick(text("[]deny", src.base_state), src)

		return

	examine()
		..()
		boutput(usr, "The access panel is [src.p_open ? "open" : "closed"].")
		if (src.disabled || (stat & NOPOWER))
			boutput(usr, "The power light is off!")
		if (istype(src, /obj/machinery/door/window/brigdoor) && src.p_open && !(src.shield))
			boutput(usr, "The protective shielding is sliced open!")
		return

	emp_act()
		..()
		if (prob(20) && (src.density && src.cant_emag != 1 && src.isblocked() != 1))
			src.open(1)
		if (prob(40))
			if (src.secondsElectrified == 0)
				src.secondsElectrified = -1
				spawn (300)
					if (src)
						src.secondsElectrified = 0
		return

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (src.density && src.cant_emag != 1 && src.isblocked() != 1)
			flick(text("[]spark", src.base_state), src)
			spawn (6)
				if (src)
					src.open(1)
			return 1
		return 0


	demag(var/mob/user)
		if (src.operating != -1)
			return 0
		src.operating = 0
		sleep(6)
		close()
		return 1

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if (istype(mover, /obj/projectile))
			var/obj/projectile/P = mover
			if (P.proj_data.window_pass)
				return 1

		if (get_dir(loc, target) == dir) // Check for appropriate border.
			return !density
		else
			return 1

	CheckExit(atom/movable/mover as mob|obj, turf/target as turf)
		if (istype(mover, /obj/projectile))
			var/obj/projectile/P = mover
			if (P.proj_data.window_pass)
				return 1

		if (get_dir(loc, target) == dir)
			return !density
		else
			return 1

	update_nearby_tiles(need_rebuild)
		if (!air_master) return 0

		var/turf/simulated/source = loc
		var/turf/simulated/target = get_step(source,dir)

		if (need_rebuild)
			if (istype(source)) // Rebuild resp. update nearby group geometry.
				if (source.parent)
					air_master.queue_update_group(source.parent)
				else
					air_master.queue_update_tile(source)

			if (istype(target))
				if (target.parent)
					air_master.queue_update_group(target.parent)
				else
					air_master.queue_update_tile(target)
		else
			if (istype(source)) air_master.queue_update_tile(source)
			if (istype(target)) air_master.queue_update_tile(target)

		return 1

	open(var/emag_open = 0)
		if (!ticker)
			return 0
		if (src.operating)
			return 0
		if ((stat & NOPOWER) || (src.disabled))
			return 0
		src.operating = 1

		flick(text("[]opening", src.base_state), src)
		playsound(src.loc, "sound/machines/windowdoor.ogg", 100, 1)
		src.icon_state = text("[]open", src.base_state)

		spawn (10)
			if (src)
				src.density = 0
				src.RL_SetOpacity(0)
				src.update_nearby_tiles()
				if (emag_open == 1)
					src.operating = -1
				else
					src.operating = 0

		spawn (50)
			if (src && !src.operating && !src.density && src.autoclose == 1)
				src.close()

		return 1

	close()
		if (!ticker)
			return 0
		if (src.operating)
			return 0
		if ((stat & NOPOWER) || (src.disabled))
			return 0
		src.operating = 1

		flick(text("[]closing", src.base_state), src)
		playsound(src.loc, "sound/machines/windowdoor.ogg", 100, 1)
		src.icon_state = text("[]", src.base_state)

		src.density = 1
		if (src.visible)
			src.RL_SetOpacity(1)
		src.update_nearby_tiles()

		spawn (10)
			if (src)
				src.operating = 0

		return 1

	proc/unpowered_open_close(mob/user as mob)
		if (!src || !istype(src))
			return

		if ((src.density) && !( src.operating ) && ((stat & NOPOWER) || src.disabled) && !( src.locked ))
			user.show_text("You begin to pry open [src].", "red")
			if (do_after(user, 35))
				src.operating = 1

				flick(text("[]opening", src.base_state), src)
				src.icon_state = text("[]open", src.base_state)									//totally didn't just copy the above code nope haha

				spawn (10)
					if (src)
						src.density = 0
						src.RL_SetOpacity(0)
						src.update_nearby_tiles()
						src.operating = 0
				user.show_text("You pry open the [src].", "red")
				return 1

		if ((!src.density) && !( src.operating ) && ((stat & NOPOWER) || src.disabled) && !( src.locked ))
			user.show_text("You begin to pry closed [src].", "red")
			if (do_after(user, 35))
				src.operating = 1

				flick(text("[]closing", src.base_state), src)
				src.icon_state = text("[]", src.base_state)

				src.density = 1
				if (src.visible)
					src.RL_SetOpacity(1)
				src.update_nearby_tiles()

				spawn (10)
					if (src)
						src.operating = 0
				user.show_text("You pry closed the [src].", "red")
			return 1

		return 0

	// Since these things don't have a maintenance panel or any other place to put this, really (Convair880).
	verb/toggle_autoclose()
		set src in oview(1)
		set category = "Local"

		if (isobserver(usr) || isintangible(usr))
			return
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat || usr.restrained())
			return
		if (!in_range(src, usr))
			usr.show_text("You are too far away.", "red")
			return
		if (src.hardened == 1)
			usr.show_text("You cannot control this door.", "red")
			return
		if (!src.allowed(usr, req_only_one_required))
			usr.show_text("Access denied.", "red")
			return
		if (src.operating == -1) // Emagged.
			usr.show_text("[src] is unresponsive.", "red")
			return

		if (src.autoclose)
			src.autoclose = 0
		else
			src.autoclose = 1
			spawn (50)
				if (src && !src.density)
					src.close()

		usr.show_text("Setting confirmed. [src] will [src.autoclose == 0 ? "no longer" : "now"] close automatically.", "blue")
		return

////////////////////////////////////////////// Brig door //////////////////////////////////////////////

/obj/machinery/door/window/brigdoor
	name = "Brig Door"
	icon = 'icons/obj/doors/windoor.dmi'
	icon_state = "leftsecure"
	base_state = "leftsecure"
	var/id = 1.0
	req_access = list(access_brig)
	autoclose = 0 //brig doors close only when the cell timer starts
	shield = 1 //brig doors have a shield that protects against wire cutting (can be broken with welder)

	// Please keep synchronizied with these lists for easy map changes:
	// /obj/storage/secure/closet/brig/automatic (secure_closets.dm)
	// /obj/machinery/floorflusher (floorflusher.dm)
	// /obj/machinery/door_timer (door_timer.dm)
	// /obj/machinery/flasher (flasher.dm)
	solitary
		name = "Cell"
		id = "solitary"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	solitary2
		name = "Cell #2"
		id = "solitary2"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	solitary3
		name = "Cell #3"
		id = "solitary3"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	solitary4
		name = "Cell #4"
		id = "solitary4"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	minibrig
		name = "Mini-Brig"
		id = "minibrig"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	minibrig2
		name = "Mini-Brig #2"
		id = "minibrig2"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	minibrig3
		name = "Mini-Brig #3"
		id = "minibrig3"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	genpop
		name = "General Population"
		id = "genpop"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	genpop_n
		name = "General Population North"
		id = "genpop_n"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

	genpop_s
		name = "General Population South"
		id = "genpop_s"

		northleft
			dir = NORTH

		eastleft
			dir = EAST

		westleft
			dir = WEST

		southleft
			dir = SOUTH

		northright
			dir = NORTH
			icon_state = "rightsecure"
			base_state = "rightsecure"

		eastright
			dir = EAST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		westright
			dir = WEST
			icon_state = "rightsecure"
			base_state = "rightsecure"

		southright
			dir = SOUTH
			icon_state = "rightsecure"
			base_state = "rightsecure"
	generic
		name = "secure interior door"
		id = 99999999.0			//some random id that will hopefully never be used
		req_access = null
		autoclose = 1

/////////////////////////////////////////////////////////// Opaque door //////////////////////////////////////

/obj/machinery/door/window/opaque
	icon_state = "opaque-left"
	base_state = "opaque-left"
	visible = 1
	opacity = 1
/obj/machinery/door/window/opaque/northleft
	dir = NORTH
/obj/machinery/door/window/opaque/eastleft
	dir = EAST
/obj/machinery/door/window/opaque/westleft
	dir = WEST
/obj/machinery/door/window/opaque/southleft
	dir = SOUTH
/obj/machinery/door/window/opaque/northright
	dir = NORTH
	icon_state = "opaque-right"
	base_state = "opaque-right"
/obj/machinery/door/window/opaque/eastright
	dir = EAST
	icon_state = "opaque-right"
	base_state = "opaque-right"
/obj/machinery/door/window/opaque/westright
	dir = WEST
	icon_state = "opaque-right"
	base_state = "opaque-right"
/obj/machinery/door/window/opaque/southright
	dir = SOUTH
	icon_state = "opaque-right"
	base_state = "opaque-right"

//////////////////////////////////////////////////////// Generic door //////////////////////////////////////////////

/obj/machinery/door/window/northleft
	dir = NORTH

/obj/machinery/door/window/eastleft
	dir = EAST

/obj/machinery/door/window/westleft
	dir = WEST

/obj/machinery/door/window/southleft
	dir = SOUTH

/obj/machinery/door/window/northright
	dir = NORTH
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/eastright
	dir = EAST
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/westright
	dir = WEST
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/southright
	dir = SOUTH
	icon_state = "right"
	base_state = "right"