//Unlockable traits? tied to achievements?
#define TRAIT_STARTING_POINTS 1 //How many "free" points you get
#define TRAIT_MAX 6			    //How many traits people can select at most.

/proc/getTraitById(var/id)
	return traitList[id]

/proc/traitCategoryAllowed(var/list/targetList, var/idToCheck)
	var/obj/trait/C = getTraitById(idToCheck)
	if(C.category == null) return 1
	for(var/A in targetList)
		var/obj/trait/T = getTraitById(A)
		if(T.category == C.category) return 0
	return 1

/datum/traitPreferences
	var/list/traits_selected = list()

	var/point_total = TRAIT_STARTING_POINTS
	var/free_points = TRAIT_STARTING_POINTS

	proc/selectTrait(var/id)
		if(!traits_selected.Find(id) && traitList.Find(id))
			traits_selected.Add(id)
		calcTotal()
		return 1

	proc/unselectTrait(var/id)
		if(traits_selected.Find(id))
			traits_selected.Remove(id)
		calcTotal()
		return 1

	proc/calcTotal()
		var/sum = free_points
		for(var/T in traits_selected)
			if(traitList.Find(T))
				var/obj/trait/O = traitList[T]
				sum += O.points
		point_total = sum
		return sum

	proc/isValid()
		var/list/categories = list()
		for(var/A in traits_selected)
			var/obj/trait/T = getTraitById(A)
			if(T.unselectable) return 0
			if(T.category != null)
				if(categories.Find(T.category)) return 0
				else categories.Add(T.category)
		return (calcTotal() >= 0)

	proc/updateTraits(var/mob/user)
		if(!winexists(user, "traitssetup_[user.ckey]"))
			winclone(user, "traitssetup", "traitssetup_[user.ckey]")

		var/list/selected = list()
		var/list/available = list()

		for(var/X in traitList)
			var/obj/trait/C = getTraitById(X)
			if(C.unselectable) continue
			if(traits_selected.Find(X)) selected += X
			else available += X

		winset(user, "traitssetup_[user.ckey].traitsSelected", "cells=\"1x[selected.len]\"")
		var/countSel = 0
		for(var/S in selected)
			winset(user, "traitssetup_[user.ckey].traitsSelected", "current-cell=1,[++countSel]")
			user << output(traitList[S], "traitssetup_[user.ckey].traitsSelected")

		winset(user, "traitssetup_[user.ckey].traitsAvailable", "cells=\"1x[available.len]\"")
		var/countAvail = 0
		for(var/A in available)
			winset(user, "traitssetup_[user.ckey].traitsAvailable", "current-cell=1,[++countAvail]")
			user << output(traitList[A], "traitssetup_[user.ckey].traitsAvailable")

		winset(user, "traitssetup_[user.ckey].traitPoints", "text=\"Points left : [calcTotal()]\"&text-color=\"[calcTotal() > 0 ? "#00AA00" : "#AA0000"]\"")
		return

	proc/showTraits(var/mob/user)
		if(!winexists(user, "traitssetup_[user.ckey]"))
			winclone(user, "traitssetup", "traitssetup_[user.ckey]")

		winshow(user, "traitssetup_[user.ckey]")
		updateTraits(user)

		user << browse(null, "window=preferences")
		return


/datum/traitHolder
	var/list/traits = list()
	var/mob/owner = null

	New(var/mob/ownerMob)
		owner = ownerMob
		return ..()

	proc/addTrait(id)
		if(!traits.Find(id) && owner)
			traits.Add(id)
			var/obj/trait/T = traitList[id]
			T.onAdd(owner)
		return

	proc/removeTrait(id)
		if(traits.Find(id) && owner)
			traits.Remove(id)
			var/obj/trait/T = traitList[id]
			T.onRemove(owner)
		return

	proc/hasTrait(var/id)
		return traits.Find(id)

//Yes these are objs because grid control. Shut up. I don't like it either.
/obj/trait
	icon = 'icons/ui/traits.dmi'
	icon_state = "placeholder"
	var/id = ""        //Unique ID
	var/points = 0	   //The change in points when this is selected.
	var/isPositive = 1 //Is this a positive, good effect or a bad one.
	var/category = null //If set to a non-null string, People will only be able to pick one trait of any given category
	var/unselectable = 0 //If 1 , trait can not be select at char setup
	var/cleanName = ""   //Name without any additional information.

	proc/onAdd(var/mob/owner)
		return

	proc/onRemove(var/mob/owner)
		return

	proc/onLife(var/mob/owner)
		return

	proc/onHear(var/mob/owner, var/message)
		return

	Click(location,control,params)
		if(control)
			if(control == "traitssetup_[usr.ckey].traitsAvailable")
				if(!usr.client.preferences.traitPreferences.traits_selected.Find(id))
					if(traitCategoryAllowed(usr.client.preferences.traitPreferences.traits_selected, id))
						if(usr.client.preferences.traitPreferences.traits_selected.len >= TRAIT_MAX)
							alert(usr, "You can not select more than [TRAIT_MAX] traits.")
						else
							if(((usr.client.preferences.traitPreferences.calcTotal()) + points) < 0)
								alert(usr, "You do not have enough points available to select this trait.")
							else
								usr.client.preferences.traitPreferences.selectTrait(id)
					else
						alert(usr, "You can only select one trait of this category.")
			else if (control == "traitssetup_[usr.ckey].traitsSelected")
				if(usr.client.preferences.traitPreferences.traits_selected.Find(id))
					if(((usr.client.preferences.traitPreferences.calcTotal()) - points) < 0)
						alert(usr, "Removing this trait would leave you with less than 0 points. Please remove a different trait.")
					else
						usr.client.preferences.traitPreferences.unselectTrait(id)

			usr.client.preferences.traitPreferences.updateTraits(usr)
		return

	MouseEntered(location,control,params)
		if(winexists(usr, "traitssetup_[usr.ckey]"))
			winset(usr, "traitssetup_[usr.ckey].traitName", "text=\"[name]\"")
			winset(usr, "traitssetup_[usr.ckey].traitDesc", "text=\"[desc]\"")
		return

/obj/trait/alcoholic
	name = "Career alcoholic (0)"
	cleanName = "Career alcoholic"
	desc = "You gain alcohol resistance but your speech is permanently slurred."
	id = "alcoholic"
	points = 0
	isPositive = 1

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			owner.bioHolder.AddEffect("resist_alcohol")
		return

/obj/trait/roboarms
	name = "Robotic arms (0) \[Body\]"
	cleanName = "Robotic arms"
	desc = "Your arms have been replaced with light robotic arms."
	id = "roboarms"
	points = 0
	isPositive = 1
	category = "body"

	onAdd(var/mob/owner)
		spawn(40) //Fuck this. Fuck the way limbs are added with a delay. FUCK IT
			if(istype(owner, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = owner
				if(H.limbs != null)
					H.limbs.l_arm = new /obj/item/parts/robot_parts/arm/left/light(H)
					H.limbs.r_arm = new /obj/item/parts/robot_parts/arm/right/light(H)
					H.update_body()
		return

/obj/trait/swedish
	name = "Swedish (0) \[Language\]"
	cleanName = "Swedish"
	desc = "You are from sweden. Meat balls and so on."
	id = "swedish"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			owner.bioHolder.AddEffect("accent_swedish")
		return

/obj/trait/chav
	name = "Chav (0) \[Language\]"
	cleanName = "Chav"
	desc = "U wot m8? I sware i'll fite u."
	id = "chav"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			owner.bioHolder.AddEffect("accent_chav")
		return

/obj/trait/tommy
	name = "New Jersey Accent (0) \[Language\]"
	cleanName = "New Jersey Accent"
	desc = "Ha ha ha. What a story, Mark."
	id = "tommy"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			owner.bioHolder.AddEffect("accent_tommy")
		return

/obj/trait/addict
	name = "Addict (+2)"
	cleanName = "Addict"
	desc = "You spawn with a random addiction. Once cured there is a small chance that you will suffer a relapse."
	id = "addict"
	icon_state = "syringe"
	points = 2
	isPositive = 0
	var/selected_reagent = "ethanol"

	New()
		selected_reagent = pick("bath salts", "lysergic acid diethylamide", "space drugs", "tetrahydrocannabinol", "psilocybin", "cat drugs", "methamphetamine")
		. = ..()

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			addAddiction(owner)
		return

	onLife(var/mob/owner) //Just to be safe.
		if(istype(owner, /mob/living/carbon/human) && prob(1))
			var/mob/living/carbon/human/M = owner
			for(var/datum/ailment_data/addiction/A in M.ailments)
				if(istype(A, /datum/ailment_data/addiction))
					if(A.associated_reagent == selected_reagent) return
			addAddiction(owner)
		return

	proc/addAddiction(var/mob/owner)
		var/mob/living/carbon/human/M = owner
		var/datum/ailment_data/addiction/AD = new
		AD.associated_reagent = selected_reagent
		AD.last_reagent_dose = world.timeofday
		AD.name = "[selected_reagent] addiction"
		AD.affected_mob = M
		M.ailments += AD
		return

/obj/trait/strongwilled
	name = "Strong willed (-1)"
	cleanName = "Strong willed"
	desc = "You are more resistant to addiction."
	id = "strongwilled"
	points = -1
	isPositive = 1

/obj/trait/unionized
	name = "Unionized (-1)"
	cleanName = "Unionized"
	desc = "You start with a higher paycheck than normal."
	id = "unionized"
	points = -1
	isPositive = 1

/obj/trait/jailbird
	name = "Jailbird (0)"
	cleanName = "Jailbird"
	desc = "You have a criminal record and are currently on the run!"
	id = "jailbird"
	points = 0
	isPositive = 0

/obj/trait/clericalerror
	name = "Clerical Error (0)"
	cleanName = "Clerical Error"
	desc = "The name on your starting ID is misspelled."
	id = "clericalerror"
	points = 0
	isPositive = 1

/obj/trait/slowmetabolism
	name = "Slow Metabolism (0)"
	cleanName = "Slow Metabolism"
	desc = "Any chemicals in you body deplete much more slowly."
	id = "slowmetabolism"
	points = 0
	isPositive = 1

/obj/trait/chemresist
	name = "Chem resistant (-2)"
	cleanName = "Chem resistant"
	desc = "You are more resistant to chem overdoses."
	id = "chemresist"
	points = -2
	isPositive = 1

/obj/trait/puritan
	name = "Puritan (+2)"
	cleanName = "Puritan"
	desc = "You can not be cloned. Any attempt will end badly."
	id = "puritan"
	points = 2
	isPositive = 0

/obj/trait/survivalist
	name = "Survivalist (-1)"
	cleanName = "Survivalist"
	desc = "Food will heal you even if you are badly injured."
	id = "survivalist"
	points = -1
	isPositive = 1

/obj/trait/smoothtalker
	name = "Smooth talker (-1)"
	cleanName = "Smooth talker"
	desc = "Traders will tolerate 50% more when you are haggling with them."
	id = "smoothtalker"
	points = -1
	isPositive = 1

/obj/trait/smoker
	name = "Smoker (-1)"
	cleanName = "Smoker"
	desc = "You will not absorb any chemicals from smoking cigarettes."
	id = "smoker"
	points = -1
	isPositive = 1

/obj/trait/immigrant
	name = "Illegal immigrant (+1)"
	cleanName = "Illegal immigrant"
	desc = "You spawn without an ID or PDA."
	id = "immigrant"
	points = 1
	isPositive = 0

/obj/trait/shortsighted
	name = "Short-sighted (+1)"
	cleanName = "Short-sighted"
	desc = "Spawn with permanent short-sightedness and glasses."
	id = "shortsighted"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(istype(owner, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = owner
				owner.bioHolder.AddEffect("bad_eyesight")
				H.equip_if_possible(new /obj/item/clothing/glasses/regular(H), H.slot_glasses)
		return

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("bad_eyesight"))
			owner.bioHolder.AddEffect("bad_eyesight")
		return

/obj/trait/deaf
	name = "Deaf (+1)"
	cleanName = "Deaf"
	desc = "Spawn with permanent deafness and an auditory headset."
	id = "deaf"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(istype(owner, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = owner
				owner.bioHolder.AddEffect("deaf")
				H.equip_if_possible(new /obj/item/device/radio/headset/deaf(H), H.slot_ears)
		return

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("deaf"))
			owner.bioHolder.AddEffect("deaf")
		return

//Todo: make this an actual harmful bioEffect?
//TODO: Perhaps use the same systems drones do to hide people faces and names in examinetext, context menu and bottom-left display?
/*
/obj/trait/prosopagnosia
	name = "Prosopagnosia (+2)"
	cleanName = "Prosopagnosia"
	desc = "Also known as face blindness, makes everyone's faces indistinguishable to you."
	id = "prosopagnosia"
	points = 2
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(istype(owner, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = owner
				owner.bioHolder.AddEffect("prosopagnosia")
		return

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("prosopagnosia"))
			owner.bioHolder.AddEffect("prosopagnosia")
		return
*/
/obj/trait/hemo
	name = "Hemophilia (+1)"
	cleanName = "Hemophilia"
	desc = "You bleed more easily and you bleed more."
	id = "hemophilia"
	points = 1
	isPositive = 0

/obj/trait/nervous
	name = "Nervous (+1)"
	cleanName = "Nervous"
	desc = "Witnessing injuries or violence will sometimes make you freak out."
	id = "nervous"
	points = 1
	isPositive = 0

/obj/trait/burning
	name = "Human Torch (+1)"
	cleanName = "Human Torch"
	desc = "Extends the time that you remain on fire for, when burning."
	id = "burning"
	points = 1
	isPositive = 0

/obj/trait/carpenter
	name = "Carpenter (-1)"
	cleanName = "Carpenter"
	desc = "You can construct things more quickly than other people."
	id = "carpenter"
	points = -1
	isPositive = 1

/obj/trait/explolimbs
	name = "Adamantium Skeleton (-2)"
	cleanName = "Adamantium Skeleton"
	desc = "Halves the chance that an explosion will blow off your limbs."
	id = "explolimbs"
	points = -2
	isPositive = 1

/obj/trait/cateyes
	name = "Cat eyes (-1) \[Vision\]"
	cleanName = "Cat eyes"
	desc = "You can see 2 tiles further in the dark."
	id = "cateyes"
	points = -1
	isPositive = 1
	category = "vision"

/obj/trait/infravision
	name = "Infravision (-1) \[Vision\]"
	cleanName = "Infravision"
	desc = "You gain permanent infravision."
	id = "infravision"
	points = -1
	isPositive = 0
	category = "vision"

/obj/trait/kleptomaniac
	name = "Kleptomaniac (+1)"
	cleanName = "Kleptomaniac"
	desc = "You will sometimes randomly pick up nearby items."
	id = "kleptomaniac"
	points = 1
	isPositive = 0

	onLife(var/mob/owner)
		if(!owner.stat && can_act(owner) && prob(9))
			if(!owner.equipped())
				for(var/obj/item/I in view(1, owner))
					if(!I.anchored && isturf(I.loc))
						I.attack_hand(owner)
						if(prob(12))
							owner.emote(pick("grin", "smirk", "chuckle", "smug"))
						break
		return

/obj/trait/phobia
	name = "Error"
	cleanName = "Error"
	desc = "This is an error! Please report this to coders."
	id = "error"
	points = 0
	isPositive = 0
	category = "phobia"
	unselectable = 1

	//phobia-specific variables
	var/list/types = list() //list of horrible things that are classified under this phobia
	var/list/triggers = list() //list of trigger words to make you TREMBLE IN FEAR

	onLife(var/mob/owner)
		var/severity = 0
		if(!owner.stat && can_act(owner))
			for(var/atom/A in view(7, owner))
				if(!(A.type in types))
					return
				if(severity < 1)
					severity = 1 //Only 1 severity for visibility
				if(A in view(2, owner)) //TOO CLOSE
					severity += 1

		if(severity == 1)
			if(prob(4))
				owner.emote(pick("pale", "hiccup", "tremble", "shiver", "shudder", "quiver"))
				owner.stuttering += 2 //ticks of stuttering
		else if(severity == 2)
			if(prob(2))
				owner.emote("faint")
				owner.paralysis += 7
			else if (prob(8))
				owner.emote("scream")
				owner.stunned += 2
		else if(severity >= 3) //LOTS AND LOTS OF SPOOKY STUFF!
			if(prob(4))
				owner.emote("faint")
				owner.paralysis += 7
			else if (prob(10))
				owner.emote(pick("scream", "weep", "cry", "choke", "panic"))
				owner.stunned += 2
			else if(prob(8))
				owner.emote(pick("pale", "hiccup", "tremble", "shiver", "shudder", "quiver", "choke"))
		return

	onHear(var/mob/owner, var/message)
		for(var/T in triggers)
			if(findtext(message,T))
				owner.emote(pick("pale", "hiccup", "tremble", "shiver", "shudder", "quiver"))

/obj/trait/phobia/space
	name = "Spacephobia (+2) \[Phobia\]"
	cleanName = "Spacephobia"
	desc = "Being in space scares you. A lot. While in space you might panic or faint."
	id = "spacephobia"
	points = 2
	unselectable = 0
	types = list(/turf/space)
	triggers = list("space", "stars", "celestial", "asteroids")

/obj/trait/phobia/monkey
	name = "Pithecophobia (+2) \[Phobia\]"
	cleanName = "Pithecophobia"
	desc = "Monkeys are horrifying. You hate the idea of monkeys being our ancestors!\nSeeing a monkey terrifies you. Being near one might make you panic or faint.\nAvoid groups of monkeys!"
	id = "pithecophobia"
	points = 2
	isPositive = 0
	unselectable = 0
	types = list(/mob/living/carbon/human/monkey, /obj/item/wrench/monkey)
	triggers = list("monkey", "chimp", "ape", "gorilla", "baboon", "simian")

/obj/trait/phobia/robot
	name = "Robophobia (+2) \[Phobia\]"
	cleanName = "Robophobia"
	desc = "Robots are going to take over the world! Fear your metal overlords! Aaaagh!\nSeeing a silicon being terrifies you. Being near one makes you panic or faint.\nAvoid groups of robots!"
	id = "robophobia"
	points = 2
	unselectable = 0
	types = list(/mob/living/silicon, /obj/machinery/bot, /mob/living/critter/gunbot, /mob/living/critter/drone,\
				/mob/living/critter/repairbot, /obj/critter/gunbot, /obj/critter/automaton)
	triggers = list("bot", "tron", "drone", "borg") //"Pass me the bottle!" *GASP*

/obj/trait/robustgenetics
	name = "Robust Genetics (-2) \[Genetics\]"
	cleanName = "Robust Genetics"
	desc = "You gain an additional 20 genetic stability."
	id = "robustgenetics"
	points = -2
	isPositive = 0
	category = "genetics"

/obj/trait/stablegenes
	name = "Stable Genes (-2) \[Genetics\]"
	cleanName = "Stable Genes"
	desc = "You are less likely to mutate from radiation or mutagens."
	id = "stablegenes"
	points = -2
	isPositive = 0
	category = "genetics"

/obj/trait/loyalist
	name = "NT loyalist (-1) \[Trinkets\]"
	cleanName = "NT loyalist"
	desc = "Start with a Nanotrasen Beret as your trinket."
	id = "loyalist"
	points = -1
	isPositive = 1
	category = "trinkets"

/obj/trait/petasusaphilic
	name = "Petasusaphilic (-1) \[Trinkets\]"
	cleanName = "Petasusaphilic"
	desc = "Start with a random hat as your trinket."
	id = "petasusaphilic"
	points = -1
	isPositive = 1
	category = "trinkets"

/obj/trait/clutz
	name = "Clutz (+2)"
	cleanName = "Clutz"
	desc = "When interacting with anything you have a chance to interact with something different instead."
	id = "clutz"
	points = 2
	isPositive = 0

/obj/trait/leftfeet
	name = "Two left feet (+1)"
	cleanName = "Two left feet"
	desc = "Every now and then you'll stumble in a random direction."
	id = "leftfeet"
	points = 1
	isPositive = 0

/obj/trait/meathead
	name = "Meathead (-1) \[Stats\]"
	cleanName = "Meathead"
	desc = "Can take quite a beating! Suffers from brain trauma, though."
	id = "meathead"
	category = "stats"
	points = -1
	isPositive = 1

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.max_health = 150
			H.health = 150
			H.brainloss = 60
		return

	onLife(var/mob/owner) //Just to be safe.
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.max_health = 150
			if(H.brainloss < 60)
				H.brainloss = 60
		return

/obj/trait/athletic
	name = "Athletic (-2) \[Stats\]"
	cleanName = "Athletic"
	desc = "Great stamina! Frail body."
	id = "athletic"
	category = "stats"
	points = -2
	isPositive = 1

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.add_stam_mod_max("trait", STAMINA_MAX * 0.1)
			H.add_stam_mod_regen("trait", STAMINA_REGEN * 0.2)
			H.max_health = 80
			H.health = 80
		return

/obj/trait/bigbruiser
	name = "Big Bruiser (-2) \[Stats\]"
	cleanName = "Big Bruiser"
	desc = "Stronger punches but higher stamina cost!"
	id = "bigbruiser"
	category = "stats"
	points = -2
	isPositive = 1

/obj/trait/glasscannon
	name = "Glass cannon (-2) \[Stats\]"
	cleanName = "Glass cannon"
	desc = "You have 1 stamina max. Attacks no longer cost you stamina and\nyou deal double the normal damage with most melee weapons."
	id = "glasscannon"
	category = "stats"
	points = -2
	isPositive = 1

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.add_stam_mod_max("trait", -(STAMINA_MAX - 1))
		return

/obj/trait/matrixflopout
	name = "Matrix Flopout (-2) \[Skill\]"
	cleanName = "Matrix Flopout"
	desc = "Flipping lets you dodge bullets and attacks for a higher stamina cost!"
	id = "matrixflopout"
	category = "skill"
	points = -2
	isPositive = 1


/*
/obj/trait/lizard
	name = "Lizard (-1) \[Race\]"
	desc = "You spawn as a lizard. Remember; you have no rights as a human if you choose this trait!"
	cleanName = "Lizard"
	id = "lizard"
	points = -1
	isPositive = 1
	category = "race"

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.set_mutantrace(/datum/mutantrace/lizard)
		return
*/
//UNSELECTABLE BELOW////UNSELECTABLE BELOW////UNSELECTABLE BELOW////UNSELECTABLE BELOW////UNSELECTABLE BELOW////UNSELECTABLE BELOW////UNSELECTABLE BELOW//

// People use this to identify changelings and people wearing disguises and I can't be bothered
// to rewrite a whole bunch of stuff for what is essentially something very specific and minor.
/obj/trait/observant
	name = "Observant (-1)"
	cleanName = "Observant"
	desc = "Examining people will show you their traits."
	id = "observant"
	points = -1
	isPositive = 1
	unselectable = 1

/obj/trait/roboears
	name = "Robotic ears (-4) \[Body\]"
	cleanName = "Robotic ears"
	desc = "You can hear, understand and speak robotic languages."
	id = "roboears"
	category = "body"
	points = -4
	isPositive = 1
	unselectable = 1

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.robot_talk_understand = 1
		return

	onLife(var/mob/owner) //Just to be safe.
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.robot_talk_understand = 1
		return
/*
	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			if(H.organHolder != null)
				H.organHolder.receive_organ(var/obj/item/I, var/type, var/op_stage = 0.0)
		return
*/

/obj/trait/deathwish
	name = "Death wish (+8) \[Stats\]"
	cleanName = "Death wish"
	desc = "You take double damage from most things and have half your normal health."
	id = "deathwish"
	category = "stats"
	points = 8
	isPositive = 0
	unselectable = 1

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.max_health = 50
			H.health = 50
		return

	onLife(var/mob/owner) //Just to be safe.
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.max_health = 50
		return

/obj/trait/fat
	name = "Fat (-1)"
	cleanName = "Fat"
	desc = "You're a little ... pudgy. And there's nothing you can do about it."
	id = "fat"
	points = -1
	isPositive = 1
	unselectable = 1

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			owner.bioHolder.AddEffect("fat")
		return

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("fat"))
			owner.bioHolder.AddEffect("fat")
		return

/obj/trait/soggy
	name = "Overly soggy (-1)"
	cleanName = "Overly soggy"
	desc = "When you die you explode into gibs and drop everything you were carrying."
	id = "soggy"
	points = -1
	isPositive = 1
	unselectable = 1

/obj/trait/badgenes
	name = "Bad Genes (+2) \[Genetics\]"
	cleanName = "Bad Genes"
	desc = "You spawn with 2 random, permanent, bad mutations."
	id = "badgenes"
	points = 2
	isPositive = 0
	category = "genetics"
	unselectable = 1

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			var/str = "I have the following bad mutations: "

			var/curr_id = owner.bioHolder.RandomEffect("bad", 1)
			var/datum/bioEffect/curr = owner.bioHolder.effects[curr_id]
			curr.curable_by_mutadone = 0
			curr.can_reclaim = 0
			curr.can_scramble = 0
			str += " [curr.name],"
			curr_id = owner.bioHolder.RandomEffect("bad", 1)
			curr = owner.bioHolder.effects[curr_id]
			curr.curable_by_mutadone = 0
			curr.can_reclaim = 0
			curr.can_scramble = 0
			str += " [curr.name]"

			spawn(40) owner.add_memory(str) //FUCK THIS SPAWN FUCK FUUUCK
		return

/obj/trait/goodgenes
	name = "Good Genes (-3) \[Genetics\]"
	cleanName = "Good Genes"
	desc = "You spawn with 2 random good mutations."
	id = "goodgenes"
	points = -3
	isPositive = 0
	category = "genetics"
	unselectable = 1

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			var/str = "I have the following good mutations: "

			var/curr_id = owner.bioHolder.RandomEffect("good", 1)
			var/datum/bioEffect/curr = owner.bioHolder.effects[curr_id]
			str += " [curr.name],"
			curr_id = owner.bioHolder.RandomEffect("good", 1)
			curr = owner.bioHolder.effects[curr_id]
			str += " [curr.name]"

			spawn(40) owner.add_memory(str) //FUCK THIS SPAWN FUCK FUUUCK
		return


//RANDOM SNIPPETS AND RUBBISH BELOW

/*
/obj/trait/testTrait1//
	name = "Lizard (-1) \[Race\]"
	desc = "You spawn as a lizard person thing. Yep.\nThere you go. Finally you can live out your dream."
	id = "lizard"
	points = -1
	isPositive = 1
	category = "race"

	onAdd(var/mob/owner)
		if(istype(owner, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = owner
			H.set_mutantrace(/datum/mutantrace/lizard)
		return

/obj/trait/testTrait2
	name = "Cough (+1) \[Race\]"
	desc = "You suffer from a chronic cough."
	id = "cough"
	points = 1
	isPositive = 0
	category = "race"

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			owner.bioHolder.AddEffect("cough")
		return

/obj/trait/testTrait3
	name = "Swedish (-1)"
	desc = "You are from sweden. Meat balls and so on."
	id = "swedish"//
	points = -1
	isPositive = 1

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			owner.bioHolder.AddEffect("accent_swedish")
		return
*/

			/*
			var/mob/living/carbon/human/target = null
			for(var/mob/living/carbon/human/M in range(1, owner))
				if(M == owner || !istype(M,/mob/living/carbon/human)) continue
				target = M
				break
			if(target)
				if(!actions.hasAction(owner, "otheritem") && !owner.equipped())
					var/trgSlot = null
					if(target.get_slot(target.slot_l_hand)) trgSlot = target.slot_l_hand
					else if(target.get_slot(target.slot_r_hand)) trgSlot = target.slot_r_hand
					else if(target.get_slot(target.slot_wear_id)) trgSlot = target.slot_wear_id
					else if(target.get_slot(target.slot_l_store)) trgSlot = target.slot_l_store
					else if(target.get_slot(target.slot_r_store)) trgSlot = target.slot_r_store
					else if(target.get_slot(target.slot_head)) trgSlot = target.slot_head
					else if(target.get_slot(target.slot_back)) trgSlot = target.slot_back
					else if(target.get_slot(target.slot_w_uniform)) trgSlot = target.slot_w_uniform
					if(trgSlot)
						actions.start(new/datum/action/bar/icon/otherItem( owner, target, null, trgSlot ) , owner)
			*/