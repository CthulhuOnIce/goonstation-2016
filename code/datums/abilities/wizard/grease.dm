/datum/targetable/spell/grease
	name = "Grease"
	desc = "Lubes the floor around the target area"
	icon_state = "grease"
	targeted = 1
	target_anything = 1
	cooldown = 400
	requires_robes = 1
	offensive = 1
	sticky = 1

	cast(atom/target)
		if(!holder)
			return

		holder.owner.say("TEW RLOOF")
		playsound(holder.owner.loc, "sound/voice/wizard/PandemoniumLoud.ogg", 50, 0, -1)

		var/turf/simulated/T = get_turf(target)
		if (holder.owner.wizard_spellpower())
			for (var/turf/simulated/TF in orange(2,T))
				TF.wet = 2
				spawn(350)
					TF.wet = 0
		else
			boutput(holder.owner, "<span style=\"color:red\">Your spell is weak without a staff to focus it!</span>")
			for (var/turf/simulated/TF in orange(1,T))
				TF.wet = 2
				spawn(350)
					TF.wet = 0

		particleMaster.SpawnSystem(new /datum/particleSystem/sonic_burst(target))
		boutput(holder.owner, "<span style=\"color:red\">You grease the area.</span>")
		playsound(target.loc, "sound/effects/slosh.ogg", 25, 1, -1)
