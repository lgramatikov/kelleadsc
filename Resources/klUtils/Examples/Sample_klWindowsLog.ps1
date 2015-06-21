configuration Sample_klWindowsLog
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
    Import-DscResource -Module klUtils

    Node $NodeName
    {
        # Add custom Windows log called Kellea
        klWindowsLog wl
        {
            Ensure  = "Present"
            LogName = "Kellea"
        }
    }
}

Sample_klWindowsLog -NodeName "10.10.10.85" -OutputPath .\TST