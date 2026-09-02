--!strict

local Constants = if script
	then require(script.Parent.Parent.data.Constants)
	else require("@shared/data/Constants")
local ShopLogic = if script
	then require(script.Parent.ShopLogic)
	else require("@shared/util/ShopLogic")
local AchievementDatabase = if script
	then require(script.Parent.Parent.data.AchievementDatabase)
	else require("@shared/data/AchievementDatabase")

type AchievementId = AchievementDatabase.AchievementId
type AchievementState = {
	buyAllArea1: boolean,
	buyAllArea2: boolean,
	fallOffMap: boolean,
	jumpFiveTimes: boolean,
}

local AchievementLogic = {}

function AchievementLogic.isComplete(state: AchievementState, id: AchievementId): boolean
	return state[id] == true
end

function AchievementLogic.shouldUnlockBuyAll(areaId: string, pads: { [string]: boolean }): boolean
	if not ShopLogic.isValidArea(areaId) then
		return false
	end
	return ShopLogic.allPadsBought(pads)
end

function AchievementLogic.shouldUnlockJumpFive(jumpCount: number): boolean
	return jumpCount >= Constants.JUMPS_FOR_ACHIEVEMENT
end

function AchievementLogic.shouldUnlockFall(y: number): boolean
	return y <= Constants.FALL_Y_THRESHOLD
end

function AchievementLogic.areaAchievementId(areaId: string): AchievementId?
	if areaId == "Area1" then
		return "buyAllArea1"
	elseif areaId == "Area2" then
		return "buyAllArea2"
	end
	return nil
end

return AchievementLogic
