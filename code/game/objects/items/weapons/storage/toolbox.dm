/obj/item/storage/toolbox
	name = "toolbox"
	desc = "A highly durable and sturdy toolbox designed to provide secure and organized storage for a wide range of tools."
	icon = 'icons/obj/storage.dmi'
	icon_state = "red"
	item_state = "toolbox_red"
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 20
	attack_cooldown = 21
	melee_accuracy_bonus = -15
	throwforce = 10
	throw_speed = 1
	throw_range = 7
	w_class = ITEM_SIZE_LARGE
	max_w_class = ITEM_SIZE_NORMAL
	max_storage_space = DEFAULT_LARGEBOX_STORAGE //enough to hold all starting contents
	origin_tech = list(TECH_COMBAT = 1)
	attack_verb = list("robusted")
	use_sound = 'sound/effects/storage/toolbox.ogg'
	matter = list(MATERIAL_STEEL = 5000)

/obj/item/storage/toolbox/open(mob/user)
	. = ..()
	icon_state = "redopen"

/obj/item/storage/toolbox/close(mob/user)
	. = ..()
	icon_state = initial(icon_state)
	playsound(src, use_sound, 30)

/obj/item/storage/toolbox/emergency
	name = "emergency toolbox"
	startswith = list(
		/obj/item/crowbar/red,
		/obj/item/extinguisher/mini,
		/obj/item/device/radio,
		/obj/item/weldingtool/mini,
		/obj/item/welder_tank/mini
	)

/obj/item/storage/toolbox/emergency/Initialize()
	. = ..()
	var/item = pick(list(/obj/item/device/flashlight, /obj/item/device/flashlight/flare,  /obj/item/device/flashlight/flare/glowstick/red))
	new item(src)

/obj/item/storage/toolbox/mechanical
	name = "mechanical toolbox"
	icon_state = "blue"
	item_state = "toolbox_blue"
	startswith = list(/obj/item/screwdriver, /obj/item/wrench, /obj/item/weldingtool, /obj/item/crowbar, /obj/item/device/scanner/gas, /obj/item/wirecutters)

/obj/item/storage/toolbox/mechanical/open(mob/user)
	. = ..()
	icon_state = "blueopen"

/obj/item/storage/toolbox/mechanical/close(mob/user)
	. = ..()
	icon_state = initial(icon_state)
	playsound(src, use_sound, 30)

/obj/item/storage/toolbox/electrical
	name = "electrical toolbox"
	icon_state = "yellow"
	item_state = "toolbox_yellow"
	startswith = list(/obj/item/screwdriver, /obj/item/wirecutters, /obj/item/device/t_scanner, /obj/item/crowbar)

/obj/item/storage/toolbox/electrical/open(mob/user)
	. = ..()
	icon_state = "yellowopen"

/obj/item/storage/toolbox/electrical/close(mob/user)
	. = ..()
	icon_state = initial(icon_state)
	playsound(src, use_sound, 30)

/obj/item/storage/toolbox/electrical/Initialize()
	. = ..()
	new /obj/item/stack/cable_coil/random(src,30)
	new /obj/item/stack/cable_coil/random(src,30)
	if(prob(5))
		new /obj/item/clothing/gloves/insulated(src)
	else
		new /obj/item/stack/cable_coil/random(src,30)

/obj/item/storage/toolbox/syndicate
	name = "black and red toolbox"
	desc = "A toolbox in black, with stylish red trim. This one feels particularly heavy, yet balanced."
	icon_state = "syndicate"
	item_state = "toolbox_syndi"
	origin_tech = list(TECH_COMBAT = 1, TECH_ESOTERIC = 1)
	attack_cooldown = 10
	startswith = list(/obj/item/clothing/gloves/insulated, /obj/item/screwdriver, /obj/item/wrench, /obj/item/weldingtool, /obj/item/crowbar, /obj/item/wirecutters, /obj/item/device/multitool)

/obj/item/storage/toolbox/syndicate/open(mob/user)
	. = ..()
	icon_state = "syndicateopen"

/obj/item/storage/toolbox/syndicate/close(mob/user)
	. = ..()
	icon_state = initial(icon_state)
	playsound(src, use_sound, 30)
