/datum/soundOutput
	var/client/owner
	var/scape_cooldown = INITIAL_SOUNDSCAPE_COOLDOWN //This value is changed when entering an area. Time it takes for a soundscape sound to be triggered
	var/list/soundscape_playlist = list() //Updated on changing areas
	var/ambience = null //The file currently being played as ambience
	var/status_flags = 0 //For things like ear deafness, psychodelic effects, and other things that change how all sounds behave
	var/list/current_sounds = list()
	var/list/source_sounds = list()

	/// Currently applied environmental reverb.
	VAR_PROTECTED/owner_environment = SOUND_ENVIRONMENT_NONE

/datum/soundOutput/New(client/client)
	if(!client)
		qdel(src)
		return
	owner = client
	RegisterSignal(owner.mob, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_moved))
	RegisterSignal(owner.mob, COMSIG_MOB_LOGOUT, PROC_REF(on_mob_logout))
	RegisterSignal(owner, COMSIG_CLIENT_MOB_LOGGED_IN, PROC_REF(on_client_mob_logged_in))
	RegisterSignal(owner, COMSIG_CLIENT_MOB_MOVED, PROC_REF(update_sounds))
	return ..()

/datum/soundOutput/Destroy()
	UnregisterSignal(owner.mob, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_LOGOUT))
	UnregisterSignal(owner, COMSIG_CLIENT_MOB_LOGGED_IN)
	UnregisterSignal(owner, COMSIG_CLIENT_MOB_MOVED)
	owner = null
	return ..()

#define SMOOTHING 2 // [1, 32], 32 Means best sound most lag 1 Means worst sound least lag

/datum/soundOutput/proc/update_sounds(atom/user, direction)
	SIGNAL_HANDLER
	for(var/channel in current_sounds)
		for(var/i in 0 to round(32/SMOOTHING))
			i = i * SMOOTHING
			switch(direction)
				if(1)
					process_sound(current_sounds[channel], TRUE, 0, -1+i/32)
				if(2)
					process_sound(current_sounds[channel], TRUE, 0, 1-i/32)
				if(4)
					process_sound(current_sounds[channel], TRUE, -1+i/32)
				if(8)
					process_sound(current_sounds[channel], TRUE, 1-i/32, 0)

/datum/soundOutput/proc/update_sounds_from_source(atom/source, direction)
	SIGNAL_HANDLER
	for(var/datum/sound_template/template in source_sounds[source])
		for(var/i in 0 to round(32/SMOOTHING))
			i = i * SMOOTHING
			switch(direction)
				if(1)
					process_sound(template, TRUE, 0, 1+i/32)
				if(2)
					process_sound(template, TRUE, 0, -1-i/32)
				if(4)
					process_sound(template, TRUE, 1+i/32)
				if(8)
					process_sound(template, TRUE, -1-i/32, 0)

/datum/soundOutput/proc/remove_sound(channel)
	current_sounds -= channel

/datum/soundOutput/proc/process_sound(datum/sound_template/T, update=FALSE, offset_x = 0, offset_y = 0)
	var/sound/S = sound(T.file, T.wait, T.repeat)
	S.volume = owner.volume_preferences[T.volume_cat] * T.volume
	if(T.channel == 0)
		S.channel = get_free_channel()
	else
		S.channel = T.channel
	S.frequency = T.frequency
	S.falloff = T.falloff
	S.status = update ? SOUND_UPDATE : T.status 
	if(!update)
		S.params = list("on-end" = ".soundend [S.channel] [T.source]")


	var/turf/source_turf
	if(!QDELETED(T.source))
		source_turf = get_turf(T.source)

		if(!update && istype(T.source, /atom/movable))
			source_sounds[T.source] = T
			RegisterSignal(T.source, COMSIG_MOVABLE_MOVED, PROC_REF(update_sounds))
	else
		source_turf = locate(T.x, T.y, T.z)

	var/turf/owner_turf = get_turf(owner.mob)
	if(owner_turf)
		// We're in an interior and sound came from outside
		if(SSinterior.in_interior(owner_turf) && owner_turf.z != T.z)
			var/datum/interior/VI = SSinterior.get_interior_by_coords(owner_turf.x, owner_turf.y, owner_turf.z)
			if(VI && VI.exterior)
				var/turf/candidate = get_turf(VI.exterior)
				if(candidate.z != T.z)
					return // Invalid location
				S.falloff /= 2
				owner_turf = candidate
		S.x = source_turf.x - owner_turf.x + offset_x
		S.y = 0
		S.z = source_turf.y - owner_turf.y + offset_y
	S.y += T.y_s_offset
	S.x += T.x_s_offset
	if(source_turf.x && source_turf.y && source_turf.z)
		S.echo = SOUND_ECHO_REVERB_ON
	if(owner.mob.ear_deaf > 0)
		S.status |= SOUND_MUTE

	if(!update)
		current_sounds[num2text(S.channel)] = T
	sound_to(owner, S)

/client/verb/sound_ended(channel as num, source as mob|obj|turf)
	set name = ".soundend"

	soundOutput.remove_sound(num2text(channel))

	if(soundOutput.source_sounds[source])
		soundOutput.source_sounds -= source
		UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	

