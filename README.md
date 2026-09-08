# Valheim Dedicated Server Automation

A collection of Windows batch and PowerShell scripts designed to automate the startup, shutdown, logging, and Discord join-code notification process for locally hosted Valheim dedicated servers.

## Overview

The idea behind this project was simple: I had a spare Windows PC and wanted a way to fully automate the local Valheim servers I host for my friends and me.

Rather than manually starting servers, waiting for them to initialize, finding the crossplay join code, and sharing it with everyone, these scripts handle the process automatically.

For basic use, the scripts provide the following workflow:

```text
Start Server -> Detect Join Code -> Post Join Code to Discord -> Graceful Shutdown
```

Combined with Windows Task Scheduler, they can also periodically restart your servers without requiring someone to interact with the server PC:

```text
Scheduled Shutdown -> Wait -> Restart Servers -> Post New Join Codes
```

Task Scheduler is optional and is only required if you want to automate server restarts.

## How This Differs from the Standard Valheim Startup Script

Valheim Dedicated Server includes the standard `start_headless_server.bat` provided by Iron Gate. **This project does not use or modify that script.**

Instead, `serverStartYOURSERVERNAME.bat` launches `valheim_server.exe` directly. This gives the automation control over the complete startup process, including server-specific logging, join-code detection, Discord notifications, and integration with Windows Task Scheduler.

You do not need to configure `start_headless_server.bat` when using these scripts. All server-specific settings should instead be configured in the `CONFIGURATION` section of `serverStartYOURSERVERNAME.bat`.

> **Important:** Settings from an existing `start_headless_server.bat` are not automatically inherited. Make sure the corresponding server name, world, password, ports, and other required settings are configured in the startup script.

---

# Features

### `serverStartYOURSERVERNAME.bat`

The startup script handles the complete server startup process:

1. Provides a configuration section for quickly changing server-specific settings.
2. Prepares the required logging.
3. Checks whether the specified Valheim server is already running.
4. Clears the previous server log to provide a clean startup log.
5. Passes the required configuration values to an embedded PowerShell instance.
6. Starts the Valheim dedicated server.
7. Monitors the server log for the Valheim join-code message.
8. Uses a regular expression to extract the join code from the matching log entry.
9. Sends the join code, along with a customizable message, to Discord using a webhook.

This allows players to automatically receive the current join code whenever the server starts.

### `serverShutdown.bat`

The shutdown script gracefully stops all Valheim dedicated servers running on the machine:

1. Finds all running instances of `valheim_server.exe`.
2. Sends `CTRL+C` to each server to initiate Valheim's normal shutdown process.
3. Waits for each server process to close.
4. Cleans up any remaining launcher Command Prompt windows.

Using a graceful shutdown instead of simply terminating `valheim_server.exe` gives each server an opportunity to save its current state before closing.

> **Note:** `serverShutdown.bat` shuts down **all** active Valheim dedicated server instances on the machine rather than targeting an individual world.

---

# Requirements & Limitations

These scripts currently assume:

* You are running the scripts on **Windows**.
* Valheim and the **Valheim Dedicated Server** tool are installed locally.
* The Valheim Dedicated Server installation is on the **C:** drive.
* You already have one or more Valheim worlds configured on the server PC.
* Your network and port-forwarding configuration is already set up as required for your server.
* You have access to a Discord server where you can create and manage webhooks. The current version of the script requires the webhook present to run properly. A future separate version of the script will be uploaded that does not have this functionality.
* You are comfortable using Windows Task Scheduler if you want to automate server restarts.

The following are currently outside the scope of the project:

* Operating systems other than Windows.
* Automatic network or port-forwarding configuration.
* Automatic creation of Valheim worlds.
* Automatic removal of old join-code messages from Discord.
* Non-standard installation paths without manually modifying the scripts.

> **Note:** These scripts were created and tested on Windows. Other operating systems are not currently supported or tested.

## Creating a Discord Webhook

A Discord webhook is required if you want the startup script to automatically post the server's join code.

Discord's instructions for creating a webhook can be found here:

