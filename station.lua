station = {}

station.temp = nil
station.humi = nil
station.epoch = 0
station.gotReadings = false
station.lastNtpSync = 0
station.lastReading = 0

station.ctof = function(c)
    return c*1.8 + 32
end

station.wusend = function(temp, humidity)
    temp = station.ctof(temp)
    url = "/weatherstation/updateweatherstation.php?ID=" ..
    wu_id .. "&PASSWORD=" .. wu_pass .. "&dateutc=now&tempf=" .. temp .. "&humidity=" ..
    humidity .. "&action=updateraw"

    srv = net.createConnection(net.TCP, 0)
    srv:on("receive", function(sck, c) print(c) end)
    srv:connect(80,"weatherstation.wunderground.com")
    srv:on("connection", function(sck, c)
      sck:send("GET " .. url .." HTTP/1.1\r\nHost: 192.168.0.66\r\nConnection: keep-alive\r\nAccept: */*\r\n\r\n")
    end)
end

station.dhtRead = function()
    status, temp, humi, temp_dec, humi_dec = dht.read(pin)
	if status == dht.OK then
		station.temp = temp
		station.humi = humi
		station.gotReadings = true
		station.lastReading = rtctime.get()
    	station.wusend(station.temp, station.humi)
	elseif status == dht.ERROR_CHECKSUM then
--        lcd:put(lcd:locate(1,0), "DHT Checksum error.")
	elseif status == dht.ERROR_TIMEOUT then
--        lcd:put(lcd:locate(1,0), "DHT timed out." )
	end
end

-- check if daylight saving applies for given date
station.isDst = function(tm)
    is = false
    next_sunday = (tm.day - (tm.wday - 1) + 7)
    if tm.mon < 3 or tm.mon > 10 then
        is = true
    elseif tm.mon == 3 then
        if next_sunday > 31 then
            if tm.wday == 1 and tm.hour < 1 then
                is = true
            end
        else -- last sunday will occur
            is = true
        end
    elseif tm.mon == 10 then
        if next_sunday > 31 then
            if tm.wday == 1 then -- today is sunday
                if tm.hour >= 1 then -- after 3pm last sunday
                    is = true
                end
            else -- days after last sunday
                is = true
            end
        end
    end
    return is
end

station.drawScreen = function()
    tm = station.epoch2local(rtctime.get())
    tstr = string.format("%02d.%02d.      %02d:%02d:%02d", tm["day"], tm["mon"], tm["hour"], tm["min"], tm["sec"])
    lcd:put(lcd:locate(0,0), tstr)
	if station.gotReadings then
    	lcd:put(lcd:locate(1,0), "T:".. station.temp .. string.char(223) .. "C"
	.. " H:" .. station.humi .. "%")
	else
		lcd:put(lcd:locate(1,0), "--- not available ---")
	end
    ip = wifi.sta.getip()
    lcd:put(lcd:locate(3,0), ip)
end

station.ntpSync = function()
	if not station.syncing then
		station.syncing = true
 		sntp.sync('tak.cesnet.cz',
 		    function(sec,usec,server)
 				print('NTP sync ok!')
				if station then
		            station.lastNtpSync = station.epoch
					station.syncing = false
				end
 		    end,
 		    function()
 		        print('NTP sync failed!')
				if station then
					station.syncing = false
				end
 		end)
	end
end

station.epoch2local = function(epoch)
    tm = rtctime.epoch2cal(epoch)
    dst = station.isDst(tm)
    offset = 3600 * utc_offset
    if dst then
        offset = offset - 3600
    end
    return rtctime.epoch2cal(epoch + offset)
end

return station
