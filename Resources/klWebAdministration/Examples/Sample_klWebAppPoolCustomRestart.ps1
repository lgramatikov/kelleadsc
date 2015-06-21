configuration Sample_klWebAppPoolCustomRestart
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
        klWebAppPoolCustomRestart kcr
        {
            Ensure  = "Present"
            AppPoolName = "onlinebanking-ab-nd.virtual-affairs.nl"
            RestartSchedule = @("01:23:45") #HH:mm:ss
        }
    }
}

Sample_klWebAppPoolCustomRestart -NodeName "10.10.10.85" -OutputPath .\TST