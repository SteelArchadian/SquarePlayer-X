; Audio capture for the visualizer. Band values are only read by Engine.lua.
; Bars = number of MeasureBandN sections below (also add matching ShapeN lines to [MeterBands]).
; Port=Output with no ID follows the Windows default playback device, so it works on any PC.

[MeasureAudio]
Measure = Plugin
Plugin = AudioLevel
Port = Output
FFTSize = 4096
FFTOverlap = 2048
FFTAttack = 0
FFTDecay = 0
; log-spaced bands over the range real music actually has (streamed audio is often cut above ~16 kHz)
FreqMin = 45
FreqMax = 14000
Sensitivity = 60
Bands = 10

[MeasureBand0]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 0

[MeasureBand1]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 1

[MeasureBand2]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 2

[MeasureBand3]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 3

[MeasureBand4]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 4

[MeasureBand5]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 5

[MeasureBand6]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 6

[MeasureBand7]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 7

[MeasureBand8]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 8

[MeasureBand9]
Measure = Plugin
Plugin = AudioLevel
Parent = MeasureAudio
Type = Band
BandIdx = 9
