note = {}
note[1] = {45,43,50}
note[2] = {55,64}
note[3] = {69,74,76,79}
note[4] = {86,83,81,72,79}

seq = {1,1,1,1}

c = {{},{},{},{}}

tickrate = 10

-- shape 1: cos (top = max, bottom = min)
-- shape 2: ramp (north = 0, CW increases)
function init()
	print("\n0000 cycles\n")
	local r = pset_read(1)
	if not r or r.script ~= "cycles" then 
		print("fresh pset")
		c[1] = {cc=10,ch=1,min=0,max=127,shape=1,f=0} 
		c[2] = {cc=11,ch=1,min=0,max=127,shape=1,f=0} 
		c[3] = {cc=12,ch=1,min=0,max=127,shape=1,f=0} 
		c[4] = {cc=13,ch=1,min=0,max=127,shape=1,f=0} 
		c.script = "cycles"
		pset_write(1,c)
	else
		c = r
	end
	for i=1,4 do arc_res(i,8) end
	m = metro.new(tick,tickrate)
	mr = metro.new(redraw,33)

    crow.ii.jf.mode(1)
    crow.ii.jf.run_mode(1)
    crow.ii.jf.run(5)
	for n=1,4 do
        crow.ii.jf.trigger(n, 1)
    end
end

function cleanup()
    crow.ii.jf.mode(0)
	for n=1,4 do
        crow.ii.jf.trigger(n, 0)
    end
end

pos = {0,0,0,0}
phase = {0,0,0,0}
speed = {0,0,0,0}
friction = 0.9
f = 1
out = {0,0,0,0}
mode = 1

SPEED, FRICTION, SHAPE, END = 1, 2, 3, 4
modetext = {"normal","friction","shape"}

function arc(n,d)
	if mode==SPEED then
		speed[n] = clamp(speed[n] + (d*tickrate/33),-64,64)
	elseif mode==FRICTION then
		c[n].shape = clamp(c[n].shape + d,1,2)
	elseif mode==SHAPE then
		c[n].f = clamp(c[n].f + d,0,15)
	end
end

function arc_key(z)
	if z == 1 then
		km = metro.new(key_timer,500,1)
	elseif km then
		--print("keyshort")
		metro.stop(km)
		mode = mode + 1
		if mode==END then mode=2 end
		ps("mode: %s",modetext[mode])
	else
		--print("friction off")
		f = 1
	end
end

function key_timer()
	--print("keylong!")
	metro.stop(km)
	km = nil
	if mode ~= 1 then
		mode = 1 
		pset_write(1,c)
	end
	f = friction
end

function redraw()
	for n=1,4 do
		arc_led_all(n,0)
	end
		
	if mode==SPEED then
		for n=1,4 do
            for m=1,#note[n] do arc_led(n,32+m*2,1) end
		    arc_led_rel(n,32+seq[n]*2,9)

			point(n,pos[n])
		end
	elseif mode==SHAPE then
		for n=1,4 do
			if c[n].shape == 1 then
				arc_led(n,33,15)
				arc_led(n,32,10)
				arc_led(n,34,10)
				arc_led(n,31,5)
				arc_led(n,35,5)
				arc_led(n,30,1)
				arc_led(n,36,1)
			else
				for i=1,7 do arc_led(n,29+i,i*2-1) end
			end
		end
	elseif mode==FRICTION then
		for n=1,4 do
			for i=1,16 do
				arc_led(n,(56+i)%64+1,1)
				arc_led(n,(57+c[n].f)%64+1,15)
			end
		end
	end
	arc_refresh()
end

-- draw point 1-1024
function point(n,y)
	x = math.floor(y)
	local c = x >> 4
	arc_led(n,c%64+1,15)
	arc_led(n,(c+1)%64+1,x%16)
	arc_led(n,(c+63)%64+1,15-(x%16))
end

function point2(n,x)
	local xx = math.floor(linlin(0,1023,1,768,x)) + 128 + 512
	local c = xx >> 4
	arc_led_rel(n,c%64+1,15-(xx%16))
	arc_led_rel(n,(c+1)%64+1,(xx%16))
end

function tick()
	for n=1,4 do
		pos[n] = pos[n] + speed[n]
		speed[n] = speed[n] * (f - (c[n].f/50))
		if c[n].shape == 1 then phase[n] = (math.cos((pos[n]%1024)/1024*math.pi*2)+1)/2
		else phase[n] = (pos[n]%1024)/1024 end
		local now = 7 - (phase[n]*7)
        out[n] = now

        iiitoii.crow_volts(n, now)
        
        local trig = false
		if pos[n] < 0 then
			seq[n] = ((seq[n] - 2) % #note[n]) + 1
            trig = true
		elseif pos[n] > 1023 then
			seq[n] = (seq[n] % #note[n]) + 1
            trig = true
		end

        if trig then
            crow.ii.jf.pitch(n, (note[n][seq[n]]-48)/12)

			pos[n] = pos[n] % 1024
        end
	end
end

init()
