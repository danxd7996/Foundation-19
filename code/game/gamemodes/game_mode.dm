var/global/antag_add_finished // Used in antag type voting.
var/global/list/additional_antag_types = list()

/datum/game_mode
	var/name = "invalid"
	var/round_description = "How did you even vote this in?"
	var/extended_round_description = "This roundtype should not be spawned, let alone votable. Someone contact a developer and tell them the game's broken again."
	var/config_tag = null
	var/votable = TRUE
	var/probability = 0

	var/required_players = 0                 // Minimum players for round to start if voted in.
	var/required_enemies = 0                 // Minimum antagonists for round to start.
	var/newscaster_announcements = null
	var/end_on_antag_death = FALSE           // Round will end when all antagonists are dead.
	var/ert_disabled = FALSE                 // ERT cannot be called.
	var/deny_respawn = FALSE	             // Disable respawn during this round.

	var/list/disabled_jobs = list()          // Mostly used for Malf.  This check is performed in job_controller so it doesn't spawn a regular AI.

	var/shuttle_delay = 1                    // Shuttle transit time is multiplied by this.
	var/auto_recall_shuttle = FALSE          // Will the shuttle automatically be recalled?

	var/list/antag_tags = list()             // Core antag templates to spawn.
	var/list/antag_templates                 // Extra antagonist types to include.
	var/list/latejoin_antag_tags = list()    // Antags that may auto-spawn, latejoin or otherwise come in midround.
	var/round_autoantag = FALSE              // Will this round attempt to periodically spawn more antagonists?
	var/antag_scaling_coeff = 5              // Coefficient for scaling max antagonists to player count.
	var/require_all_templates = FALSE        // Will only start if all templates are checked and can spawn.
	var/addantag_allowed = ADDANTAG_ADMIN

	var/station_was_nuked = FALSE            // See nuclearbomb.dm and malfunction.dm.
	var/explosion_in_progress = FALSE        // Sit back and relax

	var/event_delay_mod_moderate             // Modifies the timing of random events.
	var/event_delay_mod_major                // As above.

	var/waittime_l = 60 SECONDS				 // Lower bound on time before start of shift report
	var/waittime_h = 180 SECONDS		     // Upper bounds on time before start of shift report

	//Format: list(start_animation = duration, hit_animation, miss_animation). null means animation is skipped.
	var/cinematic_icon_states = list(
		"intro_nuke" = 35,
		"summary_selfdes",
		null
	)

/datum/game_mode/New()
	..()
	// Enforce some formatting.
	// This will probably break something.
	name = capitalize(lowertext(name))
	config_tag = lowertext(config_tag)

	if(round_autoantag && !latejoin_antag_tags.len)
		latejoin_antag_tags = antag_tags.Copy()
	else if(!round_autoantag && latejoin_antag_tags.len)
		round_autoantag = TRUE