/datum/soundOutput/proc/update_ambience(area/target_area, ambience_override, force_update = FALSE)
	var/status_flags = SOUND_STREAM
	var/target_ambience = ambience_override

	if(!(owner.prefs.toggles_sound & SOUND_AMBIENCE))
		if(!force_update)
			return
		status_flags |= SOUND_MUTE

	// Autodetect mode
	if(!target_area && !target_ambience)
		target_area = get_area(owner.mob)
		if(!target_area)
			return
	if(!target_ambience)
		target_ambience = target_area.get_sound_ambience(owner)
	if(target_area)
		soundscape_playlist = target_area.soundscape_playlist

	var/sound/S = sound(null,1,0,SOUND_CHANNEL_AMBIENCE)

	if(ambience == target_ambience)
		if(!force_update)
			return
		status_flags |= SOUND_UPDATE
	else
		S.file = target_ambience
		ambience = target_ambience


	S.volume = 100 * owner.volume_preferences[VOLUME_AMB]
	S.status = status_flags

	if(target_area)
		var/muffle
		if(target_area.ceiling_muffle)
			switch(target_area.ceiling)
				if(CEILING_NONE)
					muffle = 0
				if(CEILING_GLASS)
					muffle = MUFFLE_MEDIUM
				if(CEILING_METAL)
					muffle = MUFFLE_HIGH
				else
					S.volume = 0
		muffle += target_area.base_muffle
		S.echo = list(muffle)
	sound_to(owner, S)


/datum/soundOutput/proc/update_soundscape()
	scape_cooldown--
	if(scape_cooldown <= 0)
		if(length(soundscape_playlist))
			var/sound/S = sound()
			S.file = pick(soundscape_playlist)
			S.volume = 100 * owner.volume_preferences[VOLUME_AMB]
			S.x = pick(1,-1)
			S.z = pick(1,-1)
			S.y = 1
			S.channel = SOUND_CHANNEL_SOUNDSCAPE
			sound_to(owner, S)
		var/area/A = get_area(owner.mob)
		if(A)
			scape_cooldown = pick(A.soundscape_interval, A.soundscape_interval + 1, A.soundscape_interval -1)
		else
			scape_cooldown = INITIAL_SOUNDSCAPE_COOLDOWN

/datum/soundOutput/proc/apply_status()
	var/sound/S = sound()
	if(status_flags & EAR_DEAF_MUTE)
		S.status = SOUND_MUTE | SOUND_UPDATE
		sound_to(owner, S)
	else
		S.status = SOUND_UPDATE
		sound_to(owner, S)

/// Pulls mob's area's sound_environment and applies if necessary and not overridden.
/datum/soundOutput/proc/update_area_environment()
	var/area/owner_area = get_area(owner.mob)
	var/new_environment = owner_area.sound_environment

	if(owner.mob.sound_environment_override != SOUND_ENVIRONMENT_NONE) //override in effect, can't apply
		return

	set_owner_environment(new_environment)

/// Pulls mob's sound_environment_override and applies if necessary.
/datum/soundOutput/proc/update_mob_environment_override()
	var/new_environment_override = owner.mob.sound_environment_override

	if(new_environment_override == SOUND_ENVIRONMENT_NONE) //revert to area environment
		update_area_environment()
		return

	set_owner_environment(new_environment_override)

/// Pushes new_environment to owner and updates owner_environment var.
/datum/soundOutput/proc/set_owner_environment(new_environment = SOUND_ENVIRONMENT_NONE)
	if(new_environment ~= src.owner_environment) //no need to change
		return

	var/sound/sound = sound()
	sound.environment = new_environment
	sound_to(owner, sound)

	src.owner_environment = new_environment

/datum/soundOutput/proc/on_mob_moved(datum/source, atom/oldloc, direction, Forced)
	SIGNAL_HANDLER //COMSIG_MOVABLE_MOVED
	update_area_environment()

/datum/soundOutput/proc/on_mob_logout(datum/source)
	SIGNAL_HANDLER //COMSIG_MOB_LOGOUT
	UnregisterSignal(owner.mob, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_LOGOUT))

/datum/soundOutput/proc/on_client_mob_logged_in(datum/source, mob/new_mob)
	SIGNAL_HANDLER //COMSIG_CLIENT_MOB_LOGGED_IN
	RegisterSignal(owner.mob, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_moved))
	RegisterSignal(owner.mob, COMSIG_MOB_LOGOUT, PROC_REF(on_mob_logout))
	update_mob_environment_override()

/client/proc/adjust_volume_prefs(volume_key, prompt = "", channel_update = 0)
	volume_preferences[volume_key] = (tgui_input_number(src, prompt, "Volume", volume_preferences[volume_key]*100)) / 100
	if(volume_preferences[volume_key] > 1)
		volume_preferences[volume_key] = 1
	if(volume_preferences[volume_key] < 0)
		volume_preferences[volume_key] = 0
	if(channel_update)
		var/sound/S = sound()
		S.channel = channel_update
		S.volume = 100 * volume_preferences[volume_key]
		S.status = SOUND_UPDATE
		sound_to(src, S)

/client/verb/adjust_volume_sfx()
	set name = "Adjust Volume SFX"
	set category = "Preferences.Sound"
	adjust_volume_prefs(VOLUME_SFX, "Set the volume for sound effects", 0)

/client/verb/adjust_volume_ambience()
	set name = "Adjust Volume Ambience"
	set category = "Preferences.Sound"
	adjust_volume_prefs(VOLUME_AMB, "Set the volume for ambience and soundscapes", 0)
	soundOutput.update_ambience(null, null, TRUE)

/client/verb/adjust_volume_lobby_music()
	set name = "Adjust Volume LobbyMusic"
	set category = "Preferences.Sound"
	adjust_volume_prefs(VOLUME_LOBBY, "Set the volume for Lobby Music", SOUND_CHANNEL_LOBBY)
