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
		$AppPoolName
	)

    $returnValue = @{
		WebSiteName = $WebSiteName
        AppPoolName = $AppPoolName
		Ensure = "Absent"
	}

    Import-Module -Name WebAdministration

    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klApplicationInitialization]$WebSiteName" 

        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            throw "Please ensure that WebAdministration module is installed."
        }

        $alwaysRunning = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/applicationPools/add[@name='$AppPoolName']" -Name "startMode"
        $preloadEnabled = Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST'  -Filter "system.applicationHost/sites/site[@name='$WebSiteName']/application[@path='/']" -Name "preloadEnabled"

        Write-Verbose -Message "For site: $WebSiteName and apppool: $AppPoolName, found alwaysRunning: $alwaysRunning, and preloadEnabled: $($preloadEnabled.Value)"

        if (($alwaysRunning -eq "AlwaysRunning") -and ($preloadEnabled.Value -eq $true)) {
            $returnValue.Ensure = "Present"
        }

        $returnValue
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klApplicationInitializationGet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Get [klApplicationInitialization]$WebSiteName" 
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
		$AppPoolName,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klApplicationInitialization]$WebSiteName" 
        
        if ($Ensure -eq "Present") {
            Write-Verbose -Message "Present is set, will set preloadEnabled to True for site: $WebSiteName, and startMode to AlwaysRunning for apppool: $AppPoolName"
            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/applicationPools/add[@name='$AppPoolName']" -Name "startMode" -Value "AlwaysRunning"
            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/sites/site[@name='$WebSiteName']/application[@path='/']" -Name "preloadEnabled" -Value "True"
        }
        else {
            Write-Verbose -Message "Present is set, will set preloadEnabled to False for site: $WebSiteName, and startMode to AlwaysRunning for apppool: $AppPoolName"
            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.applicationHost/sites/site[@name='$WebSiteName']/application[@path='/']" -Name "preloadEnabled" -Value "False"
        }
    }
     catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klApplicationInitializationSet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klApplicationInitialization]$WebSiteName" 
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
		$AppPoolName,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
    
    $result = $false
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klApplicationInitialization]$WebSiteName" 
        
        $appInit = Get-TargetResource -WebSiteName $WebSiteName -AppPoolName $AppPoolName
        $result = $appInit.Ensure -eq $Ensure

        Write-Verbose -Message "Got Ensure value: $($appInit.Ensure) for site: $WebSiteName, and apppool: $AppPoolName. Will return: $result."

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klApplicationInitializationTest" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klApplicationInitialization]$WebSiteName" 
    }
}

Export-ModuleMember -Function *-TargetResource