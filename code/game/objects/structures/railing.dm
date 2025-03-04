/obj/structure/railing
	name = "railing"
	desc = "A simple bar railing designed to protect against careless trespass."
	icon = 'icons/obj/railing.dmi'
	icon_state = "railing_preview"
	density = TRUE
	throwpass = 1
	layer = OBJ_LAYER
	climb_speed_mult = 0.25
	anchored = FALSE
	atom_flags = ATOM_FLAG_NO_TEMP_CHANGE | ATOM_FLAG_CHECKS_BORDER | ATOM_FLAG_CLIMBABLE | ATOM_FLAG_CAN_BE_PAINTED
	obj_flags = OBJ_FLAG_ROTATABLE
	health_max = 70

	var/broken =    FALSE
	var/neighbor_status = 0

/obj/structure/railing/mapped
	color = COLOR_GUNMETAL
	anchored = TRUE

/obj/structure/railing/mapped/Initialize()
	. = ..()
	color = COLOR_GUNMETAL // They're not painted!

/obj/structure/railing/mapped/no_density
	density = FALSE

/obj/structure/railing/mapped/no_density/Initialize()
	. = ..()
	update_icon()

/obj/structure/railing/New(newloc, material_key = DEFAULT_FURNITURE_MATERIAL)
	material = material_key // Converted to datum in initialize().
	..(newloc)

/obj/structure/railing/Process()
	if(!material || !material.radioactivity)
		return
	for(var/mob/living/L in range(1,src))
		L.apply_damage(round(material.radioactivity/20),IRRADIATE, damage_flags = DAM_DISPERSED)

/obj/structure/railing/Initialize()
	. = ..()

	if(!isnull(material) && !istype(material))
		material = SSmaterials.get_material_by_name(material)
	if(!istype(material))
		return INITIALIZE_HINT_QDEL

	name = "[material.display_name] [initial(name)]"
	desc = "A simple [material.display_name] railing designed to protect against careless trespass."
	set_max_health(material.integrity / 5)
	color = material.icon_colour

	if(material.products_need_process())
		START_PROCESSING(SSobj, src)
	if(material.conductive)
		obj_flags |= OBJ_FLAG_CONDUCTIBLE
	else
		obj_flags &= (~OBJ_FLAG_CONDUCTIBLE)
	update_icon(FALSE)

/obj/structure/railing/Destroy()
	. = ..()
	for(var/thing in trange(1, src))
		var/turf/T = thing
		for(var/obj/structure/railing/R in T.contents)
			R.update_icon()

/obj/structure/railing/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(!istype(mover) || mover.checkpass(PASS_FLAG_TABLE))
		return TRUE
	if(get_dir(loc, target) == dir)
		return !density
	return TRUE

/obj/structure/railing/handle_death_change(new_death_state)
	if(new_death_state)
		visible_message(SPAN_DANGER("\The [src] [material.destruction_desc]!"))
		playsound(loc, 'sound/effects/grillehit.ogg', 50, 1)
		material.place_shard(get_turf(usr))
		qdel(src)

/obj/structure/railing/proc/NeighborsCheck(UpdateNeighbors = 1)
	neighbor_status = 0
	var/Rturn = turn(src.dir, -90)
	var/Lturn = turn(src.dir, 90)

	for(var/obj/structure/railing/R in src.loc)
		if ((R.dir == Lturn) && R.anchored)
			neighbor_status |= 32
			if (UpdateNeighbors)
				R.update_icon(0)
		if ((R.dir == Rturn) && R.anchored)
			neighbor_status |= 2
			if (UpdateNeighbors)
				R.update_icon(0)
	for (var/obj/structure/railing/R in get_step(src, Lturn))
		if ((R.dir == src.dir) && R.anchored)
			neighbor_status |= 16
			if (UpdateNeighbors)
				R.update_icon(0)
	for (var/obj/structure/railing/R in get_step(src, Rturn))
		if ((R.dir == src.dir) && R.anchored)
			neighbor_status |= 1
			if (UpdateNeighbors)
				R.update_icon(0)
	for (var/obj/structure/railing/R in get_step(src, (Lturn + src.dir)))
		if ((R.dir == Rturn) && R.anchored)
			neighbor_status |= 64
			if (UpdateNeighbors)
				R.update_icon(0)
	for (var/obj/structure/railing/R in get_step(src, (Rturn + src.dir)))
		if ((R.dir == Lturn) && R.anchored)
			neighbor_status |= 4
			if (UpdateNeighbors)
				R.update_icon(0)

