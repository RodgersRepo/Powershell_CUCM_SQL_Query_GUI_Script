# Powershell CUCM SQL Query/Update GUI script 

This PowerShell script will send a SQL query or an update to CUCM over HTTPS. It uses the AXLAPI wsdl that you must first download from your version of CUCM. See [Installation](#Installation) section of this README. Toggle the slider to change from a query to an update. You will recieve a pop up warning when selecting 'update'.

You will need to alter the script variable `$global:cucmUrl` to equal the IP address or FQDN of your CUCM server. If your enterprise has a functioning PKI you will probably want to use the FQDN. You may also want to remove the `trust_all_policy` include line from the script. You only need this if you are using self signed certificates.

This script is slightly better than SSHing to your CUCM server and issuing the SQL CLI command, as it lets you save the SQL results table to a CSV on your local computer. For example the equivelent SQL query from the screen shot, but on the CUCM CLI.
```sh
admin: run sql select lastname, userid from enduser limit 2 
```
Once the query completes click `File->Save As`, to save the result.

The file `sqlExamples.txt` is just a collection of example SQL querys ripped from the internet.
### Screenshot

![Figure 1 - CUCM SQL Query screen shot](/./cucmsqlquery.png "PowerShell Script screenshot")

## Installation

Click on the `cucmsqlquery.ps1` link for the script above. When the PowerShell code page appears click the **Download Raw file** button top right. Copy the `include` folder to your computer. This script and the `include` folder must be in the same folder on your computer.

Download the `AXL Toolkit plugin` from your version of CUCM. This will also need to be unzipped and saved to the same folder as this script. You can access the toolkit by browsing to `Application->Plugin` on CUCM administration web page.

Once downloaded to your computer have a read of the script in your prefered editor. All the information for executing the script will be in the script synopsis.
The system this script was developed on was `Windows Server 2016`, the PowerShell version is `5.1.14393.206`.
Once installed open the script in your prefered text editor. Find each line that has the comment text `CHANGE FOR YOUR ENVIROMENT` in it. Alter these lines to match your enviroment.
## Usage

To execute. Save the ps1 file and include folder to a folder on your computer (along with the unzipped AXL toolkit), then from a powershell prompt in the same folder.
```sh
Run .\cucmsqlquery.ps1 
```

If your Windows enviroment permits, you could create a shortcut to the script. Paste the following line into the shortcut.
```sh
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\<PathToYourScripts>\cucmsqlquery.ps1"
```
Then just double click the shortcut like you are starting an application. Check the correct path to the  PowerShell executable on your system. 

## Known Problems
This script uses runspaces in an attempt to stop the GUI freezing when a long running SQL query is being executed. It can take up to minute to read the `AXLAPI.wsdl` file and then execute your query. It works fairly well, but if you press the `Stop` button mid query you still experience a momentary GUI freeze.

## Credits and references

#### [Certificate Include](https://github.com/CiscoDevNet/axl-powershell-samples/tree/main)
Thanks to GitHub user dstaudt for the certificate overide routine.
#### [Utilizing Runspaces for Responsive WPF GUI Applications](https://smsagent.blog/2015/09/07/powershell-tip-utilizing-runspaces-for-responsive-wpf-gui-applications/)
Thanks to Trevor Jones for the runspaces examples.

Check the comments within the script for more credits.

----

