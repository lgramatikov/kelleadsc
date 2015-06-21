configuration Sample_klWebSiteCustomLogPath
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
    Import-DscResource -Module klWebAdministration

    Node $NodeName
    {
        # Add custom Windows log called Kellea
        klWebSiteCustomLogPath kwlp
        {
            Ensure  = "Present"
            LogFilePath = "C:\IIS_LOGS\onlinebanking-ab-nd.virtual-affairs.nl"
            WebSiteName = "onlinebanking-ab-nd.virtual-affairs.nl"
        }
    }
}

Sample_klWebSiteCustomLogPath -NodeName "10.10.10.85" -OutputPath .\TST