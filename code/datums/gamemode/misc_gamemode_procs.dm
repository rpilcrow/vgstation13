#define LOW_THREAT 1
#define MEDIUM_THREAT 2
#define HIGH_THREAT 3


/proc/display_roundstart_logout_report()
	var/msg = "<span class='notice'><b>Roundstart logout report\n\n</span>"
	for(var/mob/living/L in mob_list)

		if(L.ckey)
			var/found = 0
			for(var/client/C in clients)
				if(C.ckey == L.ckey)
					found = 1
					break
			if(!found)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Disconnected</b></font>)\n"


		if(L.ckey && L.client)
			if(L.client.inactivity >= (ROUNDSTART_LOGOUT_REPORT_TIME / 2))	//Connected, but inactive (alt+tabbed or something)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Connected, Inactive</b></font>)\n"
				continue //AFK client
			if(L.stat)
				if(L.suiciding)	//Suicider
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='red'><b>Suicide</b></font>)\n"
					continue //Disconnected client
				if(L.stat == UNCONSCIOUS)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dying)\n"
					continue //Unconscious
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dead)\n"
					continue //Dead

			continue //Happy connected client
		for(var/mob/dead/observer/D in mob_list)
			if(D.mind && (D.mind.original == L || D.mind.current == L))
				if(L.stat == DEAD)
					if(L.suiciding)	//Suicider
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Suicide</b></font>)\n"
						continue //Disconnected client
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (Dead)\n"
						continue //Dead mob, ghost abandoned
				else
					if(D.can_reenter_corpse)
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>This shouldn't appear.</b></font>)\n"
						continue //Lolwhat
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Ghosted</b></font>)\n"
						continue //Ghosted while alive



	for(var/mob/M in mob_list)
		if(M.client && M.client.holder)
			to_chat(M, msg)


/proc/get_nt_opposed()
	var/list/dudes = list()
	for(var/mob/living/carbon/human/man in player_list)
		if (!man.client || !man.mind)
			continue

		if (man.mind.assigned_role == "MODE") // Wiz, nukies, ...
			continue

		if(man.client.prefs.nanotrasen_relation == "Opposed")
			dudes += man
		else if(man.client.prefs.nanotrasen_relation == "Skeptical" && prob(50))
			dudes += man

		else if( (man.mind.antag_roles[CULTIST] && prob(40)) || \
				 (man.mind.antag_roles[CHANGELING] && prob(50)) || \
				 (man.mind.antag_roles[TRAITOR] && prob(30)) || \
				 (man.mind.antag_roles[HEADREV] && prob(30)) \
				 )
			dudes += man

		else if(prob(10))
			dudes += man

	return dudes

