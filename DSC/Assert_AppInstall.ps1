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
    Import-DscResource -Module xPSDesiredStateConfiguration
    Import-DscResource -Module klDeploy

    node $AllNodes.Where{$_.Role -eq "ContentDelivery"}.NodeName
    {
        # Download installation package
        xRemoteFile DownloadInstallPackage
        {
            Uri = "$($ConfigurationData.NonNodeData.DistributionServerRoot)/rel/$($InstallationPackage).zip"
            DestinationPath = $Node.InstallationPath
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
            
                klConfigFileKeyValue "ck_$($site.Name)_hostName"
                {
                    Ensure = "Present"
                    ConfigId = New-Guid
                    FilePath = "$realSiteHomeFolder\App_Config\Include\Z.BRight.SiteDefinition.config"
                    XPathForKey = "/configuration/sitecore/sites/site/patch:attribute[@name='hostName']"
                    Namespace = "patch=http://www.sitecore.net/xmlconfig/"
                    Value = $site.Name
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }

                klConfigFileKeyValue "ck_$($siteNameNoSpecialChars)_jsver"
                {
                    Ensure = "Present"
                    ConfigId = New-Guid
                    FilePath = "$realSiteHomeFolder\App_Config\BRight.config"
                    XPathForKey = "/BRight/Settings/add[@key='ClientFramework.JavaScriptFilesVersion']"
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
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\IdentityModel.config).replace(`"http://1.1.1.1:40500`",`"$($ConfigurationData.NonNodeData.MSLUrl)`").replace(`"XYZ`",`"$($ConfigurationData.NonNodeData.STSCertificateThumbprint)`")|Set-Content $realSiteHomeFolder\App_Config\IdentityModel.config -Force" 
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
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\IdentityModelServices.config).replace(`"http://2.2.2.2:40500`",`"$($ConfigurationData.NonNodeData.MSLUrl)`").replace(`"https://172.20.25.73:40443`",`"$($ConfigurationData.NonNodeData.STSUrl)`").replace(`"YUV`",`"$($ConfigurationData.NonNodeData.EncryptionCertificateThumbprint)`")|Set-Content $realSiteHomeFolder\App_Config\IdentityModelServices.config -Force" 
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
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\SystemServiceModelBindings.config).replace(`"https://172.20.25.73:40443`",`"$($ConfigurationData.NonNodeData.STSUrl)`")|Set-Content $realSiteHomeFolder\App_Config\SystemServiceModelBindings.config -Force" 
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
                    SetScript =  "(Get-Content $realSiteHomeFolder\App_Config\SystemServiceModelClient.config).replace(`"http://3.3.3.3:40500`",`"$($ConfigurationData.NonNodeData.MSLUrl)`")|Set-Content $realSiteHomeFolder\App_Config\SystemServiceModelClient.config -Force" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = "[File]install_$($siteNameNoSpecialChars)"
                }

                #certificate encodedValue
            }
            
            # Encrypt config files
        }
    }

    # As there is no point to upload and approve Sitecore content on all nodes in CMS role, we'll target one specific node. Well, if it is broken, nothing good will happen.
    # But there is no way to check in Sitecore if something is there or not. Or I might be totally wrong. May be try Sitecore.Ship?
    #node "4.5.6.7
    #{
    #    # Import SC content
    #    foreach ($package in @($ConfigurationData.NonNodeData.TDSMasterPackageName,$ConfigurationData.NonNodeData.TDSLabelsPackageName))
    #    {
    #        klUploadTDSPackage "UploadTDSPackage_$package"
    #        {
    #            Ensure = "Present"
    #            FilePath =  Join-Path -Path (Join-Path -Path $Node.InstallationPath -ChildPath $InstallationPackage) -ChildPath $package
    #            WebsiteName = "cms.example.com"
    #            Username = $ConfigurationData.NonNodeData.SitecoreUsernameForTDSUpload
    #            Password = $ConfigurationData.NonNodeData.SitecorePasswordForTDSUpload
    #            UseSSL = $false
    #            DependsOn = "[klSCWebPackageDeploy]klwd_xxx" # No point of doing something with content if install failed. Or move this only to content approval and always prepare content for the new version
    #        }
    #    }
    #   
    #    # Publish SC content
    #    klSCPublishContent "PublishContent"
    #    {
    #        Ensure = "Present"
    #        WebsiteName = "cms.example.com"
    #        Username = $ConfigurationData.NonNodeData.SitecoreUsernameForTDSUpload
    #        Password = $ConfigurationData.NonNodeData.SitecorePasswordForTDSUpload
    #        UseSSL = $false
    #        SourceDatabase = "master"
    #        PublishingTargets = @()
    #        DependsOn   = @("[klUploadTDSPackage]UploadTDSPackage_$($ConfigurationData.NonNodeData.TDSMasterPackageName)","[klUploadTDSPackage]UploadTDSPackage_$($ConfigurationData.NonNodeData.TDSLabelsPackageName)")
    #    }
    #}

    # Delete dictionary.dat
}

Assert_AppInstall -InstallationPackage "VACustomerPortal" -PackageVersion "0.6.2" -ConfigurationData Configuration.VAT.psd1 -OutputPath .\INSTALL_APP