/datum/game_mode/Topic(href, href_list[])
	if(..())
		return
	if(href_list["toggle"])
		switch(href_list["toggle"])
			if("respawn")
				deny_respawn = !deny_respawn
			if("ert")
				ert_disabled = !ert_disabled
				announce_ert_disabled()
			if("shuttle_recall")
				auto_recall_shuttle = !auto_recall_shuttle
			if("autotraitor")
				round_autoantag = !round_autoantag
		message_staff("Admin [key_name_admin(usr)] toggled game mode option '[href_list["toggle"]]'.")
	else if(href_list["set"])
		var/choice = ""
		switch(href_list["set"])
			if("shuttle_delay")
				choice = input("Enter a new shuttle delay multiplier") as num
				if(!choice || choice < 1 || choice > 20)
					return
				shuttle_delay = choice
			if("antag_scaling")
				choice = input("Enter a new antagonist cap scaling coefficient.") as num
				if(isnull(choice) || choice < 0 || choice > 100)
					return
				antag_scaling_coeff = choice
			if("event_modifier_moderate")
				choice = input("Enter a new moderate event time modifier.") as num
				if(isnull(choice) || choice < 0 || choice > 100)
					return
				event_delay_mod_moderate = choice
				refresh_event_modifiers()
			if("event_modifier_severe")
				choice = input("Enter a new moderate event time modifier.") as num
				if(isnull(choice) || choice < 0 || choice > 100)
					return
				event_delay_mod_major = choice
				refresh_event_modifiers()
		message_staff("Admin [key_name_admin(usr)] set game mode option '[href_list["set"]]' to [choice].")
	else if(href_list["debug_antag"])
		if(href_list["debug_antag"] == "self")
			usr.client.debug_variables(src)
			return
		var/datum/antagonist/antag = GLOB.all_antag_types_[href_list["debug_antag"]]
		if(antag)
			usr.client.debug_variables(antag)
			message_staff("Admin [key_name_admin(usr)] is debugging the [antag.role_text] template.")
	else if(href_list["remove_antag_type"])
		if(antag_tags && (href_list["remove_antag_type"] in antag_tags))
			to_chat(usr, "Cannot remove core mode antag type.")
			return
		var/datum/antagonist/antag = GLOB.all_antag_types_[href_list["remove_antag_type"]]
		if(antag_templates && antag_templates.len && antag && (antag in antag_templates) && (antag.id in additional_antag_types))
			antag_templates -= antag
			additional_antag_types -= antag.id
			message_staff("Admin [key_name_admin(usr)] removed [antag.role_text] template from game mode.")
	else if(href_list["add_antag_type"])
		var/choice = input("Which type do you wish to add?") as null|anything in GLOB.all_antag_types_
		if(!choice)
			return
		var/datum/antagonist/antag = GLOB.all_antag_types_[choice]
		if(antag)
			if(!islist(SSticker.mode.antag_templates))
				SSticker.mode.antag_templates = list()
			SSticker.mode.antag_templates |= antag
			message_staff("Admin [key_name_admin(usr)] added [antag.role_text] template to game mode.")

	if (usr.client && usr.client.holder)
		usr.client.holder.show_game_mode(usr)

/datum/game_mode/proc/announce() //to be called when round starts
	to_world("<B>The current game mode is [capitalize(name)]!</B>")
	if(round_description) to_world("[round_description]")
	if(round_autoantag) to_world("Antagonists will be added to the round automagically as needed.")
	if(antag_templates && antag_templates.len)
		var/antag_summary = "<b>Possible antagonist types:</b> "
		var/i = 1
		for(var/datum/antagonist/antag in antag_templates)
			if(i > 1)
				if(i == antag_templates.len)
					antag_summary += " and "
				else
					antag_summary += ", "
			antag_summary += "[antag.role_text_plural]"
			i++
		antag_summary += "."
		if(antag_templates.len > 1 && SSticker.master_mode != "secret")
			to_world("[antag_summary]")
		else
			message_staff("[antag_summary]")

/// Run prior to a mode vote to determine if the mode should be included. Falsy if yes, otherwise a status message.
/datum/game_mode/proc/check_votable(list/lobby_players)
	if(lobby_players.len < required_players)
		return "Not enough players are in the lobby. [lobby_players.len] of the required [required_players]."


/// Check to see if the currently selected mode can be started. Falsy if yes, otherwise a status message.
/datum/game_mode/proc/check_startable(list/lobby_players)
	var/list/ready_players = SSticker.ready_players(lobby_players)
	if(ready_players.len < required_players)
		return "Not enough players. [ready_players.len] ready of the required [required_players]."

/datum/game_mode/proc/refresh_event_modifiers()
	if(event_delay_mod_moderate || event_delay_mod_major)
		SSevent.report_at_round_end = 1
		if(event_delay_mod_moderate)
			var/datum/event_container/EModerate = SSevent.event_containers[EVENT_LEVEL_MODERATE]
			EModerate.delay_modifier = event_delay_mod_moderate
		if(event_delay_mod_moderate)
			var/datum/event_container/EMajor = SSevent.event_containers[EVENT_LEVEL_MAJOR]
			EMajor.delay_modifier = event_delay_mod_major

