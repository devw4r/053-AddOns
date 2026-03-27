local MainExtendedStats = {
	name = "Extended Stats",
	description = "Shows an expanded stats panel beside the character sheet.",
}

local MAIN_EXTENDED_STATS_WHITE = "|cFFFFFFFF"
local MAIN_EXTENDED_STATS_RESET = "|r"
local MAIN_EXTENDED_STATS_BASE_PROC_CHANCE = 0.03
local MAIN_EXTENDED_STATS_BASE_CRIT_CHANCE = 0.05
local MAIN_EXTENDED_STATS_BASE_MELEE_MISS_CHANCE = 0.05
local MAIN_EXTENDED_STATS_SPELL_SCHOOLS = {"Holy", "Fire", "Nature", "Frost", "Shadow", "Arcane"}
local MAIN_EXTENDED_STATS_RESISTANCE_NAMES = {"Holy", "Fire", "Nature", "Frost", "Shadow"}
local MAIN_EXTENDED_STATS_SKILL_CATEGORIES = {"class", "secondary", "spec", "racial", "proficiency"}
local MAIN_EXTENDED_STATS_CLASS_NAME_TO_TOKEN = {
	Warrior = "WARRIOR",
	Paladin = "PALADIN",
	Hunter = "HUNTER",
	Rogue = "ROGUE",
	Priest = "PRIEST",
	Shaman = "SHAMAN",
	Mage = "MAGE",
	Warlock = "WARLOCK",
	Druid = "DRUID",
}
local MAIN_EXTENDED_STATS_CLASS_BASE_DODGE = {
	DRUID = 0.9,
	MAGE = 3.2,
	PALADIN = 0.7,
	PRIEST = 3.0,
	SHAMAN = 1.7,
	WARLOCK = 2.0,
}
local MAIN_EXTENDED_STATS_CLASS_AGI_DODGE_SCALING = {
	DRUID = {4.6, 20.0},
	PALADIN = {4.6, 20.0},
	SHAMAN = {4.6, 20.0},
	MAGE = {12.9, 20.0},
	ROGUE = {1.1, 14.5},
	HUNTER = {1.8, 26.5},
	PRIEST = {11.0, 20.0},
	WARLOCK = {8.4, 20.0},
	WARRIOR = {3.9, 20.0},
}
local MAIN_EXTENDED_STATS_CLASS_STRENGTH_SCALING_CRIT = {
	DRUID = {4.6, 20.0},
	PALADIN = {4.6, 20.0},
	SHAMAN = {4.6, 20.0},
	MAGE = {12.9, 20.0},
	ROGUE = {2.2, 29.0},
	HUNTER = {1.8, 26.5},
	PRIEST = {11.0, 20.0},
	WARLOCK = {8.4, 20.0},
	WARRIOR = {7.8, 40.0},
}
local MAIN_EXTENDED_STATS_CLASS_MAGIC_SCHOOLS = {
	WARRIOR = {},
	ROGUE = {},
	MAGE = {"Fire", "Frost"},
	PRIEST = {"Holy", "Shadow"},
	PALADIN = {"Holy"},
	DRUID = {"Nature"},
	WARLOCK = {"Fire", "Shadow"},
	SHAMAN = {"Fire", "Frost", "Nature"},
}

local function MainExtendedStats_FormatStat(baseValue, modifier)
	local totalValue
	local sign
	local color

	totalValue = baseValue + modifier
	if modifier == 0 then
		return tostring(baseValue)
	end

	sign = modifier > 0 and "+" or ""
	color = modifier > 0 and "|cff20ff20" or "|cffff2020"
	return color .. totalValue .. " (" .. baseValue .. sign .. modifier .. ")" .. "|r"
end

local function MainExtendedStats_Interpolate(level1Value, level60Value, level)
	return ((level1Value * (60 - level)) + (level60Value * (level - 1))) / 59
end

local function MainExtendedStats_EstimateArmorReduction(armor, level)
	local reduction

	reduction = (0.3 * (armor - 1)) / (10 * level + 89)
	if reduction > 0.75 then
		reduction = 0.75
	end
	if reduction < 0 then
		reduction = 0
	end
	return string.format("%.2f%%", reduction * 100)
