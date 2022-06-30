local snd <const> = playdate.sound

function makeTape()
    local buffer = snd.sample.new(30, snd.kFormat16bitMono)
    local tape = {
        sound_buffer = buffer,
        player = snd.sampleplayer.new(buffer),

        rate = 1.0,
        offset = 0.0,
        targetLength = 1.0,
        queued = false,
        queuedRecording = false
    }
    return tape
end

-- begin playing a tape
function startPlaying(tape)
    -- don't try and overlap
    if isPlaying(tape) then
        stopPlaying(tape)
    end

    local length = tape.player:getLength()
    local fps = snd.getSampleRate()
    local total_frames = length * fps
    
    -- set parameters for playback
    tape.player:setRate(tape.rate)
    tape.player:setOffset(length * tape.offset)

    local start = total_frames * tape.offset 
    local remaining_frames = total_frames - start

    tape.player:setPlayRange(0, start + (remaining_frames * tape.targetLength))
    if tape.rate > 0.01 or tape.rate < -0.01 then
        tape.player:play()
    end
end

-- check if tape is playing
function isPlaying(tape)
    return tape.player:isPlaying()
end

-- stop playing a tape
function stopPlaying(tape)
    if isPlaying(tape) then
        tape.player:stop()
    end
end

-- reset the tapes parameters
function resetTape(tape)
    tape.rate = 1.0
    tape.offset = 0.0
    tape.targetLength = 1.0
end

-- empty callback
local function recording_callback(buf)
end

-- global-ish tracking of microphone state
local recording = false

-- begin recording to a tape's buffer
function startRecording(tape)
    -- make sure this isn't playing
    if isPlaying(tape) then
        stopPlaying(tape)
    end

    if recording then
        snd.micinput.stopRecording()
        -- no need to stop recording here
    end

    snd.micinput.recordToSample(tape.sound_buffer, recording_callback)
    recording = true
end

-- finish recording to a tapes buffer
function stopRecording(tape)
    if recording then
        snd.micinput.stopRecording()
        recording = false
    end

    tape.player:setSample(tape.sound_buffer)
    resetTape(tape)
end

function getLength(tape)
    local length = tape.player:getLength()
    length *= 1 - tape.offset
    length *= tape.targetLength
    length /= math.abs(tape.rate)
    return length
end
