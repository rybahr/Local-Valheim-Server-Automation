# Valheim Dedicated Server Automation

A collection of Windows batch and PowerShell scripts designed to automate the startup, shutdown, logging, and Discord join-code notification process for locally hosted Valheim dedicated servers.

## Overview

The idea behind this project was simple: I had a spare Windows PC and wanted a way to fully automate the local Valheim servers I host for my friends and me.

Rather than manually starting servers, waiting for them to initialize, finding the crossplay join code, and sharing it with everyone, these scripts handle the process automatically.

Combined with Windows Task Scheduler, they can also be used to periodically restart your Valheim servers without requiring someone to interact with the server PC.

## Features

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

This allows players to receive the current join code automatically whenever the server starts.

### `serverShutdown.bat`

The shutdown script is designed to gracefully stop all Valheim dedicated servers running on the machine.

It:

1. Finds all running instances of `valheim_server.exe`.
2. Sends `CTRL+C` to each server to initiate Valheim's normal shutdown process.
3. Waits for each server process to close.
4. Cleans up any remaining launcher Command Prompt windows.

Using a graceful shutdown instead of simply terminating `valheim_server.exe` helps ensure that the server has an opportunity to save its current state before closing.

---

# Requirements and Assumptions

These scripts currently make the following assumptions:

* You are running the scripts on **Windows**.
* Valheim and the **Valheim Dedicated Server** tool are installed locally.
* The Valheim Dedicated Server installation is on the **C:** drive.
* You already have one or more Valheim worlds available on the server PC.
* Your network and port-forwarding configuration is already set up as required for your server.
* You have access to a Discord server where you can create and manage webhooks.
* You are comfortable using Windows Task Scheduler if you want to automate server restarts.

> **Note:** These scripts were created and tested for Windows. Other operating systems are not currently supported or tested.

## Creating a Discord Webhook

A Discord webhook is required if you want the startup script to automatically post the server's join code.

Discord's instructions for creating a webhook can be found here:

[Discord — Intro to Webhooks](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)

Keep the webhook URL handy, as you will need to add it to the startup script configuration.

---

# Script Setup

## 1. Download the Scripts

For ease of use you can download the repository ZIP and extract the files onto the machine that will host the Valheim server. The individual script files are provided for code review. The template log files in the zip are empty .txt files and not provided outside of the zip file.

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

## 3. Rename the Startup Script

Rename:

```text
serverStartYOURSERVERNAME.bat
```

replacing `YOURSERVERNAME` with the name of the Valheim world/server you are configuring.

For example:

```text
serverStartMyWorld.bat
```

If you host multiple worlds, create and configure a startup script for each server.

## 4. Rename the Log Files

Two log files are provided for each server in the zip folder. Rename both files by replacing YOURSERVERNAME with the same server/world name used for the startup script. You can also manually create .txt files following the template as shown below.

Rename:

YOURSERVERNAMElog.txt
YOURSERVERNAMETaskSchedulerLog.txt

For example, if your world is named MyWorld, the files should be renamed to:

MyWorldlog.txt
MyWorldTaskSchedulerLog.txt

After renaming, the startup script and its associated logs should use the same server name:

serverStartMyWorld.bat
MyWorldlog.txt
MyWorldTaskSchedulerLog.txt

The two log files serve different purposes:

MyWorldlog.txt — Contains the output from the Valheim dedicated server. The startup script monitors this file to locate and extract the server's join code.
MyWorldTaskSchedulerLog.txt — Contains output from the startup automation itself when launched through Windows Task Scheduler. This is primarily used for troubleshooting startup and automation issues.

Important: Make sure you replace YOURSERVERNAME consistently across the startup script and both log filenames. The startup script expects these filenames to match its configured server name.

If you are configuring multiple servers, each server should have its own startup script and pair of log files.

For example:

C:\ValheimLogs\
├── serverStartServerOne.bat
├── ServerOnelog.txt
├── ServerOneTaskSchedulerLog.txt
│
├── serverStartServerTwo.bat
├── ServerTwolog.txt
├── ServerTwoTaskSchedulerLog.txt
│
└── serverShutdown.bat
5. Configure the Startup Script

Open the renamed startup .bat file in your preferred text editor and locate the CONFIGURATION section.

Replace the placeholder values as appropriate, including:

YOURSERVERNAME
YOURPASSWORD
YOURDISCORDWEBHOOK

Save the file when finished.

Important: Do not use spaces in these configuration values unless you have modified the scripts to support them. Spaces may cause the current scripts to fail or parse values incorrectly.

---

# Testing the Server

Before configuring Task Scheduler, test the scripts manually.

Open **Command Prompt as Administrator**, navigate to the script directory, and run:

```bat
serverStartYOURSERVERNAME.bat
```