end

local function MainExtendedStats_EstimateDodge(agility, level, classToken, defenseSkill)
	local baseValue
	local scaling
	local rate
	local bonus
	local difference
	local percent

	baseValue = MAIN_EXTENDED_STATS_CLASS_BASE_DODGE[classToken] or 0
	scaling = MAIN_EXTENDED_STATS_CLASS_AGI_DODGE_SCALING[classToken] or {20, 20}
	rate = MainExtendedStats_Interpolate(scaling[1], scaling[2], level)
	bonus = agility / rate
	difference = defenseSkill - (level * 5)
	percent = bonus + baseValue + difference * 0.04
	if percent > 100 then
		percent = 100
	end
	return string.format("%.2f%%", percent)
end

local function MainExtendedStats_EstimateBlock(strength, level, classToken, rating)
	local scaling
	local rate
	local bonus
	local difference
	local percent

	scaling = MAIN_EXTENDED_STATS_CLASS_AGI_DODGE_SCALING[classToken] or {20, 20}
	rate = MainExtendedStats_Interpolate(scaling[1], scaling[2], level)
	bonus = strength / rate
	difference = rating - (level * 5)
	percent = bonus + difference * 0.04
	if percent > 100 then
		percent = 100
	end
	if percent < 0 then
		percent = 0
	end
	return string.format("%.2f%%", percent)
end

local function MainExtendedStats_EstimateParry(defenseSkill, level)
	return string.format("%.2f%%", 5.0 + (defenseSkill - level * 5) * 0.04)
end

local function MainExtendedStats_EstimateProcChance(agility, level, classToken)
	local scaling
	local rate
	local procChance

	scaling = MAIN_EXTENDED_STATS_CLASS_AGI_DODGE_SCALING[classToken] or {20, 20}
	rate = MainExtendedStats_Interpolate(scaling[1], scaling[2], level)
	procChance = MAIN_EXTENDED_STATS_BASE_PROC_CHANCE + (agility / rate / 100)
	if procChance > 1 then
		procChance = 1
	end
	return string.format("%.2f%%", procChance * 100)
end

local function MainExtendedStats_EstimateBlockValue(strength)
	return tostring(strength)
end

local function MainExtendedStats_EstimateCritChance(strength, level, classToken, weaponSkill)
	local scaling
	local rate
	local baseChance
	local difference
	local bonus
	local critChance

	scaling = MAIN_EXTENDED_STATS_CLASS_STRENGTH_SCALING_CRIT[classToken] or {20, 20}
	rate = MainExtendedStats_Interpolate(scaling[1], scaling[2], level)
	baseChance = MAIN_EXTENDED_STATS_BASE_CRIT_CHANCE + (strength / rate / 100)
	difference = weaponSkill - (level * 5)
	if difference < 0 then
		bonus = difference * 0.002
	else
		bonus = difference * 0.0004
	end
	critChance = baseChance + bonus
	if critChance > 1 then
		critChance = 1
	end
	if critChance < 0 then
		critChance = 0
	end
	return string.format("%.2f%%", critChance * 100)
end

local function MainExtendedStats_EstimateMissChance(level, weaponSkill)
	local difference
	local missChance

	difference = (level * 5) - weaponSkill
	missChance = MAIN_EXTENDED_STATS_BASE_MELEE_MISS_CHANCE + difference * 0.04
	if missChance > 1 then
		missChance = 1
	end
	if missChance < 0 then
		missChance = 0
	end
	return string.format("%.2f%%", missChance * 100)
end

local function MainExtendedStats_EstimateHitChance()
	return "0.00%"
end

local function MainExtendedStats_EstimateSpellCritChance()
	return "5.00%"
end

local function MainExtendedStats_IsSchoolUsedByClass(classToken, schoolName)
	local schools
	local index

	schools = MAIN_EXTENDED_STATS_CLASS_MAGIC_SCHOOLS[classToken] or {}
	for index = 1, Main_ArrayCount(schools) do
		if schools[index] == schoolName then
			return 1
		end
	end
	return nil
