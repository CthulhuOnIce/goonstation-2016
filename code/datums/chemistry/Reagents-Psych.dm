// Meant to contain more RP centered medication for therapists on 1 to use/people to add to their drug cocktails.

/datum/reagent/
    psych/
        name = "some psychiatric medication"
    psych/diazepam
        name = "Diazepam"
        id = "diazepam"
        desc = "A weak benzodiazepine medication that produces a calming sedative effect, commonly used for the treatment of anxiety"
        addiction_prob = 10
	var/amount
	on_remove()
		if(istype(holder) && istype(holder.my_atom) && hascall(holder.my_atom,"remove_stam_mod_max"))
			holder.my_atom:remove_stam_mod_max("diazepam")
		return
        on_mob_life()
	    var/mob/living/carbon/human/K = M
            if(!M) 
                M = holder.my_atom
            amount = holder.get_reagent_amount(src.id) + holder.get_reagent_amount(ethanol) * 2 // don't mix these things
            if(prob(15))
		for(var/datum/ailment_data/disease/virus in M.ailments)
                        if(istype(virus.master,/datum/ailment/disease/space_madness) || istype(virus.master, /datum/ailment/disability/epilepsy))
                            M.cure_disease(virus)
		for(var/datum/ailment/addiction/addict in M.ailments)
			if(addict.associated_reagent == "ethanol")
				addict.withdrawal_duration = addict.withdrawal_duration + 6 // Speeds up ethanol withdrawl a bit to simulate the GABAenergic effects.
            if(amount) // Regular calming.
                if(prob(10))
                    	boutput(M, pick("<span style=\"color:red\">You feel less anxious.</span>", "<span style=\"color:red\">You feel a bit more mellowed out.</span>", "<span style=\"color:red\">You feel relaxed.</span>", <span style=\"color:red\">You feel sleepy.</span>")
                if(prob(5))
                    	M.emote(pick("smile", "grin", "yawn")
		if (K.sims && prob(5))
			K.sims.affectMotive("energy", -1)
                   	K.sims.affectMotive("comfort", 1)
            if(amount > 25) // Sedation
                if(prob(10))
                   	boutput(M, pick("<span style=\"color:red\">You feel like you should just lie down somewhere and sleep.</span>", "<span style=\"color:red\">You feel weak.</span>", "<span style=\"color:red\">You feel very sleepy.</span>")
                if(prob(15))
                    	M.emote("yawn")
                if (K.sims && prob(20))
			K.sims.affectMotive("energy", -3)
                    	K.sims.affectMotive("comfort", 1)
		if(istype(holder) && istype(holder.my_atom) && hascall(holder.my_atom,"add_stam_mod_max"))
			holder.my_atom:add_stam_mod_max("diazepam", -15)
		M.jitteriness = max(M.jitteriness-25,0)
		if(prob(20))
			M.drowsyness = max(M.drowsyness, 20)
             if(amount > 50) // Severe Sedation, think pancronium bromide
	        if(prob(15))
                    	M.emote(pick("drool", "tremble"))
		if (M.a_intent != INTENT_HELP && prob(10))
                    	boutput(M, <span style=\"color:red\">You're too tired to attack people right now.</span>")
                    	M.a_intent = INTENT_HELP
                if(!HasEffect(/datum/bioEffect/clumsy))
                     	M:bioHolder.AddEffect(/datum/bioEffect/clumsy, timeleft = 60)
		if(istype(holder) && istype(holder.my_atom) && hascall(holder.my_atom,"add_stam_mod_max"))
			holder.my_atom:add_stam_mod_max("diazepam", -25)
		if(M.m_intent == "run" && prob(25))
			boutput(M, "<span style=\"color:red\">Your legs feel like jelly!</span>")
			M.m_intent = "walk"
		if(prob(20))
			M.drowsyness = max(M.drowsyness, 40)
	     if(amount > 75) // Mild overdose
	     	// respiratory depression
	     if(amount > 100) // Critical overdose
		// liver toxicity and severe heart depression

    psych/chlorpromazine
        name = "chlorpromazine"
        id = "chlorpromazine"
        desc = "A antipsychotic that immediately produces a calming effect and treats psychosis, commonly used for the treatment of Schizophernia, Space Madness, Space Induced Violence Disorder (beserker), and the like."
	var/amount
	on_remove()
	    //todo
        on_mob_life()
	    var/mob/living/carbon/human/K = M
            if(!M) 
                M = holder.my_atom
            amount = holder.get_reagent_amount(src.id)
