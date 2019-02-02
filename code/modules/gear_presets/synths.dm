
/datum/equipment_preset/synth
	name = "Synth"
	uses_special_name = TRUE
	languages = list("English", "Russian", "Tradeband", "Sainja", "Xenomorph")
	skills = /datum/skills/early_synthetic

/datum/equipment_preset/synth/New()
	. = ..()
	access = get_all_accesses()

/datum/equipment_preset/synth/load_race(mob/living/carbon/human/H)
	H.set_species("Early Synthetic")

/datum/equipment_preset/synth/load_name(mob/living/carbon/human/H, var/randomise)
	H.real_name = "David"
	if(H.client && H.client.prefs)
		H.real_name = H.client.prefs.synthetic_name
		if(!H.real_name || H.real_name == "Undefined") //In case they don't have a name set or no prefs, there's a name.
			H.real_name = "David"
	if(H.mind)
		H.mind.name = H.real_name

/*****************************************************************************************************/

/datum/equipment_preset/synth/uscm
	name = "USCM Synthetic"
	flags = EQUIPMENT_PRESET_START_OF_ROUND

	idtype = /obj/item/card/id/gold
	assignment = "Synthetic"
	rank = "Synthetic"
	paygrade = "???"
	role_comm_title = "Syn"

/datum/equipment_preset/synth/uscm/load_race(mob/living/carbon/human/H)
	if(!H.client || !H.client.prefs)
		H.set_species("Early Synthetic")
	H.set_species(H.client.prefs.synthetic_type)

/datum/equipment_preset/synth/uscm/load_skills(mob/living/carbon/human/H)
	..()
	if(H.client && H.client.prefs && H.mind)
		if(H.client.prefs.synthetic_type == "Synthetic")
			H.mind.set_cm_skills(/datum/skills/synthetic)

/datum/equipment_preset/synth/uscm/load_gear(mob/living/carbon/human/H)
	var/backItem = /obj/item/storage/backpack/marine/satchel
	if (H.client && H.client.prefs && (H.client.prefs.backbag == 1))
		backItem = /obj/item/storage/backpack/industrial

	H.equip_to_slot_or_del(new /obj/item/device/radio/headset/almayer/mcom/cdrcom(H), WEAR_EAR)
	H.equip_to_slot_or_del(new /obj/item/clothing/under/rank/synthetic(H), WEAR_BODY)
	H.equip_to_slot_or_del(new /obj/item/clothing/shoes/white(H), WEAR_FEET)
	H.equip_to_slot_or_del(new /obj/item/storage/belt/utility/full(H), WEAR_WAIST)
	H.equip_to_slot_or_del(new /obj/item/clothing/gloves/yellow(H), WEAR_HANDS)
	H.equip_to_slot_or_del(new backItem(H), WEAR_BACK)

/*****************************************************************************************************/

/datum/equipment_preset/synth/uscm/wo
	name = "WO Support Synthetic"
	flags = EQUIPMENT_PRESET_START_OF_ROUND_WO

/datum/equipment_preset/synth/uscm/wo/load_gear(mob/living/carbon/human/H)
	var/backItem = /obj/item/storage/backpack/marine/satchel
	if (H.client && H.client.prefs && (H.client.prefs.backbag == 1))
		backItem = /obj/item/storage/backpack/industrial

	H.equip_to_slot_or_del(new /obj/item/clothing/head/beret/cm(H), WEAR_HEAD)
	H.equip_to_slot_or_del(new /obj/item/device/radio/headset/almayer/mcom/cdrcom(H), WEAR_EAR)
	H.equip_to_slot_or_del(new /obj/item/clothing/under/rank/synthetic(H), WEAR_BODY)
	H.equip_to_slot_or_del(new /obj/item/clothing/suit/storage/RO(H), WEAR_JACKET)
	H.equip_to_slot_or_del(new /obj/item/clothing/shoes/brown(H), WEAR_FEET)
	H.equip_to_slot_or_del(new /obj/item/storage/belt/utility/full(H), WEAR_WAIST)
	H.equip_to_slot_or_del(new /obj/item/clothing/gloves/yellow(H), WEAR_HANDS)
	H.equip_to_slot_or_del(new /obj/item/clothing/tie/storage/brown_vest(H), WEAR_ACCESSORY)
	H.equip_to_slot_or_del(new backItem(H), WEAR_BACK)
	H.equip_to_slot_or_del(new /obj/item/storage/pouch/construction/full(H), WEAR_R_STORE)
	H.equip_to_slot_or_del(new /obj/item/storage/pouch/general/medium(H), WEAR_L_STORE)

/*****************************************************************************************************/

/datum/equipment_preset/synth/combat_smartgunner
	name = "USCM Combat Synth (Smartgunner)"
	flags = EQUIPMENT_PRESET_EXTRA

	idtype = /obj/item/card/id/dogtag
	assignment = "Squad Smartgunner"
	rank = "Squad Smartgunner"
	paygrade = "E3"
	role_comm_title = "SG"
	skills = /datum/skills/smartgunner

/datum/equipment_preset/synth/combat_smartgunner/load_gear(mob/living/carbon/human/H)
	var/obj/item/clothing/under/marine/J = new(H)
	J.icon_state = ""
	H.equip_to_slot_or_del(J, WEAR_BODY)
	var/obj/item/clothing/head/helmet/specrag/L = new(H)
	L.icon_state = ""
	L.name = "synth faceplate"
	L.flags_inventory |= NODROP
	L.anti_hug = 99

	H.equip_to_slot_or_del(L, WEAR_HEAD)
	H.equip_to_slot_or_del(new /obj/item/clothing/suit/storage/marine/smartgunner(H), WEAR_JACKET)
	H.equip_to_slot_or_del(new /obj/item/storage/belt/gun/m44/full(H), WEAR_WAIST)
	H.equip_to_slot_or_del(new /obj/item/smartgun_powerpack(H), WEAR_BACK)
	H.equip_to_slot_or_del(new /obj/item/clothing/shoes/marine(H), WEAR_FEET)
	H.equip_to_slot_or_del(new /obj/item/weapon/gun/smartgun(H), WEAR_J_STORE)
	H.equip_to_slot_or_del(new /obj/item/weapon/combat_knife(H), WEAR_L_HAND)
	H.equip_to_slot_or_del(new /obj/item/clothing/gloves/marine(H), WEAR_HANDS)
	H.equip_to_slot_or_del(new /obj/item/clothing/glasses/night/m56_goggles(H), WEAR_EYES)
