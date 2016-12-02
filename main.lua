config = require "config"
station = require "station"

config.open("config.txt")

station.config = config.value
-- deallocate config since it's not needed anymore
config = nil

telSrv = net.createServer(net.TCP, 180)
telSrv:listen(23, function(socket)
    telnet = nil
	if station then
		stationStop()
	    lcd:put(lcd:locate(1,0), "    Telnet mode   ")
		print("got telenet, heap: " .. node.heap())
		station = nil
	end
    if not telnet then
        telnet = require "telnet"
    end
	collectgarbage()
	print("got telenet, heap: " .. node.heap())
	print("connection")
    socket:on("reconnection", function(c, l)
		print("reconnection")
	end)
    socket:on("disconnection", function(c, l)
		node.restart()
	end)
    socket:on("receive", function(c, l)
        -- telnetCmd(l, function(str)
        --     c:send(str .. "esp> ")
		-- end)
	end)
--    socket:on("sent", function(c)
--    end)
end)

print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
wifi.sta.config("0xDEADC0DE", "8578mKs=D_I")
-- wifi.sta.config("Testlab", "vopyho2mruk")

local busid = 0  -- I2C Bus ID. Always zero
local sda= 2     -- GPIO2 pin mapping is 4
local scl= 1     -- GPIO0 pin mapping is 3

i2c.setup(busid,sda,scl,i2c.SLOW)

lcd = dofile("lcd1602.lua")()
lcd:put(lcd:locate(0, 5), "Hello, dvv!")
lcd:clear()
lcd:light(1)

pin = 3


--am2315 = require("am2315")
--am2315.init(sda, scl)

wu_id="IBRNO63"
wu_pass="54vqq8rr"
utc_offset = 2

-- epoch=1477788900
--
-- tmr.alarm(1, 30, 1, function()
--     rtctime.set(epoch)
--     tm = epoch2local(rtctime.get())
--     tstr = string.format("%02d.%02d - %02d:%02d:%02d", tm["day"], tm["mon"], tm["hour"], tm["min"], tm["sec"])
--     print(tstr)
--     epoch = epoch + 1
-- end)

tmr.alarm(1, 1000, 1, function()
	sec, usec = rtctime.get()
	if station.epoch - station.lastReading > 120 then
		station.dhtRead()
	end
	station.drawScreen()
	if wifi.sta.status() == wifi.STA_GOTIP and
		(station.epoch - station.lastNtpSync > 120 or
		 station.lastNtpSync == 0) then
		print("syncing")
		station.ntpSync()
	end
	sec, usec = rtctime.get()
	station.epoch = sec + 1
	tmr.interval(1, 1000 - usec/1000)
end)

station.dhtRead()
station.ntpSync()

function stationStop()
	tmr.stop(1)
	lcd:clear()
	station = nil
end

-- wifi.sta.eventMonReg(wifi.STA_IDLE, function() print("STATION_IDLE") end)
-- wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() print("STATION_CONNECTING") end)
-- wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() print("STATION_WRONG_PASSWORD") end)
-- wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() print("STATION_NO_AP_FOUND") end)
-- wifi.sta.eventMonReg(wifi.STA_FAIL, function() print("STATION_CONNECT_FAIL") end)
-- adc.force_init_mode(adc.INIT_ADC)
