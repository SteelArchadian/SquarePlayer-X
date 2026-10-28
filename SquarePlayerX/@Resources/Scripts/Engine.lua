-- SquarePlayer X engine
-- Does two jobs every skin update so the .ini doesn't need dozens of DynamicVariables formulas:
--   1. Adaptive visualizer: per-band spectral whitening + auto-ranging, so any audible track moves the bars
--      regardless of which frequencies it actually has or how loud it is.
--   2. Dynamic width: measures the natural width of title/artist (hidden probe meters) and resizes the widget
--      only when that width actually changes.

local max, min, exp = math.max, math.min, math.exp

local function clamp(v, lo, hi)
	if v < lo then return lo elseif v > hi then return hi end
	return v
end

local function var(name, default)
	return tonumber(SKIN:ParseFormula(SKIN:ReplaceVariables('(' .. SKIN:GetVariable(name, default) .. ')'))) or tonumber(default)
end

-- per-frame smoothing coefficient for a time constant in seconds
local function coef(tau)
	return 1 - exp(-dt / tau)
end

function Initialize()
	S = var('Scale', '1')
	dt = var('UpdateRate', '33') / 1000
	H = 48 * S

	-- layout settings
	iconZone, vizZone, padding = var('IconZone', '50'), var('VisualizerZone', '80'), var('Padding', '20')
	minText, maxText, maxWidget = var('MinTextZone', '250'), var('MaxTextZone', '600'), var('MaxWidgetWidth', '900')

	-- visualizer settings
	whiten   = var('VizWhiten', '0.6')    -- 0 = raw spectrum, 1 = every band equally lively
	maxBoost = var('VizMaxBoost', '0.25') -- cap on how much a quiet band can be lifted (stops pure-noise bands dancing)
	range    = var('VizRange', '0.4')     -- dynamic range (in AudioLevel's 0..1 dB scale) shown by the bars
	gate     = var('VizGate', '0.04')     -- below this raw level the bars fall to rest
	gain     = var('VizGain', '1')
	barW     = var('VizBarWidth', '2') * S
	step     = var('VizSpacing', '6') * S
	maxH     = var('VizHeight', '36') * S
	minH     = var('VizMinBar', '0') * S
	radius   = var('VizRadius', '0') * S

	aAttack  = coef(var('VizAttackMs', '25') / 1000)
	aRelease = coef(var('VizReleaseMs', '160') / 1000)
	aMean    = coef(4.0)   -- per-band long-term average used for whitening
	aHi      = coef(2.5)   -- how fast the auto-range ceiling relaxes after a loud part

	bands, mean, out, lastDrawn, shapeKey = {}, {}, {}, {}, {}
	local i = 0
	while true do
		local m = SKIN:GetMeasure('MeasureBand' .. i)
		if not m then break end
		i = i + 1
		bands[i] = m
		mean[i], out[i], lastDrawn[i] = 0.35, 0, -1
		shapeKey[i] = (i == 1) and 'Shape' or ('Shape' .. i)
	end
	N = #bands
	hi = 0.6

	status = SKIN:GetMeasure('MeasureStatus')
	titleProbe = SKIN:GetMeter('MeterTitleProbe')
	artistProbe = SKIN:GetMeter('MeterArtistProbe')
	lastTextW, widgetW = -1, maxWidget

	if not status then
		-- WebNowPlaying failed to load (not installed / wrong version): say so instead of silently showing nothing
		SKIN:Bang('!SetOption', 'MeterTitle', 'Text', 'WebNowPlaying 3.x plugin missing')
		SKIN:Bang('!SetOption', 'MeterArtist', 'Text', 'Install SquarePlayerX.rmskin')
	end
	Layout(true)
end

function Layout(force)
	local tW = titleProbe and titleProbe:GetW() or 0
	local aW = artistProbe and artistProbe:GetW() or 0
	local textW = clamp(max(tW, aW), minText, maxText)
	textW = min(textW, maxWidget - iconZone - vizZone - padding)
	if not force and textW == lastTextW then return end
	lastTextW = textW
	widgetW = iconZone + textW + vizZone + padding

	SKIN:Bang('!SetOption', 'MeterTitle', 'W', textW)
	SKIN:Bang('!SetOption', 'MeterArtist', 'W', textW)
	SKIN:Bang('!SetOption', 'MeterCanvas', 'Shape',
		string.format('Rectangle 0,0,%.2f,%.2f,5 | Fill Color 0,0,0,1 | StrokeWidth 0', widgetW, H))
	SKIN:Bang('!SetOption', 'MeterProgress', 'X', 8 * S)
	SKIN:Bang('!SetOption', 'MeterProgress', 'W', widgetW - 16 * S)
	for i = 1, N do lastDrawn[i] = -1 end -- bars moved, force redraw
end

function Update()
	Layout(false)
	if N == 0 then return 0 end

	local raw, peakRaw = {}, 0
	for i = 1, N do
		local v = bands[i]:GetValue()
		raw[i] = v
		if v > peakRaw then peakRaw = v end
	end

	local target = {}
	if peakRaw < gate then
		for i = 1, N do target[i] = 0 end
	else
		-- spectral whitening in the (already logarithmic) band domain:
		-- bands that are consistently quiet in this song get lifted toward the average
		local sum = 0
		for i = 1, N do
			mean[i] = mean[i] + aMean * (raw[i] - mean[i])
			sum = sum + mean[i]
		end
		local avg = sum / N
		local w, peakW = {}, 0
		for i = 1, N do
			w[i] = raw[i] + clamp(whiten * (avg - mean[i]), -maxBoost, maxBoost)
			if w[i] > peakW then peakW = w[i] end
		end
		-- auto-range: ceiling follows the loudest band (instant up, slow down), bars show the top `range` below it
		if peakW > hi then hi = peakW else hi = hi + aHi * (peakW - hi) end
		local lo = hi - range
		for i = 1, N do
			target[i] = clamp((w[i] - lo) / range * gain, 0, 1)
		end
	end

	local x0 = widgetW - vizZone
	local mid = H / 2
	for i = 1, N do
		local t = target[i]
		out[i] = out[i] + ((t > out[i]) and aAttack or aRelease) * (t - out[i])
		local h = max(minH, out[i] * maxH)
		if h < 0.25 then h = 0 end
		if math.abs(h - lastDrawn[i]) > 0.2 then
			lastDrawn[i] = h
			SKIN:Bang('!SetOption', 'MeterBands', shapeKey[i], string.format(
				'Rectangle %.2f,%.2f,%.2f,%.2f,%.2f | Extend Style',
				x0 + (i - 1) * step, mid - h / 2, barW, h, radius))
		end
	end
	return peakRaw
end
