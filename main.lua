import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/animator"
import "CoreLibs/easing"
import "CoreLibs/timer"
import "tape"
import "tape_gfx"

local gfx <const> = playdate.graphics
local geom <const> = playdate.geometry
local snd <const> = playdate.sound

local curr_tape
local tape_gfxs = {
    makeTapeGFX("images/tape_star"),
    makeTapeGFX("images/tape_a"),
    makeTapeGFX("images/tape_b"),
    makeTapeGFX("images/tape_c"),
    makeTapeGFX("images/tape_d")
}

local tapes = {
    makeTape(),
    makeTape(),
    makeTape(),
    makeTape(),
    makeTape()
}

local modePlaybackSpeed <const> = 1
local modeStartOffset <const> = 2
local modeLength <const> = 3

local edit_mode = modePlaybackSpeed

local tape_index = 1

local tape_animator = gfx.animator.new(500, 0, 0, playdate.easingFunctions.inOutCubic)
local tape_width = 420

function startup()
    curr_tape = tapes[1]

    for index, tape_gfx in ipairs(tape_gfxs) do
        print("Moving "..index.." to "..tape_width * index - tape_width)
        moveTapeGFXTo(tape_gfx, tape_width * index - tape_width, 0)
        setTapeGFXRate(tape_gfx, 1, 4)
        setTapeGFXStartOffset(tape_gfx, 0)
        setTapeGFXTargetLength(tape_gfx, 1)
    end
end

startup()

local max_rate <const> = 4

function playdate.BButtonDown()
    if isPlaying(curr_tape) then
        stopPlaying(curr_tape)
    end

    if curr_tape.queued then
        curr_tape.queued = false
    end

    -- if its the first tape, start recording
    if tape_index == 1 then
        startRecording(curr_tape)
    else
        -- otherwise, queue the recording
        print("queued recording of tape "..tape_index)
        curr_tape.queuedRecording = true
    end
end

function playdate.BButtonUp()
    -- stop listening/recording
    if listening then
        snd.micinput.stopListening()
        listening = false
    end

    if curr_tape.queuedRecording then
        curr_tape.queuedRecording = false
    end

    stopRecording(curr_tape)
end

function playdate.AButtonDown()
    -- if not recording, toggle queue and stop playing if necessary
    if not playdate.buttonIsPressed(playdate.kButtonB) then
        curr_tape.queued = not curr_tape.queued
        if not curr_tape.queued then
            stopPlaying(curr_tape)
        end
    end
end

function playdate.upButtonDown()
    edit_mode -= 1
    if edit_mode < 1 then
        edit_mode = modeLength
    end
    setLabelIndex(edit_mode)
end

function playdate.downButtonDown()
    edit_mode += 1
    if edit_mode > 3 then
        edit_mode = 1
    end
    setLabelIndex(edit_mode)
end

function playdate.leftButtonDown()
    tape_index -= 1
    if tape_index < 1 then
        tape_index = #tapes
    end
    curr_tape = tapes[tape_index]

    tape_animator = gfx.animator.new(500,
    tape_animator:currentValue(),
    tape_index * tape_width - tape_width,
    playdate.easingFunctions.inOutCubic)
end

function playdate.rightButtonDown()
    tape_index += 1
    if tape_index > #tapes then
        tape_index = 1 
    end
    curr_tape = tapes[tape_index]

    tape_animator = gfx.animator.new(500,
    tape_animator:currentValue(),
    tape_index * tape_width - tape_width,
    playdate.easingFunctions.inOutCubic)
end

function playdate.update()
    local curr_tape_gfx = tape_gfxs[tape_index]
    local playbackTime = getLength(tapes[1])
    if playdate.getElapsedTime() > playbackTime then
        playdate.resetElapsedTime()
        for _, tape in pairs(tapes) do
            if tape.queued then
                startPlaying(tape)
            end
        end

        if curr_tape.queuedRecording then
            print("Began recording tape "..tape_index)
            curr_tape.queuedRecording = false
            startRecording(curr_tape)
        end
    end

    local change = playdate.getCrankChange()
    if edit_mode == modePlaybackSpeed then
        curr_tape.rate += change / 1440
        if curr_tape.rate < -max_rate then
            curr_tape.rate = -max_rate
        elseif curr_tape.rate > max_rate then
            curr_tape.rate = max_rate
        end
        setTapeGFXRate(curr_tape_gfx, curr_tape.rate, max_rate)
    elseif edit_mode == modeStartOffset then
        if change ~= 0 then
            curr_tape.offset += change / 1440
            if curr_tape.offset > 1 then
                curr_tape.offset = 1
            elseif curr_tape.offset < 0 then
                curr_tape.offset = 0
            end

            if tape_index == 1 then
                playdate.resetElapsedTime()
                startPlaying(curr_tape)
            end
        end
        setTapeGFXStartOffset(curr_tape_gfx, curr_tape.offset)
    elseif edit_mode == modeLength then
        if change ~= 0 then
            curr_tape.targetLength += change / 1440

            if curr_tape.targetLength < 0 then
                curr_tape.targetLength = 9
            elseif curr_tape.targetLength > 1 then
                curr_tape.targetLength = 1
            end

            if tape_index == 1 then
                playdate.resetElapsedTime()
                startPlaying(curr_tape)
            end
        end
        setTapeGFXTargetLength(curr_tape_gfx, curr_tape.targetLength)
    end


    -- animation stuff
    playdate.graphics.setDrawOffset(-tape_animator:currentValue(), 0)

    if curr_tape.queued then
        unpauseTapeGFX(curr_tape_gfx)
    else
        pauseTapeGFX(curr_tape_gfx)
    end

    updateTapeGFX(curr_tape_gfx)
    gfx.sprite.update()

    playdate.timer.updateTimers()
end
