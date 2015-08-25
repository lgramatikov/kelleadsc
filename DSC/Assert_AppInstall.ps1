Configuration Assert_AppInstall
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $InstallationPackage,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $PackageVersion

    )
    
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -Module klDeploy

    node $AllNodes.Where{$_.Role -eq "ContentDelivery"}.NodeName
    {
        # Remove old install package if any
        File "delete_oldinstallzip"
        {
            Ensure = "Absent"
            Type = "File"
            Force = $true
            DestinationPath = Join-Path -Path $Node.InstallationPath -ChildPath "$($InstallationPackage).zip"
        }

         File "delete_oldinstallfolder"
         {
            Ensure = "Absent"
            Type = "Directory"
            Force = $true
            DestinationPath = Join-Path -Path $Node.InstallationPath -ChildPath $InstallationPackage
        }

        # Download installation package
        xRemoteFile DownloadInstallPackage
        {
            Uri = "$($ConfigurationData.NonNodeData.DistributionServerRoot)/rel/$($InstallationPackage).zip"
            DestinationPath = $Node.InstallationPath
            DependsOn = "[File]delete_oldinstallfolder"
        }

        # Unzip installation package
        Archive UnzipInstallPackage
        {
            Ensure = "Present"
            Path = Join-Path -Path $Node.InstallationPath -ChildPath "$($InstallationPackage).zip"
            Destination =  Join-Path -Path $Node.InstallationPath -ChildPath $InstallationPackage
            Validate = $true
            Checksum = "SHA-256"
            Force = $true
            DependsOn = "[xRemoteFile]DownloadInstallPackage"
        }

        # We should have backups here. See Assert_AppBackup.ps1. Idea is that backups are done before installation in order to have installation as short as possible.

        # Install new packages
        foreach ($site in $ConfigurationData.NonNodeData.ContentDistributionRoleConfiguration.Sites)
        {
            # Trouble here is with Sitecore. Usually, sites there live in Website. All other normal sites live in their normal home folder.
            $realSiteHomeFolder = "$($Node.WebSiteRootPath)\$($site.Name)"
            $siteNameNoSpecialChars = $site.Name.Replace("-","").Replace(".","")

            if (($site.SitecoreType -eq "CMS") -or ($site.SitecoreType -eq "CDS")) {
                $realSiteHomeFolder = "$($Node.WebSiteRootPath)\$($site.Name)\Website"
            }
            
            Log "l_$($siteNameNoSpecialChars)"
            {
                Message = "SourcePath =  $($Node.InstallationPath)\$InstallationPackage\$($site.PackageName)\, DestinationPath = $realSiteHomeFolder"
            }

            File "install_$($siteNameNoSpecialChars)"
            {
                Ensure = "Present"
                Force = $true
                Type = "Directory"
                Recurse = $true
                Checksum = "SHA-256"
                SourcePath =  "$($Node.InstallationPath)\$InstallationPackage\$($site.PackageName)"
                DestinationPath = $realSiteHomeFolder
                MatchSource = $true
                DependsOn = "[Archive]UnzipInstallPackage"
            }

            # Remove old dictionary.dat
            File "dictdat_$($siteNameNoSpecialChars)"
            {
                Ensure = "Absent"
                Type = "File"
                DestinationPath = "$realSiteHomeFolder\temp\dictionary.dat"
                DependsOn = "[File]install_$($siteNameNoSpecialChars)"
            }
        
            # Adjust connection strings
            foreach ($db in $site.Databases)
            {
                klSQLServerDatabaseConnection "db_$($site.Name)_$($db.Key)"
                {
                    ConnectionId = New-Guid
                    Ensure = "Present"
                    FilePath = "$realSiteHomeFolder\App_Config\ConnectionStrings.config"
                    Name = $db.Key
                    Server = $db.Server
                    Database = $db.Database
                    Username = $db.Username
                    Password = $db.Password
                    Metadata = $db.Metadata
                    Application = $site.Name
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }
            }
            
            # This might be moved out of sites loop
            # Adjust config files. Frequently we have a requirement to always deliver one package for all environments. Because. So all env. specifics are handled in script. En masse.
            if (($site.SitecoreType -eq "CMS") -or ($site.SitecoreType -eq "CDS"))
            {
                klConfigFileKeyValue "ck_$($siteNameNoSpecialChars)_dataFolder"
                {
                    Ensure = "Present"
                    ConfigId = New-Guid
                    FilePath = "$realSiteHomeFolder\Web.config"
                    XPathForKey = "/configuration/sitecore/sc.variable[@name='dataFolder']"
                    Attribute = "value"
                    Value = "$($Node.WebSiteRootPath)\$($site.Name)\Data\"
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }
                
                #cookie domain
                if ($site.SessionCookieDomain -ne $null)
                {
                    klConfigFileKeyValue "ck_$($siteNameNoSpecialChars)_cookie"
                    {
                       Ensure = "Present"
                           ConfigId = New-Guid
                           FilePath = "$realSiteHomeFolder\Web.config"
                           XPathForKey = "/configuration/system.web/authentication/forms"
                           Attribute = "domain"
                           Value = $site.SessionCookieDomain
                   }
                }
                
                klConfigFileKeyValue "ck_$($site.Name)_hostName"
                {
                    Ensure = "Present"
                    ConfigId = New-Guid
                    FilePath = "$realSiteHomeFolder\App_Config\Include\Z.BankingRight.SiteDefinition.config"
                    XPathForKey = "/configuration/sitecore/sites/site/patch:attribute[@name='hostName']"
                    Namespace = "patch=http://www.sitecore.net/xmlconfig/"
                    Attribute = ""
                    Value = $site.Name
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }
                
                klConfigFileKeyValue "ck_$($siteNameNoSpecialChars)_jsver"
                {
                    Ensure = "Present"
                    ConfigId = New-Guid
                    FilePath = "$realSiteHomeFolder\App_Config\BankingRight.config"
                    XPathForKey = "/BankingRight/Settings/add[@key='ClientFramework.JavaScriptFilesVersion']"
                    Attribute = ""
                    Namespace = ""
                    Value = $PackageVersion
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }

                Log "lim_$($siteNameNoSpecialChars)"
                {
                    Message = "IdentityModel: $realSiteHomeFolder\App_Config\IdentityModel.config, mslurl: $($ConfigurationData.NonNodeData.MSLUrl), sts thumb: $($ConfigurationData.NonNodeData.MatrixSTSCertificateThumbprint)"
                }

                #Adjust IdentityModel.config MSL URLs
                Script "IdentityModel_$($site.Name)"
                {
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\IdentityModel.config).replace(`"http://1.2.3.4:40500`",`"$($ConfigurationData.NonNodeData.MSLUrl)`").replace(`"c45783764c8f889c699c8515cb8a9a907569ca28`",`"$($ConfigurationData.NonNodeData.MatrixSTSCertificateThumbprint)`")|Set-Content $realSiteHomeFolder\App_Config\IdentityModel.config -Force" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }

                Log "lims_$($siteNameNoSpecialChars)"
                {
                    Message = "IdentityModelServices: $realSiteHomeFolder\App_Config\IdentityModelServices.config, mslurl: $($ConfigurationData.NonNodeData.MSLUrl), stsurl: $($ConfigurationData.NonNodeData.STSUrl), encthumb: $($ConfigurationData.NonNodeData.MatrixEncryptionCertificateThumbprint)"
                }

                #Adjust IdentityModelServices.config
                Script "IdentityModelServices_$($siteNameNoSpecialChars)"
                {
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\IdentityModelServices.config).replace(`"http://1.2.3.4:40500`",`"$($ConfigurationData.NonNodeData.MSLUrl)`").replace(`"https://172.20.25.73:40443`",`"$($ConfigurationData.NonNodeData.STSUrl)`").replace(`"604aa7329449bc8d3dc8f33edd9db897ba170340`",`"$($ConfigurationData.NonNodeData.MatrixEncryptionCertificateThumbprint)`")|Set-Content $realSiteHomeFolder\App_Config\IdentityModelServices.config -Force" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }

                Log "lssmb_$($siteNameNoSpecialChars)"
                {
                    Message = "SystemServiceModelBindings: $realSiteHomeFolder\App_Config\SystemServiceModelBindings.config, stsurl: $($ConfigurationData.NonNodeData.STSUrl)"
                }

                #Adjust SystemServiceModelBindings.config
                Script "SystemServiceModelBindings_$($siteNameNoSpecialChars)"
                {
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\SystemServiceModelBindings.config).replace(`"https://1.2.3.4:40443`",`"$($ConfigurationData.NonNodeData.STSUrl)`")|Set-Content $realSiteHomeFolder\App_Config\SystemServiceModelBindings.config -Force" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }

                Log "lssmc_$($siteNameNoSpecialChars)"
                {
                    Message = "SystemServiceModelClient: $realSiteHomeFolder\App_Config\SystemServiceModelClient.config, msurl: $($ConfigurationData.NonNodeData.MSLUrl)"
                }

                #Adjust SystemServiceModelClient.config
                Script "SystemServiceModelClient_$($siteNameNoSpecialChars)"
                {
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\SystemServiceModelClient.config).replace(`"http://1.2.3.4:40500`",`"$($ConfigurationData.NonNodeData.MSLUrl)`")|Set-Content $realSiteHomeFolder\App_Config\SystemServiceModelClient.config -Force" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }

                #certificate encodedValue
            }
            
            if ($site.SitecoreType -eq "CDS")
            {
                klSCSwitchMasterToWeb "smtw_$($siteNameNoSpecialChars)"
                {
                    Ensure = "Present"
                    SiteHomePath = $realSiteHomeFolder
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }
            }

            # Encrypt config files
            #klEncryptedConfigurationKey "eck_$($siteNameNoSpecialChars)"
            #{
            #    Ensure = "Present"
            #    ConfigId = New-Guid
            #    SiteHomePath = $realSiteHomeFolder
            #    ConfigurationKey = "connectionStrings"
            #}
        }
    }

    # Delete dictionary.dat
}

Assert_AppInstall -InstallationPackage "VACustomerPortal" -PackageVersion "$(New-Guid)" -ConfigurationData Configuration.VAT.psd1 -OutputPath .\INSTALL_APP