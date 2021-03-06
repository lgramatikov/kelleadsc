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
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$XPathForKey,

		[System.String]
		$Namespace="",

		[System.String]
		$Attribute="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Value
	)

    $returnValue = @{
		FilePath = $FilePath
		XPathForKey = $XPathForKey
        Namespace = $Namespace
        Attribute = $Attribute
		Value = $Value
		Ensure = "Absent"
	}

    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Get [klConfigFileKeyValue]$FilePath, xpath: $XPathForKey"

        $confMatch = Get-CurrentValuesMatch -FilePath $FilePath -XPathForKey $XPathForKey -Attribute $Attribute -Value $Value
        if ($confMatch -eq $true) {
            $returnValue.Ensure = "Present"
        }

        $returnValue
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klConfigFileKeyValueGet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation 
    }
    finally
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Done Get [klConfigFileKeyValue]$FilePath, xpath: $XPathForKey" 
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
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$XPathForKey,

		[System.String]
		$Namespace="",

		[System.String]
		$Attribute="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Value,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Set [klConfigFileKeyValue]$FilePath, xpath: $XPathForKey, value: $Value, attr: $Attribute, namespace: $Namespace"

        $config = New-Object -TypeName System.Xml.XmlDocument
        $config.Load($FilePath)

        $configKey = $null

        if ("" -eq $Namespace) {
             
            $configKey = $config.SelectSingleNode($XPathForKey)
        }
        else {
            $s = $Namespace.Split("=")

            $ns = New-Object -TypeName System.Xml.XmlNamespaceManager($config.NameTable)
			$ns.AddNamespace($s[0], $s[1])
            $configKey = $config.SelectSingleNode($XPathForKey, $ns)
        }

        if ($Ensure -eq "Present")
        {
            if ("" -eq $Attribute) {
                # On Windows 10 for some reason .value is not available, but FirstChild.Value is.
                if ($configKey.Value -ne $null) {
                    $configKey.Value = $Value
                }
                else {
                    $configKey.FirstChild.Value = $Value
                }
            }
            else {
                $configKey.SetAttribute($Attribute, $Value)
            }
        }
        else
        {
            # That's just lame. On other hand, if Absent results in node removal, that's even worse.
            if ("" -eq $Attribute) {
                if ($configKey.Value -ne $null) {
                    $configKey.Value = ""
                }
                else {
                     $configKey.FirstChild.Value = $Value
                }
            }
            else {
                $configKey.SetAttribute($Attribute, "")
            }
        }
        
        # File can get locked by antivirus or bad admins.
        Start-Sleep -Seconds 1
        
        $config.Save($FilePath)
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klConfigFileKeyValueSet" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Set [klConfigFileKeyValue]$FilePath, xpath: $XPathForKey" 
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
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$XPathForKey,

		[System.String]
		$Namespace="",

		[System.String]
		$Attribute="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Value,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$result = $false
    
    try
    {
        Write-Verbose -Message "$((Get-Date).GetDateTimeFormats()[112]) Start Test [klConfigFileKeyValue]$FilePath, xpath: $XPathForKey" 
        
        $confMatch = Get-CurrentValuesMatch -FilePath $FilePath -XPathForKey $XPathForKey -Namespace $Namespace -Attribute $Attribute -Value $Value

        if (($confMatch -eq $true) -and ($Ensure -eq "Present")) {
            $result = $true
        }

        Write-Verbose -Message "Got Ensure value: $Ensure, for file: $FilePath, attribute: $Attribute, namespace: $Namespace and value: $Value. Will return: $result."

        return $result
    }
    catch
    {
        Write-Debug -Message "ERROR: $($_|Format-List -Property * -Force|Out-String)"
        New-TerminatingError -ErrorId "klConfigFileKeyValueTest" -ErrorMessage $_.Exception -ErrorCategory InvalidOperation
    }
    finally
    {
        Write-Verbose -Message "$((get-date).GetDateTimeFormats()[112]) Done Test [klConfigFileKeyValue]$FilePath, xpath: $XPathForKey" 
    }
}

# Check if specified value is present in config file. If configuration has been found and its value matches the one we specify, return true.
# Otherwise return false
function Get-CurrentValuesMatch
{
	[OutputType([System.String])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$FilePath,

		[parameter(Mandatory = $true)]
		[System.String]
		$XPathForKey,

		[System.String]
		$Namespace="",

		[System.String]
		$Attribute="",

		[parameter(Mandatory = $true)]
		[System.String]
		$Value
	)

    Write-Verbose -Message "Start Get-CurrentValuesMatch with values: filepath: $FilePath, xpathforkey: $XPathForKey, namespace: $Namespace, attribute: $Attribute, value: $Value"

    if (Test-Path -Path $FilePath) {
        Write-Verbose -Message "Found config file at: $FilePath"
    }
    else {
        throw "Could not find specified path: $FilePath"
    }

    $x = $null
    $valuesMatch = $false

    # in case we have to use namespaces, they shoudl be provided during node selection. Current way of supplying namespaces is not the best, a hash table would be much better.
    if ("" -eq $Namespace) {
        $x = Select-Xml -XPath $XPathForKey -Path $FilePath -Verbose
    }
    else {
        $s = $Namespace.Split("=")
            
        if (2 -ne $s.Length) {
            throw "Namespace should be only one (for now) and in format something=somethingelse. Like: 'patch=http://www.sitecore.net/xmlconfig/'"
        }

        $ns = @{$s[0]=$s[1]}
        $x = Select-Xml -XPath $XPathForKey -Path $FilePath -Namespace $ns -Verbose
    }

    # After all namespacing, if we still don't have node, probably XPath is wrong (likely), target file is incorrect (can happen) or this code is broken (most likely)
    if (($null -eq $x) -or ($null -eq $x.Node))
    {
        throw "Could not find node for XPath: $XPathForKey, in file: $FilePath"
    }

    # Try to figure out if we have to search for attribute (<something key='something' somethingtosearchfor='value' />) or value (<something>value</something>)
    if ($Attribute -eq "")
    {
        if ($x.Node.InnerText -ceq $Value)
        {
            Write-Verbose -Message "Found value: $Value"
            $valuesMatch = $true
        }
        else
        {
            Write-Verbose -Message "Could not find value: $Value"
        }
    }
    else
    {
        if ($null -ne $x.Node.GetAttribute($Attribute))
        {
            if ($x.Node.GetAttribute($Attribute) -ceq $Value)
            {
                Write-Verbose -Message "Found value: $Value, for attribute: $Attribute"
                $valuesMatch = $true
            }
            else
            {
                Write-Verbose -Message "Found attribute: $Attribute, but value: $($x.Node.GetAttribute($Attribute)), do not match ours: $Value"
            }
        }
        else
        {
            Write-Verbose -Message "Could not find attribute: $Attribute"
        }
    }

    return $valuesMatch
}

Export-ModuleMember -Function *-TargetResource