end

local function MainExtendedStats_ClassUsesAnyMagic(classToken)
	local schools

	schools = MAIN_EXTENDED_STATS_CLASS_MAGIC_SCHOOLS[classToken]
	return schools and Main_ArrayCount(schools) > 0
end

local function MainExtendedStats_GetSkillRankByName(skillName)
	local counts
	local categoryIndex
	local category
	local count
	local index
	local name
	local rank

	counts = {GetSkillLineInfo()}
	for categoryIndex = 1, Main_ArrayCount(MAIN_EXTENDED_STATS_SKILL_CATEGORIES) do
		category = MAIN_EXTENDED_STATS_SKILL_CATEGORIES[categoryIndex]
		count = counts[categoryIndex] or 0
		for index = 1, count do
			name, _, rank = GetSkillByIndex(category, index)
			if name == skillName then
				return rank
			end
		end
	end

	return nil
end

local function MainExtendedStats_GetSpellSchoolSkill(schoolName)
	local counts
	local categoryIndex
	local category
	local count
	local index
	local name
	local rank

	counts = {GetSkillLineInfo()}
	for categoryIndex = 1, Main_ArrayCount(MAIN_EXTENDED_STATS_SKILL_CATEGORIES) do
		category = MAIN_EXTENDED_STATS_SKILL_CATEGORIES[categoryIndex]
		count = counts[categoryIndex] or 0
		for index = 1, count do
			name, _, rank = GetSkillByIndex(category, index)
			if name and strfind(string.lower(name), string.lower(schoolName)) then
				return rank
			end
		end
	end

	return nil
end

local function MainExtendedStats_EstimateSpellResistChanceBySchool(level, classToken)
	local result
	local defense
	local index
	local school
	local skill
	local difference
	local resistChance

	result = {}
	defense = level * 5
	for index = 1, Main_ArrayCount(MAIN_EXTENDED_STATS_SPELL_SCHOOLS) do
		school = MAIN_EXTENDED_STATS_SPELL_SCHOOLS[index]
		if not MAIN_EXTENDED_STATS_CLASS_MAGIC_SCHOOLS[classToken] or
			MainExtendedStats_IsSchoolUsedByClass(classToken, school) then
			skill = MainExtendedStats_GetSpellSchoolSkill(school) or 0
			difference = defense - skill
			resistChance = 0.04
			if difference > 0 then
				if difference < 75 then
					resistChance = resistChance + (difference / 5 / 100)
				else
					resistChance = resistChance + (0.04 + ((difference / 5 / 100 - 0.02) * 7))
				end
			end
			result[school] = string.format("%.2f%%", math.min(100, math.max(0, resistChance * 100)))
		else
			result[school] = "N/A"
		end
	end
	return result
end

local function MainExtendedStats_EstimateSpellDamage()
	return {
		Holy = "0",
		Fire = "0",
		Nature = "0",
		Frost = "0",
		Shadow = "0",
		Arcane = "0",
	}
end

local function MainExtendedStats_EstimateCastingSpeed()
	return "0.00%"
end

local function MainExtendedStats_EstimateSpellCostModifier()
	return "0.00%"
end

local function MainExtendedStats_EstimateManaRegen(spirit, classToken)
	local regen

	regen = 0
	if classToken == "PRIEST" then
		regen = spirit * 0.15
	elseif classToken == "MAGE" then
		regen = spirit * 0.1
	elseif classToken == "DRUID" then
		regen = spirit * 0.08
	elseif classToken == "PALADIN" then
		regen = spirit * 0.075
	elseif classToken == "SHAMAN" or classToken == "WARLOCK" then
		regen = spirit * 0.07
	end

	return string.format("%.2f", regen * 2.5) .. " / 5s"
end

