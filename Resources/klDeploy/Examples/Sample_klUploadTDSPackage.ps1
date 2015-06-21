# Do not use this, it relies on internal code.

configuration Sample_klUploadTDSPackage
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
        klUploadTDSPackage kutds
        {
            Ensure = "Present"
            FilePath =  "C:\INSTALL\VA_TDS_Master.update"
            WebsiteName = "www.va.com"
            Username = "admin"
            Password = "b"
            UseSSL = $false
            #DependsOn = "[klSCWebPackageDeploy]klwd_www.va.com" # No point of doing something with content if install failed.
        }
    }
}

Sample_klUploadTDSPackage -NodeName "10.10.10.85" -OutputPath .\TST