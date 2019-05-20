/obj/item/gun/energy
	name = "energy weapon"
	icon = 'icons/obj/gun.dmi'
	item_state = "gun"
	m_amt = 2000
	g_amt = 1000
	mats = 16
	add_residue = 0 // Does this gun add gunshot residue when fired? Energy guns shouldn't.
	var/rechargeable = 1 // Can we put this gun in a recharger? False should be a very rare exception.
	var/robocharge = 800
	var/obj/item/ammo/power_cell/cell = null
	var/custom_cell_max_capacity = null // Is there a limit as to what power cell (in PU) we can use?
	var/wait_cycle = 0 // Using a self-charging cell should auto-update the gun's sprite.

	New()
		if (!cell)
			cell = new/obj/item/ammo/power_cell
		if (!(src in processing_items)) // No self-charging cell? Will be kicked out after the first tick (Convair880).
			processing_items.Add(src)
		..()

	disposing()
		if (src in processing_items)
			processing_items.Remove(src)
		..()

	examine()
		set src in usr
		if(src.cell)
			src.desc = "[src.projectiles ? "It is set to [src.current_projectile.sname]. " : ""]There are [src.cell.charge]/[src.cell.max_charge] PUs left!"
		else
			src.desc = "There is no cell loaded!"
		if(current_projectile)
			src.desc += " Each shot will currently use [src.current_projectile.cost] PUs!"
		else
			src.desc += "<span style=\"color:red\">*ERROR* No output selected!</span>"
		..()
		return

	update_icon()
		return 0

	emp_act()
		if (src.cell && istype(src.cell))
			src.cell.use(INFINITY)
			src.update_icon()
		return

	process()
		src.wait_cycle = !src.wait_cycle // Self-charging cells recharge every other tick (Convair880).
		if (src.wait_cycle)
			return

		if (!(src in processing_items))
			logTheThing("debug", null, null, "<b>Convair880</b>: Process() was called for an egun ([src]) that wasn't in the item loop. Last touched by: [src.fingerprintslast]")
			processing_items.Add(src)
			return
		if (!src.cell)
			processing_items.Remove(src)
			return
		if (!istype(src.cell, /obj/item/ammo/power_cell/self_charging)) // Plain cell? No need for dynamic updates then (Convair880).
			processing_items.Remove(src)
			return
		if (src.cell.charge == src.cell.max_charge) // Keep them in the loop, as we might fire the gun later (Convair880).
			return

		src.update_icon()
		return

	canshoot()
		if(src.cell && src.cell:charge && src.current_projectile)
			if(src.cell:charge >= src.current_projectile:cost)
				return 1
		return 0

	process_ammo(var/mob/user)
		if(istype(user,/mob/living/silicon/robot))
			var/mob/living/silicon/robot/R = user
			if(R.cell)
				if(R.cell.charge >= src.robocharge)
					R.cell.charge -= src.robocharge
					return 1
			return 0
		else
			if(src.cell && src.current_projectile)
				if(src.cell.use(src.current_projectile.cost))
					return 1
			boutput(user, "<span style=\"color:red\">*click* *click*</span>")
			return 0

	attackby(obj/item/b as obj, mob/user as mob)
		if (src.custom_cell_max_capacity && (b:max_charge > src.custom_cell_max_capacity))
			user.show_text("This power cell won't fit!", "red")
			return
		if (istype(b, /obj/item/ammo/power_cell) && !rechargeable)
			src.logme_temp(user, src, b)
			if (istype(b, /obj/item/ammo/power_cell/self_charging) && !(src in processing_items)) // Again, we want dynamic updates here (Convair880).
				processing_items.Add(src)
			if(src.cell)
				if(b:swap(src))
					user.visible_message("<span style=\"color:red\">[user] swaps [src]'s power cell.</span>")
			else
				src.cell = b
				user.drop_item()
				b.set_loc(src)
				user.visible_message("<span style=\"color:red\">[user] swaps [src]'s power cell.</span>")
		else
			..()

	attack_hand(mob/user as mob)
		if ((user.r_hand == src || user.l_hand == src) && src.contents && src.contents.len)
			if (src.cell&&!src.rechargeable)
				var/obj/item/ammo/power_cell/W = src.cell
				user.put_in_hand_or_drop(W)
				src.cell = null
				update_icon()
				src.add_fingerprint(user)
		else
			return ..()
		return