local function MainExtendedStats_GetRangedWeaponStats()
	local name
	local minDamage
	local maxDamage
	local speed
	local weaponType
	local lineIndex
	local leftText
	local rightText
	local text
	local low
	local high
	local speedValue

	-- The classic API does not expose full ranged tooltip stats directly, so this parses the tooltip text.
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetInventoryItem("player", 18)

	for lineIndex = 1, 15 do
		leftText = getglobal("GameTooltipTextLeft" .. lineIndex)
		rightText = getglobal("GameTooltipTextRight" .. lineIndex)

		if lineIndex == 1 and leftText and leftText:GetText() then
			name = leftText:GetText()
		end

		if leftText and leftText:GetText() then
			text = leftText:GetText()
			_, _, low, high = strfind(text, "(%d+)%s?%-+%s?(%d+)%s?[Dd]amage")
			if low and high then
				minDamage = tonumber(low)
				maxDamage = tonumber(high)
			end
		end

		if rightText and rightText:GetText() then
			text = rightText:GetText()
			if text == "Bow" or text == "Gun" or text == "Thrown" or text == "Crossbow" or text == "Wand" then
				weaponType = text
			end
			if strfind(text, "Speed") then
				speedValue = strsub(text, strfind(text, "Speed") + 5)
				speedValue = gsub(speedValue, "[:%s]", "")
				speed = tonumber(speedValue) or speed
			end
		end
	end

	GameTooltip:Hide()
	return minDamage, maxDamage, speed, weaponType, name
end

local function MainExtendedStats_HasRangedWeaponEquipped()
	local lineIndex
	local leftText
	local text

	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetInventoryItem("player", 18)

	for lineIndex = 1, 10 do
		leftText = getglobal("GameTooltipTextLeft" .. lineIndex)
		if leftText and leftText:GetText() then
			text = leftText:GetText()
			if strfind(text, "%d+%s?%-+%s?%d+%s?[Dd]amage") then
				GameTooltip:Hide()
				return 1
			end
		end
	end

	GameTooltip:Hide()
	return nil
end

local function MainExtendedStats_GetRangedWeaponSkill(weaponType)
	local skillName

	if weaponType == "Bow" then
		skillName = "Bows"
	elseif weaponType == "Gun" then
		skillName = "Guns"
	elseif weaponType == "Crossbow" then
		skillName = "Crossbows"
	elseif weaponType == "Thrown" then
		skillName = "Thrown"
	elseif weaponType == "Wand" then
		skillName = "Wands"
	end

	if not skillName then
		return nil
	end

	return MainExtendedStats_GetSkillRankByName(skillName)
end