The script should:

* Start the Valheim dedicated server.
* Begin writing the server log.
* Wait for Valheim to generate the join code.
* Extract the join code from the log.
* Send the join code to the configured Discord webhook.

Depending on the server and machine, it may take a minute or two for the join code to appear in Discord.

If the Discord message appears with the correct join code, the startup automation is working.

---

# Testing Server Shutdown

Run:

```bat
serverShutdown.bat
```

The script will locate active `valheim_server.exe` instances and attempt to shut each one down gracefully.

It will then wait for the server processes to close before cleaning up any remaining launcher windows.

> **Note:** Shutting down the server does **not** remove the previously posted join-code message from Discord. That message must currently be deleted manually if you no longer want it displayed.

---

# Automating Restarts with Windows Task Scheduler

Windows Task Scheduler can be used to periodically restart your Valheim servers.

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

Name the tasks clearly so it is easy to identify which server they control.

## 2. Configure the Schedule

Under **Triggers**, select whatever restart schedule works best for your group.

For example, I restart my servers once a week during the workday, when the servers are unlikely to have active players.

## 3. Schedule Shutdown Before Startup

Always schedule:

```text
serverShutdown.bat
```

before the startup scripts.

I recommend leaving approximately **five minutes** between the shutdown and startup tasks.

For example:

```text
12:00 PM - serverShutdown.bat
12:05 PM - serverStartServerOne.bat
12:05 PM - serverStartServerTwo.bat
```

This gives the servers enough time to finish shutting down and saving before they are started again.

## 4. Configure the Startup Task Action

For the startup task, set **Program/script** to:

```text
cmd.exe
```

Then use the following under **Add arguments**:

```bat
/c "C:\ValheimLogs\serverStartYOURSERVERNAME.bat >> C:\ValheimLogs\YOURSERVERNAMETaskSchedulerLog.txt 2>&1"
```

Replace `YOURSERVERNAME` with the appropriate server name.

This runs the startup script and redirects its console output into a Task Scheduler log file for troubleshooting.

## 5. Configure the Shutdown Task

The shutdown script does not require any additional arguments.

You can select:

```text
serverShutdown.bat
```

using Task Scheduler's **Browse** option.

---

# Log Files

The automation uses two different types of logs.

### Valheim Server Log

The Valheim server log contains the output generated by the dedicated server itself.

Among other things, this log is used by the startup script to detect the server's join-code message. Once the appropriate log entry appears, the script extracts the join code and posts it to Discord.

### Task Scheduler Log

When the startup script is launched through Task Scheduler using:

```bat
>> C:\ValheimLogs\YOURSERVERNAMETaskSchedulerLog.txt 2>&1
```

the batch script's standard output and error output are written to a separate log.

This is primarily useful for troubleshooting automated startup problems where the Command Prompt window may not be visible.

### Log Maintenance

The scripts perform their own log cleanup where necessary so that old startup information does not interfere with join-code detection.

If the log files become excessively large, they can also be manually cleared while the Valheim servers are stopped.

---

# Multiple Servers

The scripts can be used to manage multiple Valheim worlds from the same Windows machine.

Create a separate startup script for each server:

```text
serverStartServerOne.bat
serverStartServerTwo.bat
serverStartServerThree.bat
```

Each startup script can have its own:

* World/server name
* Server password
* Discord webhook
* Log file
* Server configuration
* Task Scheduler task

The shared:

```text
serverShutdown.bat
```

can be used to gracefully stop all currently running Valheim dedicated server instances.

---

# Troubleshooting

If the server starts but no join code appears in Discord, check the following:

* Confirm that the Valheim server successfully started.
* Check the Valheim server log for a generated join code.
* Verify that the Discord webhook URL is correct.
* Make sure the configured world/server name matches the intended server.
* Check the Task Scheduler log for script errors.
* Confirm that none of the configured values contain unsupported spaces.
* Run the startup script manually from an Administrator Command Prompt to determine whether the problem is specific to Task Scheduler.

If the script works manually but not through Task Scheduler, the Task Scheduler log should be the first place to check.

---

# Current Limitations

The current scripts have several intentional limitations:

* Windows only.
* Designed around Valheim/Valheim Dedicated Server being installed on the `C:` drive.
* Existing Valheim worlds must already be configured.
* Network and port-forwarding configuration is outside the scope of these scripts.
* Discord join-code messages are not automatically removed when a server shuts down.
* Paths and configuration assumptions may need to be modified for non-standard Valheim installations.

---

# Disclaimer

These scripts are provided **as-is**, without warranty or guarantee of any kind.

They were created primarily to automate my own locally hosted Valheim servers and are being shared in case they are useful to others.

Always make backups of your Valheim worlds before introducing new automation or making significant changes to your dedicated server configuration.
