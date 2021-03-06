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
		$ConfigId,

		[parameter(Mandatory = $true)]
		[System.String]
		$ConfigurationKey,

		[parameter(Mandatory = $true)]
		[System.String]
		$SiteHomePath
	)

	try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klEncryptedConfigurationKey]$ConfigurationKey" 

        $current = Get-Current -SiteHomePath $SiteHomePath -ConfigurationKey $ConfigurationKey

        $current
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klEncryptedConfigurationKey" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Done Get [klEncryptedConfigurationKey]$SiteHomePath" 
    }
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
	    [parameter(Mandatory = $true)]
		[System.String]
		$ConfigId,

		[parameter(Mandatory = $true)]
		[System.String]
		$ConfigurationKey,

		[parameter(Mandatory = $true)]
		[System.String]
		$SiteHomePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klEncryptedConfigurationKey]$ConfigurationKey"
        New-Variable -Name "configPath" -Value (Join-Path -Path $SiteHomePath -ChildPath "Web.config") -Option ReadOnly
        
        $config = New-Object -TypeName System.Xml.XmlDocument
        $config.Load($configPath)
        $configKey = $config.SelectSingleNode("//$ConfigurationKey")

        if ($Ensure -eq "Present")
        {
            if ($null -eq $configKey.EncryptedData)
            {
                Write-Verbose -Message "Ensure is Present and there is no EncryptedData. Will encrypt $ConfigurationKey, config path: $SiteHomePath"
                
                # aspnet_regiis.exe is very picky when it comes to paths. trailing slash will cause an error (it won't be able to find Web.config)
                if ($SiteHomePath.EndsWith("\")) {
                    $SiteHomePath = $SiteHomePath.Substring(0,$SiteHomePath.Length-1)
                }
                
                & "C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe" -pef $ConfigurationKey $SiteHomePath 
            }
            else
            {
                Write-Verbose -Message "Ensure is Present and there is EncryptedData. Nothing to do."
            }
        }
        else
        {
            if ($null -ne $configKey.EncryptedData)
            {
                Write-Verbose -Message "Ensure is Absent and there is EncryptedData. Will decrypt key $ConfigurationKey"
                & "C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe" -pdf $ConfigurationKey $SiteHomePath 
            }
            else
            {
                Write-Verbose -Message "Ensure is Absent and there is no EncryptedData. Nothing to do."
            }
        }
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klEncryptedConfigurationKey" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klEncryptedConfigurationKey]$ConfigurationKey" 
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
		$ConfigId,

		[parameter(Mandatory = $true)]
		[System.String]
		$ConfigurationKey,

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
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klEncryptedConfigurationKey]$ConfigurationKey" 
        
        $conf = Get-Current -SiteHomePath $SiteHomePath -ConfigurationKey $ConfigurationKey
        $result = $conf.Ensure -eq $Ensure

        Write-Verbose -Message "Got Ensure value: $($conf.Ensure) for site home: $SiteHomePath, config key: $ConfigurationKey. Will return: $result."

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klEncryptedConfigurationKey" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klEncryptedConfigurationKey]$SiteHomePath" 
    }
}

function Get-Current
{
    [OutputType([System.Collections.Hashtable])]
    param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConfigurationKey,

# String ConfigurationFile
    
        [parameter(Mandatory = $true)]
		[System.String]
		$SiteHomePath
	)

    $returnValue = @{
		SiteHomePath = $SiteHomePath
		Ensure = "Absent"
	}

    if ($false -eq (Test-Path -Path "C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe"))
    {
        throw "Could not find C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe"
    }
    
    # it is not just web.config we have to test. In case of included file, like ConnectionStrings.config, we have to go and look in that file for encrypted value
    $configPath = Join-Path -Path $SiteHomePath -ChildPath "Web.config"

    $conf = New-Object -TypeName System.Xml.XmlDocument
    $conf.Load($configPath)
    
    # That's a bit flaky, just doing xpath on //. But for appSettings and connectionStrings works fine.
    $configKey = $conf.SelectSingleNode("//$ConfigurationKey")

    if ($null -eq $configKey)
    {
        throw "Could not find key: $ConfigurationKey in file: $configPath"
    }

    if ($null -ne $configKey.EncryptedData)
    {
        $returnValue.Ensure = "Present"
    }

    Write-Verbose -Message "return value will be:"
    Write-Verbose -Message $returnValue

    return $returnValue
}


Export-ModuleMember -Function *-TargetResource

