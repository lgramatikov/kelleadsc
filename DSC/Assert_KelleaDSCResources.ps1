Configuration Assert_KelleaDSCResources
{
   Import-DscResource -Module PSDesiredStateConfiguration
   Import-DscResource -Module xPSDesiredStateConfiguration

   node $AllNodes.Where{$_.Role -eq "ContentDelivery"}.NodeName
   {
        xRemoteFile DownloadCustomModules
        {
            Uri = "$($ConfigurationData.NonNodeData.DistributionServerRoot)/dist/dsc_custom_modules.zip"
            DestinationPath = Join-Path -Path $Node.InstallationPath -ChildPath "dsc_custom_modules.zip"
        }

        Archive UnzipCustomModules
        {
            Ensure = "Present"
            Path = Join-Path -Path $Node.InstallationPath -ChildPath "dsc_custom_modules.zip"
            Destination =  $Node.InstallationPath
            Validate = $true
            Checksum = "ModifiedDate"
            DependsOn = "[xRemoteFile]DownloadCustomModules"
        }

        File "Copy_DSC"
        {
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
            SourcePath = Join-Path -Path $Node.InstallationPath -ChildPath "dsc_custom_modules\"
            DestinationPath = "C:\Program Files\WindowsPowerShell\Modules"
            DependsOn = "[Archive]UnzipCustomModules"
        }
    }
}

Assert_KelleaDSCResources -ConfigurationData Configuration.VAT.psd1 -OutputPath .\CUSTOM_MODULES