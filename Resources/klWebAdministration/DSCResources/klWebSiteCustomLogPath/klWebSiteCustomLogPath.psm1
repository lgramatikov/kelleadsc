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
		$WebSiteName,

		[parameter(Mandatory = $true)]
		[System.String]
		$LogFilePath
	)

    $returnValue =  @{
        WebSiteName = $WebSiteName
        LogFilePath = $LogFilePath
    }

    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klWebSiteCustomLogPath]$WebSiteName" 

        Import-Module -Name WebAdministration

        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            throw "Please ensure that WebAdministration module is installed."
        }
        
        Write-Verbose -Message "Search for $LogFilePath, site: $WebSiteName"
        
        $log = Get-ItemProperty -Path IIS:\Sites\$WebSiteName -Name logFile.directory -ErrorAction SilentlyContinue -Verbose

        Write-Verbose -Message "Found log file setting: $($log.Value) for site $WebSiteName"

        $fsLogPathIsPresent = Test-Path -Path $LogFilePath -Verbose

        if (($null -ne $log) -and ($fsLogPathIsPresent -eq $true) -and ($log.Value.StartsWith(($LogFilePath)))) {
            Write-Verbose -Message "Found IIS log setting that starts with  $LogFilePath and ensure is: $Ensure (should be Present), return true"
            $returnValue.Ensure = "Present"
        }
        else {
            Write-Verbose -Message "Will return absent for $LogFilePath and ensure is: $Ensure, return true"
            $returnValue.Ensure = "Absent"
        }

        $returnValue
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebSiteCustomLogPathGet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Get [klWebSiteCustomLogPath]$LogFilePath" 
    }
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$WebSiteName,

		[parameter(Mandatory = $true)]
		[System.String]
		$LogFilePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klWebSiteCustomLogPath]$WebSiteName" 

        if ($Ensure -eq "Present") {
            if ((Test-Path -Path $LogFilePath) -eq $false) {
                Write-Verbose -Message "Could not find file system path $LogFilePath, will create it"
                New-Item -Path $LogFilePath -ItemType Directory
            }
        
            Write-Verbose -Message "Set $LogFilePath to logFile.directory for site $WebSiteName"
            Set-ItemProperty -Path IIS:\Sites\$WebSiteName -Name logFile.directory -value $LogFilePath
        }
        else {
            Write-Verbose -Message "Ensure is absent, set to default IIS Log path"
            $defaultIISLogPath = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST'-Filter "system.applicationHost/sites/siteDefaults/logFile" -Name "directory"
            
            Write-Verbose -Message "Found default IIS Logs path at: $($defaultIISLogPath.Value)"
            Set-ItemProperty -Path IIS:\Sites\$WebSiteName -Name logFile.directory -value $defaultIISLogPath.Value
        }
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebSiteCustomLogPathSet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Set [klWebSiteCustomLogPath]$LogFilePath" 
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
		$WebSiteName,

		[parameter(Mandatory = $true)]
		[System.String]
		$LogFilePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klWebSiteCustomLogPath]$WebSiteName" 
        Write-Verbose -Message "Search for $LogFilePath, site: $WebSiteName"
        
        $log = Get-TargetResource -WebSiteName $WebSiteName -LogFilePath $LogFilePath
        $result = $log.Ensure -eq $Ensure

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebSiteCustomLogPathTest" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klWebSiteCustomLogPath]$LogFilePath" 
    }
}

Export-ModuleMember -Function *-TargetResource