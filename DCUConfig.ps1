<#                             
    .SYNOPSIS
        Configure Update Cycle for Dell Command Update

    .DESCRIPTION
        Configures update window for workstations
        Generates a date from predetermined array for execution
        Configures a monthly update cycle
        Select types of updates to perform
        Configures conservative options catered to a balanced optimal user experience while maintaining update enforcement
        Only installs updates older than 30 days
        Custom logging

    .PARAMETER


    .EXAMPLE
      https://www.dell.com/support/manuals/en-us/command-update/dcu_rg/dell-command-update-cli-commands?guid=guid-92619086-5f7c-4a05-bce2-0d560c15e8ed&lang=en-us
                Can run "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe /help" to see all options

                                Expected value(s): 
                                        Week [< first | second | third | fourth | last >],
                                        Day [< Sun | Mon | Tue | Wed | Thu | Fri | Sat >],
                                        Time[00:00(24 hr format, 15 mins increment)]

                                Ex: > dcu-cli /configure -scheduleMonthly=second,Fri,00:45
    .NOTES
        Author: https://github.com/iGalxz
        Date: 10/18/2024
        Version: 1
        Script Name: DCUConfig.ps1
        Additional Notes:

    .LINK
        # Example usage of the logging function
        Write-Log -Message "Script started." -LogLevel "Info"

        try {
            # Simulate some process
            Write-Log -Message "Performing an operation..." -LogLevel "Info"

            Write-Log -Message "Operation completed successfully." -LogLevel "Info"
        } catch {
            Write-Log -Message "An error occurred: $_" -LogLevel "Error"
        }

#>

$ScriptName = "DCUConfig"
$ErrorActionPreference = "Stop"
$LogFilePath = "C:\Temp\$ScriptName.log"
$LogLocation = "C:\Temp"


#If log location doesn't exist create it (Windows 10 machines)
if(!(Test-Path -Path $LogLocation))
{
    New-Item -Path $LogLocation -ItemType Directory
}

# Function to write a log entry
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$LogLevel = "Info"
    )

    # Get the current date and time
    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    # Format the log message
    $LogMessage = "$Timestamp [$LogLevel] $Message"

    # Write the log message to the file
    Add-Content -Path $LogFilePath -Value $LogMessage

    # Optionally, write the log message to the console
    switch ($LogLevel) {
        "Info" { Write-Host $LogMessage -ForegroundColor Green }
        "Warning" { Write-Host $LogMessage -ForegroundColor Yellow }
        "Error" { Write-Host $LogMessage -ForegroundColor Red }
        }
     
    }

############################################################################
            <# SCRIPT BEGIN #>
############################################################################

#Custom function used to generate a compliant time window for update cycle and convert it to a Dell Command Update readable format (see the .Example field above)
function Get-DCURunTime
{

    #Select Random Day Of Week For Monthly Update Schedule - Excluding Mon+Fri by request of my company
        $global:DaysOfWeek = "Tue","Wed","Thu"
        $global:RandomDayOfWeek = Get-Random -InputObject $DaysOfWeek

    #Select Random Week of Month
        $global:WeeksInMonth = "First","Second","Third","Fourth","Last"
        $global:RandomWeekOfMonth = Get-Random -InputObject $WeeksInMonth

    #Select Random Time of Day between operating hours
        $global:15MinIntervals = "15","30","45","00"
        $global:RandomHour = Get-Random -Minimum 8 -Maximum 15
        $global:Minute = Get-Random -InputObject $15MinIntervals

    #Compile time to 24hr format
        $global:CompileTimeOfDay = [datetime]"$RandomHour`:$Minute"
        $global:TimeOfDay = $CompileTimeOfDay.ToString("HH:mm")
        $global:DCURuntime = "$RandomWeekOfMonth,$RandomDayOfWeek,$TimeOfDay"
}

#Confirm system is Dell Manufacturer
Write-Log -Message "Checking PC Manufacturer..." -LogLevel Info
$PCManufacturer = (Get-WmiObject -Class:Win32_ComputerSystem).Manufacturer


if($PCManufacturer -like "*Dell*")
    {

#If Device is Dell Continue, otherwise don't
    Write-Log -Message "PC detected as Dell Workstation, continuing with configuration of DCU..." -LogLevel Info

    try{
        Write-Log -Message "Generating a unique run time for the endpoint..." -LogLevel "Info"

        #Fetching random runtime
        Get-DCURunTime

        #These have to specified and ran independently or DCU ignores parameters because DCU sucks for some reason.
          $Updates = "-updatetype=driver,firmware,application"
          $AddConfig = "-scheduleAction=DownloadAndNotify"
          $AddConfig2 = "-autoSuspendBitlocker=enable"
          $AddConfig3 = "-systemRestartDeferral=enable -deferralRestartCount=3 -deferralRestartInterval=9"
          $AddConfig4 = "-delayDays=30 -forceRestart=disable"
              
            Write-Log -Message "Configuring update schedule: $DCURuntime" -LogLevel Info
            Start-Process -filepath "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -argumentlist "/configure -scheduleMonthly=$DCURuntime" -wait
    
            Write-Log -Message "Selecting update type... $Updates"  -LogLevel Info
            Start-Process -filepath "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -argumentlist "/configure $Updates" -wait

            Write-Log -Message "Setting additional configuration.... $AddConfig"  -LogLevel Info
            Start-Process -filepath "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -argumentlist "/configure $AddConfig" -wait

            Write-Log -Message "Setting additional configuration.... $AddConfig2"  -LogLevel Info
            Start-Process -filepath "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -argumentlist "/configure $AddConfig2" -wait

            Write-Log -Message "Setting additional configuration.... $AddConfig3"  -LogLevel Info
            Start-Process -filepath "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -argumentlist "/configure $AddConfig3" -wait

            Write-Log -Message "Setting additional configuration.... $AddConfig4"  -LogLevel Info
            Start-Process -filepath "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -argumentlist "/configure $AddConfig4" -wait
    }
    catch
    {
    #Catch any errors and write to log
        Write-Log -Message "An error occurred: $_" -Loglevel Error
        break
    }
}
else{
#If not detected as Dell, write to log
    Write-Log -Message "Dell was not detected as the Manufacturer of the device."
    break
}

    Write-Log -Message "
        Configuration complete. Updates included: Drivers, Firmware, and Dell application updates. 
        Updates will download and install updates that are older than $AddConfig4.
        The user cannot defer updates, but may defer the required restart up to 3 times, for 9 hours each to a maximum of 3 work days.

        Updates are scheduled to be installed on the $DCURuntime monthly." -LogLevel Info
