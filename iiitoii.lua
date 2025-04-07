-- iiitoii
--
-- E1: select an iii script
-- K2: mapped to arc button

-- lib/loader handles running an iii-like script in the sripts/ dir
local loader = include 'lib/loader'

function init()
    loader.init()

    params:add_separator('iiitoii')
    loader.add_params()

    params:read()
    params:bang()
end

function cleanup()
    params:write()
end

function enc(n, d)
    if n==1 then
        params:delta('iiitoii_script', d)
    end

    redraw()
end

function key(n, z)
    if n==2 then
        params:set('iiitoii_arc_key', z)
    end
end

function redraw()
    screen.clear()

    screen.aa(1)
    screen.level(4)
    screen.circle(10, 64-9, 4)
    screen.level(4 + (params:get('iiitoii_arc_key') * 8))
    screen.fill()

    screen.level(15)
    screen.move(64, 30)
    screen.font_face(10)
    screen.font_size(20)
    screen.text_center(params:string('iiitoii_script'))

    screen.update()
end
