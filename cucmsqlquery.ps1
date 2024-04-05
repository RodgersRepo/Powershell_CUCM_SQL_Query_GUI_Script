<#
.SYNOPSIS
  Name: cucmsqlquery.ps1
  Will send a SQL query to the CUCM Administrative XML service (AXL)
  via HTTPS. The results table can be exported as a CSV file.
  Before you begin download and save the WSDL file from CUCM to the same
  folder where this script is saved. From CUCM admin navigate to.
  Application\Plugin. Click the Downlod link next to Cisco AXL toolkit.
  Press the Next button to enter your CUCM credentials. When the form
  loads type your SQL query in the top text box then press GO.
  Table names for your querys can be found here.

  https://d1nmyq4gcgsfi5.cloudfront.net/media/UCM-DD-11-0-1/datadictionary.11.0.1.html

  GUI elements created using
  XAML and windows presentation framework (wpf).
 
.DESCRIPTION
  Takes input from a GUI form, outputs SQL query result.
 
.NOTES
Copyright (C) 2024  Rodge Industries 2000
 
     This program is free software: you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation, version 4.
 
     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.
 
     To view the GNU General Public License, see <http://www.gnu.org/licenses/>.

    Release Date: 27/02/2024
    Last Updated:      
   
    Change comments:
    Initial realease V1 - RITT
    Now does SQL update V1.1 - RITT 05/04/2024    
   
  Author: RodgeIndustries2000 (RITT)
       
.EXAMPLE
  Run .\cucmsqlquery.ps1 <no arguments needed>
  Or create shortcut to:
  "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\<PathToYourScripts>\cucmsqlquery.ps1"
  Then just double click the shortcut like you are starting an application.

#>

#----------------[ Declarations ]-----------------------------------------------------#

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"                                     # What to do if an unrecovable error occures
$global:scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path  # This scripts path
$global:scriptName = $MyInvocation.MyCommand.Name                   # This scripts name
$global:myCreds = ""                                                # Variable to store encoded user/password
$global:cucmUrl = "https://10.10.1.4:8443/axl/"                     # Variable to store CUCM AXL url. CHANGE FOR YOUR ENVIROMENT
$syncHashTable = [Hashtable]::Synchronized(@{ })                    # Syncronised hash table object for talking accross runspaces.
                                                                    # Multiple threads can safely and efficiently add or remove
                                                                    # items from this type of hash table
                                                                    # This hash tables main use is to store node names from the XAML below
                                                                    # hash tables are key/value stored arrays, each      
                                                                    # value in the array has a key. Not Case Senstive
$syncHashTable.asyncObject = $null                                  # Assign the method asyncObject to $syncHashTable object. Will
                                                                    # use this later to check the state of any runspaces


Add-Type -AssemblyName presentationframework, presentationcore      # Add these assemblys
# Import dotNET class to accept server certs but dont validate
#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
# I think a better way than the above is to include dot net core class
# below. Thanks to dstaudt for this. see
# https://github.com/CiscoDevNet/axl-powershell-samples/tree/main
# You probably wont need this include if you have a working PKI in your enterprise
# if you remove the following include update the variable $global:cucmUrl above
# for the FQDN of your CUCM server, not the IP address.
. $global:scriptPath\include\trust_all_policy.ps1 

# Negotiate TLS version start at 1.1 up to 1.2
[System.Net.ServicePointManager]::SecurityProtocol = 'Tls11, Tls12'

######################################################################################
#       Here-String with the eXAppMarkupLang (XAML) needed to display the GUI        #
######################################################################################

