import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"
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

local switch_spr
local switch_default_pos = {
    x = 88 + 135,
    y = 150
}

function startup()
    sound_buffer = snd.sample.new(10, snd.kFormat16bitMono)
    player = snd.sampleplayer.new(sound_buffer)

    local bg_img = gfx.image.new("images/tape")
    bg_spr = gfx.sprite.new(bg_img)
    bg_spr:setCenter(0, 0)
    bg_spr:add()

    local gear_table = gfx.imagetable.new("images/gear")
    gear_anim = gfx.animation.loop.new(100, gear_table)
    gear_spr = gfx.sprite.new(gear_anim:image())
    gear_spr:setCenter(0, 0)
    gear_spr:moveTo(104, 84)
    gear_spr:add()

    gear_anim_2 = gfx.animation.loop.new(100, gear_table)
    gear_spr_2 = gfx.sprite.new(gear_anim:image())
    gear_spr_2:setCenter(0, 0)
    gear_spr_2:moveTo(255, 84)
    gear_spr_2:add()

    local switch_img = gfx.image.new("images/switch")
    switch_spr = gfx.sprite.new(switch_img)
    switch_spr:moveTo(switch_default_pos.x, switch_default_pos.y)
    switch_spr:add()
end

startup()

local rec_finished = false
local playing = false

function record_callback(buffer)
    rec_finished = true
end

function playdate.BButtonDown()
    rec_finished = false
    playing = false
    if player:isPlaying() then
        player:stop()
    end
    snd.micinput.recordToSample(sound_buffer, record_callback)
end

function playdate.BButtonUp()
    if not rec_finished then
        snd.micinput.stopRecording()
        player:setSample(sound_buffer)
        rec_finished = true
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


local max_rate <const> = 4
local rate = 1.0

function playdate.crankDocked()
    rate = 1.0
end

function playdate.update()
    if playing then
        if not player:isPlaying() then
            player:setRate(rate)
            if rate > 0.01 or rate < -0.001 then
                player:play()
            end
        end
    end

    local change = playdate.getCrankChange()
    rate += change / 1440
    if rate < -max_rate then
        rate = -max_rate
    elseif rate > max_rate then
        rate = max_rate
    end

    local offset = 135 * (rate / max_rate)
    switch_spr:moveTo(switch_default_pos.x + offset, switch_default_pos.y)

    if player:isPlaying() then
        gear_anim.paused = false
        gear_anim.delay = 50 * (max_rate / rate)

        gear_anim_2.paused = false
        gear_anim_2.delay = 50 * (max_rate / rate)
    else
        gear_anim.paused = true
        gear_anim_2.paused = true
    end

    gear_spr:setImage(gear_anim:image())
    gear_spr_2:setImage(gear_anim_2:image())
    gfx.sprite.update()
end
