--class to load & run iii scripts from the scripts/ folder
local loader = {
    path = '',
    name = ''
}

--this table will become the new global environment for each script using some lua magic
--  this means that any time a global variable is envoked in an iii script, 
--  lua will look for it in this table
local iii_env = {}

--NOTE: this could maybe break in weird cases like alt operating system (? fates)
local data_path = '/home/we/dust/data/iiitoii/'
local lib_path = '/home/we/dust/code/iiitoii/lib/'
local script_path = lib_path..'scripts/'

-- loader vars
local a = false
local arc_key = function() end
local iii_cleanup = function() end
local script_names = { 'none' }
local script_paths = { nil }

-- a few private vars as part of the iii->norns adapter layer
local metro_instances = {}
local arc_res = { 1, 1, 1, 1 }
local arc_led_levels = {}

function loader.init()
    local paths = util.scandir(script_path)
    for i,path in ipairs(paths) do
        script_paths[i + 1] = path
        script_names[i + 1] = string.gsub(path, '.lua', '')
    end
end

function loader.cleanup()
    loader.clearscript()
end

function loader.loadscript(path, name)
    if path then
        if not a then a = arc.connect() end

        loader.path = path
        loader.name = name

        local script = loadfile(script_path..path, nil, iii_env)
        script()
        
        a.delta = function(ring, delta) iii_env.arc(ring, delta/arc_res[ring]) end
        arc_key = iii_env.arc_key
        iii_cleanup = iii_env.cleanup

        a.key = function(n, z) 
            if n==1 then params:set('iiitoii_arc_key', z) end
        end
    end
end

function loader.add_params()
    params:add{
        id = 'iiitoii_arc_key', name = 'arc key', type = 'binary', behavior = 'momentary',
        action = function(v) arc_key(v) end
    }
    params:add{
        id = 'iiitoii_script', name = 'script', type = 'option', options = script_names,
        action = function(v)
            loader.clearscript()
            loader.loadscript(script_paths[v], script_names[v])
        end
    }
end
loader.params_count = 2

function loader.clearscript()
    if iii_cleanup then iii_cleanup() end

    for k,m in pairs(metro_instances) do
        m:stop()
        metro_instances[k] = nil
    end
        
    for i = 1,4 do
        arc_led_levels[i] = {}
        for ii = 1,64 do arc_led_levels[i][ii] = 0 end
    end

    if a then
        a:all(0)
        a:refresh()
    end
end

-- utility class for talking to crow
local iiitoii = {}
do
    -- we make an abstraction around crow voltages so that iiitoii can manage delegation
    --  between the main crow and an ii-connected crow, w/o having to add that logic
    --  to every script
    iiitoii.crow_volts = function(output, volts)
        --TODO: support ii-connected crow

        crow.output[output].volts = volts
    end
    iiitoii.crow_slew = function(output, t)
        --TODO: support ii-connected crow

        crow.output[output].slew = t
    end
    iiitoii.crow_shape = function(output, v)
        --TODO: support ii-connected crow

        crow.output[output].shape = v
    end

    --with any other ii destination, we're not worried about this, so scripts can just 
    --  interact with the device directly, i.e.: iiitoii.ii.<device>.<do_thing()>
    -- iiitoii.ii = crow.ii
end

--iii -> norns api adapter layer. this is incomplete !
do
    local e = iii_env
    
    --well typing all this makes make think I should just set the env metatable to _G but
    --  i'll push forward for now I guess
    e.print = print
    e.dofile = dofile
    e.error = error
    e.getmetatable = getmetatable
    e.ipairs = ipairs
    e.load = load
    e.loadfile = loadfile
    e.next = next
    e.pairs = pairs
    e.pcall = pcall
    e.print = print
    e.rawequal = rawequal
    e.rawget = rawget
    e.rawlen = rawlen
    e.rawset = rawset
    e.require = require
    e.select = select
    e.setmetatable = setmetatable
    e.tonumber = tonumber
    e.tostring = tostring
    e.type = type
    e.warn = warn
    e.xpcall = xpcall
    e.math = math
    e.table = table
    e.string = string
    e.coroutine = coroutine

    e.iiitoii = iiitoii
    e.crow = crow

    e.metro = {}
    e.metro.new = function(callback, time_ms, count)
        local m = metro.init(callback, time_ms / 1000, count)
        m:start()
        -- tab.insert(metro_instances, m)
        metro_instances[m.props.id] = m
        return m
    end
    e.metro.stop = function(m)
        m:stop()
        metro_instances[m.props.id] = nil
    end
    --NOTE: i'm not recreating metro.slew just yet - in many cases we can use crow_slew

    e.pset_write = function(i, data)
        local name = loader.name..'-'..string.format("%02d", i)
        local fname = data_path..name..'.data'
        data.script = name
        
        local err = tab.save(data, fname)

        if err then print('ERROR pset action write: '..err) end
    end
    e.pset_read = function(i)
        local name = loader.name..'-'..string.format("%02d", i)
        local fname = data_path..name..'.data'
            
        local data, err = tab.load(fname)
        
        if err then print('ERROR pset action read: '..err) 
            return {}
        else
            return data
        end
    end

    e.clamp = util.clamp
    e.arc_res = function(ring, div) arc_res[ring] = div end
    e.arc_led = function(ring, led, level) 
        a:led(ring, led//1, level//1) 
        arc_led_levels[ring][led] = level
    end
    e.arc_led_rel = function(ring, led, level, level_min, level_max) 
        level_min, level_max = 0, 16
        local new_l = util.clamp(arc_led_levels[ring][led] + level, level_min, level_max)
        arc_led_levels[ring][led] = new_l

        a:led(ring, led//1, new_l//1)
    end
    e.arc_led_all = function(ring, level)
        for ii = 1,64 do arc_led_levels[ring][ii] = level end
        --does this work ?
        a:segment(ring, 1, 64, level)
    end
    e.arc_refresh = function()
        a:refresh()
    end

    --TODO
    e.get_time = function() end

    e.ps = function(...) print(string.format(...)) end
    e.pt = tab.print
    e.clamp= util.clamp
    e.round = util.round
    e.linlin = util.linlin
    e.wrap = util.wrap
end

return loader
