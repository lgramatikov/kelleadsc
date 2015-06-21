# Do not use this, it relies on internal code.

configuration Sample_klSCPublishContent
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
        klSCPublishContent "PublishContent"
        {
            Ensure = "Present"
            WebsiteName = "www.va.com"
            Username = "admin"
            Password = "b"
            UseSSL = $false
            SourceDatabase = "master"
            PublishingTargets = @()
            #DependsOn = "[klSCWebPackageDeploy]klwd_www.va.com" # No point of doing something with content if install failed.
        }
    }
}

Sample_klSCPublishContent -NodeName "10.10.10.85" -OutputPath .\TST