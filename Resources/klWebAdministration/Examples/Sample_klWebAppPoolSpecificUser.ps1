configuration Sample_klWebAppPoolSpecificUser
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
        klWebAppPoolSpecificUser ksu
        {
            Ensure  = "Present"
            AppPoolName = "onlinebanking-ab-nd.virtual-affairs.nl"
            Username = "VPC-LG-TB-TD\apuser"
            Password = "P@ssw0rd"
        }
    }
}

Sample_klWebAppPoolSpecificUser -NodeName "10.10.10.85" -OutputPath .\TST