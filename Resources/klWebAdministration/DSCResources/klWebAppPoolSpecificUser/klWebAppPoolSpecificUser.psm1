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
		[System.String]
		$Username,
        
		[parameter(Mandatory = $true)]
		[System.String]
		$Password
	)
    
    $returnValue = @{
		AppPoolName = $AppPoolName
		Ensure = "Absent"
	}

    Import-Module -Name WebAdministration

    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klWebAppPoolSpecificUser]$AppPoolName" 

        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            throw "Please ensure that WebAdministration module is installed."
        }

        $pool = Get-Item -Path IIS:\AppPools\$AppPoolName -ErrorAction SilentlyContinue

        if ($null -eq $pool) {
            throw "Could not find $AppPoolName. Can't continue as resource expects app pool to be present"
        }

        Write-Verbose -Message "Found apppool: $AppPoolName with username: $($pool.processModel.username), identityType: $($pool.processModel.identityType)"

        $returnValue.Username = $pool.processModel.username
        $returnValue.Password = $pool.processModel.password
        $returnValue.IdentityType = $pool.processModel.identityType

        if (($pool.processModel.userName -eq $Username) -and ($pool.processModel.password -eq $Password) -and ($pool.processModel.identityType -eq "SpecificUser")) 
        {
              $returnValue.Ensure = "Present"
        }
        
        $returnValue
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebAppPoolSpecificUserGet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Get [klWebAppPoolSpecificUser]$AppPoolName" 
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
		[System.String]
		$Username,

		[parameter(Mandatory = $true)]
		[System.String]
		$Password,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klWebAppPoolSpecificUser]$AppPoolName" 
	    $pool = Get-Item -Path IIS:\AppPools\$AppPoolName -ErrorAction SilentlyContinue

        if ($null -eq $pool) {
            throw "Could not find $AppPoolName. Can't continue as resource expects app pool to be present"
        }

        if ($Ensure -eq "Present") {
            $date = (Get-Date).ToString("ddMMyyyyHHmmss")
            Backup-WebConfiguration -Name "klWebAppPoolSpecificUser_$date" -ErrorAction SilentlyContinue
            Write-Verbose -Message "Ensure is present, found app pool named: $AppPoolName, will set username to: $Username, identityType to: SpecificUser"
            $pool.processModel.username = $Username
		    $pool.processModel.password = $Password
		    $pool.processModel.identityType = "SpecificUser"
        }
        else {
            Write-Verbose -Message "Ensure is present, found app pool named $AppPoolName, will set identityType to: ApplicationPoolIdentity"
            $pool.processModel.IdentityType = "ApplicationPoolIdentity"
        }
    
        $pool | Set-Item
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebAppPoolSpecificUserSet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Set [klWebAppPoolSpecificUser]$AppPoolName" 
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
		[System.String]
		$Username,

		[parameter(Mandatory = $true)]
		[System.String]
		$Password,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)
    
    $result = $false
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klWebAppPoolSpecificUser]$AppPoolName" 
        
        $appPool = Get-TargetResource -AppPoolName $AppPoolName -Username $Username -Password $Password
        $result = $appPool.Ensure -eq $Ensure

        Write-Verbose -Message "Got Ensure value: $($appPool.Ensure) for apppool: $AppPoolName, username: $Username. Will return: $result"

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klWebAppPoolSpecificUserTest" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klWebAppPoolSpecificUser]$AppPoolName" 
    }
}

Export-ModuleMember -Function *-TargetResource