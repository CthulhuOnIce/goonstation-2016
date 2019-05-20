
/obj/machinery/computer/tetris
	name = "Robustris Pro Cabinet"
	icon = 'icons/obj/computer.dmi'
	icon_state = "tetris"

	desc = "Instructions: Left/Right Arrows: move, Up Arrow: turn, Down Arrow: faster, Space: auto place | HIGHSCORE: 0"

	var/highscore
	var/highscoreholder
	var/tetriscode

/obj/machinery/computer/tetris/attackby(I as obj, user as mob)
	if(istype(I, /obj/item/screwdriver))
		playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)
		if(do_after(user, 20))
			if (src.stat & BROKEN)
				boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
				var/obj/computerframe/A = new /obj/computerframe( src.loc )
				if(src.material) A.setMaterial(src.material)
				new /obj/item/raw_material/shard/glass( src.loc )
				var/obj/item/circuitboard/tetris/M = new /obj/item/circuitboard/tetris( A )
				for (var/obj/C in src)
					C.set_loc(src.loc)
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				qdel(src)
			else
				boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
				var/obj/computerframe/A = new /obj/computerframe( src.loc )
				if(src.material) A.setMaterial(src.material)
				var/obj/item/circuitboard/tetris/M = new /obj/item/circuitboard/tetris( A )
				for (var/obj/C in src)
					C.set_loc(src.loc)
				A.circuit = M
				A.state = 4
				A.icon_state = "4"
				A.anchored = 1
				qdel(src)
	else
		src.attack_hand(user)
		src.add_fingerprint(user)
	return

/obj/machinery/computer/tetris/New()
	..()
	highscore = 0
	tetriscode = file2text("code/obj/machinery/computer/tetris/gamecode.txt")


/obj/machinery/computer/tetris/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/tetris/attack_hand(mob/user as mob)
	if(..())
		return
	user.machine = src
	var/dat = replacetext(tetriscode, "{{HIGHSCORE}}", num2text(highscore))
	dat = replacetext(dat, "{{TOPICURL}}", "'?src=\ref[src];highscore='+this.ScoreCur;")

	user << browse(dat, "window=tetris;size=375x500")
	onclose(user, "tetris")
	return

/obj/machinery/computer/tetris/Topic(href, href_list)
	if(..())
		return

	if (href_list["highscore"])
		if (text2num(href_list["highscore"]))
			if (text2num(href_list["highscore"]) > highscore)
				highscore = text2num(href_list["highscore"])
				highscoreholder = sanitize(input("Congratulations! You have achieved the highscore! Enter a name:", "Highscore!", usr.name) as text)

				desc = "Instructions: Left/Right Arrows: move, Up Arrow: turn, Down Arrow: faster, Space: auto place<br><br><b>Highscore: [highscore] by [highscoreholder]</b>"

	return

/obj/machinery/computer/tetris/power_change()

	if(stat & BROKEN)
		icon_state = "tetrisb"
	else
		if( powered() )
			icon_state = initial(icon_state)
			stat &= ~NOPOWER
		else
			spawn(rand(0, 15))
				src.icon_state = "tetris0"
				stat |= NOPOWER
