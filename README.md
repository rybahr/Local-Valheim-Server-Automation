# Local-Valheim-Server-Automation

The idea behind this project was to find a way to fully automate local Valheim servers for my friends and I since I had a spare PC to run them on. These scripts do the following at a high level:
- serverStartYOURSERVERNAME
  1. Allows for fast configurations of the server details
  2. Prepares a logging solution
  3. Checks to see if the server is already running
  4. Clears the server log for a clean slate/readability
  5. Passes the required values to an embedded powershell instance
  6. starts the Valheim server
  7. waits for the join code to be populated by looking through the log for a matching string using regex
  8. strips the string found by regex to just the join code
  9. sends the join code with a custom message to discord using the webhook url
- severShutdown
  1. finds all running instances of the valheim_server.exe process
  2. sends the CTRL+C command
  3. waits for every instance to be confirmed as closed
  4. closes any leftover launcher windows

These files make the following assumptions:
  - You installed Valheim and it's Server tool locally and not on a drive other than C:
  - You already have portforwarding enabled for your server to be able to reach the internet
  - You are using a Windows machine to run these scripts on. They have not been tested on other OS
  - You have a Discord server you have Admin access to
  - You have a Valheim World/s already in place on the Windows machine that will be running these scripts
  - You are comfortable with Task Scheduler
  - create a Discord Webhook: https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks

Setup of Scripts
1. Download the ZIP file and extract it to C:\ on the machine that will be acting as the server
2. Rename the files replacing YOURSERVERNAME with the name of your Valheim world, as the files in C:\Users\*USER*\AppData\LocalLow\IronGate\Valheim\worlds_local show it
3. Edit the serverStartYOURSERVERNAME.bat file using your preffered editor
4. Replace the values in the CONFIGURATION section as necessary (YOURSERVERNAME, YOURPASSWORD, YOURDISCORDWEBHOOK) and save the file. No spaces in any of the values or the scripts will not work!

At this point you can use and Admin CMD to run the .bat file to test that it is working properly. Discord should populate the join code within a minute or two of the it being run.

The serverShutdown.bat when run will identify all active Valheim servers and shut them down gracefully. This does not remove the Join Code message that was sent to Discord. That will require manual deletion.

Setup Task Scheduler for Automation
Depending on your needs, you can use Task Scheduler to ensure that the server/s you want up stay up. 
1. Create a basic task as normal, naming it appropriately.
2. Under Triggers, determine what cycle works best for you and your group of players to have the servers be down for a couple of minutes. I stick with once a week during the work day when most of us are working.
2a. Make sure to schedule the serverShutdown.bat first before the serverStartYOURSERVERNAME.bat, leaving about five minutes between the shutdown and the startup tasks
3.Under Actions, enter cmd.exe as the program/script and the following for the argument:
  /c "C:\ValheimLogs\serverStartYOURSERVERNAME.bat >> C:\ValheimLogs\YOURSERVERNAMETaskSchedulerLog.txt 2>&1"
3a. The shutdownServer.bat does not need any arguments and can be selected using the Browse function

Explanation of the dual log files
The scripts utilize the two log files to aid in a few steps. Chiefly debugging but also it's what allows for the capture of the Join ID for the post to discord. The scripts should be self clearing, but if they do start to get too big they can be cleared manually when the servers aren't running.

Scripts are provided as is and have no warranty behind them!
