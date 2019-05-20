//This is the base stuff. the actual interaction with the attached computer, and the physical monitor
#if DM_VERSION >= 512

/obj/machinery/security_monitor
	name = "Security Monitor"
	icon = 'icons/obj/sec_tv.dmi'
	icon_state = "wall-monitor"
	anchored = 1.0
	pixel_y = 30
	layer = OBJ_LAYER+1
	appearance_flags = KEEP_TOGETHER 
	var/list/cameras = list()							//all camera's detected by this device which it can link to
	var/obj/item/clothing/glasses/sunglasses/camera/current_camera = null
	var/obj/video_screen
	var/obj/blank_screen			//black screen to use when off.
	var/fov = 2						//value to provide for view(). 1 = 3x3 tiles, 2 = 5x5, etc.
	var/active = 0

	var/monitor_id = "MONITOR-1"				//set in map maker
	var/network = "SS13"			//used in camera computer

	New()
		..()
		create_base_screen()

	Del()
		if (current_camera)
			current_camera.connected_monitor = null
		current_camera = null
		cameras = null
		video_screen.vis_contents = null
		qdel(blank_screen)
		qdel(video_screen)
		..()

	process()
		if (active)
			power_usage = 500
		else
			power_usage = 50

		if (stat & NOPOWER || !active)
			turn_off()
			return
		//Shouldn't happen, but I guess singularities can break it. This should be fine though
		if (video_screen.loc != src.loc || blank_screen.loc != src.loc)
			turn_off()
			qdel(blank_screen)

			return

		return

	attack_hand(mob/user as mob)
		active = 0
		boutput(user, "You press the Power Button.")

	//remove vis_contents display, set active off, changes monitor sprite
	proc/turn_off()
		if (video_screen)
			video_screen.vis_contents = null
		current_camera = null
		src.icon_state = "wall-monitor"
		active = 0

	//sets active on, changes monitor sprite
	proc/turn_on()
		active = 1

		src.icon_state = "wall-monitor-on"

	//creates a screen that is 5x5 turfs.
	//sets the frame of view to 5x5, Makes new video screen/blank screen (I didn't want to have to deal with transformation matrices and stuff)
	//Called to reset screen/alignment
	proc/create_base_screen()
		fov = 2
		if (video_screen)
			video_screen.vis_contents = null

		video_screen = new(src.loc)
		video_screen.name = "video screen"
		video_screen.appearance_flags = KEEP_TOGETHER
		video_screen.mouse_opacity = 0

		video_screen.pixel_x = -6
		video_screen.pixel_y = 24
		video_screen.Scale(0.3375, 0.3375)

		blank_screen = new(src.loc)
		blank_screen.name = "blank screen"
		blank_screen.icon = 'icons/obj/sec_tv.dmi'
		blank_screen.icon_state = "wall-screen"

		blank_screen.pixel_x = src.pixel_x
		blank_screen.pixel_y = src.pixel_y
		blank_screen.layer = src.layer-1
		blank_screen.mouse_opacity = 0

/*
		wall monitor screen size is ~ 53x53 pixels I moved it around
		3x3 tiles is 96x96
		5x5 is 160x160

*/
	//keeping this in here for now. I first started this with a 3x3 screen and it looked ok, so I dunno what we want to do
	//I don't wanna screw around with transformations too much, so I just hardcoded it for 3x3 and 5x5 and make a new screen object here
	proc/change_fov()
		set src in view(1)
		set name = "Change Height"

		create_base_screen()
		switch (fov)
			if (1)
				fov = 2
				video_screen.pixel_x = -6
				video_screen.pixel_y = 24
				video_screen.Scale(0.3375, 0.3375)

			if (2)
				fov = 1
				video_screen.pixel_x = -3
				video_screen.pixel_y = 28
				video_screen.Scale(0.5626, 0.5626)

		get_picture()
		return 1

	//provide a key to search the cameras assoc list for. default HUD1
	proc/pair_camera(var/key = "HUD1")
		var/obj/item/clothing/glasses/sunglasses/camera/camera = cameras[key]
		create_base_screen()

		if (camera)
			//remove monitor reference from current camera if it's not the same, Hadn't run into issues with this, but why not?
			if (src.current_camera && src.current_camera != camera)
				current_camera.connected_monitor = null
			camera.connected_monitor = src
			current_camera = camera
			turn_on()
			get_picture()

		else

			turn_off()
			src.visible_message("<span style=\"color:blue\"><b>Camera not found! Try scanning for cameras again.</b></span>")

	//loops through world looking for appropriate cameras. currently using sunglasses/camera, should make upgradable HUD but I don't have access to that

	proc/detect_cameras()
		var/count = 1
		for (var/obj/item/clothing/glasses/sunglasses/camera/g in world)
			cameras["HUD[count]"] = g
			count++

	//adds the turfs surrounding the current camera to the screen's vis_contents.
	proc/get_picture()
		if (video_screen)
			video_screen.vis_contents = null		//delete vis_contents contents

			//populate vis_contents
			for (var/turf/i in view(fov, current_camera.loc))
				video_screen.vis_contents += i

#else
	#warn BYOND v512 or higher is required to use vis_contents.
#endif
