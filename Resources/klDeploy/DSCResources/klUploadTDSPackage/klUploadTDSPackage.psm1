#requires -version 5

Import-Module -Name $PSScriptRoot\..\..\Library\Helper.psm1

# IMPORTANT! - Please, do not use this resource. It relies on piece of software which is for internal use only. Well, for now that is.

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$WebSiteName,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$UseSSL,

		[parameter(Mandatory = $true)]
		[System.String]
		$Username,

		[parameter(Mandatory = $true)]
		[System.String]
		$Password
	)
	
	$returnValue = @{
		FilePath = $FilePath
		WebSiteName = $WebSiteName
        UseSSL = $UseSSL
		Username = $Username
		Password = $Password
		Ensure = "Absent"
	}

    Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klUploadTDSPackage]$FilePath"

	$returnValue

    Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Done Get [klUploadTDSPackage]$FilePath" 
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$WebSiteName,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$UseSSL,

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
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klUploadTDSPackage]$FilePath"

        if(Test-Path -Path $FilePath)
        {
            Write-Verbose -Message "Found TDS package: $FilePath"
        }
        else {
          throw "Could not find TDS package: $FilePath"
        }

        $site= "http://$WebsiteName"

        if ($UseSSL -eq $true) {
            $site = "https://$WebsiteName"
        }

        # Should warm-up a bit Sitecore, especially after installation.
        Invoke-WebRequest -Uri $site -UseBasicParsing -Method GET -TimeoutSec 300

        $basicAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($UserName):$Password"));
        $updateFile = Split-Path -Path $FilePath -Leaf

        $uploadUrl = "$site/api/TdsDeploy/UploadAndInstallPackage/$updateFile" 

        Write-Verbose -Message "Complete upload Url: $uploadUrl"

        $response = Invoke-WebRequest -Uri $uploadUrl -Method POST -InFile $updateFile -ContentType "application/octet-stream" -Headers @{"Authorization"="Basic $basicAuth"} -TimeoutSec 600 -Verbose

        Write-Verbose -Message "Upload done with result: $response"
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klUploadTDSPackageSet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Set [klUploadTDSPackage]$FilePath" 
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
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$WebSiteName,

		[parameter(Mandatory = $true)]
		[System.Boolean]
		$UseSSL,

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

    # I can't think of a way to test if current package has been uploaded correctly. May be check Sitecore.Ship
    Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klUploadTDSPackage]$FilePath" 
    Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klUploadTDSPackage]$FilePath" 
	return $false
}


Export-ModuleMember -Function *-TargetResource

