--- Terraria chat bridge to/from discord by Rami Sabbagh (RamiLego4Game)
-- V1.0.0

local json = require("json")

--Load the configuration
local config
do
    local file = assert(io.open("configuration.json"))
    local data = assert(file:read("*a"))
    file:close()

    config = json.decode(data)
end

--Clear the output file
do
    local file = assert(io.open(config.serverOutput, "w"))
    file:close()
end

--Prepare the server startup command
local serverCommand = string.format("bash -c \"%s -config %s > %s\"",
    config.serverExecutable, config.serverConfig, config.serverOutput
)

local input = assert(io.popen(serverCommand, "w"))
local output = assert(io.open(config.serverOutput, "r"))

local http = require("coro-http")
local timer = require("timer")
local discordia = require('discordia')
local client = discordia.Client()

local serverReady = false
local playersCount = 0

local function updateStatus()
    client:setGame({
        name = string.format("%d players online", playersCount),
        type = 3,
    })
end

local function sendMessage(content, name)
    local avatarURL = nil

    if config.players[name] then
        avatarURL = config.players[name]:getAvatarURL()
        name = config.players[name].name
    end

    local payload = {
        content = content,
        username = name,
        avatar_url = avatarURL
    }

    payload = json.encode(payload)

    http.request("POST", config.bridgeWebhook, {
        {"content-type", "application/json"},
        {"content-length", #payload}
    }, payload)
end

local function runTerrariaLoop()
    while true do
        if serverReady then
            for line in output:lines() do
                line = line:gsub("[\r\n]",""):gsub("^ :", "")
                if line:match("^<.->") then
                    local sender = line:match("^<.->"):sub(2,-2)
                    local content = line:gsub("^<.->%s+", "")

                    if #sender > 0 and #content > 0 and sender ~= "Server" then
                        print("Terraria -> Discord", sender, ":", content)
                        sendMessage(content, sender)
                    end
                elseif line:match("^%S+ has joined") then
                    playersCount = playersCount + 1
                    updateStatus()
                    pcall(sendMessage, "_joined the game._", line:match("^%S+"))
                elseif line:match("^%S+ has left") then
                    playersCount = playersCount - 1
                    updateStatus()
                    pcall(sendMessage, "_left the game._", line:match("^%S+"))
                end
            end
        end

        timer.sleep(1)
    end
end

client:on('ready', function()
    for gameName, user in pairs(config.players) do
        print("Requesting "..gameName.."'s user...")
        config.players[gameName] = client:getUser(user)
    end

    print("Waiting for the server to be ready...")
    client:setGame("loading world...")
    while output:read("*l") ~= ": " do end

    updateStatus()
    print("Terraria's bridge ready!")

    serverReady = true
    runTerrariaLoop()
end)

client:on('messageCreate', function(message)
    if message.channel.id == config.bridgeChannel then
        if serverReady and #message.content > 0 and not message.author.bot then
            print("Discord -> Terraria", message.author.name, ":", message.content)
            local content = message.content:gsub("\r","").."\n"

            for line in content:gmatch(".-\n") do
                input:write("say [")
                input:write(message.author.name)
                input:write("]: ")
                input:write(line)
            end

            input:flush()
        end
    elseif message.channel.type == 1 then --private
        local owner = false
        for _, id in pairs(config.owners) do
            if id == message.author.id then owner = true break end
        end

        if not owner then return end

        if message.content == "exit" then
            serverReady = false

            client:setGame("exitting...")
            input:write("exit\n")
            input:flush()

            input:close()
            output:close()

            message.channel:send("Exited server successfully ✅")

            client:setGame("goodbye")
            client:stop()
            os.exit(0)
        elseif message.content == "save" then
            serverReady = false
            client:setGame("saving world...")

            input:write("say Saving world...\n")
            input:flush()

            message.channel:send("Saving world ⚙")

            input:write("save\n")
            input:flush()

            while output:read("*l") ~= ": " do end

            input:write("say Saved successfully.\n")
            input:flush()
            serverReady = true

            updateStatus()
            message.channel:send("Saved successfully ✅")
        end
    end
end)

client:run('Bot '..config.token)