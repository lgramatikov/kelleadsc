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
		$SiteHomePath
	)

	try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klSCSwitchMasterToWeb]$SiteHomePath" 

        $current = Get-Current -SiteHomePath $SiteHomePath

        $current
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klSCSwitchMasterToWeb" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Done Get [klSCSwitchMasterToWeb]$SiteHomePath" 
    }
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SiteHomePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klSCSwitchMasterToWeb]$SiteHomePath"

        if ($Ensure -eq "Present")
        {
            $includePath = Join-Path -Path $SiteHomePath -ChildPath "\App_Config\Include"
            
            if (($false -eq (Test-Path -Path "$includePath\SwitchMasterToWeb.config")) -and ($false -eq (Test-Path -Path "$includePath\SwitchMasterToWeb.config.example")))
            {
                throw "Could not find $includePath\SwitchMasterToWeb.config.example AND $includePath\SwitchMasterToWeb.config, will not continue"
            }

            # Rename sample config to, well, just config
            if ($true -eq (Test-Path -Path "$includePath\SwitchMasterToWeb.config.example"))
            {
                Rename-Item -Path "$includePath\SwitchMasterToWeb.config.example" -NewName "SwitchMasterToWeb.config"
            }
            else 
            {
                Write-Verbose -Message "Could not find $includePath\SwitchMasterToWeb.config.example and there should be one as Ensure is set to Present."
            }
            
            # Remove master connection string from ConnectionStrings.config
            $connStringsConfig = New-Object -TypeName System.Xml.XmlDocument
            $connStringsConfig.Load("$SiteHomePath\App_Config\ConnectionStrings.config")
            $configKey = $connStringsConfig.SelectSingleNode("/connectionStrings/add[@name = 'master']")

            if ($null -ne $configKey) {
                $configKey.ParentNode.RemoveChild($configKey)
                $connStringsConfig.Save("$SiteHomePath\App_Config\ConnectionStrings.config")
            }
            else 
            {
                Write-Verbose -Message "configKey is null when searching for /connstrings/master"
            }
        }
        else
        {
            throw "Ensure set to Absent is not supported. Why would you need it anyway? If there is a good reason, let me know in comments"
        }
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klSCSwitchMasterToWeb" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Set [klSCSwitchMasterToWeb]$SiteHomePath" 
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
		$SiteHomePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$result = $false
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klSCSwitchMasterToWeb]$SiteHomePath" 
        
        $conf = Get-Current -SiteHomePath $SiteHomePath
        $result = $conf.Ensure -eq $Ensure

        Write-Verbose -Message "Got Ensure value: $($conf.Ensure) for site home: $SiteHomePath. Will return: $result."

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klSCSwitchMasterToWeb" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klSCSwitchMasterToWeb]$SiteHomePath" 
    }
}

function Get-Current
{
    [OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SiteHomePath
	)

    $returnValue = @{
		SiteHomePath = $SiteHomePath
		Ensure = "Absent"
	}

    # Really basic check if we have this enabled - By default Sitecore 8.0 comes with SwitchMasterToWeb.config.example.
    # So if we have .config instead of .config.example and master connection string s missing from ConnectionStrings.config, then most probably we are all good.
    # Btw, this does not support Oracle as database. Apparently there are like 2 customers that use Oracle (or I have no idea what I am talking about).

    $connStringsConfig = New-Object -TypeName System.Xml.XmlDocument
    $connStringsConfig.Load("$SiteHomePath\App_Config\ConnectionStrings.config")
    $configKey = $connStringsConfig.SelectSingleNode("/connectionStrings/add[@name = 'master']")
    
    if (($true -eq (Test-Path -Path "$SiteHomePath\App_Config\Include\SwitchMasterToWeb.config")) -and ($null -eq $configKey)) {
        $returnValue.Ensure = "Present"
    }

	return $returnValue
}


Export-ModuleMember -Function *-TargetResource

