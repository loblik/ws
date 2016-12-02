local config = {}

function config.open(fileName, options)
    config.file = fileName
    config.value = {}
    if not file.open(fileName) then
        return false
    end
    line = file.readline()
    while line do
        line = string.gsub(line, "%s+", "")
        match = string.gmatch(line, "[^=]+")
        key = match()
        value = match()
        if key and options then
            option = options[key]
            if not option then
                print("unknown option: " .. key)
            else
                if value then
                    if option["type"] == "number" then
                        value = tonumber(value)
                    end
                end
                if not value then
                    config.value[key] = option.default
                end
            end
        end
        line = file.readline()
    end
    file.close()
    return true
end

function config.set(key, value)
    config.value[key] = value
end

function config.get(key)
    return config.value[key]
end

function config.show()
    str = ''
    for k, v in pairs(config.value) do
        str = str .. k .. " = " .. v .. "\n";
    end
    return str
end

function config.write()
    if not config.file or not file.open(config.file, "w+") then
        return false
    end
    for k, v in pairs(config.value) do
        print("wl: " .. k)
        file.writeline(k .. "=" .. v)
    end
    file.flush()
    file.close()
    return true
end

-- Print AP list that is easier to read
function listap(t) -- (SSID : Authmode, RSSI, BSSID, Channel)
    str  = "SSID        " ..
           "BSSID                 " ..
           "RSSI  " ..
           "AUTHMODE  " ..
           "CHANNEL\n"
    for bssid,v in pairs(t) do
        local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
        str = str .. string.format("%-12s", ssid) ..
                     string.format("%-22s", bssid) ..
                     string.format("%-6s", rssi) ..
                     string.format("%-10s", authModePretty(authmode)) ..
                     channel .. "\n"
    end
    return str
end

return config
