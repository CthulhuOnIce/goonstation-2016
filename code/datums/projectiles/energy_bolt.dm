/datum/projectile/energy_bolt
	name = "energy bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "spark"
//How much of a punch this has, tends to be seconds/damage before any resist
	power = 15
//How much ammo this costs
	cost = 15
//How fast the power goes away
	dissipation_rate = 2
//How many tiles till it starts to lose power
	dissipation_delay = 2
//Kill/Stun ratio
	ks_ratio = 0.0
//name of the projectile setting, used when you change a guns setting
	sname = "stun"
//file location for the sound you want it to play
	shot_sound = 'sound/weapons/Taser.ogg'
//How many projectiles should be fired, each will cost the full cost
	shot_number = 1
//What is our damage type
/*
kinetic - raw power
piercing - punches though things
slashing - cuts things
energy - energy
burning - hot
radioactive - rips apart cells or some shit
toxic - poisons
*/
	damage_type = D_ENERGY
	//With what % do we hit mobs laying down
	hit_ground_chance = 0
	//Can we pass windows
	window_pass = 0
	brightness = 1
	color_red = 0.9
	color_green = 0.9
	color_blue = 0.1

	disruption = 8

	on_pointblank(var/obj/projectile/P, var/mob/living/M)
		stun_bullet_hit(P, M)


//Any special things when it hits shit?
	on_hit(atom/hit)
		if (ishuman(hit))
			var/mob/living/carbon/human/H = hit
			H.slowed = max(2, H.slowed)
			H.change_misstep_chance(5)
			H.emote("twitch_v")
		return

/datum/projectile/energy_bolt/robust
	power = 45
	dissipation_rate = 6

/datum/projectile/energy_bolt/burst
	shot_number = 3
	cost = 50
	sname = "burst stun"

/datum/projectile/energy_bolt/aoe
	icon = 'icons/obj/lawgiver.dmi'
	icon_state = "detain-projectile"
	power = 20
	cost = 50
	dissipation_rate = 6
	color_red = 255
	color_green = 165
	color_blue = 0
	var/distance = 6		//Distance needs to be explicitly set before usage. in shoot// currently only used for the Lawgiver
	var/hit = 0				//This hit var and the on_hit on_end nonsense was to make it so that if it hits a guy, the explosion starts on them and not one tile before, but if it hits a wall, it explodes on the floor tile in front of it

	//die/detonate when you go the required distance
	tick(var/obj/projectile/O)
		if (distance <= 0)
			O.die()
		distance--

	on_hit(atom/O)

		//lets make getting hit by the projectile a bit worse than getting the shockwave
		//tasers have changed in production code, I'm not really sure what value is good to give it here...
		if (ishuman(O))
			var/mob/living/carbon/human/H = O
			H.slowed = max(5, H.slowed)
			H.change_misstep_chance(10)
			H.emote("twitch_v")


		hit = 1

		detonate(O)

	//do AOE stuff. This is not on on_hit because this effect should trigger when the projectile reaches the end of its distance OR hits things.
	on_end(var/obj/projectile/O)
		distance = 6		//reset distance for next shot
		//if we hit a mob or something, that will handle the detonation, we don't need to do it on_end
		if (!hit)
			detonate(O)
		hit = 0

	proc/detonate(atom/O)
		if (istype(O, /obj/projectile))
			var/obj/projectile/proj = O
			new /obj/effects/energy_bolt_aoe_burst(get_turf(proj), x_val = proj.xo, y_val = proj.yo)
		else
			new /obj/effects/energy_bolt_aoe_burst(get_turf(O))

		for (var/mob/M in orange(O, 1))
			if (ishuman(M))

				var/mob/living/carbon/human/H = M
				H.slowed = max(2, H.slowed)
				H.change_misstep_chance(5)
				H.emote("twitch_v")
			return

/obj/effects/energy_bolt_aoe_burst
	name = "shockwave"
	desc = ""
	density = 0
	icon = 'icons/obj/lawgiver.dmi'
	icon_state = "shockwave"

	New(var/x_val, var/y_val)
		pixel_x = x_val
		pixel_y = y_val
		src.Scale(0.4,0.4)
		animate(src, matrix(2, MATRIX_SCALE), time = 6, color = "#ffdddd", easing = LINEAR_EASING)
		var/matrix/m1 = transform
		var/matrix/m2 = transform
		m1.Scale(7,7)
		m2.Scale(0.4,0.4)
		transform = m2
		animate(src,transform=m1,time=5)
		animate(transform=m2,time=7)

		
		spawn(12) del(src)
		

//////////// VUVUZELA
/datum/projectile/energy_bolt_v
	name = "vuvuzela bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "v_sound"
//How much of a punch this has, tends to be seconds/damage before any resist
	power = 50 // 100 was way too fucking long what the HECK
//How much ammo this costs
	cost = 25
//How fast the power goes away
	dissipation_rate = 5
//How many tiles till it starts to lose power
	dissipation_delay = 1
//Kill/Stun ratio
	ks_ratio = 0.0
//name of the projectile setting, used when you change a guns setting
	sname = "sonic wave"
//file location for the sound you want it to play
	shot_sound = 'sound/items/vuvuzela.ogg'
//How many projectiles should be fired, each will cost the full cost
	shot_number = 1
//What is our damage type
/*
kinetic - raw power
piercing - punches though things
slashing - cuts things
energy - energy
burning - hot
radioactive - rips apart cells or some shit
toxic - poisons
*/
	damage_type = D_ENERGY
	//With what % do we hit mobs laying down
	hit_ground_chance = 0
	//Can we pass windows
	window_pass = 0

	disruption = 0

//Any special things when it hits shit?
	on_hit(atom/hit)
		if (isliving(hit) && !issilicon(hit))
			var/mob/living/L = hit
			L.apply_sonic_stun(0, 0, 25, 10, 0, rand(1, 3))
		return

	on_pointblank(var/obj/projectile/P, var/mob/living/M)
		if (isliving(M) && !issilicon(M))
			M.apply_sonic_stun(0, 0, 25, 20, 0, rand(2, 4))
		stun_bullet_hit(P, M)

//////////// Ghost Hunting for Halloween
/datum/projectile/energy_bolt_antighost
	name = "ectoplasmic bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "green_spark"
//How much of a punch this has, tends to be seconds/damage before any resist
	power = 2
//How much ammo this costs
	cost = 25
//How fast the power goes away
	dissipation_rate = 2
//How many tiles till it starts to lose power
	dissipation_delay = 4
//Kill/Stun ratio
	ks_ratio = 0.0
//name of the projectile setting, used when you change a guns setting
	sname = "deghostify"
//file location for the sound you want it to play
	shot_sound = 'sound/weapons/Taser.ogg'
//How many projectiles should be fired, each will cost the full cost
	shot_number = 1

	damage_type = D_ENERGY
	//With what % do we hit mobs laying down
	hit_ground_chance = 0
	//Can we pass windows
	window_pass = 0
	brightness = 0.8
	color_red = 0.2
	color_green = 0.8
	color_blue = 0.2

	disruption = 0