local function MainExtendedStats_Update()
	local className
	local classToken
	local level
	local health
	local mana
	local strengthBase
	local strengthModifier
	local agilityBase
	local agilityModifier
	local staminaBase
	local staminaModifier
	local intellectBase
	local intellectModifier
	local spiritBase
	local spiritModifier
	local strengthTotal
	local agilityTotal
	local intellectTotal
	local spiritTotal
	local baseArmor
	local positiveArmor
	local negativeArmor
	local armorText
	local armorReductionText
	local defenseBase
	local defenseModifier
	local defenseText
	local defenseSkill
	local shieldSkill
	local blockSkill
	local blockRatingSkill
	local showBlockSkillText
	local attackBase
	local attackModifier
	local attackText
	local minDamage
	local maxDamage
	local damageBonus
	local rawBonus1
	local rawBonus2
	local rawBonus3
	local rawBonus4
	local rawBonus5
	local totalDamageBonus
	local damageText
	local mainHandSpeed
	local speedText
	local dodgeText
	local parryText
	local blockText
	local procText
	local blockValueText
	local critText
	local hitBonusText
	local missText
	local spellCritText
	local spellResistText
	local spellDamage
	local castingSpeedText
	local spellCostModifierText
	local manaRegenText
	local resistanceLines
	local resistanceIndex
	local resistanceBase
	local text
	local tooltipMinDamage
	local tooltipMaxDamage
	local rangedWeaponSpeed
	local rangedWeaponType
	local hasRangedWeapon
	local rangedColor
	local rangedAttackPower
	local rangedBonusDamage
	local finalMinDamage
	local finalMaxDamage
	local rangedSkill
	local rangedCritText
	local rangedMissText
	local rangedHitText
	local schoolIndex
	local schoolName
	local schoolValue
	local schoolColor

	if not MainExtendedStatsText then
		return
	end

	className = UnitClass("player")
	classToken = MAIN_EXTENDED_STATS_CLASS_NAME_TO_TOKEN[className] or "WARRIOR"
	level = UnitLevel("player") or 0
	health = UnitHealthMax("player") or 0
	mana = UnitManaMax("player") or 0

	strengthBase, strengthModifier = UnitStat("player", 1)
	agilityBase, agilityModifier = UnitStat("player", 2)
	staminaBase, staminaModifier = UnitStat("player", 3)
	intellectBase, intellectModifier = UnitStat("player", 4)
	spiritBase, spiritModifier = UnitStat("player", 5)

	strengthTotal = strengthBase + strengthModifier
	agilityTotal = agilityBase + agilityModifier
	intellectTotal = intellectBase + intellectModifier
	spiritTotal = spiritBase + spiritModifier

	_, baseArmor, positiveArmor, negativeArmor = UnitArmor("player")
	armorText = MainExtendedStats_FormatStat(baseArmor, positiveArmor + negativeArmor)
	armorReductionText = MainExtendedStats_EstimateArmorReduction(baseArmor + positiveArmor + negativeArmor, level)

	defenseBase, defenseModifier = UnitDefense("player")
	defenseText = MainExtendedStats_FormatStat(defenseBase, defenseModifier)
	defenseSkill = defenseBase + defenseModifier

	shieldSkill = MainExtendedStats_GetSkillRankByName("Shields") or (level * 5)
	blockSkill = MainExtendedStats_GetSkillRankByName("Block") or (level * 5)
	blockRatingSkill = defenseSkill
	showBlockSkillText = 1

	if classToken == "PALADIN" then
		blockRatingSkill = blockSkill
	elseif classToken == "WARRIOR" then
		blockRatingSkill = shieldSkill
	elseif classToken == "ROGUE" or classToken == "SHAMAN" or classToken == "HUNTER" then
		showBlockSkillText = nil
	end

	attackBase, attackModifier = UnitAttackBothHands("player")
	attackText = MainExtendedStats_FormatStat(attackBase, attackModifier)
	minDamage, maxDamage, damageBonus, rawBonus1, rawBonus2, rawBonus3, rawBonus4, rawBonus5 = UnitDamage("player")
	totalDamageBonus = damageBonus + rawBonus1 + rawBonus2 + rawBonus3 + rawBonus4 + rawBonus5
	damageText = string.format("%d - %d", minDamage + totalDamageBonus, maxDamage + totalDamageBonus)
	mainHandSpeed = UnitAttackSpeed("player")
	speedText = string.format("%.2f", mainHandSpeed or 0)

	dodgeText = MainExtendedStats_EstimateDodge(agilityTotal, level, classToken, defenseSkill)
	parryText = MainExtendedStats_EstimateParry(defenseSkill, level)
	blockText = MainExtendedStats_EstimateBlock(strengthTotal, level, classToken, blockRatingSkill)
	procText = MainExtendedStats_EstimateProcChance(agilityTotal, level, classToken)
	blockValueText = MainExtendedStats_EstimateBlockValue(strengthTotal)
	critText = MainExtendedStats_EstimateCritChance(strengthTotal, level, classToken, attackBase)
	hitBonusText = MainExtendedStats_EstimateHitChance()
	missText = MainExtendedStats_EstimateMissChance(level, attackBase)

	spellCritText = MainExtendedStats_EstimateSpellCritChance()
	spellResistText = MainExtendedStats_EstimateSpellResistChanceBySchool(level, classToken)
	spellDamage = MainExtendedStats_EstimateSpellDamage()
	castingSpeedText = MainExtendedStats_EstimateCastingSpeed()
	spellCostModifierText = MainExtendedStats_EstimateSpellCostModifier()
	manaRegenText = MainExtendedStats_EstimateManaRegen(spiritTotal, classToken)

	resistanceLines = {}
	for resistanceIndex = 1, 5 do
		_, resistanceBase = UnitResistance("player", resistanceIndex)
		table.insert(resistanceLines, string.format("%s: %d", MAIN_EXTENDED_STATS_RESISTANCE_NAMES[resistanceIndex], resistanceBase))
	end

	tooltipMinDamage, tooltipMaxDamage, rangedWeaponSpeed, rangedWeaponType = MainExtendedStats_GetRangedWeaponStats()
	hasRangedWeapon = MainExtendedStats_HasRangedWeaponEquipped()
	rangedColor = hasRangedWeapon and "" or "|cff888888"
	rangedAttackPower = agilityTotal * 2
	rangedBonusDamage = rangedAttackPower / 14
	finalMinDamage = tooltipMinDamage and (tooltipMinDamage + rangedBonusDamage) or rangedBonusDamage
	finalMaxDamage = tooltipMaxDamage and (tooltipMaxDamage + rangedBonusDamage) or rangedBonusDamage
	rangedSkill = MainExtendedStats_GetRangedWeaponSkill(rangedWeaponType) or (level * 5)
	rangedCritText = MainExtendedStats_EstimateCritChance(strengthTotal, level, classToken, rangedSkill)
	rangedMissText = MainExtendedStats_EstimateMissChance(level, rangedSkill)
	rangedHitText = MainExtendedStats_EstimateHitChance()

	text = ""
	text = text .. "HP: " .. health .. "\n"
	text = text .. "MP: " .. mana .. "\n\n"

	text = text .. MAIN_EXTENDED_STATS_WHITE .. "MELEE:\n" .. MAIN_EXTENDED_STATS_RESET
	text = text .. "Attack Rating: " .. attackText .. "\n"
	text = text .. "Damage: " .. damageText .. "\n"
	text = text .. "Attack Speed: " .. speedText .. "\n"
	text = text .. "Crit Chance: " .. critText .. "\n"
	text = text .. "Hit Chance (Bonus): " .. hitBonusText .. "\n"
	text = text .. "Miss Chance: " .. missText .. "\n"
	text = text .. "Proc Chance: " .. procText .. "\n\n"

	text = text .. MAIN_EXTENDED_STATS_WHITE .. "RANGED:\n" .. MAIN_EXTENDED_STATS_RESET
	text = text .. rangedColor .. "Attack Rating: " .. rangedSkill .. MAIN_EXTENDED_STATS_RESET .. "\n"
	if tooltipMinDamage then
		text = text .. rangedColor .. string.format("Damage: %.1f - %.1f\n", finalMinDamage, finalMaxDamage) .. MAIN_EXTENDED_STATS_RESET
	else
		text = text .. rangedColor .. "Damage: N/A" .. MAIN_EXTENDED_STATS_RESET .. "\n"
	end
	if rangedWeaponSpeed then
		text = text .. rangedColor .. string.format("Attack Speed: %.2f\n", rangedWeaponSpeed) .. MAIN_EXTENDED_STATS_RESET
	else
		text = text .. rangedColor .. "Attack Speed: N/A" .. MAIN_EXTENDED_STATS_RESET .. "\n"
	end
	text = text .. rangedColor .. "Crit Chance: " .. rangedCritText .. MAIN_EXTENDED_STATS_RESET .. "\n"
	text = text .. rangedColor .. "Hit Chance (Bonus): " .. rangedHitText .. MAIN_EXTENDED_STATS_RESET .. "\n"
	text = text .. rangedColor .. "Miss Chance: " .. rangedMissText .. MAIN_EXTENDED_STATS_RESET .. "\n\n"

	text = text .. MAIN_EXTENDED_STATS_WHITE .. "DEFENSIVE:\n" .. MAIN_EXTENDED_STATS_RESET
	text = text .. "Armor: " .. armorText .. "\n"
	text = text .. "Armor Dmg Reduction: " .. armorReductionText .. "\n"
	text = text .. "Defense: " .. defenseText .. "\n"
	if showBlockSkillText then
		if classToken == "PALADIN" then
			text = text .. "Block Skill: " .. blockRatingSkill .. "\n"
		else
			text = text .. "Shield Skill: " .. blockRatingSkill .. "\n"
		end
	end
	text = text .. "Dodge: " .. dodgeText .. "\n"
	text = text .. "Parry: " .. parryText .. "\n"
	text = text .. "Block: " .. blockText .. "\n"
	text = text .. "Block Value: " .. blockValueText .. "\n\n"

	if MainExtendedStats_ClassUsesAnyMagic(classToken) then
		rangedColor = ""
	else
		rangedColor = "|cff888888"
	end
	text = text .. MAIN_EXTENDED_STATS_WHITE .. "MAGICAL:\n" .. MAIN_EXTENDED_STATS_RESET
	text = text .. rangedColor .. "Spell Crit Chance: " .. spellCritText .. MAIN_EXTENDED_STATS_RESET .. "\n"
	text = text .. rangedColor .. "Casting Speed: " .. castingSpeedText .. MAIN_EXTENDED_STATS_RESET .. "\n"
	text = text .. rangedColor .. "Mana Regen: " .. manaRegenText .. MAIN_EXTENDED_STATS_RESET .. "\n"
	text = text .. rangedColor .. "Spell Cost Modifier: " .. spellCostModifierText .. MAIN_EXTENDED_STATS_RESET .. "\n\n"

	text = text .. MAIN_EXTENDED_STATS_WHITE .. "SPELL RESIST CHANCE:\n" .. MAIN_EXTENDED_STATS_RESET
	for schoolIndex = 1, Main_ArrayCount(MAIN_EXTENDED_STATS_SPELL_SCHOOLS) do
		schoolName = MAIN_EXTENDED_STATS_SPELL_SCHOOLS[schoolIndex]
		schoolValue = spellResistText[schoolName]
		if MainExtendedStats_IsSchoolUsedByClass(classToken, schoolName) then
			schoolColor = ""
		else
			schoolColor = "|cff888888"
		end
		text = text .. schoolColor .. schoolName .. " Resist Chance: " .. (schoolValue or "N/A") .. MAIN_EXTENDED_STATS_RESET .. "\n"
	end

	text = text .. "\n" .. MAIN_EXTENDED_STATS_WHITE .. "SPELL BONUS DAMAGE:\n" .. MAIN_EXTENDED_STATS_RESET
	for schoolIndex = 1, Main_ArrayCount(MAIN_EXTENDED_STATS_SPELL_SCHOOLS) do
		schoolName = MAIN_EXTENDED_STATS_SPELL_SCHOOLS[schoolIndex]
		schoolValue = spellDamage[schoolName]
		if MainExtendedStats_IsSchoolUsedByClass(classToken, schoolName) then
			schoolColor = ""
		else
			schoolColor = "|cff888888"
		end
		text = text .. schoolColor .. schoolName .. " Damage: " .. (schoolValue or "N/A") .. MAIN_EXTENDED_STATS_RESET .. "\n"
	end

	text = text .. "\n" .. MAIN_EXTENDED_STATS_WHITE .. "RESISTANCES:\n" .. MAIN_EXTENDED_STATS_RESET
	text = text .. table.concat(resistanceLines, "\n")

	MainExtendedStatsText:SetText(text)
end

function MainExtendedStatsFrame_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("UNIT_STATS")
	this:RegisterEvent("UNIT_INVENTORY_CHANGED")
	this:RegisterEvent("UNIT_DEFENSE")
	this:Hide()
end

function MainExtendedStatsFrame_OnShow()
	if Main.IsModuleEnabled("extended_stats") then
		MainExtendedStats_Update()
	end
end

function MainExtendedStatsFrame_OnEvent(event)
	if not Main.IsModuleEnabled("extended_stats") then
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		MainExtendedStats_Update()
	elseif (event == "UNIT_STATS" or event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_DEFENSE") and arg1 == "player" then
		MainExtendedStats_Update()
	end
end

function MainExtendedStats:Init()
	MainExtendedStatsFrame:Hide()
end

function MainExtendedStats:Enable()
	MainExtendedStats_Update()
	MainExtendedStatsFrame:Show()
end

function MainExtendedStats:Disable()
	MainExtendedStatsFrame:Hide()
end

Main.RegisterModule("extended_stats", MainExtendedStats)
