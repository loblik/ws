telnet = {}

local telnetCmdMap = {}

function telnetCmdAdd(cmd, subcmd, fnc)
    if telnetCmdMap[cmd] == nil then
        telnetCmdMap[cmd] = {}
    end
    telnetCmdMap[cmd][subcmd] = fnc
end

function authModePretty(modeNum)
    modeNum = tonumber(modeNum)
    if modeNum == wifi.WPA_PSK then
        str = "wpa"
    elseif modeNum == wifi.WPA2_PSK then
        str = "wpa2"
    elseif modeNum == wifi.WPA_WPA2_PSK then
        str = "wpa/wpa2"
    elseif modeNum == wifi.OPEN then
        str = "open"
    elseif modeNum == 5 then
        str = "wpa(eap)"
    else
        str = "?"
    end
    return str
end

telnetCmdAdd("cfg", "show", function(tokens, output)
    output(config.show())
end)

telnetCmdAdd("cfg", "set", function(line, output)
  print(line)
    print(string.gsub(line, "[^%s]+", ""))
    setting = tokens()
    if setting == nil then
        output("missing key\n")
        return
    end
    value = tokens()
    if value == nil then
        output("missing value\n")
        return
    end
    v = string.match(value, "'[^']+'")
    if v == nil then
        output("invalid value argument " .. value .. "\n")
        return
    end
    config.set(setting, v)
    output("")
end)

telnetCmdAdd("cfg", "help", function(tokens, output)
    output("cfg show\tshow current config\n")
end)

telnetCmdAdd("wifi", "scan", function(toknes, output)
    wifi.sta.getap(1, function(t)
            output(listap(t))
    end)
end)

telnetCmdAdd("wifi", "help", function(tokens, output)
    output("wifi scan\tshows available networks\n")
end)

telnet.cmd = function(line, output)

    if string.byte(line) == 0xff then
        output("Welcome to NodeMCU!\n")
    end

    print("line: " .. line)
    tokens = string.gmatch(line, "[^%s]+")
    cmd = tokens()

    if telnetCmdMap[cmd] == nil then
        output("unknown command, type help\n")
        return
    end

    subcmd = tokens()
    if telnetCmdMap[cmd][subcmd] == nil then
        output("unknown command, type " .. cmd .. " help\n")
        return
    end

    telnetCmdMap[cmd][subcmd](line, output)
end

return telnet