/datum/game_mode/proc/pre_setup()
	for(var/datum/antagonist/antag in antag_templates)
		antag.update_current_antag_max(src)
		antag.build_candidate_list(src) //compile a list of all eligible candidates

		//antag roles that replace jobs need to be assigned before the job controller hands out jobs.
		if(antag.flags & ANTAG_OVERRIDE_JOB)
			antag.attempt_spawn() //select antags to be spawned

///post_setup()
/datum/game_mode/proc/post_setup()

	next_spawn = world.time + rand(min_autotraitor_delay, max_autotraitor_delay)

	refresh_event_modifiers()

	addtimer(CALLBACK(null, /proc/display_roundstart_logout_report), ROUNDSTART_LOGOUT_REPORT_TIME)

	var/welcome_delay = rand(waittime_l, waittime_h)
	addtimer(CALLBACK(GLOB.using_map, /datum/map/proc/send_welcome), welcome_delay)
	addtimer(CALLBACK(src, .proc/announce_ert_disabled), welcome_delay + 10 SECONDS)

	//Assign all antag types for this game mode. Any players spawned as antags earlier should have been removed from the pending list, so no need to worry about those.
	for(var/datum/antagonist/antag in antag_templates)
		if(!(antag.flags & ANTAG_OVERRIDE_JOB))
			antag.attempt_spawn() //select antags to be spawned
		antag.finalize_spawn() //actually spawn antags

	//Finally do post spawn antagonist stuff.
	for(var/datum/antagonist/antag in antag_templates)
		antag.post_spawn()

	// Post-initialize, now that antag status and jobs are both resolved.
	for(var/thing in SSticker.minds)
		var/datum/mind/M = thing
		SEND_SIGNAL(M, COMSIG_MIND_POST_INIT)

	if(evacuation_controller && auto_recall_shuttle)
		evacuation_controller.recall = 1

	SSstatistics.set_field_details("round_start","[time2text(world.realtime)]")
	if(SSticker.mode)
		SSstatistics.set_field_details("game_mode","[SSticker.mode]")
	SSstatistics.set_field_details("server_ip","[world.internet_address]:[world.port]")
	return 1

/datum/game_mode/proc/fail_setup()
	for(var/datum/antagonist/antag in antag_templates)
		antag.reset_antag_selection()

/datum/game_mode/proc/announce_ert_disabled()
	if(!ert_disabled)
		return

	var/list/reasons = list(
		"political instability",
		"quantum fluctuations",
		"hostile raiders",
		"derelict station debris",
		"REDACTED",
		"ancient alien artillery",
		"solar magnetic storms",
		"sentient time-travelling killbots",
		"gravitational anomalies",
		"wormholes to another dimension",
		"a telescience mishap",
		"radiation flares",
		"supermatter dust",
		"leaks into a negative reality",
		"antiparticle clouds",
		"residual bluespace energy",
		"suspected criminal operatives",
		"malfunctioning von Neumann probe swarms",
		"shadowy interlopers",
		"a stranded Vox arkship",
		"haywire IPC constructs",
		"rogue Unathi exiles",
		"artifacts of eldritch horror",
		"a brain slug infestation",
		"killer bugs that lay eggs in the husks of the living",
		"a deserted transport carrying xenofauna specimens",
		"an emissary for the gestalt requesting a security detail",
		"radical Skrellian transevolutionaries",
		"classified security operations",
		"a gargantuan glowing goat"
		)
	command_announcement.Announce("The presence of [pick(reasons)] in the region is tying up all available local emergency resources; emergency response teams cannot be called at this time, and post-evacuation recovery efforts will be substantially delayed.","Emergency Transmission")

/datum/game_mode/proc/check_finished()
	if(evacuation_controller.round_over() || station_was_nuked)
		return 1
	if(end_on_antag_death && antag_templates && antag_templates.len)
		var/has_antags = 0
		for(var/datum/antagonist/antag in antag_templates)
			if(!antag.antags_are_dead())
				has_antags = 1
				break
		if(!has_antags)
			evacuation_controller.recall = 0
			return 1
	return 0

