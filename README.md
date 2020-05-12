
# Terraria-Discord-Bridge

A discord bot written in Lua to bridge the chat between a Terraria server and a discord channel.

> TODO: Add screenshots.

## How it works

The official dedicated Terraria server is started by the bot as a sub-process, which gives the bot access to it's input and output.

The input is done transparently by the bot (using Lua's `io.popen`), but due to some limitations in the standard Lua library, the server's output has to be written into a file.

When someone sends a message on the bridged discord channel, the bot sends the message to the Terraria players using the server's `say` command.

When a player send a message to the chat, the bot monitors the server's output and detects the messages, then sends them to the bridged discord channel.

## Bridge installation

The bridge depends on luvit, which can be installed by following the [official instructions](http://luvit.io/install.html)

Once that done, clone the bridge's repository locally

```bash
git clone https://github.com/RamiLego4Game/Terraria-Discord-Bridge.git
```

## Setting up the bridge

### Creating a bot application

### Creating the bridge channel webhook

### Setting up the Terraria server

### Configuring the bridge

Copy `configuration-template.json` into `configuration.json`.

## Running the bot

Run `luvit start_bot.lua` in your terminal.
