/mob/living/simple_animal/bullet_act(obj/item/projectile/Proj)
	if(status_flags & GODMODE)
		return PROJECTILE_FORCE_MISS

	if(!Proj || Proj.nodamage)
		return

	var/damage = Proj.damage
	if(Proj.damtype == STUN)
		damage = Proj.damage / 6
	if(Proj.damtype == BRUTE)
		damage = Proj.damage / 2
	if(Proj.damtype == BURN)
		damage = Proj.damage / 1.5
	if(Proj.agony)
		damage += Proj.agony / 6
		if(health < Proj.agony * 3)
			Paralyse(Proj.agony / 20)
			visible_message(SPAN_WARNING("[src] is stunned momentarily!"))

	bullet_impact_visuals(Proj)
	adjustBruteLoss(damage)
	Proj.on_hit(src)

	if (ai_holder && Proj.firer)
		ai_holder.react_to_attack(Proj.firer)

	return FALSE

/mob/living/simple_animal/ex_act(severity)
	if(status_flags & GODMODE)
		return

	if(can_see())
		flash_eyes()

	var/damage
	switch (severity)
		if (1)
			damage = 500

		if (2)
			damage = 120

		if(3)
			damage = 30

	apply_damage(damage, BRUTE, damage_flags = DAM_EXPLODE)

/mob/living/simple_animal/attack_hand(mob/living/carbon/human/M as mob)
	..()

	switch(M.a_intent)

		if(I_HELP)
			if (health > 0)
				M.visible_message(SPAN_NOTICE("[M] [response_help] \the [src]."))

		if(I_DISARM)
			M.visible_message(SPAN_NOTICE("[M] [response_disarm] \the [src]."))
			M.do_attack_animation(src)

		if(I_HURT)
			var/dealt_damage = harm_intent_damage
			var/harm_verb = response_harm
			if(ishuman(M) && M.species)
				var/datum/unarmed_attack/attack = M.get_unarmed_attack(src)
				dealt_damage = attack.damage <= dealt_damage ? dealt_damage : attack.damage
				harm_verb = pick(attack.attack_verb)
				playsound(loc, attack.attack_sound, 25, 1, -1)
				if(attack.sharp || attack.edge)
					adjustBleedTicks(dealt_damage)

			adjustBruteLoss(dealt_damage)
			M.visible_message(SPAN_WARNING("[M] [harm_verb] \the [src]!"))
			M.do_attack_animation(src)

			if (ai_holder)
				ai_holder.react_to_attack(M)

	return

/mob/living/simple_animal/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/stack/medical))
		if(stat != DEAD)
			var/obj/item/stack/medical/med = O
			if(!med.animal_heal)
				to_chat(user, SPAN_NOTICE("That [med] won't help \the [src] at all!"))
				return
			if(health < maxHealth)
				if(med.can_use(1))
					adjustBruteLoss(-med.animal_heal)
					visible_message(SPAN_NOTICE("[user] applies the [med] on [src]."))
					med.use(1)
		else
			to_chat(user, SPAN_NOTICE("\The [src] is dead, medical items won't bring \him back to life."))
		return

	if(istype(O, /obj/item/device/flash))
		if(stat != DEAD)
			O.attack(src, user, user.zone_sel ? user.zone_sel.selecting : ran_zone())
			return

	if(meat_type && (stat == DEAD) && meat_amount)
		if(istype(O, /obj/item/material/knife/kitchen/cleaver))
			var/victim_turf = get_turf(src)
			if(!locate(/obj/structure/table, victim_turf))
				to_chat(user, SPAN_NOTICE("You need to place \the [src] on a table to butcher it."))
				return
			var/time_to_butcher = (mob_size)
			to_chat(user, SPAN_NOTICE("You begin harvesting \the [src]."))
			if(do_after(user, time_to_butcher, src, do_flags = DO_DEFAULT & ~DO_BOTH_CAN_TURN))
				if(prob(user.skill_fail_chance(SKILL_COOKING, 60, SKILL_TRAINED)))
					to_chat(user, SPAN_NOTICE("You botch harvesting \the [src], and ruin some of the meat in the process."))
					subtract_meat(user)
					return
				else
					harvest(user, user.get_skill_value(SKILL_COOKING))
					SEND_SIGNAL(user, COMSIG_BUTCHERED, src, O)
					return
			else
				to_chat(user, SPAN_NOTICE("Your hand slips with your movement, and some of the meat is ruined."))
				subtract_meat(user)
				return

	else
		if(!O.force)
			visible_message(SPAN_NOTICE("[user] gently taps [src] with \the [O]."))
		else
			O.attack(src, user, user.zone_sel ? user.zone_sel.selecting : ran_zone())

			if (ai_holder)
				ai_holder.react_to_attack(user)

/mob/living/simple_animal/hit_with_weapon(obj/item/O, mob/living/user, effective_force, hit_zone)

	visible_message(SPAN_DANGER("\The [src] has been attacked with \the [O] by [user]!"))

	if(O.force <= resistance)
		to_chat(user, SPAN_DANGER("This weapon is ineffective; it does no damage."))
		return FALSE

	var/damage = O.force
	if (O.damtype == PAIN)
		damage = 0
	if (O.damtype == STUN)
		damage = (O.force / 8)
	if(supernatural && istype(O,/obj/item/nullrod))
		damage *= 2
		purge = 3
	adjustBruteLoss(damage)
	if(O.edge || O.sharp)
		adjustBleedTicks(damage)

	if (ai_holder)
		ai_holder.react_to_attack(user)

	return TRUE

/mob/living/simple_animal/proc/reflect_unarmed_damage(mob/living/carbon/human/attacker, damage_type, description)
	if(attacker.a_intent == I_HURT)
		var/hand_hurtie
		if(attacker.hand)
			hand_hurtie = BP_L_HAND
		else
			hand_hurtie = BP_R_HAND
		attacker.apply_damage(rand(return_damage_min, return_damage_max), damage_type, hand_hurtie, used_weapon = description)
		if(rand(25))
			to_chat(attacker, SPAN_WARNING("Your attack has no obvious effect on \the [src]'s [description]!"))