[Discord — Intro to Webhooks](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)

Keep the webhook URL handy, as you will need to add it to the startup script configuration.

> **Security:** Your Discord webhook URL should be treated like a password. Do not publish a configured copy of your startup script containing your real webhook URL to a public GitHub repository.

---

# Script Setup

## 1. Download the Scripts

Download or clone the repository onto the machine that will host the Valheim server.

The repository includes the startup and shutdown scripts along with two empty `.txt` log-file templates that will be renamed for each server.

The examples in this project assume the scripts and logs are located under:

```text
C:\ValheimLogs\
```

If you use another location, update the paths in the scripts and Task Scheduler configuration accordingly.

## 2. Determine Your Valheim World Name

Your locally stored Valheim worlds can normally be found at:

```text
C:\Users\<USER>\AppData\LocalLow\IronGate\Valheim\worlds_local\
```

Determine the exact name of the world you want the script to start.

You will use this name to replace `YOURSERVERNAME` throughout the setup process.

## 3. Rename the Startup Script

Rename:

```text
serverStartYOURSERVERNAME.bat
```

replacing `YOURSERVERNAME` with the name of the Valheim world/server you are configuring.

For example, a world named `MyWorld` would use:

```text
serverStartMyWorld.bat
```

If you host multiple worlds, create and configure a separate startup script for each server.

## 4. Rename the Log Files

Two empty `.txt` log files are included in the repository. Rename both by replacing `YOURSERVERNAME` with the same name used for the startup script:

```text
YOURSERVERNAMElog.txt
YOURSERVERNAMETaskSchedulerLog.txt
```

For example, a server named `MyWorld` would use:

```text
serverStartMyWorld.bat
MyWorldlog.txt
MyWorldTaskSchedulerLog.txt
```

If you are configuring multiple servers, create a copy of the startup script and both log files for each server.

For example:

```text
C:\ValheimLogs\

serverStartServerOne.bat
ServerOnelog.txt
ServerOneTaskSchedulerLog.txt

serverStartServerTwo.bat
ServerTwolog.txt
ServerTwoTaskSchedulerLog.txt

serverShutdown.bat
```

`serverShutdown.bat` is shared between the servers and does not need a separate copy for each one.

> **Important:** Make sure `YOURSERVERNAME` is replaced consistently in the startup script and both log filenames. The startup script expects these names to match.

