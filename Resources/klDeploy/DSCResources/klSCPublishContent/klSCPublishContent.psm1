#requires -version 5

Import-Module -Name $PSScriptRoot\..\..\Library\Helper.psm1

# --- IMPORTANT! --- - Please, do not use this resource. It relies on piece of software which is for internal use only. Well, for now that is. --- IMPORTANT! ---

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
		[System.Boolean]
		$UseSSL,

		[parameter(Mandatory = $true)]
		[System.String]
		$SourceDatabase,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$PublishingTargets,

		[parameter(Mandatory = $true)]
		[System.String]
		$Username,

		[parameter(Mandatory = $true)]
		[System.String]
		$Password
	)
    
    $returnValue = @{
		WebSiteName = $WebSiteName
        UseSSL = $UseSSL
        SourceDatabase = $SourceDatabase
        PublishingTargets = $PublishingTargets
		Username = $Username
		Password = $Password
		Ensure = "Absent"
	}

    Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klSCPublishContent]$WebSiteName"

	$returnValue

    Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Done Get [klSCPublishContent]$WebSiteName" 
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
		[System.Boolean]
		$UseSSL,

		[parameter(Mandatory = $true)]
		[System.String]
		$SourceDatabase,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$PublishingTargets,

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
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klSCPublishContent]$WebSiteName"

        $site= "http://$WebsiteName"

        if ($UseSSL -eq $true) {
            $site = "https://$WebsiteName"
        }

        $url = "$site/api/SitecorePublish/publish/$SourceDatabase"
        $json = ConvertTo-Json -InputObject $PublishingTargets -Compress
        $basicAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($UserName):$Password"));
        
        Invoke-RestMethod -Uri $url -Method POST -ContentType "application/json" -Body $json -Headers @{"Authorization"="Basic $basicAuth"} -Verbose -TimeoutSec 60
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klSCPublishContentSet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Set [klUploadTDSPackage]$WebSiteName" 
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
		[System.Boolean]
		$UseSSL,

		[parameter(Mandatory = $true)]
		[System.String]
		$SourceDatabase,

		[parameter(Mandatory = $true)]
		[System.String[]]
		$PublishingTargets,

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
    Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klSCPublishContent]$WebSiteName" 
    Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klSCPublishContent]$WebSiteName" 
	return $false
}


Export-ModuleMember -Function *-TargetResource

