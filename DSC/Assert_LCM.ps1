Configuration Assert_LCM
{
   node $AllNodes.Where{$_.Role -eq "ContentDelivery"}.NodeName
   {
     LocalConfigurationManager
      {
         RebootNodeIfNeeded = $true
         DebugMode = "None" #"None" #"ForceModuleImport"  #DebugMode = "ResourceScriptBreakAll"
      }
   }
}

Assert_LCM -ConfigurationData Configuration.VAT.psd1 -OutputPath .\LCM

#$cred = Get-Credential
# Set-DscLocalConfigurationManager -Path .\LCM_VAT -Credential $cred