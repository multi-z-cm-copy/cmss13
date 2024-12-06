/obj/structure/watchtower
    name = "watchtower"
    icon = 'icons/obj/structures/watchtower.dmi'
    icon_state = "stage1"

    density = FALSE
    bound_width = 64
    bound_height = 96

    var/stage = 1
    var/image/roof_image

/obj/structure/watchtower/Initialize()
    var/list/turf/top_turfs = CORNER_BLOCK_OFFSET(get_turf(src), 2, 1, 0, 1)
    var/list/turf/blocked_turfs = CORNER_BLOCK(get_turf(src), 2, 1) + CORNER_BLOCK_OFFSET(get_turf(src), 2, 1, 0, 2)
    var/list/turf/bottom_turfs = CORNER_OUTLINE(get_turf(src), 2, 3)

    for(var/turf/current_turf in top_turfs)
        new /obj/structure/blocker/invisible_wall/watchtower(current_turf)

    for(var/turf/current_turf in bottom_turfs)
        new /obj/structure/blocker/invisible_wall/watchtower/inverse(current_turf)

    for(var/turf/current_turf in blocked_turfs)
        new /obj/structure/blocked_turfs/invisible_wall/throw_pass(current_turf)

    update_icon()

/obj/structure/watchtower/Destroy()
    var/list/turf/turfs = CORNER_BLOCK(get_turf(src), 2, 2) + CORNER_OUTLINE(get_turf(src), 2, 3)

    for(var/turf/current_turf in turfs)
        for(var/obj/structure/blocker/invisible_wall in current_turf.contents)
            qdel(invisible_wall)

/obj/structure/watchtower/update_icon()
    . = ..()
    icon_state = "stage[stage]"

    overlays.Cut()

    if(stage >= 5)
        overlays += image(icon=icon, icon_state="railings", layer=ABOVE_MOB_LAYER, pixel_y=25)

    if (stage == 7)
        roof_image = image(icon=icon, icon_state="roof", layer=ABOVE_MOB_LAYER, pixel_y=51)
        roof_image.plane = ROOF_PLANE
        roof_image.appearance_flags = KEEP_APART
        overlays += roof_image

/obj/structure/watchtower/attackby(obj/item/W, mob/user)
    switch(stage)
        if(1)
            if(!istype(W, /obj/item/stack/rods))
                return

            var/obj/item/stack/rods/rods = W

            if(!do_after(user, 40 * user.get_skill_duration_multiplier(SKILL_CONSTRUCTION), INTERRUPT_NO_NEEDHAND|BEHAVIOR_IMMOBILE, BUSY_ICON_FRIENDLY, src))
                return

            if(rods.use(10))
                to_chat(user, SPAN_NOTICE("You add connection rods to the watchtower."))
                stage = 2
                update_icon()
            else
                to_chat(user, SPAN_NOTICE("You failed to construct the connection rods. You need more rods."))

            return
        if(2)
            if(!iswelder(W))
                return

            if(!HAS_TRAIT(W, TRAIT_TOOL_BLOWTORCH))
                to_chat(user, SPAN_WARNING("You need a stronger blowtorch!"))
                return

            if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
                return

            to_chat(user, SPAN_NOTICE("You weld the connection rods to the frame."))
            stage = 2.5

            return
        if(2.5)
            if(!HAS_TRAIT(W, TRAIT_TOOL_WRENCH))
                return

            if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
                return

            to_chat(user, SPAN_NOTICE("You summon a black hole and somehow produce more matter to elevate the frame."))
            stage = 3
            update_icon()

            return
        if(3)
            if(!HAS_TRAIT(W, TRAIT_TOOL_SCREWDRIVER))
                return

            var/obj/item/stack/sheet/metal/metal = user.get_inactive_hand()
            if(!istype(metal))
                to_chat(user, SPAN_BOLDWARNING("You need metal sheets in your offhand to continue construction of the watchtower."))
                return FALSE

            if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
                return

            if(metal.use(10))
                to_chat(user, SPAN_NOTICE("You construct the watchtower platform."))
                stage = 4
                update_icon()
            else
                to_chat(user, SPAN_NOTICE("You failed to construct the watchtower platform, you need more metal sheets in your offhand."))

            return
        if(4)
            if(!HAS_TRAIT(W, TRAIT_TOOL_CROWBAR))
                return

            var/obj/item/stack/sheet/plasteel/plasteel = user.get_inactive_hand()
            if(!istype(plasteel))
                to_chat(user, SPAN_BOLDWARNING("You need plasteel sheets in your offhand to continue construction of the watchtower."))
                return FALSE

            if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
                return

            if(plasteel.use(10))
                to_chat(user, SPAN_NOTICE("You construct the watchtower railing."))
                stage = 5
                update_icon()
            else
                to_chat(user, SPAN_NOTICE("You failed to construct the watchtower railing, you need more plasteel sheets in your offhand."))

            return
        if(5)
            if (!HAS_TRAIT(W, TRAIT_TOOL_WRENCH))
                return

            var/obj/item/stack/rods/rods = user.get_inactive_hand()
            if(!istype(rods))
                to_chat(user, SPAN_BOLDWARNING("You need metal rods in your offhand to continue construction of the watchtower."))
                return FALSE

            if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
                return

            if(rods.use(10))
                to_chat(user, SPAN_NOTICE("You construct the watchtower support rods."))
                stage = 6
                update_icon()
            else
                to_chat(user, SPAN_NOTICE("You failed to construct the watchtower support rods, you need more metal rods in your offhand."))

            return
        if(6)
            if (!iswelder(W))
                return

            if(!HAS_TRAIT(W, TRAIT_TOOL_BLOWTORCH))
                to_chat(user, SPAN_WARNING("You need a stronger blowtorch!"))
                return

            var/obj/item/stack/sheet/plasteel/plasteel = user.get_inactive_hand()
            if(!istype(plasteel))
                to_chat(user, SPAN_BOLDWARNING("You need plasteel sheets in your offhand to continue construction of the watchtower."))
                return FALSE

            if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
                return

            if(plasteel.use(10))
                to_chat(user, SPAN_NOTICE("You complete the watchtower."))
                stage = 7
                update_icon()
                

            else
                to_chat(user, SPAN_NOTICE("You failed to complete the watchtower, you need more plasteel sheets in your offhand."))

            return


