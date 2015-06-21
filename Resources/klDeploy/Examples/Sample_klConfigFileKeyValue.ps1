configuration Sample_klConfigFileKeyValue
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
        # Set custom not sure what exactly, but Sitecore uses it to figure out something about the site.
        klConfigFileKeyValue klck1
        {
            Ensure  = "Present"
            ConfigId = New-Guid
            FilePath = "C:\VA\Sites\va.com\Website\App_Config\Include\Z.BankingRight.SiteDefinition.config"
            XPathForKey = "/configuration/sitecore/sites/site/patch:attribute[@name='hostName']"
            Namespace = "patch=http://www.sitecore.net/xmlconfig/"
            Attribute = ""
            Value = "dev.va.local"
        }

        # Set Sitecore data folder
        klConfigFileKeyValue klck2
        {
            Ensure = "Present"
            ConfigId = New-Guid
            FilePath = "C:\VA\Sites\va.com\Website\Web.config"
            XPathForKey = "/configuration/sitecore/sc.variable[@name='dataFolder']"
            Attribute = "value"
            Value = "C:\VA\Sites\va.com\Data\"
        }
    }
}

Sample_klConfigFileKeyValue -NodeName "10.10.10.85" -OutputPath .\TST