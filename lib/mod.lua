local mod = require 'core/mods'

local loader = dofile('/home/we/dust/code/iiitoii/lib/loader.lua')

mod.hook.register("script_pre_init", "iiitoii init", function()
    loader.init()

    params:add_separator('iiitoii')
    loader.add_params()
end)

mod.hook.register("script_post_cleanup", "iiitoii cleanup", function()
    loader.cleanup()
end)
