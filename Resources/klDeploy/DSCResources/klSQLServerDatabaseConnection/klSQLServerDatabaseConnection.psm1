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
		$ConnectionId,

		[parameter(Mandatory = $true)]
		[System.String]
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Server,

		[parameter(Mandatory = $true)]
		[System.String]
		$Database,

		[System.String]
		$Username="",

		[System.String]
		$Password="",

		[System.String]
		$Metadata="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Application=""
	)

    $returnValue = @{
        ConnectionId = $ConnectionId
		FilePath = $FilePath
		Name = $Name
		Server = $Server
		Database = $Database
		Username = $Username
		Password = $Password
		Metadata = $Metadata
        Application = $Application
		Ensure = "Absent"
	}

	try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klSQLServerDatabaseConnection]$FilePath" 

        $conn = Get-CurrentConnectionStringValue -FilePath $FilePath -Name $Name -Server $Server -Database $Database -Username $Username -Password $Password -Application $Application -Metadata $Metadata

        $returnValue.Ensure = $conn.Ensure
        $returnValue.ConnectionString = $conn.ConnectionString

        $returnValue
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klSQLServerDatabaseConnectionGet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Done Get [klSQLServerDatabaseConnection]$FilePath" 
    }
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$ConnectionId,

		[parameter(Mandatory = $true)]
		[System.String]
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Server,

		[parameter(Mandatory = $true)]
		[System.String]
		$Database="",

		[System.String]
		$Username="",

		[System.String]
		$Password="",

		[System.String]
		$Metadata="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Application,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klSQLServerDatabaseConnection]$FilePath"

        $config = New-Object -TypeName System.Xml.XmlDocument
        $config.Load($FilePath)

        $configKey = $config.SelectSingleNode("/connectionStrings/add[@name = '$Name']")
          
        if ($configKey)
        {
            Write-Verbose -Message "Found configKey with name: $Name"            
            if ($Ensure -eq "Present")
            {
                $connString = Get-ExpectedConnectionString -Server $Server -Database $Database -Username $Username -Password $Password -Application $Application -Metadata $Metadata

                # When saving, &quot will be escaped to &amp;&quot; and that is not right. But during reading, we need escaped value
                #$connString -replace "&quot","`""
                $unescapedConnString = $connString.Replace("&quot;","`"")
                
                $configKey.SetAttribute("connectionString", $unescapedConnString)
            }
            else
            {
                $configKey.connectionString = ""
            }
            
            Write-Verbose -Message "Save XML file: $FilePath to file system. "
            $config.Save($FilePath)
        }
        else {
            Write-Verbose -Message "Could not find connection string with name: $Name"
        }
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klSQLServerDatabaseConnection" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klSQLServerDatabaseConnection]$FilePath" 
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
		$ConnectionId,

		[parameter(Mandatory = $true)]
		[System.String]
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Server,

		[parameter(Mandatory = $true)]
		[System.String]
		$Database,

		[System.String]
		$Username="",

		[System.String]
		$Password="",

		[System.String]
		$Metadata="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Application,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$result = $false
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klSQLServerDatabaseConnection]$FilePath" 
        
        $conf = Get-CurrentConnectionStringValue -FilePath $FilePath -Name $Name -Server $Server -Database $Database -Username $Username -Password $Password -Metadata $Metadata -Application $Application
        $result = $conf.Ensure -eq $Ensure

        Write-Verbose -Message "Got Ensure value: $($conf.Ensure) for file: $FilePath, and name: $Name. Will return: $result."

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klSQLServerDatabaseConnectionTest" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klSQLServerDatabaseConnection]$FilePath" 
    }
}

function Get-ExpectedConnectionString
{
    [OutputType([System.String])]
	param
	(
        [parameter(Mandatory = $true)]
		[System.String]
		$Server,

		[parameter(Mandatory = $true)]
		[System.String]
		$Database,

		[System.String]
		$Username="",

		[System.String]
		$Password="",

		[System.String]
		$Metadata="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Application=""
	)

    $connString = ""
    if ($Metadata -eq "") 
    {
        $connString = Get-SqlConnectionString -Server $Server -Database $Database -Username $Username -Password $Password -ApplicationName $Application
    }
    else
    {
        $connString = Get-EFConnectionString -Server $Server -Database $Database -Username $Username -Password $Password -ApplicationName $Application -Metadata $Metadata
    }

    return $connString
}

# Both Get-, Set- and Test- need to load connection string from config file. Set- and Test- can just call Get-, but then output will be littered with unexpected Get- calls. So we move logic out of Get-
# In order to avoid logging data like "start set" and then all of a sudden "start get". Or, at least, that's the theory.
function Get-CurrentConnectionStringValue
{
    [OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.String]
		$Server,

		[parameter(Mandatory = $true)]
		[System.String]
		$Database,

		[System.String]
		$Username="",

		[System.String]
		$Password="",

		[System.String]
		$Metadata="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Application=""
	)

    $returnValue = @{
        ConnectionString = ""
		Ensure = "Absent"
	}

	try
    {
        Write-Verbose -Message "Start Get-CurrentConnectionStringValue" 

        $connString = ""
        $connString = Get-ExpectedConnectionString -Server $Server -Database $Database -Username $Username -Password $Password -Application $Application -Metadata $Metadata

        # We might check if target file is XML at all
        if ((Test-Path -Path $FilePath) -eq $false) {
            throw "Could not find file: $FilePath. Can't continue"
        }

        $x = Select-Xml -XPath "/connectionStrings/add[@name = '$Name']" -Path $FilePath -Verbose

        if (($null -ne $x.Node) -and ($null -ne $x.Node.GetAttribute("connectionString")))
        {
            Write-Verbose -Message "Found node and it has attribute connectionString"
            
            if ($x.Node.GetAttribute("connectionString") -ceq $connString)
            {
                Write-Verbose -Message "Found connectionString: $connString"
                $returnValue.Ensure = "Present"

                $returnValue.ConnectionString = $connString
            }
            else
            {
                Write-Verbose "Found connectionString attribute, but value does not match what we expect: $connString"
            }
        }
        else
        {
            Write-Verbose -Message "Could not find node holding connectionString for name: $Name"
        }

        return $returnValue
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "CurrentConnectionStringValue" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "Done Get-CurrentConnectionStringValue" 
    }
}


Export-ModuleMember -Function *-TargetResource