See [Logging & Troubleshooting](#logging--troubleshooting) for more information about the two log files.

## 5. Configure the Startup Script

Open the renamed `.bat` file in your preferred text editor and locate the `CONFIGURATION` section.

Replace the placeholder values as appropriate:

```text
YOURSERVERNAME
YOURPASSWORD
YOURDISCORDWEBHOOK
```

For example:

```text
YOURSERVERNAME -> MyWorld
YOURPASSWORD -> MyServerPassword
YOURDISCORDWEBHOOK -> Your Discord webhook URL
```
> ** Important:** An eight character minimum password is required at this point for the server and the PlayFab backend to work properly.

Save the file when finished.

> **Important:** Do not use spaces in these configuration values unless you have modified the scripts to support them. Spaces may cause the current scripts to fail or parse values incorrectly.

---

# Testing the Scripts

Before configuring Windows Task Scheduler, test both scripts manually.

## Startup Test

Open **Command Prompt as Administrator**, navigate to the script directory, and run:

```bat
serverStartYOURSERVERNAME.bat
```

using the filename you created during setup.

The script should:

* Start the Valheim dedicated server.
* Begin writing the Valheim server log.
* Wait for Valheim to generate the join code.
* Extract the join code from the log.
* Send the join code to the configured Discord webhook.

Depending on the server and machine, it may take a minute or two for the join code to appear in Discord.

If the Discord message appears with the correct join code, the startup automation is working.

## Shutdown Test

Run in Admin Command Prompt:

```bat
serverShutdown.bat
```

The script should locate all active `valheim_server.exe` instances and begin shutting them down gracefully.

It will wait for the server processes to close before cleaning up any remaining launcher windows.

> **Note:** Shutting down the server does **not** remove previously posted join-code messages from Discord. Those messages must currently be deleted manually if you no longer want them displayed.

---

# Automating Restarts with Windows Task Scheduler

Once the scripts have been successfully tested, Windows Task Scheduler can optionally be used to automate periodic server restarts.

This is useful for keeping long-running servers fresh and ensuring they automatically return after a scheduled shutdown.

## 1. Create the Tasks

Create separate scheduled tasks for:

```text
serverShutdown.bat
```

and each:

```text
serverStartYOURSERVERNAME.bat
```

If you run multiple Valheim servers, each server should have its own startup task.

Name the tasks clearly so it is easy to identify which server they control.

## 2. Configure the Schedule

Under **Triggers**, select whatever restart schedule works best for your group.

For example, I restart my servers once a week during the workday, when the servers are unlikely to have active players.

## 3. Schedule Shutdown Before Startup

Always schedule `serverShutdown.bat` before the startup scripts.

I recommend leaving approximately **five minutes** between the shutdown and startup tasks.

For example:

```text
12:00 PM - serverShutdown.bat
12:05 PM - serverStartServerOne.bat
12:05 PM - serverStartServerTwo.bat
```

This gives the servers time to finish shutting down and saving before they are started again.

## 4. Configure the Startup Task Action

For each startup task, set **Program/script** to:

```text
cmd.exe
```

Then use the following under **Add arguments**:

```bat
/c "C:\ValheimLogs\serverStartYOURSERVERNAME.bat >> C:\ValheimLogs\YOURSERVERNAMETaskSchedulerLog.txt 2>&1"
```

Replace both instances of `YOURSERVERNAME` with the appropriate server name.

For example:

```bat
/c "C:\ValheimLogs\serverStartMyWorld.bat >> C:\ValheimLogs\MyWorldTaskSchedulerLog.txt 2>&1"
```

This launches the startup script and redirects its console output and errors to the server's Task Scheduler log for troubleshooting.

## 5. Configure the Shutdown Task

The shutdown script does not require any additional arguments.

Select:

```text
serverShutdown.bat
```

using Task Scheduler's **Browse** option.

Make sure the shutdown task is scheduled to run before any of the startup tasks.

---

# Logging & Troubleshooting

The automation uses two different log files for each server.

### Valheim Server Log

```text
YOURSERVERNAMElog.txt
```

This contains output generated by the Valheim dedicated server itself.

The startup script monitors this file during startup for the message containing the server's join code. Once found, the script extracts the join code and posts it to Discord.

The server log is cleared when the startup script begins so that old join-code entries do not interfere with detection.

### Task Scheduler Log

```text
YOURSERVERNAMETaskSchedulerLog.txt
```

This captures the startup script's standard output and error output when the script is launched through Task Scheduler.

It is primarily intended for troubleshooting automated startup problems where the Command Prompt window may not be visible.

### Troubleshooting

If the server starts but no join code appears in Discord:

* Confirm that the Valheim server successfully started.
* Check `YOURSERVERNAMElog.txt` for a generated join code.
* Verify that the Discord webhook URL is correct.
* Make sure the configured world/server name matches the intended server.
* Confirm that the startup script and log filenames all use the same server name.
* Confirm that none of the configured values contain unsupported spaces.
* Run the startup script manually from an Administrator Command Prompt.

If the script works manually but fails when launched through Task Scheduler, check:

```text
YOURSERVERNAMETaskSchedulerLog.txt
```

This should contain the startup script's console output and any errors generated during the scheduled run.

### Log Maintenance

The scripts perform their own log cleanup where necessary to prevent old startup information from interfering with join-code detection.

If the log files become excessively large, they can also be manually cleared while the Valheim servers are stopped.

---

# Disclaimer

These scripts are provided **as-is**, without warranty or guarantee of any kind.

They were created primarily to automate my own locally hosted Valheim servers and are being shared in case they are useful to others.

Always make backups of your Valheim worlds before introducing new automation or making significant changes to your dedicated server configuration.