//Do (almost) nothing - indev placeholder for switch case implementations etc
#define NOOP (.=.);

#define list_find(L, needle, LIMITS...) L.Find(needle, LIMITS)

#define PUBLIC_GAME_MODE SSticker.master_mode

#define Clamp(value, low, high) (value <= low ? low : (value >= high ? high : value))
#define CLAMP01(x) 		(Clamp(x, 0, 1))

var/const/POSITIVE_INFINITY = 1#INF // win: 1.#INF, lin: inf
var/const/NEGATIVE_INFINITY = -1#INF // win: -1.#INF, lin: -inf
//var/const/POSITIVE_NAN = -(1#INF/1#INF) // win: 1.#QNAN, lin: nan -- demonstration of creation, but not useful
//var/const/NEGATIVE_NAN = (1#INF/1#INF) //win: -1.#IND, lin: -nan -- demonstration of creation, but not useful
#define isfinite(N) (isnum(N) && ((N) == (N)) && ((N) != POSITIVE_INFINITY) && ((N) != NEGATIVE_INFINITY))

#define isnan(N) (isnum(N) && (N) != (N))

#define get_x(A) (get_step(A, 0)?.x || 0)

#define get_y(A) (get_step(A, 0)?.y || 0)

#define get_z(A) (get_step(A, 0)?.z || 0)

#define isAI(A) istype(A, /mob/living/silicon/ai)

#define isalien(A) istype(A, /mob/living/carbon/alien)

#define isanimal(A) istype(A, /mob/living/simple_animal)

#define isairlock(A) istype(A, /obj/machinery/door/airlock)

#define isatom(A) isloc(A)

#define isbrain(A) istype(A, /mob/living/carbon/brain)

#define iscarbon(A) istype(A, /mob/living/carbon)

#define iscolorablegloves(A) (istype(A, /obj/item/clothing/gloves/color)||istype(A, /obj/item/clothing/gloves/insulated)||istype(A, /obj/item/clothing/gloves/thick))

#define isclient(A) istype(A, /client)

#define iscorgi(A) istype(A, /mob/living/simple_animal/friendly/corgi)

#define is_drone(A) istype(A, /mob/living/silicon/robot/drone)

#define isEye(A) istype(A, /mob/observer/eye)

#define ishuman(A) istype(A, /mob/living/carbon/human)

#define isid(A) istype(A, /obj/item/card/id)

#define isitem(A) istype(A, /obj/item)

#define isliving(A) istype(A, /mob/living)

#define ismouse(A) istype(A, /mob/living/simple_animal/friendly/mouse)

#define isnewplayer(A) istype(A, /mob/new_player)

#define isobj(A) istype(A, /obj)

#define isghost(A) istype(A, /mob/observer/ghost)

#define isobserver(A) istype(A, /mob/observer)

#define isorgan(A) istype(A, /obj/item/organ/external)

#define isstack(A) istype(A, /obj/item/stack)

#define isspace(A) istype(A, /area/space)

#define isspaceturf(A) istype(A, /turf/space)

#define isopenturf(A) istype(A, /turf/simulated/open)

#define ispAI(A) istype(A, /mob/living/silicon/pai)

#define isrobot(A) istype(A, /mob/living/silicon/robot)

#define issilicon(A) istype(A, /mob/living/silicon)

#define ismachinerestricted(A) (issilicon(A) && A.machine_restriction)

#define isslime(A) istype(A, /mob/living/carbon/slime)

#define ischorus(A) istype(A, /mob/living/carbon/alien/chorus)

#define isunderwear(A) istype(A, /obj/item/underwear)

#define isvirtualmob(A) istype(A, /mob/observer/virtual)

#define isweakref(A) istype(A, /weakref)

#define attack_animation(A) if(istype(A)) A.do_attack_animation(src)

#define isopenspace(A) istype(A, /turf/simulated/open)

#define isPlunger(A) istype(A, /obj/item/clothing/mask/plunger) || istype(A, /obj/item/device/plunger/robot)

/proc/isspecies(A, B)
	if(!iscarbon(A))
		return FALSE
	var/mob/living/carbon/C = A
	return C.species?.name == B

#define sequential_id(key) uniqueness_repository.Generate(/datum/uniqueness_generator/id_sequential, key)

#define random_id(key,min_id,max_id) uniqueness_repository.Generate(/datum/uniqueness_generator/id_random, key, min_id, max_id)

/// General I/O helpers
#define to_target(target, payload)            target << (payload)
#define from_target(target, receiver)         target >> (receiver)

/// Common use
#define legacy_chat(target, message)          to_target(target, message)
#define to_world(message)                     to_chat(world, message)
#define to_world_log(message)                 to_target(world.log, message)
#define sound_to(target, sound)               to_target(target, sound)
#define image_to(target, image)               to_target(target, image)
#define show_browser(target, content, title)  to_target(target, browse(content, title))
#define close_browser(target, title)          to_target(target, browse(null, title))
#define send_rsc(target, content, title)      to_target(target, browse_rsc(content, title))
#define send_link(target, url)                to_target(target, link(url))
#define send_output(target, msg, control)     to_target(target, output(msg, control))
#define to_file(handle, value)                to_target(handle, value)
#define to_save(handle, value)                to_target(handle, value) //semantics
#define from_save(handle, target_var)         from_target(handle, target_var)

