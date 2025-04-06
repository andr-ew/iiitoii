-- iiitoii

-- lib/loader handles running an iii-like script in the sripts/ dir
local loader = include 'lib/loader'

function init()
    loader.init()
    loader.add_params()

    params:read()
    params:bang()
end

function cleanup()
    params:write()
end