/obj/structure/watchtower/attack_hand(mob/user)
    if(get_turf(user) == locate(x, y-1, z))
        if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
            return

        var/turf/actual_turf = locate(x, y+1, z)
        ADD_TRAIT(user, TRAIT_ON_WATCHTOWER, "watchtower")
        user.forceMove(actual_turf)
        user.client.change_view(user.client.view + 2)
        var/atom/movable/screen/plane_master/roof/roof_plane = user.hud_used.plane_masters["[ROOF_PLANE]"]
        roof_plane?.invisibility = INVISIBILITY_MAXIMUM
    else if(get_turf(user) == locate(x, y+1, z))
        if(!do_after(user,30, INTERRUPT_ALL|BEHAVIOR_IMMOBILE, BUSY_ICON_BUILD))
            return

        REMOVE_TRAIT(user, TRAIT_ON_WATCHTOWER, "watchtower")
        var/turf/actual_turf = locate(x, y-1, z)
        user.forceMove(actual_turf)
        user.client.change_view(user.client.view - 2)
        var/atom/movable/screen/plane_master/roof/roof_plane = user.hud_used.plane_masters["[ROOF_PLANE]"]
        roof_plane?.invisibility = 0

/obj/structure/blocked_turfs/invisible_wall/throw_pass

/obj/structure/blocked_turfs/invisible_wall/throw_pass/initialize_pass_flags(datum/pass_flags_container/PF)
	..()
	if (PF)
		PF.flags_can_pass_all = PASS_HIGH_OVER_ONLY

/obj/structure/blocker/invisible_wall/watchtower
    throwpass = TRUE

/obj/structure/blocker/invisible_wall/watchtower/initialize_pass_flags(datum/pass_flags_container/PF)
	..()
	if (PF)
		PF.flags_can_pass_all = PASS_HIGH_OVER_ONLY

/obj/structure/blocker/invisible_wall/watchtower/Collided(atom/movable/AM)
    if(HAS_TRAIT(AM, TRAIT_ON_WATCHTOWER))
        AM.forceMove(get_turf(src))

/obj/structure/blocker/invisible_wall/watchtower/inverse

/obj/structure/blocker/invisible_wall/watchtower/inverse/Collided(atom/movable/AM)
    if(!HAS_TRAIT(AM, TRAIT_ON_WATCHTOWER))
        AM.forceMove(get_turf(src))

// For Mappers
/obj/structure/watchtower/stage1
    stage = 1
    icon_state = "stage1"
/obj/structure/watchtower/stage2
    stage = 2
    icon_state = "stage2"
/obj/structure/watchtower/stage3
    stage = 3
    icon_state = "stage3"
/obj/structure/watchtower/stage4
    stage = 4
    icon_state = "stage4"
/obj/structure/watchtower/stage5
    stage = 5
    icon_state = "stage5"
/obj/structure/watchtower/stage6
    stage = 6
    icon_state = "stage6"
/obj/structure/watchtower/complete
    stage = 7
    icon_state = "stage7"