#define MAP_IMAGE_PATH "nano/images/[GLOB.using_map.path]/"

#define map_image_file_name(z_level) "[GLOB.using_map.path]-[z_level].png"

#define RANDOM_BLOOD_TYPE pick(4;"O-", 36;"O+", 3;"A-", 28;"A+", 1;"B-", 20;"B+", 1;"AB-", 5;"AB+")

#define CanInteract(user, state) (CanUseTopic(user, state) == STATUS_INTERACTIVE)

#define CanDefaultInteract(user) (CanUseTopic(user, DefaultTopicState()) == STATUS_INTERACTIVE)

#define CanInteractWith(user, target, state) (target.CanUseTopic(user, state) == STATUS_INTERACTIVE)

#define CanPhysicallyInteract(user) (CanUseTopicPhysical(user) == STATUS_INTERACTIVE)

#define CanPhysicallyInteractWith(user, target) (target.CanUseTopicPhysical(user) == STATUS_INTERACTIVE)

#define DROP_NULL(x) if(x) { x.dropInto(loc); x = null; }

#define DROP_NULL_LIST(x) if(x) { for(var/atom/movable/y in x) { y.dropInto(loc) }}; x.Cut(); x = null;

#define ARGS_DEBUG log_debug("[__FILE__] - [__LINE__]") ; for(var/arg in args) { log_debug("\t[log_info_line(arg)]") }

// Insert an object A into a sorted list using cmp_proc (/code/_helpers/cmp.dm) for comparison.
#define ADD_SORTED(list, A, cmp_proc) if(!list.len) {list.Add(A)} else {list.Insert(FindElementIndex(A, list, cmp_proc), A)}

// Spawns multiple objects of the same type
#define cast_new(type, num, args...) if((num) == 1) { new type(args) } else { for(var/i=0;i<(num),i++) { new type(args) } }

#define JOINTEXT(X) jointext(X, null)

#define SPAN_ITALIC(X) "<span class='italic'>[X]</span>"

#define SPAN_BOLD(X) "<span class='bold'>[X]</span>"

#define SPAN_NOTICE(X) "<span class='notice'>[X]</span>"

#define SPAN_WARNING(X) "<span class='warning'>[X]</span>"

#define SPAN_GOOD(X) "<span class='good'>[X]</span>"

#define SPAN_BAD(X) "<span class='bad'>[X]</span>"

#define SPAN_ALERT(X) "<span class='alert'>[X]</span>"

#define SPAN_DANGER(X) "<span class='danger'>[X]</span>"

#define SPAN_USERDANGER(X) "<span class='userdanger'>[X]</span>"

#define SPAN_OCCULT(X) "<span class='cult'>[X]</span>"

#define SPAN_MFAUNA(X) "<span class='mfauna'>[X]</span>"

#define SPAN_SUBTLE(X) "<span class='subtle'>[X]</span>"

#define SPAN_INFO(X) "<span class='info'>[X]</span>"

#define SPAN_INFOPLAIN(X) "<span class='infoplain'>[X]</span>"

#define SPAN_DEBUG(X) "<span class='debug'>[X]</span>"

#define SPAN_DEADSAY(X) "<span class='deadsay'>[X]</span>"

#define SPAN_MENTOR(X) "<span class='mentor'>[X]</span>"

#define SPAN_STYLE(style, X) "<span style=\"[style]\">[X]</span>"

#define SPAN_CLASS(class, X) "<span class=\"[class]\">[X]</span>"

#define FONT_COLORED(color, text) "<font color='[color]'>[text]</font>"

#define FONT_SMALL(X) "<font size='1'>[X]</font>"

#define FONT_NORMAL(X) "<font size='2'>[X]</font>"

#define FONT_LARGE(X) "<font size='3'>[X]</font>"

#define FONT_HUGE(X) "<font size='4'>[X]</font>"

#define FONT_GIANT(X) "<font size='5'>[X]</font>"

#define crash_with(X) crash_at(X, __FILE__, __LINE__)

#define isscp106(A) istype(A, /mob/living/carbon/human/scp_106)

#define isscp049(A) istype(A, /mob/living/carbon/human/scp049)

#define isscp343(A) istype(A, /mob/living/carbon/human/scp343)

#define isscp049_1(A) (istype(A, /mob/living/carbon/human) && A.scp_049_instance)

#define isscp999(A) istype(A, /mob/living/simple_animal/scp_999)

#define isscp131(A) istype(A, /mob/living/simple_animal/scp_131)

#define isscp529(A) istype(A, /mob/living/simple_animal/cat/fluff/scp_529)

#define isscp527(A) istype(A, /mob/living/carbon/human/scp_527)

#define isscp173(A) istype(A, /mob/living/scp_173)

#define isstructure(A) istype(A, /obj/structure)

#define ismachinery(A) istype(A, /obj/machinery)

#define isdatum(A) istype(A, /datum)

#define isassembly(O) istype(O, /obj/item/device/assembly)

#define isigniter(O) istype(O, /obj/item/device/assembly/igniter)

#define isprox(O) istype(O, /obj/item/device/assembly/prox_sensor)

#define issignaller(O) istype(O, /obj/item/device/assembly/signaller)

#define istimer(O) istype(O, /obj/item/device/assembly/timer)

#define isscp2343(A) istype(A, /mob/living/carbon/human/scp2343)
