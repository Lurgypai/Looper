import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/animator"
import "CoreLibs/easing"

local gfx <const> = playdate.graphics
local geom <const> = playdate.geometry
local snd <const> = playdate.sound

local sound_buffer
local player

local bg_spr
local gear_anim
local gear_anim_2
local gear_spr
local gear_spr_2
local label_spr

local switch_spr
local switch_default_pos = {
    x = 88 + 135,
    y = 150
}

local label_default_pos = {
    x = 57,
    y = 168
}

local label_height <const> = 17


local modePlaybackSpeed <const> = 1
local modeStartOffset <const> = 2
local modeLength <const> = 3

local edit_mode = modePlaybackSpeed

local label_animator

function startup()
    sound_buffer = snd.sample.new(30, snd.kFormat16bitMono)
    player = snd.sampleplayer.new(sound_buffer)

    local bg_img = gfx.image.new("images/tape")
    bg_spr = gfx.sprite.new(bg_img)
    bg_spr:setCenter(0, 0)
    bg_spr:add()

    local gear_table = gfx.imagetable.new(45 / 5)
    local gear_img = gfx.image.new("images/gear")
    local index = 1
    for i=5,45,5 do
        gear_table:setImage(index, gear_img:rotatedImage(i))
        index += 1
    end
    gear_anim = gfx.animation.loop.new(100, gear_table)
    gear_spr = gfx.sprite.new(gear_anim:image())
    gear_spr:moveTo(126, 106)
    gear_spr:add()

    gear_anim_2 = gfx.animation.loop.new(100, gear_table)
    gear_spr_2 = gfx.sprite.new(gear_anim:image())
    gear_spr_2:moveTo(276, 106)
    gear_spr_2:add()

    local switch_img = gfx.image.new("images/switch")
    switch_spr = gfx.sprite.new(switch_img)
    switch_spr:moveTo(switch_default_pos.x, switch_default_pos.y)
    switch_spr:add()

    local label_img = gfx.image.new("images/label")
    label_spr = gfx.sprite.new(label_img)
    label_spr:moveTo(label_default_pos.x, label_default_pos.y)
    label_spr:setZIndex(-1)
    label_spr:add()

    label_animator = gfx.animator.new(0.5, 0, 0)
end

startup()

local rec_finished = false
local playing = false
local listening = false

local max_rate <const> = 4

local rate = 1.0
local startOffset = 0.0
local targetLength = 1.0

function reset()
    rate = 1.0
    startOffset = 0.0
    targetLength = 1.0
end

function record_callback(buffer)
    if not rec_finished then
        rec_finished = true
        reset()
    end
end

function playdate.BButtonDown()
    rec_finished = false
    playing = false
    if player:isPlaying() then
        player:stop()
    end
    listening = true
    snd.micinput.startListening()
end

function playdate.BButtonUp()
    if listening then
        snd.micinput.stopListening()
        listening = false
    end
    if not rec_finished then
        snd.micinput.stopRecording()
        player:setSample(sound_buffer)
        rec_finished = true
        reset()
    end
end

function playdate.AButtonDown()
    if not playdate.buttonIsPressed(playdate.kButtonB) then
        playing = not playing
        if not playing then
            if player:isPlaying() then
                player:stop()
            end
        end
    end
end

function playdate.upButtonDown()
    edit_mode -= 1
    if edit_mode < 1 then
        edit_mode = modeLength
    end
    label_animator = gfx.animator.new(500, label_animator:currentValue(), edit_mode * label_height - label_height, playdate.easingFunctions.inOutCubic)
end

function playdate.downButtonDown()
    edit_mode += 1
    if edit_mode > 3 then
        edit_mode = 1
    end
    label_animator = gfx.animator.new(500, label_animator:currentValue(), edit_mode * label_height - label_height, playdate.easingFunctions.inOutCubic)
end


function playdate.update()
    local length = player:getLength()
    local fps = snd.getSampleRate()
    local total_frames = length * fps

    if listening then
        if snd.micinput.getLevel() > 0.02 then
            snd.micinput.stopListening()
            listening = false
            snd.micinput.recordToSample(sound_buffer, record_callback)
        end
    end

    if playing then
        if not player:isPlaying() then
            player:setRate(rate)
            player:setOffset(length * startOffset)

            local start = total_frames * startOffset
            local remainingFrames = total_frames - start
            player:setPlayRange(0, start + (remainingFrames * targetLength))
            if rate > 0.01 or rate < -0.01 then
                player:play()
            end
        end
    end

    local change = playdate.getCrankChange()
    if edit_mode == modePlaybackSpeed then
        rate += change / 1440
        if rate < -max_rate then
            rate = -max_rate
        elseif rate > max_rate then
            rate = max_rate
        end

        local offset = 135 * (rate / max_rate)
        switch_spr:moveTo(switch_default_pos.x + offset, switch_default_pos.y)
    elseif edit_mode == modeStartOffset then
        if change ~= 0 then
            startOffset += change / 1440
            if startOffset > 1 then
                startOffset = 1
            elseif startOffset < 0 then
                startOffset = 0
            end

            if player:isPlaying() then
                player:stop()
            end

            player:setOffset(length * startOffset)
            player:play()
        end
        local offset = 270 * startOffset - 135
        switch_spr:moveTo(switch_default_pos.x + offset, switch_default_pos.y)
    elseif edit_mode == modeLength then
        if change ~= 0 then
            targetLength += change / 1440

            if targetLength < 0 then
                targetLength = 9
            elseif targetLength > 1 then
                targetLength = 1
            end

            if player:isPlaying() then
                player:stop()
            end

            local start = total_frames * startOffset
            local remainingFrames = total_frames - start
            player:setOffset(length * startOffset)
            player:setPlayRange(0, start + (remainingFrames * targetLength))
            player:play()
        end
        local offset = 270 * targetLength - 135
        switch_spr:moveTo(switch_default_pos.x + offset, switch_default_pos.y)
    end


    -- animation stuff

    if player:isPlaying() then
        gear_anim.paused = false
        gear_anim.delay = 10 * (max_rate / rate)

        gear_anim_2.paused = false
        gear_anim_2.delay = 10 * (max_rate / rate)
    else
        gear_anim.paused = true
        gear_anim_2.paused = true
    end

    gear_spr:setImage(gear_anim:image())
    gear_spr_2:setImage(gear_anim_2:image())

    label_spr:moveTo(label_default_pos.x, label_default_pos.y - label_animator:currentValue())
    gfx.sprite.update()
end
