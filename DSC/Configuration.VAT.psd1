@{
    AllNodes = @(
         @{
            NodeName           = "*"
            InstallationPath = "C:\INSTALL"
            BackupPath = "C:\BACKUP"
            LogFilesPath = "C:\IIS_LOG"
            WebSiteRootPath = "C:\VA"
            SystemTimeZone = "FLE Standard Time"
            FeaturesToAdd = "Web-Asp-Net45","Web-WebSockets","Web-AppInit","Web-Mgmt-Console","Web-Scripting-Tools","AS-NET-Framework","AS-Web-Support","Web-Http-Redirect","Web-Custom-Logging","Web-Log-Libraries","Web-Request-Monitor","Web-Http-Tracing","Web-Basic-Auth","Web-CertProvider","Web-Url-Auth","Web-Windows-Auth","DSC-Service","Web-Mgmt-Service"
            FeaturesToRemove = "PowerShell-ISE"
        },
        @{
            NodeName = "9.8.7.6"
            Role = "ContentDelivery"
        }
        #,
        # @{
        #    NodeName = "4.5.6.7"
        #    Role = "ContentDelivery"
        #},
        #@{
        #    NodeName = "2.3.4.5"
        #    Role = "ContentManagement"
        #}
    );

    NonNodeData = 
    @{
        DistributionServerRoot = "http://1.2.3.4:8664"
        SitecoreDefaultSitePackageName = "SC-80Update1-Base.zip"
        SitecoreLicensePackageName = "license.zip"
        SitecoreLicenseFileName = "license.xml"
        MSLCertificatesPackageName = "MSLCertificates.zip"
        MSLCertificatesMSIName = "MSLCertificates.msi"
        MSLEncryptionCertificateThumbprint ="XYZ"
        STSUrl = "https://1.2.3.4:90443"
        MSLUrl = "http://1.2.3.4:90500"
        VAWindowsEventLog = "VA_Log"
        TDSMasterPackageName = "TDS.Master.update"
        TDSLabelsPackageName = "TDS.Labels.update"
        SitecoreUsernameForTDSUpload = "admin"
        SitecorePasswordForTDSUpload = "b"
        SitecoreUsernameForContentPublish = "admin"
        SitecorePasswordForContentPublish = "b"
        ContentDistributionRoleConfiguration = 
        @{
         Sites = @(
                    @{
                        Name = "cds.example.com"
                        SitecoreType = "CDS"
                        UsesMSLEncryptionCertificate = $true
                        PackageName = "BRight.Web.Personal"
                        # Uncomment for using domain accounts
                        AppPoolAccountUsername = ""
                        AppPoolAccountPassword = ""
                        Bindings = @(
                            @{
                                Protocol = "HTTP"
                                HostHeader = "cds.example.com"
                                IP = "*"
                                Port = 80    
                            }
                        )
                        Databases = @(
                            @{
                                Key = "core"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Core"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "master"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Master"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "web"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Web"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "reporting"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Analytics"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "UserSessionDatabase"
                                Server = "ag_intdev"
                                Database = "VA_UserStorage"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "ParameterTablesDatabase"
                                Server = "ag_intdev"
                                Database = "VA_Configuration"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "UserPreferencesDatabase"
                                Server = "ag_intdev"
                                Database = "VA_UserStorage"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "LookupsDatabase"
                                Server = "ag_intdev"
                                Database = "VA_Configuration"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "Log4netConnectionString"
                                Server = "ag_intdev"
                                Database = "VA_Log"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "LogContext"
                                Server = "ag_intdev"
                                Database = "VA_Log"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "ErrorMappingContext"
                                Server = "ag_intdev"
                                Database = "VA_ErrorMapping"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            }
                        )
                    },
                    @{
                        Name = "cms.example.com"
                        SitecoreType = "CMS"
                        UsesMSLEncryptionCertificate = $true
                        PackageName = "BRight.Web.Personal"
                        # Uncomment for using domain accounts
                        AppPoolAccountUsername = ""
                        AppPoolAccountPassword = ""
                        Bindings = @(
                            @{
                                Protocol = "HTTP"
                                HostHeader = "cms.example.com"
                                IP = "*"
                                Port = 80    
                            }
                        )
                         Databases = @(
                            @{
                                Key = "core"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Core"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "master"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Master"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "web"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Web"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "reporting"
                                Server = "ag_intdev"
                                Database = "VA_Sitecore_Analytics"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "UserSessionDatabase"
                                Server = "ag_intdev"
                                Database = "VA_UserStorage"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "ParameterTablesDatabase"
                                Server = "ag_intdev"
                                Database = "VA_Configuration"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/
                            },
                            @{
                                Key = "UserPreferencesDatabase"
                                Server = "ag_intdev"
                                Database = "VA_UserStorage"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "LookupsDatabase"
                                Server = "ag_intdev"
                                Database = "VA_Configuration"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "Log4netConnectionString"
                                Server = "ag_intdev"
                                Database = "VA_Log"
                                Username = ""
                                Password = ""
                            },
                            @{
                                Key = "LogContext"
                                Server = "ag_intdev"
                                Database = "VA_Log"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            },
                            @{
                                Key = "ErrorMappingContext"
                                Server = "ag_intdev"
                                Database = "VA_ErrorMapping"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            }
                        )
                    },
                    @{
                        Name = "log.example.com"
                        PackageName = "BRight.Web.LogViewer"
                        # Uncomment for using domain accounts
                        AppPoolAccountUsername = ""
                        AppPoolAccountPassword = ""
                        Bindings = @(
                            @{
                                Protocol = "HTTPS"
                                HostHeader = "log.example.com"
                                IP = "*"
                                Port = 443
                                HTTPSCertificateThumbprint = "XXXXXX"
                            }
                        )
                        Databases = @(
                            @{
                                Key = "LogDbContext"
                                Server = "ag_intdev"
                                Database = "VA_Log"
                                Username = ""
                                Password = ""
                                Metadata = "metadata=res://*/"
                            }
                        )
                    },
                    @{
                        Name = "api.example.com"
                        SitecoreType = "CDS"
                        UsesMSLEncryptionCertificate = $true
                        PackageName = "BRight.Web.Api"
                        # Uncomment for using domain accounts
                        AppPoolAccountUsername = ""
                        AppPoolAccountPassword = ""
                        Bindings = @(
                            @{
                                Protocol = "HTTP"
                                HostHeader = "api.example.com"
                                IP = "*"
                                Port = 80
                            }
                        )
                        Databases = @(
                        )
                    }
                )
        }
    } 
}

# TODO: encrypt passwords.