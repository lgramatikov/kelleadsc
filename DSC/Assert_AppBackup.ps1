Configuration Assert_AppBackup
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    node $AllNodes.NodeName
    {
        File BackupFolder
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = $Node.BackupPath
        }

        # Use Script as File is quite slow with large number of items. Preferred option is to go for File.
        Script BackupApplication
        {
            SetScript =  "Copy-Item -Path $($Node.WebSiteRootPath) -Destination $($Node.BackupPath) -Recurse -Force" 
            TestScript = "`$False"
            GetScript = "@{}"
            DependsOn = "[File]BackupFolder"
        }
    }
}

Assert_AppBackup -ConfigurationData Configuration.VAT.psd1 -OutputPath .\APP_BACKUP