# A here-string of type xml
[xml]$xaml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Name="queryMainAppGUI"
        Title="SQL Query CUCM AXL database - Version 1.1" Height="900" Width="1000"
        FontSize="17" FontFamily="Segoe UI">

   <Window.Resources> <!--Match name with the root element in this case Window-->
        <!--Setting default styling for all buttons-->  
        <Style TargetType="Button">
         <Setter Property="Width" Value="143" />
         <Setter Property="Height" Value="32" />
         <Setter Property="Margin" Value="10" />
         <Setter Property="FontSize" Value="18" />
         <Setter Property="Background" Value="#FFB8B8B8" />
        </Style>
        <Style TargetType="TextBox">
         <Setter Property="Background" Value="#FFB8B8B8" />
         <Setter Property="Height" Value="32" />
        </Style>
        <Style TargetType="ComboBox">
         <Setter Property="Background" Value="#FFB8B8B8" />
         <Setter Property="Height" Value="32" />
        </Style>
        <Style TargetType="PasswordBox">
         <Setter Property="Background" Value="#FFB8B8B8" />
         <Setter Property="Height" Value="32" />
        </Style>
        <!-- Toggle button from https://stackoverflow.com/questions/74770662/powershell-xaml-ios-style-on-off-button -->
        <Style TargetType="ToggleButton">
	     <Setter Property="Template">
		  <Setter.Value>
		   <ControlTemplate TargetType="ToggleButton">
			<Viewbox>
			 <Border Name="Border" CornerRadius="10" Background="#FFFFFFFF" Width="40" Height="20">
			   <Border.Effect>
			    <DropShadowEffect ShadowDepth="0.5" Direction="0" Opacity="0.3" />
			   </Border.Effect>
			  <Ellipse Name="Ellipse" Fill="#FFFFFFFF" Stretch="Uniform" Margin="2 1 2 1" Stroke="Gray" StrokeThickness="0.2" HorizontalAlignment="Stretch">
			   <Ellipse.Effect>
			    <DropShadowEffect BlurRadius="10" ShadowDepth="1" Opacity="0.3" Direction="260" />
			   </Ellipse.Effect>
			  </Ellipse>
			 </Border>
			</Viewbox>
			<ControlTemplate.Triggers>
			 <EventTrigger RoutedEvent="Checked">
			  <BeginStoryboard>
				<Storyboard>
				 <ColorAnimation Name="toggleCheckedAni" Storyboard.TargetName="Border" Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" To="#FFEB4034" Duration="0:0:0.1" />
				 <ThicknessAnimation Name="toggleCheckedAniThi" Storyboard.TargetName="Ellipse" Storyboard.TargetProperty="Margin" To="20 1 2 1" Duration="0:0:0.1" />
				</Storyboard>
			  </BeginStoryboard>
			 </EventTrigger>
			 <EventTrigger RoutedEvent="Unchecked">
			  <BeginStoryboard>
				<Storyboard>
				 <ColorAnimation Name="toggleUncheckedAni" Storyboard.TargetName="Border" Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" To="White" Duration="0:0:0.1" />
				 <ThicknessAnimation Name="toggleUncheckedAniThi" Storyboard.TargetName="Ellipse" Storyboard.TargetProperty="Margin" To="2 1 2 1" Duration="0:0:0.1" />
				</Storyboard>
			  </BeginStoryboard>
			  </EventTrigger>
			</ControlTemplate.Triggers>
		   </ControlTemplate>
		  </Setter.Value>
	     </Setter>
        </Style>
     </Window.Resources>

    <Grid>
     
      <Grid.RowDefinitions>
        <RowDefinition Name ="Row0" Height="41*"/><!--Row 0 Row Heights as percentage of entire window-->
        <RowDefinition Name="Row1" Height="50*"/> <!--Row 1-->
        <RowDefinition Name="Row2" Height="9*"/> <!--Row 2-->
      </Grid.RowDefinitions>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="35*"/>           <!--Column 0-->
        <ColumnDefinition Width="35*"/>
        <ColumnDefinition Width="30*"/>
      </Grid.ColumnDefinitions>

      <DockPanel>
        <Menu DockPanel.Dock="Top" Background="#FFFFFFFF">
            <MenuItem Header="_File">
                <MenuItem Header="_About" Name="menuItemAbout"/>
                <MenuItem Header="_Save As" Name="menuItemSaveAS" IsEnabled="False"/>
                <Separator />
                <MenuItem Header="_Exit" Name="menuItemExit"/>
            </MenuItem>
        </Menu>
      </DockPanel>
       
      <GroupBox Name="instructionsGrpBox"  Header="Instructions" Margin="10" Padding="10" Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="3" Grid.RowSpan="2" Visibility="Visible" >
             <StackPanel>
                <TextBlock Foreground="teal" FontSize="30" TextWrapping="Wrap" VerticalAlignment="Center" HorizontalAlignment="Center">
                  CUCM SQL Database Query Script <LineBreak />
                </TextBlock>

                <TextBlock Name="instructionsTxtBlk" TextWrapping="Wrap" VerticalAlignment="Center" HorizontalAlignment="Center">
                    This script will send a SQL query to the CUCM Administrative XML service (AXL)
                    via HTTPS. The results table can be exported as a CSV file.<LineBreak />
                    Before you begin, download and save the WSDL file from CUCM to the same
                    folder where this script is saved. From CUCM admin navigate to.<LineBreak />                    
                    <Bold>Application-&gt;Plugin</Bold>. Click the <Bold>Download</Bold> link next to Cisco AXL toolkit.<LineBreak /><LineBreak />
                    Your user credentials must have the <Bold>Standard AXL API</Bold> role to be able to execute AXL requests. 
                    Press the <Bold>Next</Bold> button to enter your CUCM credentials. When the form
                    loads type your SQL query in the top text box then press <Bold>GO</Bold>.<LineBreak />
                    Please do not use the <Bold>&quot;</Bold> quote marks in your SQL queries. Use <Bold>&apos;</Bold><LineBreak /><LineBreak />
                    Table names for your querys can be found here.<LineBreak />
                    https://d1nmyq4gcgsfi5.cloudfront.net/media/UCM-DD-11-0-1/datadictionary.11.0.1.html<LineBreak />
                    Or Google the term <Bold>CUCM AXL Devnet</Bold>                
                </TextBlock>
             </StackPanel>
      </GroupBox> <!---->

   
    <GroupBox Header="Type your SQL text in the box below" Name="sqlTxtGrpBox" Margin="10" Padding="10"  Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="3" Visibility="Hidden" >
        <StackPanel>
        <TextBlock Name="sqlTxtGrpBlock">SQL query. Delete the example below and replace with your query:</TextBlock>
        <TextBox Name="sqlTxtBox1" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Height="200"/>
        <ToggleButton Name="myToggleButton" Width = "143" Height ="32" HorizontalAlignment="Left" Margin="110,20,620,0" />
        <Label Name="sqlExeLabel" Content="Execute a query" HorizontalAlignment="Left" Margin="0,-31,550,0" VerticalAlignment="Top"/>                
        <Button Name="sqlGoButton" HorizontalAlignment="Right" Margin="0,-32,310,0">Go</Button>
        <Button Name="sqlStopButton" HorizontalAlignment="Right" Margin="0,-33,145,0" IsEnabled="false">Stop</Button>    
        </StackPanel>
    </GroupBox>

    <GroupBox Header="Console Messages" Name="resultsGrpBox" Margin="10" Padding="10" Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="3" Visibility="Hidden" >
        <Grid Name="resultsGrid">
           <TextBlock Name="Output_TxtBlk" Visibility="Hidden" TextWrapping="Wrap" TextAlignment="Left" VerticalAlignment="Stretch" />
           <DataGrid Name="Output_dtgrd" Visibility="Hidden" ColumnWidth="*" AlternatingRowBackground = "LightGray" AlternationCount="2" CanUserAddRows="False"/>
        </Grid>
    </GroupBox>

    <StackPanel Name="buttonCancelStackPanel" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="3" HorizontalAlignment="Right" Orientation="Horizontal" > 
            <Button Name="myButton3" IsEnabled="False" Content="Back"  />
            <Button Name="myButton1" Content="Next"  />
            <Button Name="myCancelButton" Content="Cancel" />
    </StackPanel>
    </Grid>
