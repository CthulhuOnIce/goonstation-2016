// Special class for loot inventory ui
/chui/window/loot
	var/mob/living/carbon/human/owner
	var/const/window_setup = "titlebar=0;can_close=0;can_resize=0;can_scroll=0;border=0;size=380x650;"
	var/const/icon = "icons/mob/loot_ui.dmi"
	var/const/style = {"
			<style>
				.grid-container {
				  padding: 10px;
				  margin: auto;
				  width: 335px;
				}

				.grid-item {
				  background-color: rgba(255, 255, 255, 0.8);
				  border: 1px solid rgba(0, 0, 0, 0.8);
				  border-radius: 12px;
				  padding: 3px;
				  margin: 3px;
				  min-width: 64px;
				  min-height: 64px;
				  max-width: 64px;
				  max-height: 64px;
				}

				img.grid-item {
				  align: middle;
				  width: 100%;
				}

				.filler {
				  border: 1px transparent;
				  opacity:0;
				 }

				.tooltip {
				  position: relative;
		  		  display: inline-block;
				}

				.tooltip .tooltiptext {
				  visibility: hidden;
				  width: 120px;
				  background-color: black;
				  color: #fff;
				  text-align: center;
				  padding: 5px;
				  border-radius: 6px;
				  opacity: 0.85;
				  bottom: 90%;
		  		  left: 50%;
		  		  margin-left: -60px;
				  position: absolute;
				  z-index: 1;
				}

				.tooltip .tooltiptext::after {
				  content: " ";
				  position: absolute;
				  top: 90%;
				  left: 50%;
				  margin-left: -12px;
				  border-width: 8px;
				  border-style: solid;
				  border-color: black transparent transparent transparent;
				}

				.tooltip:hover .tooltiptext {
				  visibility: visible;
				}

				p:hover.tooltiptext {
				  display: none;
				}
			</style>
		"}

	New(mob/living/carbon/human/ownerm)
		..()
		name = "Inventory"
		owner = ownerm

	Subscribe( var/client/who )
		CDBG1( "[who] subscribed to [name]" )
		subscribers += who
		var/hudstyle = hud_style_selection[get_hud_style(who)]
		who << browse( src.generate(who, src.GetBody(hudstyle)), "window=\ref[src];[window_setup]" )
		winset( who, "\ref[src]", "on-close \".chui-close \ref[src]\"" )

	GetBody(hud)
		var/filler = "<img class='grid-item filler' />"	// dummy grid item for spacing
		var/dat = style

		dat += "<h1>[owner.name]</h1>"

		// loot grid start
		dat += "<div class ='grid-container'>"
		dat += filler
		dat += prepareLootHtml(owner.slot_head, hud)
		dat += filler
		dat += "<BR>"

		dat += prepareLootHtml(owner.slot_ears, hud)
		dat += prepareLootHtml(owner.slot_wear_mask, hud)
		dat += prepareLootHtml(owner.slot_glasses, hud)
		dat += prepareLootHtml(owner.slot_back, hud)
		dat += "<BR>"

		dat += prepareLootHtml(owner.slot_gloves, hud)
		dat += prepareLootHtml(owner.slot_wear_suit, hud)
		dat += prepareLootHtml(owner.slot_wear_id, hud)
		var/showInternals = istype(owner.wear_mask, /obj/item/clothing/mask) && (istype(owner.back, /obj/item/tank))
		var/icon/i = new('icons/misc/abilities.dmi', icon_state = (owner.internal ? "airon" : "airoff" ))
		dat += showInternals ? addLootTopic("<img class='grid-item' src='data:image/png;base64,[icon2base64(i)]' />", "", "internal", "internal", "Toggle internals") : filler
		dat += "<BR>"

		dat += prepareLootHtml(owner.slot_l_hand, hud)
		dat += prepareLootHtml(owner.slot_w_uniform, hud)
		dat += prepareLootHtml(owner.slot_r_hand, hud)
		dat += owner.handcuffed ? addLootTopic(replaceHtmlImgClass("[bicon(owner.handcuffed)]", "grid-item"), "", "handcuff", "handcuff", "Unhandcuff") : filler
		dat += "<BR>"

		dat += prepareLootHtml(owner.slot_l_store, hud)
		dat += prepareLootHtml(owner.slot_belt, hud)
		dat += prepareLootHtml(owner.slot_r_store, hud)
		dat += "<BR>"

		dat += filler
		dat += prepareLootHtml(owner.slot_shoes, hud)
		dat += filler
		dat += "<BR>"
		dat += "</div>"
		// loot grid end

		var/changelogHtml = grabResource("html/changelog.html")
		return changelogHtml = replacetext(changelogHtml, "<!-- HTML GOES HERE -->", dat)

	// Display a slot which is currently unavailable
	proc/prepareDisabledImg(slot)
		var/icon/i
		var/txt = ""
		switch(slot)
			if (owner.slot_belt)
				i = new (icon, icon_state = "disabled")
				txt = "No uniform"
			if (owner.slot_l_store)
				i = new (icon, icon_state = "disabled")
				txt = "No uniform"
			if (owner.slot_r_store)
				i = new (icon, icon_state = "disabled")
				txt = "No uniform"
			if (owner.slot_wear_id)
				i = new (icon, icon_state = "disabled")
				txt = "No uniform"
		return addNonTopic(replaceHtmlImgClass(bicon(i), "grid-item"), txt)

	// Setup html for a specific slot
	proc/prepareLootHtml(slot, hudstyle)
		var/varname = ""
		var/item = ""
		var/obj/item/owner_item = null
		var/alt_name = ""	// what's shown in the tooltip
		var/icon_state = "" // icon_state for hud
		switch(slot)
			if (owner.slot_back)
				varname = "back"
				item = "back"
				owner_item = owner.back
				alt_name = "Back"
				icon_state = "back"
			if (owner.slot_wear_mask)
				varname = "wear_mask"
				item = "mask"
				owner_item = owner.wear_mask
				alt_name = "Mask"
				icon_state = "mask"
			if (owner.slot_l_hand)
				varname = "l_hand"
				item = "l_hand"
				owner_item = owner.l_hand
				alt_name = "Left hand"
				icon_state = "handl0"
			if (owner.slot_r_hand)
				varname = "r_hand"
				item = "r_hand"
				owner_item = owner.r_hand
				alt_name = "Right hand"
				icon_state = "handr0"
			if (owner.slot_belt)
				if (!owner.w_uniform)
					return prepareDisabledImg(slot)	// can't wear a belt without a uniform!
				varname = "belt"
				item = "belt"
				owner_item = owner.belt
				alt_name = "Belt"
				icon_state = "belt"
			if (owner.slot_wear_id)
				if (!owner.w_uniform)
					return prepareDisabledImg(slot)	// can't wear an id without a uniform!
				varname = "wear_id"
				item = "id"
				owner_item = owner.wear_id
				alt_name = "ID"
				icon_state = "id"
			if (owner.slot_ears)
				varname = "ears"
				item = "ears"
				owner_item = owner.ears
				alt_name = "Ears"
				icon_state = "ears"
			if (owner.slot_glasses)
				varname = "glasses"
				item = "eyes"
				owner_item = owner.glasses
				alt_name = "Glasses"
				icon_state = "glasses"
			if (owner.slot_gloves)
				varname = "gloves"
				item = "gloves"
				owner_item = owner.gloves
				alt_name = "Gloves"
				icon_state = "gloves"
			if (owner.slot_head)
				varname = "head"
				item = "head"
				owner_item = owner.head
				alt_name = "Head"
				icon_state = "hair"
			if (owner.slot_shoes)
				varname = "shoes"
				item = "shoes"
				owner_item = owner.shoes
				alt_name = "Shoes"
				icon_state = "shoes"
			if (owner.slot_wear_suit)
				varname = "wear_suit"
				item = "suit"
				owner_item = owner.wear_suit
				alt_name = "Suit"
				icon_state = "armor"
			if (owner.slot_w_uniform)
				varname = "w_uniform"
				item = "uniform"
				owner_item = owner.w_uniform
				alt_name = "Uniform"
				icon_state = "center"
			if (owner.slot_l_store)	// pockets are a special case, you shouldn't see what's in it
				if (!owner.w_uniform)
					return prepareDisabledImg(slot) // can't use pockets without a uniform!
				varname = "l_store"
				item = "pockets"
				alt_name = "Left pocket"
				var/icon/hudcon = new(hudstyle, "pocket", dir = SOUTH)
				var/icon/something = new ("icons/mob/loot_ui.dmi", icon_state = "something")
				return addLootTopic((owner.l_store ? replaceHtmlImgClass(bicon(something), "grid-item") : replaceHtmlImgClass(bicon(hudcon), "grid-item")), varname, slot, item, owner.l_store ? "Something" : alt_name)
			if (owner.slot_r_store)
				if (!owner.w_uniform)
					return prepareDisabledImg(slot) // can't use pockets without a uniform!
				varname = "r_store"
				item = "pockets"
				alt_name = "Right pocket"
				var/icon/hudcon = new(hudstyle, "pocket", dir = SOUTH)
				var/icon/something = new ("icons/mob/loot_ui.dmi", icon_state = "something")
				return addLootTopic((owner.r_store ? replaceHtmlImgClass(bicon(something), "grid-item") : replaceHtmlImgClass(bicon(hudcon), "grid-item")), varname, slot, item, owner.r_store ? "Something" : alt_name)

		var/icon/hudcon = new(hudstyle, icon_state, dir = SOUTH)
		return addLootTopic((owner_item ? replaceHtmlImgClass(bicon(owner_item), "grid-item") : replaceHtmlImgClass(bicon(hudcon), "grid-item")), varname, slot, item, owner_item ? owner_item.name : alt_name)

	proc/addNonTopic(html, text)
		return {"<span class='tooltip'>
					[html]
					<p class='tooltiptext'>[text]</p>
				</span>"}

	// Setup the href for looting items on click
	proc/addLootTopic(html, varname, slot, item, text)
		return {"<a class='tooltip' href='?src=\ref[owner];varname=[varname];slot=[slot];item=[item]'>
					[html]
					<p class='tooltiptext'>[text]</p>
				</a>"}

	// Assumes html based off the bicon return value
	proc/replaceHtmlImgClass(html, class)
		return "<img class='[class]' [copytext(html, findtext(html, "src="))]"

	// Updates all subscribers
	proc/UpdateSubscribers()
		for (var/client/c in subscribers)
			UpdateClient(c)

	// Update one client
	proc/UpdateClient(var/client/c)
		if (get_dist( c.mob.loc, owner.loc ) < 2)
			var/hudstyle = hud_style_selection[get_hud_style(c)]
			c << browse( src.generate(c, src.GetBody(hudstyle)), "window=\ref[src];[window_setup]" )