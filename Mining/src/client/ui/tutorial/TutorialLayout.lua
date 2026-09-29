--!strict
-- Общие размеры туториала для phone / desktop.

local ViewportLayout = require(script.Parent.Parent.util.ViewportLayout)

local TutorialLayout = {}

export type DialogMetrics = {
	width: number,
	sideInset: number,
	avatarSize: number,
	avatarPad: number,
	textColX: number,
	nameH: number,
	nameText: number,
	bodyText: number,
	minH: number,
	maxH: number,
	footerAdvance: number,
	footerSkipOnly: number,
	skipSize: number,
	corner: number,
}

export type TrackerMetrics = {
	designW: number,
	designH: number,
	scaleMin: number,
	scaleMax: number,
	topY: number,
	iconSlot: number,
	iconSize: number,
	iconPad: number,
	textX: number,
	titleY: number,
	titleH: number,
	titleText: number,
	descY: number,
	descH: number,
	descText: number,
	progressY: number,
	progressH: number,
	progressTextY: number,
	progressTextSize: number,
}

function TutorialLayout.isPhone(): boolean
	return ViewportLayout.isPhone()
end

function TutorialLayout.px(design: number): number
	return ViewportLayout.px(design)
end

function TutorialLayout.textPx(design: number): number
	return ViewportLayout.textPx(design)
end

function TutorialLayout.scaledDesign(design: number): number
	if ViewportLayout.isPhone() then
		return math.max(1, math.floor(design * 0.8 + 0.5))
	end
	return design
end

function TutorialLayout.dialogMetrics(): DialogMetrics
	local px = TutorialLayout.px
	local sd = TutorialLayout.scaledDesign
	local playW = ViewportLayout.playableWidth()
	local playH = ViewportLayout.playableHeight()

	if ViewportLayout.isPhone() then
		local width = math.clamp(
			math.floor(playW * 0.62 * 0.8 + 0.5),
			px(sd(200)),
			px(sd(292))
		)
		return {
			width = width,
			sideInset = px(sd(56)),
			avatarSize = px(sd(44)),
			avatarPad = px(sd(8)),
			textColX = px(sd(56)),
			nameH = px(sd(14)),
			nameText = TutorialLayout.textPx(sd(11)),
			bodyText = TutorialLayout.textPx(sd(11)),
			minH = px(sd(64)),
			maxH = math.max(px(sd(72)), math.floor(playH * 0.21 * 0.8 + 0.5)),
			footerAdvance = px(sd(30)),
			footerSkipOnly = px(sd(6)),
			skipSize = px(sd(34)),
			corner = px(sd(10)),
		}
	end

	local width = math.clamp(
		math.floor(playW * 0.92 + 0.5),
		px(260),
		px(560)
	)
	return {
		width = width,
		sideInset = px(130),
		avatarSize = px(86),
		avatarPad = px(14),
		textColX = px(112),
		nameH = px(22),
		nameText = TutorialLayout.textPx(16),
		bodyText = TutorialLayout.textPx(15),
		minH = px(118),
		maxH = math.floor(playH * 0.42 + 0.5),
		footerAdvance = px(46),
		footerSkipOnly = px(12),
		skipSize = px(34),
		corner = px(14),
	}
end

function TutorialLayout.dialogRestY(): number
	local gap = if ViewportLayout.isPhone() then TutorialLayout.px(4) else 8
	return -ViewportLayout.bottomChromeInset() - gap
end

function TutorialLayout.trackerMetrics(hasProgress: boolean): TrackerMetrics
	local px = TutorialLayout.px

	if ViewportLayout.isPhone() then
		local designH = if hasProgress then 72 else 52
		return {
			designW = 268,
			designH = designH,
			scaleMin = 0.5,
			scaleMax = 0.62,
			topY = ViewportLayout.topHudY(),
			iconSlot = 36,
			iconSize = 24,
			iconPad = 8,
			textX = 48,
			titleY = 8,
			titleH = 12,
			titleText = 10,
			descY = 22,
			descH = 20,
			descText = 13,
			progressY = 54,
			progressH = 7,
			progressTextY = 46,
			progressTextSize = 10,
		}
	end

	return {
		designW = 420,
		designH = 96,
		scaleMin = 0.5,
		scaleMax = 1,
		topY = ViewportLayout.topHudY(),
		iconSlot = 52,
		iconSize = 36,
		iconPad = 14,
		textX = 78,
		titleY = 16,
		titleH = 18,
		titleText = 13,
		descY = 36,
		descH = 22,
		descText = 18,
		progressY = 72,
		progressH = 10,
		progressTextY = 68,
		progressTextSize = 12,
	}
end

function TutorialLayout.trackerTopY(): number
	return TutorialLayout.trackerMetrics(false).topY
end

function TutorialLayout.trackerScale(designW: number): number
	local maxW = ViewportLayout.playableWidth() - ViewportLayout.sidePad() * 2
	local m = TutorialLayout.trackerMetrics(false)
	return math.clamp(math.min(ViewportLayout.uiScale(), maxW / designW), m.scaleMin, m.scaleMax)
end

return TutorialLayout
