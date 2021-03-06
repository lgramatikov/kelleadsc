#requires -version 5

Import-Module -Name $PSScriptRoot\..\..\Library\Helper.psm1

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$AppPoolName,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$RestartSchedule
	)

	$returnValue = @{
		AppPoolName = $AppPoolName
		Ensure = "Absent"
	}

    Import-Module -Name WebAdministration

    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klWebAppPoolCustomRestart]$AppPoolName" 

        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            throw "Please ensure that WebAdministration module is installed."
        }

        $pool = Get-Item -Path IIS:\AppPools\$AppPoolName -ErrorAction SilentlyContinue

        if ($null -eq $pool) {
            throw "Could not find $AppPoolName. Can't continue as resource expects app pool to be present"
        }

        Write-Verbose -Message "Found apppool: $AppPoolName"

        $restartTimesMatch = $false
        $restartTimes = Compare-Object -ReferenceObject $pool.recycling.periodicRestart.schedule -DifferenceObject $RestartSchedule -PassThru

        if ($restartTimes -eq $null) {
            $restartTimesMatch = $true
        }


        # We are a bit opinionated here. Idea is that application restarts once, when there are as less clients as possible. Then periodic restart and idle timeouts are 0.
        if (($pool.recycling.periodicrestart.time.value -eq 0) -and ($restartTimesMatch -eq $true) -and ($pool.processModel.idleTimeout.value -eq 0))
        {
            $returnValue.Ensure = "Present"    
        }
        	
        
        $returnValue
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebAppPoolCustomRestartGet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Get [klWebAppPoolCustomRestart]$AppPoolName" 
    }
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$AppPoolName,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$RestartSchedule,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klWebAppPoolCustomRestart]$AppPoolName" 

        $idleTime = 0
        $periodicRestartTime = 0

        if ($Ensure -eq "Absent") {
            $idleTime = 20
            $periodicRestartTime = 1740
            $RestartSchedule = @("03:00:00")
        }

	    $pool = Get-Item -Path "IIS:\AppPools\$AppPoolName" -ErrorAction SilentlyContinue

        if ($null -eq $pool) {
            throw "Could not find $AppPoolName. Can't continue as resource expects app pool to be present"
        }
        
        $date = (Get-Date).ToString("ddMMyyyyHHmmss")
        Backup-WebConfiguration -Name "klWebAppPoolSpecificUser_$date" -ErrorAction SilentlyContinue

        #Start-WebCommitDelay

        Write-Verbose -Message "Ensure is $Ensure, found app pool named: $AppPoolName, will set restart schedule: $RestartSchedule"

        $pool.processModel.idleTimeout= [TimeSpan]::FromMinutes($idleTime)
        $pool.recycling.periodicrestart.time= [TimeSpan]::FromMinutes($periodicRestartTime)
        $pool | Set-Item

        Clear-ItemProperty "IIS:\AppPools\$AppPoolName" -Name recycling.periodicRestart.schedule
            
        foreach ($time in $RestartSchedule) {
            Write-Verbose "Add new $time to restart schedule"
            Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='$AppPoolName']/recycling/periodicRestart/schedule" -name "." -value @{value="$time"}
        }

        #Stop-WebCommitDelay -Commit $true
    }
    catch
    {
        #Stop-WebCommitDelay –Commit $false
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebAppPoolCustomRestartSet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Set [klWebAppPoolCustomRestart]$AppPoolName" 
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$AppPoolName,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$RestartSchedule,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$result = $false
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klWebAppPoolCustomRestart]$AppPoolName" 
        
        $appPool = Get-TargetResource -AppPoolName $AppPoolName -RestartSchedule $RestartSchedule
        $result = $appPool.Ensure -eq $Ensure

        Write-Verbose -Message "Got Ensure value: $($appPool.Ensure) for apppool: $AppPoolName, restart schedule: $RestartSchedule. Will return: $result"

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebAppPoolCustomRestartTest" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klWebAppPoolCustomRestart]$AppPoolName" 
    }
}


Export-ModuleMember -Function *-TargetResource