/obj/structure/railing/on_update_icon(update_neighbors = TRUE)
	NeighborsCheck(update_neighbors)
	cut_overlays()
	if (!neighbor_status || !anchored)
		icon_state = "railing0-[density]"
		if (density)//walking over a railing which is above you is really weird, do not do this if density is 0
			add_overlay(image(icon, "_railing0-1", layer = ABOVE_HUMAN_LAYER))
	else
		icon_state = "railing1-[density]"
		if (density)
			add_overlay(image(icon, "_railing1-1", layer = ABOVE_HUMAN_LAYER))
		if (neighbor_status & 32)
			add_overlay(image(icon, "corneroverlay[density]"))
		if ((neighbor_status & 16) || !(neighbor_status & 32) || (neighbor_status & 64))
			add_overlay(image(icon, "frontoverlay_l[density]"))
			if (density)
				add_overlay(image(icon, "_frontoverlay_l1", layer = ABOVE_HUMAN_LAYER))
		if (!(neighbor_status & 2) || (neighbor_status & 1) || (neighbor_status & 4))
			add_overlay(image(icon, "frontoverlay_r[density]"))
			if (density)
				add_overlay(image(icon, "_frontoverlay_r1", layer = ABOVE_HUMAN_LAYER))
			if(neighbor_status & 4)
				var/pix_offset_x = 0
				var/pix_offset_y = 0
				switch(dir)
					if(NORTH)
						pix_offset_x = 32
					if(SOUTH)
						pix_offset_x = -32
					if(EAST)
						pix_offset_y = -32
					if(WEST)
						pix_offset_y = 32
				add_overlay(image(icon, "mcorneroverlay[density]", pixel_x = pix_offset_x, pixel_y = pix_offset_y))
				if (density)
					add_overlay(image(icon, "_mcorneroverlay1", pixel_x = pix_offset_x, pixel_y = pix_offset_y, layer = ABOVE_HUMAN_LAYER))


/obj/structure/railing/verb/flip() // This will help push railing to remote places, such as open space turfs
	set name = "Flip Railing"
	set category = "Object"
	set src in oview(1)

	if(usr.incapacitated())
		return 0

	if(anchored)
		to_chat(usr, SPAN_WARNING("It is fastened to the floor and cannot be flipped."))
		return 0

	if(!turf_is_crowded())
		to_chat(usr, SPAN_WARNING("You can't flip \the [src] - something is in the way."))
		return 0

	forceMove(get_step(src, src.dir))
	set_dir(turn(dir, 180))
	update_icon()

/obj/structure/railing/CheckExit(atom/movable/O, turf/target)
	if(istype(O) && O.checkpass(PASS_FLAG_TABLE))
		return 1
	if(get_dir(O.loc, target) == dir)
		if(!density)
			return 1
		return 0
	return 1

