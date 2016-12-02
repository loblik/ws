tmr.alarm(0,1000,0, function()
    print("Running startup")
    dofile("main.lua")
end)
