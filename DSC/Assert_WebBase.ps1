Configuration Assert_WebBase
{
   Import-DscResource -Module PSDesiredStateConfiguration
   Import-DscResource -Module xWebAdministration
   Import-DscResource -Module xTimeZone
   Import-DscResource -Module xPSDesiredStateConfiguration
   Import-DSCResource -Module xPendingReboot
   Import-DSCResource -Module cWindowsOS
   Import-DSCResource -Module klWebAdministration
   Import-DSCResource -Module klUtils

   node $AllNodes.NodeName
   {
        xTimeZone LocalTZ
        {
            TimeZone = $Node.SystemTimeZone
        }

          # Add custom Windows log
        klWindowsLog wl
        {
            Ensure  = "Present"
            LogName = $ConfigurationData.NonNodeData.VAWindowsEventLog
        }
        
        # Windows features we need for CDS role
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
            DependsOn = "[xTimeZone]LocalTZ"
        }
     
        foreach ($feature in $Node.FeaturesToAdd)
        {
            $fn = $feature.Replace("-","")
            WindowsFeature "$fn"
            {
                Ensure = "Present"
                Name = "$feature"
                DependsOn ="[WindowsFeature]IIS"
            }
        }
        
        # Features we do not need for CDS role
        WindowsFeature RemoveISE
        {
            Ensure = "Absent"
            Name = "PowerShell-ISE"
        }

        # Default folders
        File InstallFolder
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = $Node.InstallationPath
        }

        File BackupFolder
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = $Node.BackupPath
        }

        File IISLogsFolder
        {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = $Node.LogFilesPath
        }

        # Stop default web site
        xWebsite DefaultSite 
        { 
            Ensure          = "Present"
            Name            = "Default Web Site" 
            State           = "Stopped" 
            PhysicalPath    = "C:\inetpub\wwwroot" 
            DependsOn       = "[WindowsFeature]IIS" 
        } 

        # Stop default app pools that come with IIS. 
        xWebAppPool NETv45
        {
            Ensure          = "Present"
            Name            = ".NET v4.5" 
            State           = "Stopped" 
            DependsOn       = "[WindowsFeature]IIS" 
        }

         xWebAppPool NETv45Classic
         {
            Ensure          = "Present"
            Name            = ".NET v4.5 Classic" 
            State           = "Stopped" 
            DependsOn       = "[WindowsFeature]IIS" 
        }

        xWebAppPool DefaultAppPool
        {
            Ensure          = "Present"
            Name            = "DefaultAppPool" 
            State           = "Stopped" 
            DependsOn       = "[WindowsFeature]IIS" 
        }

        # If server has no access to Internet, comment out download resources and make sure that files are present in $Node.InstallationPath

        # Download URL Rewrite
        xRemoteFile DownloadURLRewrite
        {
            Uri = "http://download.microsoft.com/download/6/7/D/67D80164-7DD0-48AF-86E3-DE7A182D6815/rewrite_2.0_rtw_x64.msi" 
            # TODO: We don't really need destination file name. $Node.InstallationPath is enough
            DestinationPath = Join-Path -Path $Node.InstallationPath -ChildPath "rewrite_2.0_rtw_x64.msi"
        }
        
        # Install
        # See https://technet.microsoft.com/en-us/library/dn282132.aspx for details and getting productId
        # get-msitable <yourmsi.msi> -table Property | where { $_.Property -eq "ProductCode" }
        Package InstallURLRewrite
        {
            Ensure     = "Present"
            Path       = Join-Path -Path $Node.InstallationPath -ChildPath "rewrite_2.0_rtw_x64.msi"
            Name       = "IIS URL Rewrite Module 2"
            ProductId  = "EB675D0A-2C95-405B-BEE8-B42A65D23E11"
            LogPath    = Join-Path -Path $Node.InstallationPath -ChildPath "xDSC_rewrite_2.0_rtw_x64.log"
            DependsOn  = "[xRemoteFile]DownloadURLRewrite" 
        }

        # Download MSL certificates ZIP
        xRemoteFile DownloadMSLCertificates
        {
            Uri = "$($ConfigurationData.NonNodeData.DistributionServerRoot)/dist/$($ConfigurationData.NonNodeData.MSLCertificatesPackageName)"
            DestinationPath = Join-Path -Path $Node.InstallationPath -ChildPath $ConfigurationData.NonNodeData.MSLCertificatesPackageName
        }
        
        Archive UnzipMSLCertificates
        {
            Ensure = "Present"
            Path = Join-Path -Path $Node.InstallationPath -ChildPath $ConfigurationData.NonNodeData.MSLCertificatesPackageName
            Destination =  $Node.InstallationPath
            Validate = $true
            Force = $true
            Checksum = "SHA-256"
            DependsOn = "[xRemoteFile]DownloadMSLCertificates"
        }
        
        # Install certificates
        Package InstallMSLCertificates
        {
            Ensure     = "Present"
            Path       = Join-Path -Path $Node.InstallationPath -ChildPath $ConfigurationData.NonNodeData.MSLCertificatesMSIName
            Name       = "MSL Certificates"
            ProductId  = "204ECD48-4A2E-4AE3-A0F9-D9AE6C846EF8"
            LogPath    = Join-Path -Path $Node.InstallationPath -ChildPath "MSLCertificates.log"
            DependsOn  = "[Archive]UnzipMSLCertificates" 
        }

        # If we have at least one site that needs sitecore, we'll have to download base site from somewhere
        xRemoteFile DownloadSitecoreDefaultSite
        {
            Uri = "$($ConfigurationData.NonNodeData.DistributionServerRoot)/dist/$($ConfigurationData.NonNodeData.SitecoreDefaultSitePackageName)"
            DestinationPath = Join-Path -Path $Node.InstallationPath -ChildPath $ConfigurationData.NonNodeData.SitecoreDefaultSitePackageName
        }

        # Issue with Archive resource is that it is quite slow for very large zip files containing very large number of files. In our case, we have close to 10 000 files in 1500 folders.
        $scBasePackagePath = Join-Path -Path $Node.InstallationPath -ChildPath $ConfigurationData.NonNodeData.SitecoreDefaultSitePackageName
        $scBasePackageDestinationPath =  Join-Path -Path $Node.InstallationPath -ChildPath ($ConfigurationData.NonNodeData.SitecoreDefaultSitePackageName -replace ".zip","")
        Script "UnzipSitecoreDefaultSite"
        {
            SetScript =  "Expand-Archive -Path $scBasePackagePath -DestinationPath $scBasePackageDestinationPath -Force" 
            TestScript = "`$False"
            GetScript = "@{}"
            DependsOn = "[xRemoteFile]DownloadSitecoreDefaultSite"
        }

        # And download license file
        xRemoteFile DownloadSitecoreLicense
        {
            Uri = "$($ConfigurationData.NonNodeData.DistributionServerRoot)/dist/$($ConfigurationData.NonNodeData.SitecoreLicensePackageName)"
            DestinationPath = Join-Path -Path $Node.InstallationPath -ChildPath $ConfigurationData.NonNodeData.SitecoreLicensePackageName
        }

        Archive UnzipSitecoreLicense
        {
            Ensure = "Present"
            Path = Join-Path -Path $Node.InstallationPath -ChildPath $ConfigurationData.NonNodeData.SitecoreLicensePackageName
            Destination =  Join-Path -Path $Node.InstallationPath -ChildPath ($ConfigurationData.NonNodeData.SitecoreLicensePackageName -replace ".zip","")
            Validate = $true
            Force = $true
            Checksum = "ModifiedDate"
            DependsOn = "[xRemoteFile]DownloadSitecoreLicense"
        }
   }

   node $AllNodes.Where{$_.Role -eq "ContentDelivery"}.NodeName
   {
        # Create sites' home directories
        foreach ($site in $ConfigurationData.NonNodeData.ContentDistributionRoleConfiguration.Sites)
        {
            $siteNameNoSpecialChars = $site.Name.Replace("-","").Replace(".","")

            # Trouble here is with Sitecore. Usually, sites there live in Website. All other normal sites live in their normal home folder.
            $actualHomeFolder = "$($Node.WebSiteRootPath)\$($site.Name)"

            if (($site.SitecoreType -eq "CMS") -or ($site.SitecoreType -eq "CDS")) {
                $actualHomeFolder = "$($Node.WebSiteRootPath)\$($site.Name)\Website"
            }

            # store in hosts file in case there is no DNS. Actually, for some cases with DNS this is still needed, for example when you have LB and DNS points to VIP
            $siteIPForHostsFile = $site.IP
            if (($null -eq $site.IP) -or ("" -eq $site.IP) -or ("*" -eq $site.IP))
            {
                $siteIPForHostsFile = "127.0.0.1"
            }

            Log "l_$($siteNameNoSpecialChars)"
            {
                Message = "actualHomeFolder:  $actualHomeFolder, for site: $($site.Name), site IP for hosts file: $siteIPForHostsFile"
            }

            # Home folder. Usual SC Website and Data folders will be copied to it from resources below
            File "hf_$($siteNameNoSpecialChars)" {
                Ensure = "Present"
                Type = "Directory"
                DestinationPath = $actualHomeFolder
            }
            
            # New app pool
            xWebAppPool "apppool_$($siteNameNoSpecialChars)" 
            { 
                Name      = $site.Name
                Ensure    = "Present" 
                DependsOn = "[WindowsFeature]WebAspNet45"
            } 

            # Disable idle timeout, periodic restart, set restart once per night
            klWebAppPoolCustomRestart "kcr_$($siteNameNoSpecialChars)" 
            {
                Ensure  = "Present"
                AppPoolName = $site.Name
                RestartSchedule = @("02:00:00") # It might be better to offset restarts with 15 minutes so that we don't hit our server way too hard with bunch of sites starting
                DependsOn = "[xWebAppPool]apppool_$($siteNameNoSpecialChars)"
            }

            # Well, if there is no username specified, there is no point to have this resource.
            if ($site.AppPoolAccountUsername -ne "")
            {
                klWebAppPoolSpecificUser "ksu_$($siteNameNoSpecialChars)" 
                {
                    Ensure  = "Present"
                    AppPoolName = $site.Name
                    Username = $site.AppPoolAccountUsername
                    Password = $site.AppPoolAccountPassword
                    DependsOn = "[xWebAppPool]apppool_$($siteNameNoSpecialChars)"
                }
            }
     
            # First generate bindings, then use them for BidningInfo
            $siteBindings = @()
            foreach ($binding in $site.Bindings)
            {
                $b =  MSFT_xWebBindingInformation 
                        { 
                            Protocol  =  $binding.Protocol
                            Port      =  $binding.Port
                            IPAddress =  $binding.IP
                            HostName  =  $binding.HostHeader
                        }

                $siteBindings = $siteBindings + $b
            }

            # And create the site using app pools, bindings and home directories from above. If web site is a Sitecore site, then site actually lives in Website folder
            xWebsite "website_$($siteNameNoSpecialChars)" 
            { 
                Ensure          = "Present" 
                Name            = $site.Name
                State           = "Started" 
                PhysicalPath    = $actualHomeFolder
                ApplicationPool = $site.Name
                BindingInfo     = $siteBindings
                DependsOn       = @("[xWebAppPool]apppool_$($siteNameNoSpecialChars)","[File]hf_$($siteNameNoSpecialChars)")
            }
         
            # Enable application initialization
            klApplicationInitialization "kai_$($siteNameNoSpecialChars)" 
            {
                Ensure  = "Present"
                AppPoolName = $site.Name
                WebSiteName = $site.Name
                DependsOn   = @("[xWebAppPool]apppool_$($siteNameNoSpecialChars)","[xWebsite]website_$($siteNameNoSpecialChars)")
            }

            # Custom log path
            klWebSiteCustomLogPath "kwlp_$($siteNameNoSpecialChars)"
            {
                Ensure  = "Present"
                LogFilePath = Join-Path -Path $Node.LogFilesPath -ChildPath $site.Name
                WebSiteName = $site.Name
                DependsOn = "[xWebsite]website_$($siteNameNoSpecialChars)"
            }

            # Technically, this is not really correct in the grand scheme of things. Better to add flag in Bindings, then here search for the binding which will be used for hosts file.
            cHostsFile "hosts_$($siteNameNoSpecialChars)"
            {
                Ensure = "Present"
                ipAddress = $siteIPForHostsFile
                hostName = "$($site.Name)"
                DependsOn = "[xWebsite]website_$($siteNameNoSpecialChars)"
            }
        
            # Grant rights to private key for portal app pool account
            if ($site.UsesMSLEncryptionCertificate -eq $true)
            {
                $username = $site.AppPoolAccountUsername

                if ($username -eq "")
                {
                    $username = "IIS AppPool\$($site.Name)"
                }
            
                Script "GrantRightsToPrivateKey_$($siteNameNoSpecialChars)"
                {
                    SetScript =  "`$keyname=(((Get-ChildItem Cert:\LocalMachine\My | ? { `$_.thumbprint -eq `"$($ConfigurationData.NonNodeData.MSLEncryptionCertificateThumbprint)`"}).PrivateKey).CspKeyContainerInfo).UniqueKeyContainerName; if (!`$keyname) { throw `"Could not find certificate with thumbprint $($ConfigurationData.NonNodeData.MSLEncryptionCertificateThumbprint)`" }; `$keypath = `$env:ProgramData+ `"\Microsoft\Crypto\RSA\MachineKeys\`"; `$fullpath=`$keypath+`$keyname; icacls `$fullpath /grant `"$username`:RX`"" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = "[Package]InstallMSLCertificates"
                }
            }

            # Copy default Sitecore installation where needed
            # File copy seems like very slow operation. On other hand, unzip looks like super fast. Should we just skip File resource and go for Archive?
            if (($site.SitecoreType -eq "CMS") -or ($site.SitecoreType -eq "CDS"))
            {
                
                # Issue with File resource is that it suddenly becomes super slow for large number of files. Can be my code, can be server resources. But for now, we'll do it by hand.
                $scWebsiteSourcePath = Join-Path -Path (Join-Path -Path $Node.InstallationPath -ChildPath ($ConfigurationData.NonNodeData.SitecoreDefaultSitePackageName -replace ".zip","")) -ChildPath "Website"
                $scDataSourcePath =  Join-Path -Path (Join-Path -Path $Node.InstallationPath -ChildPath ($ConfigurationData.NonNodeData.SitecoreDefaultSitePackageName -replace ".zip","")) -ChildPath "Data"
                $scLicenseSourcePath =  Join-Path -Path (Join-Path -Path $Node.InstallationPath -ChildPath ($ConfigurationData.NonNodeData.SitecoreLicensePackageName -replace ".zip","")) -ChildPath $ConfigurationData.NonNodeData.SitecoreLicenseFileName
                $scDestinationPath = Join-Path -Path $Node.WebSiteRootPath -ChildPath $site.Name
                
                # Copy Website folder
                Script "SCCopyWebsite_$($siteNameNoSpecialChars)"
                {
                    SetScript =  "Copy-Item -Path $scWebsiteSourcePath -Destination $scDestinationPath -Recurse -Force" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = @("[xWebsite]website_$($siteNameNoSpecialChars)","[Script]UnzipSitecoreDefaultSite")
                }

                # Copy Data folder
                Script "SCCopyData_$($siteNameNoSpecialChars)"
                {
                    SetScript =  "Copy-Item -Path $scDataSourcePath -Destination $scDestinationPath -Recurse -Force" 
                    TestScript = "`$False"
                    GetScript = "@{}"
                    DependsOn = @("[xWebsite]website_$($siteNameNoSpecialChars)","[Script]UnzipSitecoreDefaultSite")
                }

                # Copy license file
                File "SCCopyLicense_$($siteNameNoSpecialChars)"
                {
                    Ensure = "Present"
                    Type = "File"
                    Force = $true
                    SourcePath = $scLicenseSourcePath
                    Checksum = "SHA-256"

                    DestinationPath = Join-Path -Path $scDestinationPath -ChildPath "Data"
                }

                # Make sure that /sitecore should be present only on CMS sites
                if ($site.SitecoreType -ne "CMS")
                {
                     File "SCDeleteAdmin_$($siteNameNoSpecialChars)" {
                        Ensure = "Absent"
                        Type = "Directory"
                        Force = $true
                        DestinationPath =Join-Path -Path $actualHomeFolder -ChildPath "sitecore"
                        DependsOn = "[Script]SCCopyWebsite_$($siteNameNoSpecialChars)"
                    }
                }
            }

            # Grant modify rights for app pool to Data folder

            # Grant write rights for sitemap.xml

            # Switch master to web for CDS sites

        } # end sites loop
    }
}


Assert_WebBase -ConfigurationData Configuration.VAT.psd1 -OutputPath .\WEB_BASE