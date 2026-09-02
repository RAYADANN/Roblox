--!strict
--[[
	SimPop UI style kit — buttons + block cards.

	Button:  require(...simpop).SimPopButton
	Block:   require(...simpop.block).SimPopBlock  — shop / inventory cards
]]

local ImageIds = require(script.ImageIds)
local SimPopButton = require(script.SimPopButton)

return {
    ImageIds = ImageIds,
    SimPop = ImageIds.SimPop,
    BlueButtonAssets = ImageIds.BlueButton,
    TONES = ImageIds.TONES,
    ORIENTATIONS = ImageIds.ORIENTATIONS,
    SimPopChrome = require(script.SimPopChrome),
    SimPopButton = SimPopButton,
    BlueButton = require(script.BlueButton),
    block = require(script.block),
}