</Window>
"@

#------------------[ Functions ]------------------------------------------------------#

#######################################################################################
#     Function to close other runspaces. Not the runspace that executes the GUI       #
#######################################################################################

function Stop-Runspaces
{
    $syncHashTable.Output_TxtBlk.Dispatcher.Invoke([action]{
        $syncHashTable.Output_TxtBlk.Text += " `r`nCancelling SQL Query. Please wait`n"
        $syncHashTable.sqlGoButton.IsEnabled = $True
    })

    $syncHashTable.Output_TxtBlk.Dispatcher.Invoke([action]{
        try{
            $syncHashTable.powershell.runspace.close()
            $syncHashTable.powershell.runspace.dispose()
            $syncHashTable.Output_TxtBlk.Text += " `r`nSQL Query. Has been cancelled`n"
        }
        catch{
            $syncHashTable.Output_TxtBlk.Text += "ERROR DURING SQL CANCEL`n$_`n"
        }
    })
     
}

#######################################################################################
#        Function to exit the script, called by the cancel button                     #
#######################################################################################

function Close-AndExit
{
  Stop-Runspaces
  $syncHashTable.queryMainAppGUI.Close()    
}

#######################################################################################
#        Function to open file save dialog, returns filename and path                 #
#######################################################################################

function Get-FileSaveDialog
{
  # Import dotNET class for file open
  [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
  $OpenSaveDialog = New-Object System.Windows.Forms.savefiledialog
  $OpenSaveDialog.initialDirectory = $global:scriptPath
  $OpenSaveDialog.filter = "CSV files (*.csv)| *.csv"
  if ($OpenSaveDialog.ShowDialog() -eq 'Ok') {return $OpenSaveDialog.filename}  
}

#######################################################################################
#     Function to check you have AXLAPI saved to the ame folder as this script        #
#######################################################################################


function checkForAxl()
{
    #Check to see if AXL toolkit is saved to the same folder as this script
    if (!(Test-Path ("$global:scriptPath" + "\AXLAPI.wsdl") -PathType Leaf))
     {
        $syncHashTable.Output_TxtBlk.Foreground = "Red"
        $syncHashTable.Output_TxtBlk.Text =
        " `r`nCannot find AXLAPI.wsdl." +
        " Download from CUCM->Applications->Plugin`n" +
        "Save to the same location as this script.`n"
        return $false
    }
    else
    {
        return $true
    }

}

#######################################################################################
#      Function to start a new run space, creates new poSH instance containing code   #
#        imported from a function . Runs independantly of the GUI instance.           #
#                            Stops GUI freezing                                       #
#######################################################################################

function Start-NewRunspace ($paramList, $codeToExec)
{
    
    # This scriptblock is invoked by the Register-ObjectEvent cmdlet at the bottom of this function. 
    # When the InvocationStateInfo of the new runspace triggers the completed event this code
    # closes any runspaces. Just trying to maintain good housekeeping
    [scriptblock] $jobDoneScriptBlock = {
        if($Sender.InvocationStateInfo.State -eq 'Completed')
        {
            $syncHashTable.powershell.runspace.close()
            $syncHashTable.powershell.runspace.dispose()              
        }
    }
    
    # Get the code to execute in the runspace from the function
    # name of the function is in variable $codeToExec

    $code = Get-Content Function:\$codeToExec -ErrorAction Stop;

    # Create a new powershell instance outside
    # of the instance that controls the GUI
    # add any params to the code this instance executes
    $newPsInstance = [PowerShell]::Create().AddScript($code).AddParameters($paramList)
    
    # Create a new runspace
    $runspace = [RunspaceFactory]::CreateRunspace()

    # Add the runspace object to the powershell instance
    $newPsInstance.Runspace = $runspace

    # Open the runspace
    $runspace.Open()

    # Add the sync hash GUI table to the runspace
    # all runspaces can then manipulate this syncronised hash
    # table
    $runspace.SessionStateProxy.SetVariable("syncHashTable", $syncHashTable)
    
    # Invoking the new powershell instance executes the code
    # in the new runspace. Again, adding and object to the sync hash 
    # table so all functions etc can access the results 
    $syncHashTable.Powershell = $newPsInstance
	$syncHashTable.AsyncObject = $newPsInstance.BeginInvoke()

    # Monitor the new runspace for event changes, call the $jobDoneScriptBlock
    # should this run space trigger an event
    Register-ObjectEvent –InputObject $newPsInstance –EventName InvocationStateChanged –Action $jobDoneScriptBlock 
     

}

#######################################################################################
# Function to make a SOAP call. Never actually gets called, it is read into           # 
# $codeToExec of function Start-NewRunspace as a scriptblock. The new runspace        #
# executes the code as a code block, this stops the GUI freezing. New runspace        #
# managed via the sync hash table $syncHashTable                                      #    
####################################################################################### 

function Get-CucmSqlResult 
{

    #param ($sqlQueryToExe, $axlFileLocation, $cucmCreds, $cucmUrl)
    param ($sqlToExec, $axlPath, $cucmSubIpAddr, $creds, $queryOrUpdate = "executeSQLQuery")
    $AXL = New-WebServiceProxy -Uri $axlPath -Credential $creds

    # Create An empty array in the sync hash table to store the HTTP returned table values
    $syncHashTable.resultsArray  = @()

    # Set the AXL parameters
    # First is namespace a way to avoid element name conflicts if two elements have the same method names
    $ns = $AXL.getType().namespace

    # set the AXL url to connect via https
    $AXL.Url = $cucmSubIpAddr

    # Set a new SQL object use namesspace to avoid conficts
    # The method is not case sensative i.e executeSQLQueryReq
    # or ExecuteSQLQueryReq will do
    $SQLstr = New-Object ($ns + "." + $queryOrUpdate + "Req")
    
    # Set the SQL query string for the object
    $SQLstr.sql = $sqlToExec 

    try
    {
        # Now invoke the sending of the SQL query or update, store the entire result in variable $httpResponse
        $httpResponse = $AXL.$queryOrUpdate($SQLstr)
        
        # Forma the results into a table, line by line
        foreach ($row in $httpResponse.return)
        {   
            $resultsObj = New-Object System.Object
            foreach ($element in $row)
            {
                if ($queryOrUpdate -eq "executeSQLQuery")
                {
                    $resultsObj | Add-Member -type NoteProperty -name $element.Name.ToString() -Value $element.InnerText.ToString()
                }
                else
                {
                    $resultsObj | Add-Member -type NoteProperty -name $element.PSObject.Properties.Name -Value $element.rowsUpdated.ToString()
                }
            }
            $syncHashTable.resultsArray += $resultsObj # Store the results in the sync hash table. Can be accessed by all runspaces
        }

        # Display the results in the GUI
        $syncHashTable.Output_TxtBlk.Dispatcher.Invoke([action]{
            $syncHashTable.Output_TxtBlk.Visibility = "Hidden";
            $syncHashTable.Output_dtgrd.Visibility = "Visible";            
            $syncHashTable.Output_dtgrd.ItemsSource = $syncHashTable.resultsArray;
            $syncHashTable.menuItemSaveAS.IsEnabled = $True
            $syncHashTable.sqlGoButton.IsEnabled = $True
            $syncHashTable.sqlStopButton.IsEnabled = $False
        })
    }
    catch
    {
        $syncHashTable.Output_TxtBlk.Dispatcher.Invoke([action]{
            $syncHashTable.Output_TxtBlk.Text += "AN ERROR HAS OCCURED`n $_`n"
            $syncHashTable.sqlGoButton.IsEnabled = $True
            $syncHashTable.sqlStopButton.IsEnabled = $False
        })
    }   
}

#----------------[ Main Execution ]---------------------------------------------------#

#######################################################################################
#               Read the XAML needed for the GUI                                      #
#######################################################################################

$reader = New-Object System.Xml.XmlNodeReader $xaml
# Import dotNET XAML reader class
$myGuiForm=[Windows.Markup.XamlReader]::Load($reader)

# Collect the Node names of buttons, txt boxes etc.

$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
$namedNodes | ForEach-Object {$syncHashTable.Add($_.Name, $myGuiForm.FindName($_.Name))}

#######################################################################################
#               This code runs when the Menu Item about button is clicked             #
#######################################################################################

$syncHashTable.menuItemAbout.Add_Click({
        #Show the help synopsis in a GUI
        Get-Help "$global:scriptPath\$global:scriptName" -ShowWindow
})

#######################################################################################
#            This code runs when the query/update slider is toggled                   #
#######################################################################################

$syncHashTable.myToggleButton.Add_Click({
        # A sql update. Warn user of the dangers
        if ($syncHashTable.myToggleButton.IsChecked){

            $syncHashTable.sqlExeLabel.Foreground = "Red"
            $syncHashTable.sqlExeLabel.Content = "Execute an update"
            $syncHashTable.sqlTxtGrpBlock.Text = "SQL update. Delete the example below and replace with your update:"
            $syncHashTable.sqlTxtBox1.Foreground = "#FFFFFFFF"
            $syncHashTable.sqlTxtBox1.Background = "#FFEB4034"

            # Pop up a warning about directly updating the CUCM datadbase
            [System.Windows.MessageBox]::Show(
                "PLEASE BE CAREFULL WHEN`nUPDATING THE CUCM DATABASE!!",
                "SQL Query CUCM AXL database",
                "Ok",
                "Stop"
            )


        }

        # Not a sql update must be a plain old query
        else{
            $syncHashTable.sqlExeLabel.Foreground = "Black"
            $syncHashTable.sqlExeLabel.Content = "Execute a query"
            $syncHashTable.sqlTxtGrpBlock.Text = "SQL query. Delete the example below and replace with your query:"
            $syncHashTable.sqlTxtBox1.Foreground = "#FF000000"
            $syncHashTable.sqlTxtBox1.Background = "#FFB8B8B8"
        } 
})

#######################################################################################
#               This code runs when the Menu Item save as button is clicked           #
#            This item is grayed out until data is returned from the endpoint call    #
#######################################################################################

$syncHashTable.menuItemSaveAs.Add_Click({
        #Save data as a csv
        $saveAsFilePathName = Get-FileSaveDialog
        If ( $saveAsFilePathName -ne $null )
        {
          $syncHashTable.resultsArray.GetEnumerator() | Export-CSV $saveAsFilePathName -NoTypeInformation
        }
                   
})

#######################################################################################
#               This code runs when the Menu Item exit button is clicked              #
#######################################################################################

$syncHashTable.menuItemExit.Add_Click({
        #Call the close and exit function
        Close-AndExit
})

#######################################################################################
#               This code runs when the Cancel buttons are clicked                    #
#######################################################################################

$syncHashTable.myCancelButton.Add_Click({
        #Call the close and exit function
        Close-AndExit
})

#######################################################################################
#               This code runs when the Next 1 button is clicked                      #
#######################################################################################

$syncHashTable.myButton1.Add_Click({
   
    $global:myCreds = $host.ui.PromptForCredential("CUCM credentials", "Please enter your CUCM user name and password.", "", "")
    if($global:myCreds)
    {
        $syncHashTable.instructionsGrpBox.Visibility = "Hidden"
        $syncHashTable.Output_dtgrd.Visibility = "Hidden"
        $syncHashTable.sqlTxtGrpBox.Visibility = "Visible"
        $syncHashTable.sqlTxtBox1.Text = "SELECT lastname, userid FROM enduser LIMIT 2"
        #$syncHashTable.goStopGrpBox.Visibility = "Visible"
        $syncHashTable.resultsGrpBox.Visibility = "Visible"
        $syncHashTable.myButton1.IsEnabled = $False
        $syncHashTable.myButton3.IsEnabled = $True

        # Clear all old txt blocks and entry fields
        $syncHashTable.queryMainAppGUI.Dispatcher.Invoke([action]{},"Render") # Refresh update the GUI and therefore the progress bar
        $syncHashTable.Output_TxtBlk.Text = ""
        $syncHashTable.Output_dtgrd.ItemsSource = ""
     }
})

#######################################################################################
#               This code runs when the Back 3 Button is clicked                      #
#######################################################################################

$syncHashTable.myButton3.Add_Click({
   
    $syncHashTable.instructionsGrpBox.Visibility = "Visible"
    $syncHashTable.Output_dtgrd.Visibility = "Hidden"
    $syncHashTable.sqlTxtGrpBox.Visibility = "Hidden"
    #$syncHashTable.goStopGrpBox.Visibility = "Hidden"
    $syncHashTable.resultsGrpBox.Visibility = "Hidden"
    $syncHashTable.myButton1.IsEnabled = $True
    $syncHashTable.myButton3.IsEnabled = $False

})

#######################################################################################
#               This code runs when the GO button is clicked                          #
#######################################################################################

$syncHashTable.sqlGoButton.Add_Click({
   
       $sqlQueryToExe  = $syncHashTable.sqlTxtBox1.Text
       $syncHashTable.sqlGoButton.IsEnabled = $False
       $syncHashTable.sqlStopButton.IsEnabled = $True
       $syncHashTable.Output_dtgrd.Visibility = "Hidden"
       $syncHashTable.Output_TxtBlk.Visibility = "Visible"
       $syncHashTable.Output_TxtBlk.Foreground = "Black"
       $syncHashTable.Output_TxtBlk.Text = " `r`n`r`nPlease be patient, this can take a while! Working On It...`n"
       $syncHashTable.queryMainAppGUI.Dispatcher.Invoke([action]{},"Render") # Refresh GUI

       # Check for presence of the AXLAPI in the same folder as this script
       if (checkForAxl)
       {       
            # Is this a sql update?
            if ($syncHashTable.myToggleButton.IsChecked){

                $paramList = @{
                sqlToExec = $sqlQueryToExe
                axlPath = $("$global:scriptPath" + "\AXLAPI.wsdl")
                cucmSubIpAddr = $global:cucmUrl
                creds = $global:myCreds
                queryOrUpdate = "executeSQLUpdate"
                }

                #Get-CucmSqlResult $sqlQueryToExe $("$global:scriptPath" + "\AXLAPI.wsdl") $global:myCreds $global:cucmUrl
                #Start-NewRunspace -sqlToExec $sqlQueryToExe -axlPath $("$global:scriptPath" + "\AXLAPI.wsdl") -cucmSubIpAddr $global:cucmUrl -creds $global:myCreds -codeToExec "Get-CucmSqlResult"
                Start-NewRunspace -paramList $paramList -codeToExec "Get-CucmSqlResult"

            }

            # If not a sql update must be a plain old query. Omit the queryOrUpdate parameter 
            else{
                $paramList = @{
                sqlToExec = $sqlQueryToExe
                axlPath = $("$global:scriptPath" + "\AXLAPI.wsdl")
                cucmSubIpAddr = $global:cucmUrl
                creds = $global:myCreds
                }

                #Get-CucmSqlResult $sqlQueryToExe $("$global:scriptPath" + "\AXLAPI.wsdl") $global:myCreds $global:cucmUrl
                #Start-NewRunspace -sqlToExec $sqlQueryToExe -axlPath $("$global:scriptPath" + "\AXLAPI.wsdl") -cucmSubIpAddr $global:cucmUrl -creds $global:myCreds -codeToExec "Get-CucmSqlResult"
                Start-NewRunspace -paramList $paramList -codeToExec "Get-CucmSqlResult"
            }            
       }   
 })

#######################################################################################
#               This code runs when the STOP button is clicked                        #
#######################################################################################

$syncHashTable.sqlStopButton.Add_Click({
   
       $syncHashTable.sqlStopButton.IsEnabled = $False
       Stop-Runspaces   
 })
 
#######################################################################################
#               Show the GUI window by name                                           #
#######################################################################################

$syncHashTable.queryMainAppGUI.ShowDialog() | out-null # null dosn't show false on exit
