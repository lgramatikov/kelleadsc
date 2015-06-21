configuration Sample_klApplicationInitialization
{
    param
    (
        # Target node to apply the configuration
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
        $NodeName
    )

    # Import the module that defines Kellea resources
    Import-DscResource -Module klWebAdministration

    Node $NodeName
    {
        klApplicationInitialization kai
        {
            Ensure  = "Present"
            AppPoolName = "onlinebanking-ab-nd.virtual-affairs.nl"
            WebSiteName = "onlinebanking-ab-nd.virtual-affairs.nl"
        }
    }
}

Sample_klApplicationInitialization -NodeName "10.10.10.85" -OutputPath .\TST