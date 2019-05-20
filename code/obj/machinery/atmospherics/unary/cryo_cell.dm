/obj/machinery/atmospherics/unary/cryo_cell
	name = "cryo cell"
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "celltop-P"
	density = 1
	anchored = 1.0
	layer = EFFECTS_LAYER_BASE//MOB_EFFECT_LAYER
	flags = NOSPLASH
	var/on = 0
	var/temperature_archived
	var/obj/overlay/O1 = null
	var/mob/occupant = null
	var/beaker = null
	var/next_trans = 0
	var/show_beaker_contents = 0
	var/current_heat_capacity = 50
	var/pipe_direction = 1
	var/reagent_scan_enabled = 0
	var/reagent_scan_active = 0
	var/obj/item/robodefibrilator/defib


	north
		dir = NORTH
	east
		dir = EAST
	south
		dir = SOUTH
	west
		dir = WEST

	New()
		..()
		build_icon()
		pipe_direction = src.dir
		initialize_directions = pipe_direction

	initialize()
		if(node) return
		var/node_connect = pipe_direction
		for(var/obj/machinery/atmospherics/target in get_step(src,node_connect))
			if(target.initialize_directions & get_dir(target,src))
				node = target
				break

	dispose()
		for (var/mob/M in src)
			M.set_loc(src.loc)
		..()

	process()
		..()
		if(!node)
			return
		if(!on)
			src.updateUsrDialog()
			return

		if(src.occupant)
			if(occupant.stat != 2)
				if (occupant.health < 100) process_occupant()
				else
					src.go_out()
					playsound(src.loc, "sound/machines/ding.ogg", 50, 1)


		if(air_contents)
			temperature_archived = air_contents.temperature
			heat_gas_contents()
			expel_gas()

		if(abs(temperature_archived-air_contents.temperature) > 1)
			network.update = 1

		src.updateUsrDialog()
		return 1


	allow_drop()
		return 0


	relaymove(mob/user as mob)
		if(user.stat)
			return
		src.go_out()
		return

	attack_hand(mob/user as mob)
		user.machine = src
		var/temp_text = ""
		if(air_contents.temperature > T0C)
			temp_text = "<FONT color=red>[air_contents.temperature]</FONT>"
		else if(air_contents.temperature > 225)
			temp_text = "<FONT color=black>[air_contents.temperature]</FONT>"
		else
			temp_text = "<FONT color=blue>[air_contents.temperature]</FONT>"

		var/dat = "<B>Cryo cell control system</B><BR>"
		dat += "<B>Current cell temperature:</B> [temp_text]K<BR>"
		dat += "<B>Eject Occupant:</B> [src.occupant ? "<A href='?src=\ref[src];eject_occupant=1'>Eject</A>" : "Eject"]<BR>"
		dat += "<B>Cryo status:</B> [src.on ? "<A href='?src=\ref[src];start=1'>Off</A> <B>On</B>" : "<B>Off</B> <A href='?src=\ref[src];start=1'>On</A>"]<BR>"
		dat += "[draw_beaker_text()]<BR>"
		dat += "--------------------------------<BR>"
		dat += "[draw_beaker_reagent_scan()]<BR>"
		dat += "[draw_defib_zap()]"
		dat += "[scan_health(src.occupant, reagent_scan_active, 1)]"

		update_medical_record(src.occupant)


		user << browse(dat, "window=cryo")
		onclose(user, "cryo")

	proc/draw_defib_zap()
		if (!src.defib)
			return ""
		else 
			if (src.occupant)
				return "<B>Defibrillate Occupant : <A href='?src=\ref[src];defib=1'>ZAP!!!</A></B> <BR>"
			else 
				return "<B>Defibrillate Occupant : No occupant!</B> <BR>"

	proc/draw_beaker_text()
		var/beaker_text = ""
		if(src.beaker)
			beaker_text = "<B>Beaker:</B> <A href='?src=\ref[src];eject=1'>Eject</A><BR>"
			beaker_text += "<B>Beaker Contents:</B> <A href='?src=\ref[src];show_beaker_contents=1'>[show_beaker_contents ? "Hide" : "Show"]</A> "
			if (show_beaker_contents)
				beaker_text += "<BR>[scan_reagents(src.beaker)]"
		else
			beaker_text = "<B>Beaker:</B> <FONT color=red>No beaker loaded</FONT>"

		return beaker_text

	proc/draw_beaker_reagent_scan()
		if (!reagent_scan_enabled)
			return ""
		else
			return "<B>Reagent Scan : </B>[ reagent_scan_active ? "<A href='?src=\ref[src];reagent_scan_active=1'>Off</A> <B>On</B>" : "<B>Off</B> <A href='?src=\ref[src];reagent_scan_active=1'>On</A>"]"

	Topic(href, href_list)
		if (( usr.machine==src && ((get_dist(src, usr) <= 1) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon/ai)))
			if(href_list["start"])
				src.on = !src.on
				build_icon()
			if(href_list["eject"])
				beaker:set_loc(src.loc)
				usr.put_in_hand(beaker)
				beaker = null
			if(href_list["show_beaker_contents"])
				show_beaker_contents = !show_beaker_contents
			if (href_list["reagent_scan_active"])
				reagent_scan_active = !reagent_scan_active
			if (href_list["defib"])
				src.defib.attack(src.occupant, usr)
			if (href_list["eject_occupant"])
				go_out()
			src.updateUsrDialog()
			src.add_fingerprint(usr)
			return

	attackby(var/obj/item/G as obj, var/mob/user as mob)
		if(istype(G, /obj/item/reagent_containers/glass))
			if(src.beaker)
				user.show_text("A beaker is already loaded into the machine.", "red")
				return

			src.beaker = G
			user.drop_item()
			G.set_loc(src)
			user.visible_message("[user] adds a beaker to \the [src]!", "You add a beaker to the [src]!")
			logTheThing("combat", user, null, "adds a beaker [log_reagents(G)] to [src] at [log_loc(src)].") // Rigging cryo is advertised in the 'Tip of the Day' list (Convair880).
			src.add_fingerprint(user)
		else if(istype(G, /obj/item/grab))
			if(!ismob(G:affecting))
				return
			if (src.occupant)
				user.show_text("The cryo tube is already occupied.", "red")
				return
			logTheThing("combat", user, G:affecting, "shoves %target% into [src] at [log_loc(src)].") // Ditto (Convair880).
			var/mob/M = G:affecting
			M.set_loc(src)
			src.occupant = M
			for (var/obj/O in src)
				if (O == src.beaker)
					continue
				O.set_loc(get_turf(src))
			src.add_fingerprint(user)
			build_icon()
			qdel(G)
		else if (istype(G, /obj/item/reagent_containers/syringe))
			//this is in syringe.dm
			logTheThing("combat", user, null, "injects [log_reagents(G)] to [src] at [log_loc(src)].")
			if (src.beaker == null)
				boutput(user, "<span style=\"color:red\">There is no beaker in [src] for you to inject reagents.</span>")
				return
			if (src.beaker:reagents.total_volume == src.beaker:reagents.maximum_volume)
				boutput(user, "<span style=\"color:red\">The beaker in [src] is full.</span>")
				return
			var/transferred = G.reagents.trans_to(src.beaker, 5)
			src.visible_message("<span style=\"color:red\"><B>[user] injects [transferred] into [src]!</B></span>")
			src.beaker:on_reagent_change()
			return
		else if (istype(G, /obj/item/device/healthanalyzer_upgrade))
			if (reagent_scan_enabled)
				boutput(user, "<span style=\"color:red\">This Cryo Cell already has a reagent scan upgrade!</span>")
				return
			else
				reagent_scan_enabled = 1
				boutput(user, "<span style=\"color:blue\">Reagent scan upgrade installed.</span>")
				playsound(src.loc ,"sound/items/Deconstruct.ogg", 80, 0)
				user.u_equip(G)
				qdel(G)
				return
		else if (istype(G, /obj/item/robodefibrilator))
			if (src.defib)
				boutput(user, "<span style=\"color:red\">[src] already has a Defibrillator installed.</span>")
			else
				var/obj/item/robodefibrilator/D = G
				src.defib = D
				boutput(user, "<span style=\"color:blue\">Defibrillator installed into [src].</span>")
				playsound(src.loc ,"sound/items/Deconstruct.ogg", 80, 0)
				user.u_equip(G)
		else if (istype(G, /obj/item/wrench))
			if (!src.defib)
				boutput(user, "<span style=\"color:red\">[src] does not have a Defibrillator installed.</span>")
			else
				src.defib.set_loc(src.loc)
				src.defib = null
				src.visible_message("<span style=\"color:red\">[user] removes the Defibrillator from [src].</span>")
				playsound(src.loc ,"sound/items/Ratchet.ogg", 50, 1)


		src.updateUsrDialog()
		return

	proc/add_overlays()
		src.overlays = list(O1)

	proc/build_icon()
		if(on)
			if(src.occupant)
				icon_state = "celltop_1"
			else
				icon_state = "celltop"
		else
			icon_state = "celltop-p"
		O1 = new /obj/overlay(  )
		O1.icon = 'icons/obj/Cryogenic2.dmi'
		if(src.node)
			O1.icon_state = "cryo_bottom_[src.on]"
		else
			O1.icon_state = "cryo_bottom"
		O1.pixel_y = -32.0
		src.pixel_y = 32
		add_overlays()

	proc/process_occupant()
		if(air_contents.total_moles() < 10)
			return
		if(occupant)
			if(occupant.stat == 2)
				return
			occupant.bodytemperature += 2*(air_contents.temperature - occupant.bodytemperature)*current_heat_capacity/(current_heat_capacity + air_contents.heat_capacity())
			occupant.bodytemperature = max(occupant.bodytemperature, air_contents.temperature) // this is so ugly i'm sorry for doing it i'll fix it later i promise
			var/mob/living/carbon/human/H = 0
			if (istype(occupant, /mob/living/carbon/human))
				H = occupant
			if (H && H.stat == 0) H.lastgasp()
			//occupant.stat = 1
			if(occupant.bodytemperature < T0C)
				if(air_contents.oxygen > 2)
					if(occupant.get_oxygen_deprivation())
						occupant.take_oxygen_deprivation(-10)
				else
					occupant.take_oxygen_deprivation(-2)
		if(beaker && (next_trans == 0))
			beaker:reagents.trans_to(occupant, 1, 10)
			beaker:reagents.reaction(occupant)
		next_trans++
		if(next_trans == 10)
			next_trans = 0

	proc/heat_gas_contents()
		if(air_contents.total_moles() < 1)
			return
		var/air_heat_capacity = air_contents.heat_capacity()
		var/combined_heat_capacity = current_heat_capacity + air_heat_capacity
		if(combined_heat_capacity > 0)
			var/combined_energy = T20C*current_heat_capacity + air_heat_capacity*air_contents.temperature
			air_contents.temperature = combined_energy/combined_heat_capacity

	proc/expel_gas()
		if(air_contents.total_moles() < 1)
			return
		var/datum/gas_mixture/expel_gas
		var/remove_amount = air_contents.total_moles()/100
		expel_gas = air_contents.remove(remove_amount)
		expel_gas.temperature = T20C // Lets expel hot gas and see if that helps people not die as they are removed
		loc.assume_air(expel_gas)

	proc/go_out()
		if(!( src.occupant ))
			return
		for (var/obj/O in src)
			if (O == src.beaker)
				continue
			O.set_loc(get_turf(src))
		src.occupant.set_loc(src.loc)
		src.occupant = null
		build_icon()
		return

	verb/move_eject()
		set src in oview(1)
		set category = "Local"
		if (usr.stat != 0)
			return
		src.go_out()
		add_fingerprint(usr)
		return

	verb/move_inside()
		set src in oview(1)
		set category = "Local"
		if (usr.stat != 0 || stat & (NOPOWER|BROKEN))
			return
		if (src.occupant)
			boutput(usr, "<span style=\"color:blue\"><B>The cell is already occupied!</B></span>")
			return
		if(!src.node)
			boutput(usr, "The cell is not corrrectly connected to its pipe network!")
			return

		if (usr.a_intent == INTENT_HELP)
			if (ishuman(usr))
				var/mob/living/carbon/human/H = usr
				usr.drop_from_slot(H.wear_suit, H.loc)
				usr.drop_from_slot(H.head, H.loc)
		usr.pulling = null
		usr.set_loc(src)
		src.occupant = usr
		for (var/obj/O in src)
			if (O == src.beaker)
				continue
			O.set_loc(get_turf(src))
		src.add_fingerprint(usr)
		build_icon()
		return





/mob/living/carbon/human/abiotic()
	if ((src.l_hand && !( src.l_hand.abstract )) || (src.r_hand && !( src.r_hand.abstract )) || (src.back || src.wear_mask || src.head || src.shoes || src.w_uniform || src.wear_suit || src.glasses || src.ears || src.gloves))
		return 1
	else
		return 0
	return

/mob/proc/abiotic()
	if ((src.l_hand && !( src.l_hand.abstract )) || (src.r_hand && !( src.r_hand.abstract )) || src.back || src.wear_mask)
		return 1
	else
		return 0
	return

/datum/data/function/proc/reset()
	return

/datum/data/function/proc/r_input(href, href_list, mob/user as mob)
	return

/datum/data/function/proc/display()
	return