/datum/gamemode/proc/send_intercept()
	var/intercepttext = {"<FONT size = 3><B>[command_name()] Update</B> Requested status information:</FONT><HR>
<B> In case you have misplaced your copy, attached is a list of personnel whom reliable sources&trade; suspect may be affiliated with the Syndicate:</B><br> <I>Reminder: Acting upon this information without solid evidence will result in termination of your working contract with Nanotrasen.</I></br>"}

	var/list/suspects = get_nt_opposed()

	for(var/mob/M in suspects)
		switch(rand(1, 100))
			if(1 to 50)
				intercepttext += "Someone with the job of <b>[M.mind.assigned_role]</b> <br>"
			else
				intercepttext += "<b>[M.name]</b>, the <b>[M.mind.assigned_role]</b> <br>"

	for (var/obj/machinery/computer/communications/comm in machines)
		if (!(comm.stat & (BROKEN | NOPOWER)) && comm.prints_intercept)
			var/obj/item/weapon/paper/intercept = new /obj/item/weapon/paper( comm.loc )
			intercept.name = "paper- '[command_name()] Status Summary'"
			intercept.info = intercepttext

			comm.messagetitle.Add("[command_name()] Status Summary")
			comm.messagetext.Add(intercepttext)

	command_alert(/datum/command_alert/enemy_comms_interception)

/datum/gamemode/dynamic/send_intercept()
	var/intercepttext = {"<FONT size = 3><B>[command_name()] Update</B> Requested status information:</FONT><HR>
<B> In case you have misplaced your copy, attached is a brief report on the star sector status:</br>"}

	var/list/threat_detected = list(MEDIUM_THREAT)

	if (threat_level > 50)
		threat_detected += HIGH_THREAT

	else
		threat_detected += LOW_THREAT

	var/detected = pick(threat_detected)

	switch (detected)
		if (LOW_THREAT)
			intercepttext += "<b>NanoTrasen controlled territory.</b> The station is nested deep inside our area of control, and a major attack is unlikely. <br/>"

		if (MEDIUM_THREAT)
			intercepttext += "<b>Contested system.</b> This station lies on the edge of our sphere of influence; exercice increased caution. <br/>"

		if (HIGH_THREAT)
			intercepttext += "<b>Uncharted space.</b> Congratulations and thank you for participating in the NT 'Frontier' space program."

	for (var/obj/machinery/computer/communications/comm in machines)
		if (!(comm.stat & (BROKEN | NOPOWER)) && comm.prints_intercept)
			var/obj/item/weapon/paper/intercept = new /obj/item/weapon/paper( comm.loc )
			intercept.name = "paper- '[command_name()] Status Summary'"
			intercept.info = intercepttext

			comm.messagetitle.Add("[command_name()] Status Summary")
			comm.messagetext.Add(intercepttext)

	command_alert(/datum/command_alert/enemy_comms_interception)

/proc/disable_suit_sensors(mob/living/carbon/human/H)
	var/obj/item/clothing/under/U = H.get_item_by_slot(slot_w_uniform)
	U.sensor_mode = 0

/proc/equip_wizard(mob/living/carbon/human/wizard_mob)
	if (!istype(wizard_mob))
		return

	//So zards properly get their items when they are admin-made.
	qdel(wizard_mob.wear_suit)
	qdel(wizard_mob.head)
	qdel(wizard_mob.shoes)
	qdel(wizard_mob.r_store)
	qdel(wizard_mob.l_store)

	if(!wizard_mob.find_empty_hand_index())
		wizard_mob.u_equip(wizard_mob.held_items[GRASP_LEFT_HAND])

	wizard_mob.equip_to_slot_or_del(new /obj/item/device/radio/headset(wizard_mob), slot_ears)
	wizard_mob.equip_to_slot_or_del(new /obj/item/clothing/under/lightpurple(wizard_mob), slot_w_uniform)
	disable_suit_sensors(wizard_mob)
	wizard_mob.equip_to_slot_or_del(new /obj/item/clothing/shoes/sandal(wizard_mob), slot_shoes)
	wizard_mob.equip_to_slot_or_del(new /obj/item/clothing/suit/wizrobe(wizard_mob), slot_wear_suit)
	wizard_mob.equip_to_slot_or_del(new /obj/item/clothing/head/wizard(wizard_mob), slot_head)
	if(wizard_mob.backbag == 2)
		wizard_mob.equip_to_slot_or_del(new /obj/item/weapon/storage/backpack(wizard_mob), slot_back)
	if(wizard_mob.backbag == 3)
		wizard_mob.equip_to_slot_or_del(new /obj/item/weapon/storage/backpack/satchel_norm(wizard_mob), slot_back)
	if(wizard_mob.backbag == 4)
		wizard_mob.equip_to_slot_or_del(new /obj/item/weapon/storage/backpack/satchel(wizard_mob), slot_back)
	wizard_mob.equip_to_slot_or_del(new /obj/item/weapon/storage/box/survival(wizard_mob), slot_in_backpack)
//	wizard_mob.equip_to_slot_or_del(new /obj/item/weapon/scrying_gem(wizard_mob), slot_l_store) For scrying gem.
	wizard_mob.equip_to_slot_or_del(new /obj/item/weapon/teleportation_scroll(wizard_mob), slot_r_store)
	wizard_mob.put_in_hands(new /obj/item/weapon/spellbook(wizard_mob))

	wizard_mob.make_all_robot_parts_organic()

	// For Vox and plasmadudes.
	//wizard_mob.species.handle_post_spawn(wizard_mob)

	to_chat(wizard_mob, "You will find a list of available spells in your spell book. Choose your magic arsenal carefully.")
	to_chat(wizard_mob, "In your pockets you will find a teleport scroll. Use it as needed.")
	wizard_mob.mind.store_memory("<B>Remember:</B> do not forget to prepare your spells.")
	wizard_mob.update_icons()
	return 1

/proc/name_wizard(mob/living/carbon/human/wizard_mob)
	//Allows the wizard to choose a custom name or go with a random one. Spawn 0 so it does not lag the round starting.
	if(wizard_mob.species && wizard_mob.species.name != "Human")
		wizard_mob.set_species("Human", 1)
	var/wizard_name_first = pick(wizard_first)
	var/wizard_name_second = pick(wizard_second)
	var/randomname = "[wizard_name_first] [wizard_name_second]"
	spawn(0)
		var/newname = copytext(sanitize(input(wizard_mob, "You are a Space Wizard. Would you like to change your name to something else?", "Name change", randomname) as null|text),1,MAX_NAME_LEN)

		if (!newname)
			newname = randomname

		wizard_mob.fully_replace_character_name(wizard_mob.real_name, newname)
	return

/proc/equip_highlander(var/mob/living/carbon/human/highlander_human)
	var/static/list/plasmaman_items = list(
		/obj/item/clothing/suit/space/plasmaman,
		/obj/item/clothing/head/helmet/space/plasmaman,
		/obj/item/weapon/tank/plasma/plasmaman,
		/obj/item/clothing/mask/breath)

	var/static/list/vox_items = list(
		/obj/item/weapon/tank/nitrogen,
		/obj/item/clothing/mask/breath/vox)

	highlander_human.mutations.Add(M_HULK) //all highlanders are permahulks
	highlander_human.set_species("Human", force_organs=TRUE) // No Dionae
	highlander_human.a_intent = I_HURT

	highlander_human.update_mutations()
	highlander_human.update_body()

	for (var/obj/item/I in highlander_human)
		if (istype(I, /obj/item/weapon/implant))
			continue
		if(isplasmaman(highlander_human) && is_type_in_list(I, plasmaman_items)) //Plasmamen don't lose their plasma gear since they need it to live.
			continue
		else if(isvox(highlander_human) && is_type_in_list(I, vox_items)) //Vox don't lose their N2 gear since they need it to live.
			continue
		qdel(I)

	highlander_human.equip_to_slot_or_del(new /obj/item/clothing/under/kilt(highlander_human), slot_w_uniform)
	highlander_human.equip_to_slot_or_del(new /obj/item/device/radio/headset/heads/captain(highlander_human), slot_ears)
	if(!isplasmaman(highlander_human)) //Plasmamen don't get a beret since they need their helmet to not burn to death.
		highlander_human.equip_to_slot_or_del(new /obj/item/clothing/head/beret(highlander_human), slot_head)
	highlander_human.put_in_hands(new /obj/item/weapon/claymore(highlander_human))
	highlander_human.equip_to_slot_or_del(new /obj/item/clothing/shoes/combat(highlander_human), slot_shoes)
	highlander_human.equip_to_slot_or_del(new /obj/item/weapon/pinpointer(highlander_human), slot_l_store)

	var/obj/item/weapon/card/id/new_id = new(highlander_human)
	new_id.name = "[highlander_human.real_name]'s ID Card"
	new_id.icon_state = "centcom"
	new_id.access = get_all_accesses()
	new_id.access += get_all_centcom_access()
	new_id.assignment = "Highlander"
	new_id.registered_name = highlander_human.real_name
	highlander_human.equip_to_slot_or_del(new_id, slot_wear_id)


///////////////////////////////////
//Keeps track of all living heads//
///////////////////////////////////
/proc/get_living_heads()
	var/list/heads = list()
	for(var/client/C in clients)
		var/mob/living/carbon/human/player = C.mob
		if(istype(player) && player.stat!=2 && player.mind && (player.mind.assigned_role in command_positions))
			heads += player.mind
	return heads


////////////////////////////
//Keeps track of all heads//
////////////////////////////
/proc/get_all_heads()
	var/list/heads = list()
	for(var/client/C in clients)
		var/mob/living/carbon/human/player = C.mob
		if(istype(player) && player.mind && (player.mind.assigned_role in command_positions))
			heads += player.mind
	return heads

/proc/get_assigned_head_roles()
	var/list/roles = list()
	for(var/client/C in clients)
		var/mob/living/carbon/human/player = C.mob
		if(istype(player) && player.mind && (player.mind.assigned_role in command_positions))
			roles += player.mind.assigned_role
	return roles

/proc/equip_traitor(mob/living/carbon/human/traitor_mob, var/uses = 20)
	if (!istype(traitor_mob))
		return
	. = 1

	// find a radio! toolbox(es), backpack, belt, headset
	var/loc = ""
	var/list/contents = recursive_type_check(traitor_mob, /obj/item/device)
	var/obj/item/R = locate(/obj/item/device/pda) in contents //Hide the uplink in a PDA if available, otherwise radio
	if(!R)
		R = locate(/obj/item/device/radio) in contents

	if (!R)
		to_chat(traitor_mob, "Unfortunately, the Syndicate wasn't able to get you a radio.")
		. = 0
	else
		if (istype(R, /obj/item/device/radio))
			// generate list of radio freqs
			var/obj/item/device/radio/target_radio = R
			var/freq = 1441
			var/list/freqlist = list()
			while (freq <= 1489)
				if (freq < 1451 || freq > 1459)
					freqlist += freq
				freq += 2
				if ((freq % 2) == 0)
					freq += 1
			freq = freqlist[rand(1, freqlist.len)]

			var/obj/item/device/uplink/hidden/T = new(R)
			T.uses = uses
			target_radio.hidden_uplink = T
			target_radio.traitor_frequency = freq
			to_chat(traitor_mob, "The Syndicate have cunningly disguised a Syndicate Uplink as your [R.name] [loc]. Simply dial the frequency [format_frequency(freq)] to unlock its hidden features.")
			traitor_mob.mind.store_memory("<B>Radio Freq:</B> [format_frequency(freq)] ([R.name] [loc]).")
			traitor_mob.mind.total_TC += target_radio.hidden_uplink.uses
		else if (istype(R, /obj/item/device/pda))
			// generate a passcode if the uplink is hidden in a PDA
			var/pda_pass = "[rand(100,999)] [pick("Alpha","Bravo","Delta","Omega")]"

			var/obj/item/device/uplink/hidden/T = new(R)
			R.hidden_uplink = T
			var/obj/item/device/pda/P = R
			P.lock_code = pda_pass

			to_chat(traitor_mob, "The Syndicate have cunningly disguised a Syndicate Uplink as your [R.name] [loc]. Simply enter the code \"[pda_pass]\" into the ringtone select to unlock its hidden features.")
			traitor_mob.mind.store_memory("<B>Uplink Passcode:</B> [pda_pass] ([R.name] [loc]).")
			traitor_mob.mind.total_TC += R.hidden_uplink.uses

/datum/mind/proc/find_syndicate_uplink()
	var/uplink = null

	for (var/obj/item/I in get_contents_in_object(current, /obj/item))
		if (I && I.hidden_uplink)
			uplink = I.hidden_uplink
			break

	return uplink

/datum/mind/proc/take_uplink()
	var/obj/item/device/uplink/hidden/H = find_syndicate_uplink()
	if(H)
		message_admins("Found and deleted [H] for [src].")
		qdel(H)
	else
		message_admins("The uplink for [src] could not be located for deletion.")

/proc/add_law_zero(mob/living/silicon/killer)
	var/law = "Accomplish your objectives at all costs."
	if(isAI(killer))
		var/mob/living/silicon/ai/KAI = killer
		KAI.set_zeroth_law(law, "Accomplish your AI's objectives at all costs.")
		KAI.notify_slaved()
	else
		var/mob/living/silicon/robot/KR = killer
		KR.set_zeroth_law(law)
	to_chat(killer, "<b>Your laws have been changed!</b>")
	killer.laws.zeroth_lock = TRUE
	to_chat(killer, "New law: 0. [law]")


/proc/equip_weeaboo(var/mob/living/carbon/human/H)
	if(!istype(H))
		return 0
	H.delete_all_equipped_items()
	var/obj/item/weapon/katana/hesfast/hayai = new /obj/item/weapon/katana/hesfast
	hayai.cant_drop = 1
	H.put_in_hands(hayai)

	H.equip_to_slot_or_del(new /obj/item/clothing/head/rice_hat, slot_head)
	H.equip_to_slot_or_del(new /obj/item/clothing/mask/balaclava, slot_wear_mask)
	H.equip_to_slot_or_del(new /obj/item/clothing/suit/kimono/ronin, slot_wear_suit)
	H.equip_to_slot_or_del(new /obj/item/clothing/under/color/black, slot_w_uniform)
	disable_suit_sensors(H)
	H.equip_to_slot_or_del(new /obj/item/weapon/storage/belt/skull, slot_belt)
	H.equip_to_slot_or_del(new /obj/item/clothing/shoes/sandal, slot_shoes)
	H.equip_to_slot_or_del(new /obj/item/clothing/gloves/nentendiepower, slot_gloves)
	H.equip_to_slot_or_del(new /obj/item/weapon/storage/backpack/messenger/black, slot_back)
	H.equip_to_slot_or_del(new /obj/item/weapon/storage/box/syndie_kit/smokebombs, slot_in_backpack)
	H.equip_to_slot_or_del(new /obj/item/weapon/dakimakura, slot_in_backpack)
	H.equip_to_slot_or_del(new /obj/item/weapon/dakimakura, slot_in_backpack)
	H.equip_to_slot_or_del(new /obj/item/weapon/dakimakura, slot_in_backpack)
	H.equip_to_slot_or_del(new /obj/item/mounted/poster/anime, slot_in_backpack)
	H.equip_to_slot_or_del(new /obj/item/stack/shuriken(H,10), slot_l_store)

/proc/name_weeaboo(var/mob/living/carbon/human/H)
	//Allows the weeb to choose a custom name or go with a random one. Spawn 0 so it does not lag the round starting.
	if(!isjusthuman(H))
		H.set_species("Human", 1)
	var/weeaboo_title = pick(ninja_titles)
	var/weeaboo_name = pick(ninja_names)
	var/randomname = "[weeaboo_title] [weeaboo_name]"
	spawn(0)
		var/newname = copytext(sanitize(input(H, "You are an angry Space Weeaboo. Would you like to change your name to something else?", randomname, randomname) as null|text),1,MAX_NAME_LEN)

		if (!newname)
			newname = randomname

		H.fully_replace_character_name(H.real_name, newname)

/proc/share_syndicate_codephrase(var/mob/living/agent)
	if(!agent)
		return 0
	if(!agent.mind)
		message_admins("tried to call share_syndicate_codephrase() on [agent] but it had no mind!")
		return 0
	var/words = "The Syndicate provided you with the following information on how to identify their agents:<br>"
	if (syndicate_code_phrase)
		words += "<span class='warning'>Code Phrase: </span>[syndicate_code_phrase]<br>"
		agent.mind.store_memory("<b>Code Phrase</b>: [syndicate_code_phrase]")
	else
		words += "Unfortunately, the Syndicate did not provide you with a code phrase.<br>"
	if (syndicate_code_response)
		words += "<span class='warning'>Code Response: </span>[syndicate_code_response]<br>"
		agent.mind.store_memory("<b>Code Response</b>: [syndicate_code_response]")
	else
		words += "Unfortunately, the Syndicate did not provide you with a code response.<br>"

	if(syndicate_code_phrase || syndicate_code_response)
		words += "Use the code words in the order provided, during regular conversation, to identify other agents. Proceed with caution, however, as everyone is a potential foe.<br>"
	else
		words += "Trust nobody.<br>"

	to_chat(agent,words)
	return 1

