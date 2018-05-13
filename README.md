# mimiwin.sh
Post-exploitation wrapper to remotely execute Invoke-Mimikatz, parse the output on the fly and get clear-text credentials to make real dictionaries for password cracking.

`./mimiwin.sh -i <ip> -u <user> -p <password> -d <domain>`

![alt text](https://github.com/hecky/mimiwin.sh/raw/master/mimiwin_example.png "mimiwin.sh")

---
|Argument|Detail|
|:------:|------|
|-i|Ip address of the targert|
|-u|Username to authenticate|
|-p|Password to authenticate|
|-d|Domain to authenticate or `.` , `workgroup` for local authentication|

---
### What does this tool do?
1. Detect if there are active users with `qwinsta` command.
2. If there are active users, then gets arch of the windows system.
3. Depending of the arch `32 bits` or `64 bits` it detects `sysnative`,`system32` or `syswow64` folder where powershell is installed.
4. Launchs winexe command to call the absolute path of powershell and execute `Invoke-Mimikatz.ps1` script that it's defined on `URL` variable.
5. Parses the output of mimikatz showing only the users and passwords and the whole output goes to a log dump file.


### Why mimiwin.sh?

Fair question, we can do the same with `metasploit` (and `kiwi` module on `meterpreter`) or `CrackMapExec` (with `-M mimikatz` module), so why '*reinvent the wheel*'.

* First of all I'm fan of shell scripting.
* I hate dependencies and here we only need 1 program (we only need winexe or wmiexec,etc...). If you can install cme or msf you can easily install winexe instead.
* My benchmark tests showed me that this is somehow faster than CME.
* It's easily modifiable so if you don't have smb access to launch psexec,winexe you can switch to WMI.
* And obviously this script it's just some few lines of code that you can easily copy&paste instead of having to have internet access to install dependencies or update the package manager.
* At the end it's just matter of flavors :)


### Notes
* It uses winexe by default to execute commands (but it can be changed to anything you want [winexe,wmiexec,pth-winexe,etc...])
  * If you change the program to execute commands be aware to change `Credentials` var format.
* `URL` var specifies the location of Invoke-Mimikatz.ps1 script
* `Invoke` var specifies powershell options trying to take care for bypassing some common detection signatures.
* You can modify the script to launch any other powershell script but be aware of the `parse` function that was created to parse mimikatz output.


---
## Real Scenario

I created this tool only thinking and for a specific case. I got Domain Admin on a pentest for a big company, there were thousands of domain users and once I extracted all domain users' hashes I tried to crack them. How? maybe dictionary attack, BruteForce, masks, etc...

On this case for example I used rockyou.txt for a dictionary attack and I got `16` cracked passwords. Once I ran `mimiwin.sh` on the local subnet with Domain Admin credentials I collected several real clear-text passwords and with this new dictionary that was much more smaller than rockyou.txt I got cracked 130 credentials.

This tools is meant to be used to grab clear-text credentials from memory to create real dictionaries on the post-exploitation phase.
