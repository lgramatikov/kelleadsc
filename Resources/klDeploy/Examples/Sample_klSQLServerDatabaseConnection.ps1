configuration Sample_klSQLServerDatabaseConnection
{
    param
    (
        # Target node to apply the configuration
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
        $NodeName
    )

    # Import the module that defines custom resources
    Import-DscResource -Module klDeploy

    Node $NodeName
    {
        # Normal SQL server connection string, will use trusted connection as username and password are empty
        klSQLServerDatabaseConnection klsql1
        {
            ConnectionId = New-Guid
            Ensure = "Present"
            FilePath = "C:\VA\Sites\va.com\App_Config\ConnectionStrings.config"
            Name = "core"
            Server = "tcp:(local)\SQLEXPRESS,1433"
            Database = "VA_Sitecore_core"
            Username = ""
            Password = ""
            Metadata = ""
            Application = "www.va.com"
        }

        # EntityFramework connection string because there is something in Metadata property. Will use sql server username and password
        klSQLServerDatabaseConnection klsql2
        {
            ConnectionId = New-Guid
            Ensure = "Present"
            FilePath = "C:\VA\Sites\va.com\App_Config\ConnectionStrings.config"
            Name = "log"
            Server = "tcp:(local)\SQLEXPRESS,1433"
            Database = "VA_Log"
            Username = "sqluser"
            Password = "P@ssw0rd"
            Metadata = "res://*/EntityModels.LogModel.csdl|res://*/EntityModels.LogModel.ssdl|res://*/EntityModels.LogModel.msl"
            Application = "www.va.com"
        }
    }
}

Sample_klSQLServerDatabaseConnection -NodeName "10.10.10.85" -OutputPath .\TST