/datum/game_mode/proc/cleanup()	//This is called when the round has ended but not the game, if any cleanup would be necessary in that case.
	return

/datum/game_mode/proc/declare_completion()
	set waitfor = FALSE

	sleep(2)

	var/list/all_antag_types = GLOB.all_antag_types_
	for(var/datum/antagonist/antag in antag_templates)
		antag.print_player_summary()
		sleep(2)
	for(var/antag_type in all_antag_types)
		var/datum/antagonist/antag = all_antag_types[antag_type]
		if(!antag.current_antagonists.len || (antag in antag_templates))
			continue
		sleep(2)
		antag.print_player_summary()
	sleep(2)

	uplink_purchase_repository.print_entries()

	sleep(2)

	var/list/data = GLOB.using_map.roundend_statistics()

	var/text = "<br><br>"
	text += GLOB.using_map.roundend_summary(data)

	SEND_GLOBAL_SIGNAL(COMSIG_ROUND_ENDED)

	to_world(text)

	send2mainirc("A round of [src.name] has ended - [data["surviving_total"]] survivor\s, [data["ghosts"]] ghost\s.")
	SSwebhooks.send(WEBHOOK_ROUNDEND, data)

	return 0

/datum/game_mode/proc/check_win() //universal trigger to be called at mob death, nuke explosion, etc. To be called from everywhere.
	return 0

/datum/game_mode/proc/get_players_for_role(antag_id)
	var/list/players = list()
	var/list/candidates = list()

	var/list/all_antag_types = GLOB.all_antag_types_
	var/datum/antagonist/antag_template = all_antag_types[antag_id]
	if(!antag_template)
		return candidates

	// If this is being called post-roundstart then it doesn't care about ready status.
	if(GAME_STATE == RUNLEVEL_GAME)
		for(var/mob/player in GLOB.player_list)
			if(!player.client)
				continue
			if(istype(player, /mob/new_player))
				continue
			if(!antag_id || (antag_id in player.client.prefs.be_special_role))
				log_debug("[player.key] had [antag_id] enabled, so we are drafting them.")
				candidates += player.mind
	else
		// Assemble a list of active players without jobbans.
		for(var/mob/new_player/player in GLOB.player_list)
			if( player.client && player.ready )
				players += player

		// Get a list of all the people who want to be the antagonist for this round
		for(var/mob/new_player/player in players)
			if(!antag_id || (antag_id in player.client.prefs.be_special_role))
				log_debug("[player.key] had [antag_id] enabled, so we are drafting them.")
				candidates += player.mind
				players -= player

		// If we don't have enough antags, draft people who voted for the round.
		if(candidates.len < required_enemies)
			for(var/mob/new_player/player in players)
				if(!antag_id || ((antag_id in player.client.prefs.be_special_role)))
					log_debug("[player.key] has not selected never for this role, so we are drafting them.")
					candidates += player.mind
					players -= player
					if(candidates.len == required_enemies || players.len == 0)
						break

	return candidates		// Returns: The number of people who had the antagonist role set to yes, regardless of recomended_enemies, if that number is greater than required_enemies
							//			required_enemies if the number of people with that role set to yes is less than recomended_enemies,
							//			Less if there are not enough valid players in the game entirely to make required_enemies.

/datum/game_mode/proc/num_players()
	. = 0
	for(var/mob/new_player/P in GLOB.player_list)
		if(P.client && P.ready)
			. ++

/datum/game_mode/proc/check_antagonists_topic(href, href_list[])
	return 0

/datum/game_mode/proc/create_antagonists()

	if(!config.traitor_scaling)
		antag_scaling_coeff = 0

	var/list/all_antag_types = GLOB.all_antag_types_
	if(antag_tags && antag_tags.len)
		antag_templates = list()
		for(var/antag_tag in antag_tags)
			var/datum/antagonist/antag = all_antag_types[antag_tag]
			if(antag)
				antag_templates |= antag

	if(additional_antag_types && additional_antag_types.len)
		if(!antag_templates)
			antag_templates = list()
		for(var/antag_type in additional_antag_types)
			var/datum/antagonist/antag = all_antag_types[antag_type]
			if(antag)
				antag_templates |= antag

	shuffle(antag_templates) //In the case of multiple antag types
	newscaster_announcements = pick(newscaster_standard_feeds)

