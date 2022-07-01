local gfx <const> = playdate.graphics

local gear_table = gfx.imagetable.new(45 / 5)
local gear_img = gfx.image.new("images/gear")

local gear_i = 1
for i = 5,45,5 do
    gear_table:setImage(gear_i, gear_img:rotatedImage(i))
    gear_i += 1
end

local gear_anim = gfx.animation.loop.new(100, gear_table)
local switch_img = gfx.image.new("images/switch")
local label_img = gfx.image.new("images/label")

local label_height <const> = 17
local label_animator = gfx.animator.new(0.5, 0, 0)

local default_switch_offset = {
    x = 88 + 135,
    y = 150
}

local default_label_offset = {
    x = 57,
    y = 177
}

local gear1_offset = {
    x = 126,
    y = 106
}

local gear2_offset = {
    x = 276,
    y = 106
}

function moveTapeGFXTo(tape_gfx, x, y)
    tape_gfx.tape_spr:moveTo(x, y)
    tape_gfx.gear_spr1:moveTo(gear1_offset.x + x, gear1_offset.y + y)
    tape_gfx.gear_spr2:moveTo(gear2_offset.x + x, gear2_offset.y + y)

    tape_gfx.switch_offset.x = default_switch_offset.x + x
    tape_gfx.switch_offset.y = default_switch_offset.y + y

    tape_gfx.label_offset.x = default_label_offset.x + x
    tape_gfx.label_offset.y = default_label_offset.y + y
end

function makeTapeGFX(img_file)
    local tape_img = gfx.image.new(img_file)
    
    local tape_gfx = {
        tape_spr = gfx.sprite.new(tape_img),
        gear_spr1 = gfx.sprite.new(gear_anim:image()),
        gear_spr2 = gfx.sprite.new(gear_anim:image()),

        switch_spr = gfx.sprite.new(switch_img),
        label_spr = gfx.sprite.new(label_img),
        
        switch_offset = {x = 0, y = 0},
        label_offset = {x = 0, y = 0}
    }

    tape_gfx.tape_spr:setCenter(0, 0)
    tape_gfx.tape_spr:add()

    tape_gfx.gear_spr1:add()

    tape_gfx.gear_spr2:add()

    tape_gfx.switch_spr:add()

    tape_gfx.label_spr:add() 
    tape_gfx.label_spr:setZIndex(-1)

    moveTapeGFXTo(tape_gfx, 0, 0)

    return tape_gfx
end

function setTapeGFXRate(tape_gfx, rate, max_rate)
    local offset = 135 * (rate / max_rate)
    tape_gfx.switch_spr:moveTo(tape_gfx.switch_offset.x + offset, tape_gfx.switch_offset.y)

    gear_anim.delay = 10 * (max_rate / rate)
end

function setTapeGFXStartOffset(tape_gfx, startOffset)
    local offset = 270 * startOffset - 135
    tape_gfx.switch_spr:moveTo(tape_gfx.switch_offset.x + offset, tape_gfx.switch_offset.y)
end

function setTapeGFXTargetLength(tape_gfx, targetLength)
    local offset = 270 * targetLength - 135
    tape_gfx.switch_spr:moveTo(tape_gfx.switch_offset.x + offset, tape_gfx.switch_offset.y)
end

function setTapeGFXVolume(tape_gfx, volume)
    local offset = 270 * volume - 135
    tape_gfx.switch_spr:moveTo(tape_gfx.switch_offset.x + offset, tape_gfx.switch_offset.y)
end

function pauseTapeGFX(tape_gfx)
    gear_anim.paused = true
end

function unpauseTapeGFX(tape_gfx)
    gear_anim.paused = false
end

function setLabelIndex(i)
    label_animator = gfx.animator.new(500,
    label_animator:currentValue(),
    i * label_height - label_height,
    playdate.easingFunctions.inOutCubic)
end

function updateTapeGFX(tape_gfx)
    tape_gfx.gear_spr1:setImage(gear_anim:image())
    tape_gfx.gear_spr2:setImage(gear_anim:image())

    tape_gfx.label_spr:moveTo(tape_gfx.label_offset.x, tape_gfx.label_offset.y - label_animator:currentValue())
end
