<# 
    .Synopsis
    Generates SQL Server connection string. 

    .Description
    Generates SQL Server connection string that can be used in .NET applications. If username or password are empty, will generate SQL connection string using trusted connection.

    .Parameter Server
    Database server to use. May contain protocol, instance and port like tcp:MyDbServer\Instance1,1433

    .Parameter Database
    Default catatalog (database) to use.

    .Parameter Username
    Username to use when creating untrusted connection. If left empty, will create trusted connection.

    .Parameter Password
    Password to use when creating untrusted connection. If Username is empty, Password will be ignored.

    .Parameter ApplicationName
     Application that connects to SQL server.

    .Example
    # Trusted connection
    Get-SqlConnectionString -Server MY-SQL-SERVER -Database MyDatabase -ApplicationName MyApplication -Username "" -Password ""
#>
Function Get-SqlConnectionString
{
     Param
     (
	    [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Server,
	    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Database,
	    
        [String] $Username="",
	    
        [String] $Password="",
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ApplicationName
    )
    
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder.PSBase.DataSource = $Server
       
    if ($Database -ne "") {
       $builder.PSBase.InitialCatalog = $Database
    }
       
    if (($Username -eq "") -or ($Password -eq "")) {
        $builder.PSBase.IntegratedSecurity = $true
    }
    else {
        $builder.PSBase.UserID = $Username
        $builder.PSBase.Password = $Password
    }
       
    if ($ApplicationName -ne "") {
        $builder.PSBase.ApplicationName= $ApplicationName
    }

    Write-Debug $builder.ToString()

    return $builder.ToString()
}

<# 
    .Synopsis
    Generates SQL Server connection string using entity framework.

    .Description
    Generates SQL Server connection string that can be used in .NET applications. If username or password are empty, will generate SQL connection string using trusted connection.

    .Parameter Server
    Database server to use. May contain protocol, instance and port like tcp:MyDbServer\Instance1,1433

    .Parameter Database
    Default catatalog (database) to use.

    .Parameter Username
    Username to use when creating untrusted connection. If left empty, will create trusted connection.

    .Parameter Password
    Password to use when creating untrusted connection. If Username is empty, Password will be ignored.

    .Parameter ApplicationName
     Application that connects to SQL server.

    .Example
    # Trusted connection
    Get-SqlConnectionString -Server MY-SQL-SERVER -Database MyDatabase -ApplicationName MyApplication -Username "" -Password ""
#>
Function Get-EFConnectionString
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Server,
	    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Database,
	    
        [String] $Username="",
	    
        [String] $Password="",
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ApplicationName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Metadata
    )

    $providerString = Get-SqlConnectionString -Server $Server -Database $Database -Username $Username -Password $Password -ApplicationName $ApplicationName

    Write-Debug "Provider connection string: $providerString"
       
    #$efBuilder = New-Object System.Data.EntityClient.EntityConnectionStringBuilder
    #$efBuilder.PSBase.Provider = "System.Data.SqlClient"
    #$efBuilder.PSBase.ProviderConnectionString = $providerString
    #$efBuilder.PSBase.Metadata = $Metadata
       
    #$efString = [string] $efBuilder.ToString()
    $efString =  "$($Metadata);provider=System.Data.SqlClient;provider connection string=`&`quot;$providerString`&`quot;"
       
    Write-Debug "EF connection string: $efString"
       
    return $efString
}

Function Encrypt-ConfigurationElement
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $WebConfigFilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $ElementName
    )

	if ((Test-Path -Path $WebConfigFilePath) -eq $false)
    {
        throw "Could not find $WebConfigFilePath"
    }
	
    Write-Verbose "Encrypt config files in: $WebConfigFilePath, configuration element $ElementName"
   	& "C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe" -pef $ElementName $WebConfigFilePath
	Write-Verbose "Done."

    #$key = $x.SelectSingleNode("/appSettings")
    # $key.EncryptedData -eq $null
	  
}

# Original source at: https://github.com/PowerShell/xJea/blob/master/DSCResources/Library/Helper.psm1

# Copyright (C) 2014, Microsoft Corporation. All rights reserved.
# Internal function to throw terminating error with specified errorCategory, errorId and errorMessage
function New-TerminatingError
{
    Param
    (
        [Parameter(Mandatory)]
        [String]$errorId,
        
        [Parameter(Mandatory)]
        [String]$errorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory]$errorCategory
    )
    
    $exception   = New-Object System.InvalidOperationException $errorMessage 
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

Export-ModuleMember -Function Get-SqlConnectionString
Export-ModuleMember -Function Get-EFConnectionString
Export-ModuleMember -Function New-TerminatingError