////////////////////////////////////TASERGUN
/obj/item/gun/energy/taser_gun
	name = "taser gun"
	icon_state = "taser"
	force = 1.0
	desc = "A weapon that produces an cohesive electrical charge that stuns its target."
	module_research = list("weapons" = 4, "energy" = 4, "miniaturization" = 2)

	New()
		current_projectile = new/datum/projectile/energy_bolt
		projectiles = list(current_projectile,new/datum/projectile/energy_bolt/burst)
		..()

	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "taser[ratio]"
			return

	borg
		New()
			cell = new/obj/item/ammo/power_cell/self_charging/slowcharge
			cell.max_charge = 100
			cell.charge = 100
			..()


/////////////////////////////////////LASERGUN
/obj/item/gun/energy/laser_gun
	name = "laser gun"
	icon_state = "laser"
	force = 7.0
	desc = "A gun that produces a harmful laser, causing substantial damage."
	module_research = list("weapons" = 4, "energy" = 4)

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/laser
		projectiles = list(current_projectile)
		..()

	virtual
		icon = 'icons/effects/VR.dmi'
		New()
			..()
			current_projectile = new /datum/projectile/laser/virtual
			projectiles.len = 0
			projectiles += current_projectile

	update_icon()
		if(cell)
			//Wire: Fix for Division by zero runtime
			var/maxCharge = (src.cell.max_charge > 0 ? src.cell.max_charge : 0)
			var/ratio = min(1, src.cell.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "laser[ratio]"
			return

////////////////////////////////////// Antique laser gun
// Part of a mini-quest thing (see displaycase.dm). Typically, the gun's properties (cell, projectile)
// won't be the default ones specified here, it's here to make it admin-spawnable (Convair880).
/obj/item/gun/energy/laser_gun/antique
	name = "antique laser gun"
	icon_state = "caplaser"
	desc = "Wait, that's not a plastic toy..."

	New()
		if (!src.cell)
			src.cell = new /obj/item/ammo/power_cell/med_power
		if (!src.current_projectile)
			src.current_projectile = new /datum/projectile/laser
		if (isnull(src.projectiles))
			src.projectiles = list(src.current_projectile)
		src.update_icon()
		..()

	update_icon()
		if (src.cell)
			var/maxCharge = (src.cell.max_charge > 0 ? src.cell.max_charge : 0)
			var/ratio = min(1, src.cell.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "caplaser[ratio]"
			return

//////////////////////////////////////// Phaser
/obj/item/gun/energy/phaser_gun
	name = "phaser gun"
	icon_state = "phaser-new"
	force = 7.0
	desc = "A gun that produces a harmful phaser bolt, causing substantial damage."
	module_research = list("weapons" = 4, "energy" = 4)

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/laser/light
		projectiles = list(current_projectile)
		..()

	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "phaser-new[ratio]"
			return

///////////////////////////////////////Rad Crossbow
/obj/item/gun/energy/crossbow
	name = "mini rad-poison-crossbow"
	desc = "A weapon favored by many of the syndicate's stealth specialists, which does damage over time using a slow-acting radioactive poison. Utilizes a self-recharging atomic power cell."
	icon_state = "crossbow"
	w_class = 2.0
	item_state = "crossbow"
	force = 4.0
	throw_speed = 3
	throw_range = 10
	rechargeable = 0 // Cannot be recharged manually.
	cell = new/obj/item/ammo/power_cell/self_charging/slowcharge
	current_projectile = new/datum/projectile/rad_bolt
	projectiles = null
	is_syndicate = 1
	silenced = 1 // No conspicuous text messages, please (Convair880).
	custom_cell_max_capacity = 100 // Those self-charging ten-shot radbows were a bit overpowered (Convair880)
	module_research = list("medicine" = 2, "science" = 2, "weapons" = 2, "energy" = 2, "miniaturization" = 10)

	New()
		current_projectile = new/datum/projectile/rad_bolt
		projectiles = list(current_projectile)
		..()

////////////////////////////////////////EGun
/obj/item/gun/energy/egun
	name = "energy gun"
	icon_state = "energy"
	desc = "Its a gun that has two modes, stun and kill"
	item_state = "gun"
	force = 5.0
	module_research = list("weapons" = 5, "energy" = 4, "miniaturization" = 5)

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/energy_bolt
		projectiles = list(current_projectile,new/datum/projectile/laser)
		..()
	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			if(current_projectile.type == /datum/projectile/energy_bolt)
				src.icon_state = "energystun[ratio]"
			else if (current_projectile.type == /datum/projectile/laser)
				src.icon_state = "energykill[ratio]"
			else
				src.icon_state = "energy[ratio]"
	attack_self()
		..()
		update_icon()

////////////////////////////////////VUVUV
/obj/item/gun/energy/vuvuzela_gun
	name = "amplified vuvuzela"
	icon_state = "vuvuzela"
	item_state = "bike_horn"
	desc = "BZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZT, *fart*"
	is_syndicate = 1

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/energy_bolt_v
		projectiles = list(current_projectile)
		..()
	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "vuvuzela[ratio]"

//////////////////////////////////////Disruptor
/obj/item/gun/energy/disruptor
	name = "Disruptor"
	icon_state = "disruptor"
	desc = "Disruptor Blaster - Comes equipped with self-charging powercell."
	m_amt = 4000
	force = 6.0

	New()
		cell = new/obj/item/ammo/power_cell/self_charging/disruptor
		current_projectile = new/datum/projectile/disruptor
		projectiles = list(current_projectile,new/datum/projectile/disruptor/burst,new/datum/projectile/disruptor/high)
		src.update_icon()
		..()

	update_icon()
		if (src.cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.20) * 100
			src.icon_state = "disruptor[ratio]"
		return

////////////////////////////////////Wave Gun
/obj/item/gun/energy/wavegun
	name = "Wave Gun"
	icon = 'icons/obj/gun.dmi'
	icon_state = "phaser"
	m_amt = 4000
	force = 6.0
	module_research = list("weapons" = 2, "energy" = 2, "miniaturization" = 3)

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/wavegun
		projectiles = list(current_projectile,new/datum/projectile/wavegun/burst,new/datum/projectile/wavegun/paralyze)
		..()

	// Old phasers aren't around anymore, so the wave gun might as well use their better sprite (Convair880).
	update_icon()
		if (src.cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "phaser[ratio]"
			return

////////////////////////////////////BFG
/obj/item/gun/energy/bfg
	name = "BFG 9000"
	icon = 'icons/obj/gun.dmi'
	icon_state = "bfg"
	m_amt = 4000
	force = 6.0
	desc = "I think it stands for Banned For Griefing?"
	module_research = list("weapons" = 25, "energy" = 25)

	New()
		cell = new/obj/item/ammo/power_cell/high_power
		current_projectile = new/datum/projectile/bfg
		projectiles = list(new/datum/projectile/bfg)
		..()

	update_icon()
		return

	shoot(var/target,var/start,var/mob/user)
		if (canshoot()) // No more attack messages for empty guns (Convair880).
			playsound(user, "sound/weapons/DSBFG.ogg", 75)
			sleep(9)
		return ..(target, start, user)

/obj/item/gun/energy/bfg/vr
	icon = 'icons/effects/VR.dmi'

///////////////////////////////////////Telegun
/obj/item/gun/energy/teleport
	name = "teleport gun"
	desc = "A hacked together combination of a taser and a handheld teleportation unit."
	icon_state = "teleport"
	w_class = 3.0
	item_state = "gun"
	force = 10.0
	throw_speed = 2
	throw_range = 10
	mats = 0
	var/obj/item/our_target = null
	var/obj/machinery/computer/teleporter/our_teleporter = null // For checks before firing (Convair880).
	module_research = list("weapons" = 3, "energy" = 2, "science" = 10)

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new /datum/projectile/tele_bolt
		projectiles = list(current_projectile)
		..()

	update_icon()
		if (!cell)
			icon_state = "teleport"
			return

		icon_state = "teleport[round((src.cell.charge / src.cell.max_charge), 0.25) * 100]"
		return

	// I overhauled everything down there. Old implementation made the telegun unreliable and crap, to be frank (Convair880).
	attack_self(mob/user as mob)
		src.add_fingerprint(user)

		var/list/L = list()
		L += "None (Cancel)" // So we'll always get a list, even if there's only one teleporter in total.

		for(var/obj/machinery/teleport/portal_generator/PG in machines)
			if (!PG.linked_computer || !PG.linked_rings)
				continue
			var/turf/PG_loc = get_turf(PG)
			if (PG && isrestrictedz(PG_loc.z)) // Don't show teleporters in "somewhere", okay.
				continue

			var/obj/machinery/computer/teleporter/Control = PG.linked_computer
			if (Control)
				switch (Control.check_teleporter())
					if (0) // It's busted, Jim.
						continue
					if (1)
						L["Tele at [get_area(Control)]: Locked in ([ismob(Control.locked.loc) ? "[Control.locked.loc.name]" : "[get_area(Control.locked)]"])"] += Control
					if (2)
						L["Tele at [get_area(Control)]: *NOPOWER*"] += Control
					if (3)
						L["Tele at [get_area(Control)]: Inactive"] += Control
			else
				continue

		if (L.len < 2)
			user.show_text("Error: no working teleporters detected.", "red")
			return

		var/t1 = input(user, "Please select a teleporter to lock in on.", "Target Selection") in L
		if ((user.equipped() != src) || user.stat || user.restrained())
			return
		if (t1 == "None (Cancel)")
			return

		var/obj/machinery/computer/teleporter/Control2 = L[t1]
		if (Control2)
			src.our_teleporter = null
			src.our_target = null
			switch (Control2.check_teleporter())
				if (0)
					user.show_text("Error: selected teleporter is out of order.", "red")
					return
				if (1)
					src.our_target = Control2.locked
					if (!our_target)
						user.show_text("Error: selected teleporter is locked in to invalid coordinates.", "red")
						return
					else
						user.show_text("Teleporter selected. Locked in on [ismob(Control2.locked.loc) ? "[Control2.locked.loc.name]" : "beacon"] in [get_area(Control2.locked)].", "blue")
						src.our_teleporter = Control2
						return
				if (2)
					user.show_text("Error: selected teleporter is unpowered.", "red")
					return
				if (3)
					user.show_text("Error: selected teleporter is not locked in.", "red")
					return
		else
			user.show_text("Error: couldn't establish connection to selected teleporter.", "red")
			return

	attack(mob/M as mob, mob/user as mob)
		if (!src.our_target)
			user.show_text("Error: no target set. Please select a teleporter first.", "red")
			return
		if (!src.our_teleporter || (src.our_teleporter.check_teleporter() != 1))
			user.show_text("Error: linked teleporter is out of order.", "red")
			return

		var/datum/projectile/tele_bolt/TB = current_projectile
		TB.target = our_target
		return ..(M, user)

	shoot(var/target, var/start, var/mob/user)
		if (!src.our_target)
			user.show_text("Error: no target set. Please select a teleporter first.", "red")
			return
		if (!src.our_teleporter || (src.our_teleporter.check_teleporter() != 1))
			user.show_text("Error: linked teleporter is out of order.", "red")
			return

		var/datum/projectile/tele_bolt/TB = current_projectile
		TB.target = our_target
		return ..(target, start, user)

///////////////////////////////////////Ghost Gun
/obj/item/gun/energy/ghost
	name = "ectoplasmic destabilizer"
	desc = "If this had streams, it would be inadvisable to cross them. But no, it fires bolts instead.  Don't throw it into a stream, I guess?"
	icon_state = "ghost"
	w_class = 3.0
	item_state = "gun"
	force = 10.0
	throw_speed = 2
	throw_range = 10
	mats = 0
	module_research = list("weapons" = 1, "energy" = 5, "science" = 10)

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new /datum/projectile/energy_bolt_antighost
		projectiles = list(current_projectile)
		..()

///////////////////////////////////////Modular Gun
/obj/item/gun/energy/mod
	name = "phaser"
	desc = "A modular energy sidearm. Can be upgraded with different kinds of modules. (WORK IN PROGRESS)"
	icon = 'icons/obj/gun_mod.dmi'
	icon_state = "pistol"
	w_class = 3.0
	force = 5.0
	mats = 0
	var/obj/item/gun_parts/emitter/emitter = null
	var/obj/item/gun_parts/back/back = null
	var/obj/item/gun_parts/top_rail/top_rail = null
	var/obj/item/gun_parts/bottom_rail/bottom_rail = null
	var/heat = 0 // for overheating stuff

	New()
		if (!emitter)
			emitter = new /obj/item/gun_parts/emitter
		if(!current_projectile)
			current_projectile = src.emitter.projectile
		projectiles = list(current_projectile)
		..()

	//handle gun mods at a workbench

	examine()
		set src in view()
		boutput(usr, "<span style=\"color:blue\">Installed components:</span><br>")
		if(emitter)
			boutput(usr, "<span style=\"color:blue\">[src.emitter.name]</span>")
		if(cell)
			boutput(usr, "<span style=\"color:blue\">[src.cell.name]</span>")
		if(back)
			boutput(usr, "<span style=\"color:blue\">[src.back.name]</span>")
		if(top_rail)
			boutput(usr, "<span style=\"color:blue\">[src.top_rail.name]</span>")
		if(bottom_rail)
			boutput(usr, "<span style=\"color:blue\">[src.bottom_rail.name]</span>")
		..()

	/*proc/generate_overlays()
		src.overlays = null
		if(extension_mod)
			src.overlays += icon('icons/obj/gun_mod.dmi',extension_mod.overlay_name)
		if(converter_mod)
			src.overlays += icon('icons/obj/gun_mod.dmi',converter_mod.overlay_name)*/
	/*proc/update_icon()
		var/ratio = src.charges / maximum_charges
		ratio = round(ratio, 0.25) * 100
		src.icon_state = text("phaser[]", ratio)*/

///////////modular components - putting them her so it's easier to work on for now////////

/obj/item/gun_parts
	name = "gun parts"
	desc = "Components for building custom sidearms."
	item_state = "table_parts"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon = 'icons/obj/gun_mod.dmi'
	icon_state = "frame" // todo: make more item icons
	mats = 0

/obj/item/gun_parts/emitter
	name = "optical pulse emitter"
	desc = "Generates a pulsed burst of energy."
	icon_state = "emitter"
	var/datum/projectile/laser/light/projectile = new/datum/projectile/laser/light
	var/obj/item/device/flash/flash = new/obj/item/device/flash
	//use flash as the core of the device

	// inherit material vars from the flash

/obj/item/gun_parts/back
	name = "phaser stock"
	desc = "A gun stock for a modular phaser. Does this even do anything? Probably not."
	icon_state = "mod-stock"

/obj/item/gun_parts/top_rail
	name = "phaser pulse modifier"
	desc = "Modifies the beam path of modular phaser."
	icon_state = "mod-range"

	range
		name = "beam collimator"
		icon_state = "mod-range"

	width
		name = "beam spreader"
		icon_state = "mod-aoe"

/obj/item/gun_parts/bottom_rail
	name = "Phaser accessory"

	sight
		name = "phaser dot accessory"
		icon_state = "mod-sight"
		// idk what the hell this would even do

	flashlight
		name = "phaser flashlight accessory"
		icon_state = "mod-flashlight"

	heatsink
		name = "phaser heatsink"
		icon_state = "mod-heatsink"

	grip // tacticool
		name = "fore grip"
		icon_state = "mod-grip"

///////////////////////////////////////Owl Gun
/obj/item/gun/energy/owl
	name = "Owl gun"
	desc = "Its a gun that has two modes, Owl and Owler"
	item_state = "gun"
	force = 5.0
	icon_state = "ghost"

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/owl
		projectiles = list(current_projectile,new/datum/projectile/owl/owlate)
		..()
	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "energy[ratio]"

/obj/item/gun/energy/owl_safe
	name = "Owl gun"
	desc = "Hoot!"
	item_state = "gun"
	force = 5.0
	icon_state = "ghost"

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/owl
		projectiles = list(current_projectile)
		..()
	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "energy[ratio]"

///////////////////////////////////////Shrink Ray
/obj/item/gun/energy/shrinkray
	name = "Shrink ray"
	item_state = "gun"
	force = 5.0
	icon_state = "ghost"

	New()
		cell = new/obj/item/ammo/power_cell/med_power
		current_projectile = new/datum/projectile/shrink_beam
		projectiles = list(current_projectile)
		..()
	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "energy[ratio]"

///////////////////////////////////////Glitch Gun
/obj/item/gun/energy/glitch_gun
	name = "Glitch Gun"
	icon = 'icons/obj/gun.dmi'
	icon_state = "airzooka"
	m_amt = 4000
	force = 0.0
	desc = "It's humming with some sort of disturbing energy. Do you really wanna hold this?"

	New()
		cell = new/obj/item/ammo/power_cell/high_power
		current_projectile = new/datum/projectile/bullet/glitch/gun
		projectiles = list(new/datum/projectile/bullet/glitch/gun)
		..()

	update_icon()
		return

	shoot(var/target,var/start,var/mob/user,var/POX,var/POY)
		if (canshoot()) // No more attack messages for empty guns (Convair880).
			playsound(user, "sound/weapons/DSBFG.ogg", 75)
			sleep(1)
		return ..(target, start, user)

///////////////////////////////////////Predator
/obj/item/gun/energy/laser_gun/pred // Made use of a spare sprite here (Convair880).
	name = "laser rifle"
	desc = "This advanced bullpup rifle contains a self-recharging power cell."
	icon_state = "bullpup"
	force = 5.0

	New()
		..()
		cell = new/obj/item/ammo/power_cell/self_charging/big
		current_projectile = new/datum/projectile/laser/pred
		projectiles = list(new/datum/projectile/laser/pred)

	update_icon()
		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "bullpup[ratio]"
			return

/obj/item/gun/energy/laser_gun/pred/vr
	name = "advanced laser gun"
	icon = 'icons/effects/VR.dmi'
	icon_state = "wavegun"

	update_icon() // Necessary. Parent's got a different sprite now (Convair880).
		return


///////////////////////////////////////////////////
/obj/item/gun/energy/lawgiver
	name = "Lawgiver"
	icon = 'icons/obj/lawgiver.dmi'
	item_state = "lawgiver0"
	icon_state = "lawgiver0"
	m_amt = 5000
	g_amt = 2000
	mats = 16
	var/owner_prints = null
	var/image/indicator_display = null
	rechargeable = 0

	New(var/mob/M)
		cell = new/obj/item/ammo/power_cell/self_charging/lawgiver
		current_projectile = new/datum/projectile/energy_bolt/aoe
		projectiles = list(current_projectile,new/datum/projectile/bullet/revolver_38,new/datum/projectile/bullet/smoke,new/datum/projectile/bullet/tranq_dart,new/datum/projectile/bullet/flare,new/datum/projectile/bullet/aex/lawgiver,new/datum/projectile/bullet/clownshot)
		
		src.indicator_display = image('icons/obj/lawgiver.dmi', "")
		asign_name(M)

		update_icon()
		..()

	disposing()
		indicator_display = null
		..()

	//if it has no owner prints scanned, the next person to attack_self it is the owner. 
	//you have to use voice activation to change modes. haha!
	attack_self(mob/user as mob)
		src.add_fingerprint(user)
		if (!owner_prints)
			boutput(user, "<span style=\"color:red\">[src] has accepted your fingerprint ID. You are its owner!</span>")
			asign_name(user)
		else
			boutput(user, "<span style=\"color:blue\">There don't see to be any buttons on [src] to press.</span>")

	proc/asign_name(var/mob/M)
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.bioHolder)
				owner_prints = md5(H.bioHolder.Uid)
				src.name = "HoS [H.real_name]'s Lawgiver"

	//stolen the heartalk of microphone. the microphone can hear you from one tile away. unless you wanna
	hear_talk(mob/M as mob, msg, real_name, lang_id)
		var/turf/T = get_turf(src)
		if (M in range(1, T))
			src.talk_into(M, msg, null, real_name, lang_id)

	//can only handle one name at a time, if it's more it doesn't do anything
	talk_into(mob/M as mob, msg, real_name, lang_id)
		//Do I need to check for this? I can't imagine why anyone would pass the wrong var here...
		if (!islist(msg))
			return

		//only work if the voice is the same as the voice of your owner fingerprints. 
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (owner_prints && (md5(H.bioHolder.Uid) != owner_prints))
				are_you_the_law(M, msg[1])
				return
		else
			are_you_the_law(M, msg[1])
			return //AFAIK only humans have fingerprints/"palmprints(in judge dredd)" so just ignore any talk from non-humans arlight? it's not a big deal.


		var/text = msg[1]
		text = sanitize_talk(text)
		if (fingerprints_can_shoot(M))
			switch(text)
				if ("detain")
					current_projectile = new/datum/projectile/energy_bolt/aoe
					playsound(M, "sound/vox/detain.ogg", 75)
				if ("execute")
					current_projectile = new/datum/projectile/bullet/revolver_38
					current_projectile.cost = 30
					playsound(M, "sound/vox/exterminate.ogg", 75)
				if ("smokeshot")
					current_projectile = new/datum/projectile/bullet/smoke
					current_projectile.cost = 100
					playsound(M, "sound/vox/smoke.ogg", 75)
				if ("knockout")
					current_projectile = new/datum/projectile/bullet/tranq_dart
					current_projectile.cost = 150
					playsound(M, "sound/vox/sleep.ogg", 75)
				if ("hotshot")
					current_projectile = new/datum/projectile/bullet/flare
					current_projectile.cost = 60					
					playsound(M, "sound/vox/hot.ogg", 75)
				if ("bigshot","highexplosive","he")
					current_projectile = new/datum/projectile/bullet/aex/lawgiver
					playsound(M, "sound/vox/high.ogg", 75)
					sleep(4)
					playsound(M, "sound/vox/explosive.ogg", 75)
				if ("clownshot")
					current_projectile = new/datum/projectile/bullet/clownshot
					playsound(M, "sound/vox/clown.ogg", 75)

			update_icon()

	//Are you really the law? takes the mob as speaker, and the text spoken, sanitizes it. If you say "i am the law" and you in fact are NOT the law, it's gonna blow. Moved out of the switch statement because it that switch is only gonna run if the owner speaks
	proc/are_you_the_law(mob/M as mob, text)
		text = sanitize_talk(text)
		if (text == "iamthelaw")
			//you must be holding/wearing the weapon
			//this check makes it so that someone can't stun you, stand on top of you and say "I am the law" to kill you
			if (src in M.contents)
				if (M.job != "Head of Security")
					playsound(src.loc, "sound/weapons/armbomb.ogg", 75, 1, -3)

					spawn(20)
						explosion_new(null, get_turf(src), 15)
					return 0
				else
					return 1

	//all gun modes use the same base sprite icon "lawgiver0" depending on the current projectile/current mode, we apply a coloured overlay to it.
	update_icon()
		src.icon_state = "lawgiver0"
		src.overlays = null

		if(cell)
			var/ratio = min(1, src.cell.charge / src.cell.max_charge)
			ratio = round(ratio, 0.25) * 100
			//if we're showing zero charge, don't do any overlay, since the main image shows an empty gun anyway
			if (ratio == 0)
				return
			indicator_display.icon_state = "lawgiver-d[ratio]"

			if(current_projectile.type == /datum/projectile/energy_bolt/aoe)			//detain - yellow
				indicator_display.color = "#FFFF00"
			else if (current_projectile.type == /datum/projectile/bullet/revolver_38)			//execute - cyan
				indicator_display.color = "#00FFFF"
			else if (current_projectile.type == /datum/projectile/bullet/smoke)			//smokeshot - dark-blue
				indicator_display.color = "#0000FF"
			else if (current_projectile.type == /datum/projectile/bullet/tranq_dart)	//knockout - green
				indicator_display.color = "#008000"
			else if (current_projectile.type == /datum/projectile/bullet/flare)			//hotshot - red
				indicator_display.color = "#FF0000"
			else if (current_projectile.type == /datum/projectile/bullet/aex/lawgiver)	//bigshot - purple
				indicator_display.color = "#551A8B"
			else if (current_projectile.type == /datum/projectile/bullet/clownshot)		//clownshot - pink
				indicator_display.color = "#FFC0CB"
			else
				indicator_display.color = "#000000"				//default, should never reach. make it black
			src.overlays += indicator_display

	//just remove all capitalization and non-letter characters
	proc/sanitize_talk(var/msg)
		//find all characters that are not letters and remove em
		var/regex/r = regex("\[^a-z\]+", "g")
		msg = lowertext(msg)
		msg = r.Replace(msg, "")
		return msg

	// Checks if the gun can shoot based on the fingerprints of the shooter.
	//returns true if the prints match or there are no prints stored on the gun(emagged). false if it fails
	proc/fingerprints_can_shoot(var/mob/user)
		if (!owner_prints || (md5(user.bioHolder.Uid) == owner_prints))
			return 1
		return 0


	shoot(var/target,var/start,var/mob/user)
		if (canshoot())
			//shock the guy who tries to use this if they aren't the proper owner. (or if the gun is not emagged)
			if (!fingerprints_can_shoot(user))
				// shock(user, 70)	
				random_burn_damage(user, 50)
				user.weakened += 4
				var/datum/effects/system/spark_spread/s = unpool(/datum/effects/system/spark_spread)
				s.set_up(2, 1, (get_turf(src)))
				s.start()
				user.visible_message("<span style=\"color:red\">[user] tries to fire [src]! The gun initiates its failsafe mode.</span>")
				return

			//// removed for now, but this code will allow for the projectile to detonate at the specific tile clicked by the user.
			// if (!istype(target, /turf) || !istype(start, /turf))
			// 	return
			// if (current_projectile.type == /datum/projectile/energy_bolt/aoe)
			// 	var/turf/T = target
			// 	var/turf/S = start
			// 	var/datum/projectile/energy_bolt/aoe/P = current_projectile
			// 	P.distance = get_dist(T,S)

		return ..(target, start, user)

	//gotta override this to set the desc name to the proper thing
	examine()
		set src in usr
		var/gun_setting_name = "detain"
		if(current_projectile.type == /datum/projectile/energy_bolt/aoe)
			gun_setting_name = "detain"
		else if (current_projectile.type == /datum/projectile/bullet/revolver_38)
			gun_setting_name = "execute"
		else if (current_projectile.type == /datum/projectile/bullet/smoke)
			gun_setting_name = "smokeshot"
		else if (current_projectile.type == /datum/projectile/bullet/tranq_dart)
			gun_setting_name = "knockout"
		else if (current_projectile.type == /datum/projectile/bullet/flare)
			gun_setting_name = "hotshot"
		else if (current_projectile.type == /datum/projectile/bullet/aex/lawgiver)
			gun_setting_name = "bigshot"
		else if (current_projectile.type == /datum/projectile/bullet/clownshot)
			gun_setting_name = "clownshot"

		src.desc = "It is set to [gun_setting_name]."
		if(src.cell)
				//[src.projectiles ? "It will use the projectile: [src.current_projectile.sname]. " : ""]
			src.desc += "There are [src.cell.charge]/[src.cell.max_charge] PUs left!"
		else
			src.desc += "There is no cell loaded!"
		if(current_projectile)
			src.desc += " Each shot will currently use [src.current_projectile.cost] PUs!"
		else
			src.desc += "<span style=\"color:red\">*ERROR* No output selected!</span>"
		return
	

/obj/item/gun/energy/lawgiver/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (user)
		boutput(user, "<span style=\"color:red\">Anyone can use this gun now. Be careful! (use it in-hand to register your fingerprints)</span>")
		owner_prints = null
	return 0