// Manipulates the end-game cinematic in conjunction with GLOB.cinematic
/datum/game_mode/proc/nuke_act(obj/screen/cinematic_screen, station_missed = 0)
	if(!cinematic_icon_states)
		return
	if(station_missed < 2)
		var/intro = cinematic_icon_states[1]
		if(intro)
			flick(intro,cinematic_screen)
			sleep(cinematic_icon_states[intro])
		var/end = cinematic_icon_states[3]
		var/to_flick = "station_intact_fade_red"
		if(!station_missed)
			end = cinematic_icon_states[2]
			to_flick = "station_explode_fade_red"
			for(var/mob/living/M in GLOB.living_mob_list_)
				if(is_station_turf(get_turf(M)))
					M.death()//No mercy
		if(end)
			flick(to_flick,cinematic_screen)
			cinematic_screen.icon_state = end

	else
		sleep(50)
	sound_to(world, sound('sound/effects/explosionfar.ogg'))

//////////////////////////
//Reports player logouts//
//////////////////////////
/proc/display_roundstart_logout_report()
	var/msg = "<span class='notice'><b>Roundstart logout report</b>\n\n"
	for(var/mob/living/L in SSmobs.mob_list)

		if(L.ckey)
			var/found = 0
			for(var/client/C in GLOB.clients)
				if(C.ckey == L.ckey)
					found = 1
					break
			if(!found)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Disconnected</b></font>)\n"

		if(L.ckey && L.client)
			if(L.client.inactivity >= (ROUNDSTART_LOGOUT_REPORT_TIME / 2))	//Connected, but inactive (alt+tabbed or something)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Connected, Inactive</b></font>)\n"
				continue //AFK client
			if(L.admin_paralyzed)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Admin paralyzed)\n"
				continue //Admin paralyzed
			if(L.stat)
				if(L.stat == UNCONSCIOUS)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dying)\n"
					continue //Unconscious
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dead)\n"
					continue //Dead

			continue //Happy connected client
		for(var/mob/observer/ghost/D in SSmobs.mob_list)
			if(D.mind && (D.mind.original == L || D.mind.current == L))
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (Dead)\n"
					continue //Dead mob, ghost abandoned
				else
					if(D.can_reenter_corpse)
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Adminghosted</b></font>)\n"
						continue //Lolwhat
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Ghosted</b></font>)\n"
						continue //Ghosted while alive

	msg += "</span>" // close the span from right at the top

	for(var/mob/M in SSmobs.mob_list)
		if(check_rights(R_ADMIN|R_MOD, FALSE, M))
			to_chat(M, msg)

/proc/show_objectives(datum/mind/player)

	if(!player || !player.current) return

	if(config.objectives_disabled == CONFIG_OBJECTIVE_NONE || !player.objectives.len)
		return

	var/obj_count = 1
	to_chat(player.current, SPAN_NOTICE("Your current objectives:"))
	for(var/datum/objective/objective in player.objectives)
		to_chat(player.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
		obj_count++

/mob/verb/check_round_info()
	set name = "Check Round Info"
	set category = "OOC"

	GLOB.using_map.map_info(src)

	if(!SSticker.mode)
		to_chat(usr, "Something is terribly wrong; there is no gametype.")
		return

	if(SSticker.master_mode != "secret")
		to_chat(usr, "<b>The roundtype is [capitalize(SSticker.mode.name)]</b>")
		if(SSticker.mode.round_description)
			to_chat(usr, "<i>[SSticker.mode.round_description]</i>")
		if(SSticker.mode.extended_round_description)
			to_chat(usr, "[SSticker.mode.extended_round_description]")
	else
		to_chat(usr, "<i>Shhhh</i>. It's a secret.")