/obj/structure/railing/attackby(obj/item/W, mob/user)
	if(user.a_intent == I_HURT)
		..()
		return

	// Handle harm intent grabbing/tabling.
	if(istype(W, /obj/item/grab) && get_dist(src,user)<2)
		var/obj/item/grab/G = W
		if(istype(G.affecting, /mob/living/carbon/human))
			var/obj/occupied = turf_is_crowded()
			if(occupied)
				to_chat(user, SPAN_DANGER("There's \a [occupied] in the way."))
				return

			if(G.force_danger())
				if(user.a_intent == I_HURT)
					visible_message(SPAN_DANGER("[G.assailant] slams [G.affecting]'s face against \the [src]!"))
					playsound(loc, 'sound/effects/grillehit.ogg', 50, 1)
					var/blocked = G.affecting.get_blocked_ratio(BP_HEAD, BRUTE, damage = 8)
					if (prob(30 * (1 - blocked)))
						G.affecting.Weaken(5)
					G.affecting.apply_damage(8, BRUTE, BP_HEAD)
				else
					if (get_turf(G.affecting) == get_turf(src))
						G.affecting.forceMove(get_step(src, src.dir))
					else
						G.affecting.dropInto(loc)
					G.affecting.Weaken(5)
					visible_message(SPAN_DANGER("[G.assailant] throws \the [G.affecting] over \the [src]."))
			else
				to_chat(user, SPAN_DANGER("You need a better grip to do that!"))
		return

	// Dismantle
	if(isWrench(W))
		if(!anchored)
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			if(do_after(user, 20, src))
				if(anchored)
					return
				user.visible_message(SPAN_NOTICE("\The [user] dismantles \the [src]."), SPAN_NOTICE("You dismantle \the [src]."))
				material.place_sheet(loc, 2)
				qdel(src)
	// Wrench Open
		else
			playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
			if(density)
				user.visible_message(SPAN_NOTICE("\The [user] wrenches \the [src] open."), SPAN_NOTICE("You wrench \the [src] open."))
				density = FALSE
			else
				user.visible_message(SPAN_NOTICE("\The [user] wrenches \the [src] closed."), SPAN_NOTICE("You wrench \the [src] closed."))
				density = TRUE
			update_icon()
		return
	// Repair
	if(isWelder(W))
		var/obj/item/weldingtool/F = W
		if(F.isOn())
			if(!health_damaged())
				to_chat(user, SPAN_WARNING("\The [src] does not need repairs."))
				return
			playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
			if(do_after(user, 20, src))
				if(!health_damaged())
					return
				user.visible_message(SPAN_NOTICE("\The [user] repairs some damage to \the [src]."), SPAN_NOTICE("You repair some damage to \the [src]."))
				restore_health(get_max_health() / 5)
		return

	// Install
	if(isScrewdriver(W))
		if(!density)
			to_chat(user, SPAN_NOTICE("You need to wrench \the [src] from back into place first."))
			return
		user.visible_message(anchored ? SPAN_NOTICE("\The [user] begins unscrew \the [src].") : SPAN_NOTICE("\The [user] begins fasten \the [src].") )
		playsound(loc, 'sound/items/Screwdriver.ogg', 75, 1)
		if(do_after(user, 10, src) && density)
			to_chat(user, (anchored ? SPAN_NOTICE("You have unfastened \the [src] from the floor.") : SPAN_NOTICE("You have fastened \the [src] to the floor.")))
			anchored = !anchored
			update_icon()
		return

	..()

/obj/structure/railing/can_climb(mob/living/user, post_climb_check=FALSE, check_silicon=TRUE)
	. = ..()
	if(. && get_turf(user) == get_turf(src))
		var/turf/T = get_step(src, src.dir)
		if (T.density || T.turf_is_crowded(user))
			to_chat(user, SPAN_WARNING("You can't climb there, the way is blocked."))
			return 0

/obj/structure/railing/do_climb(mob/living/user)
	. = ..()
	if(.)
		if(!anchored || material.is_brittle())
			kill_health() // Fatboy

		user.jump_layer_shift()
		addtimer(CALLBACK(user, /mob/living/proc/jump_layer_shift_end), 2)

/obj/structure/railing/slam_into(mob/living/L)
	var/turf/target_turf = get_turf(src)
	if (target_turf == get_turf(L))
		target_turf = get_step(src, dir)
	if (!target_turf.density && !target_turf.turf_is_crowded(L))
		L.forceMove(target_turf)
		L.visible_message(SPAN_WARNING("\The [L] [pick("falls", "flies")] over \the [src]!"))
		L.Weaken(2)
		playsound(L, 'sound/effects/grillehit.ogg', 25, 1, FALSE)
	else
		..()

/obj/structure/railing/set_color(color)
	src.color = color ? color : material.icon_colour

/obj/structure/railing/CanPathingPass(obj/item/card/id/ID, to_dir, atom/movable/caller, no_id = FALSE)
	if(!(to_dir & dir))
		return TRUE
	return ..()
