$SCCMSiteCode="TST"
$SiteServer = "SRV6666.cbyte.lab"

#Import the SCCM Module
Import-Module(Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
Set-Location($SCCMSiteCode + ":")


Function New-AppSuppersedence{
<#
    .SYNOPSIS
        
    .DESCRIPTION
        Adds supersedence to an configuration mananger application object

    .PARAMETER Appname
	    Name of the application (LocalizedDisplayName, ApplicationName

    .PARAMETER Supersedences
		Pass a list of Application (string:LocalizedDisplayName, ApplicationName) of the suppersedence to be added
	
	.PARAMETER IsAutoUninstallSup
    	Set this parameter to true to uninstall the superseded application. Default is true

    .EXAMPLE
    	[System.Collections.ArrayList]$Supersedences=New-Object -TypeName System.Collections.ArrayList
		$Supersedences.Add("Taxware_2-40-89_x64_001") | Out-Null
		$Supersedences.Add("Taxware_2-42-6_x64_001") | Out-Null

		New-AppSuppersedence -Appname "Taxware_242-12_x64_001" -Supersedences $Supersedences


    .NOTES
        Author:      Eliane Megert; clearByte 
        Contact:     info@clearByte.ch
        Website:     https://www.clearByte.ch
#>
    [CmdletBinding()]
    param(
		[Parameter(Mandatory=$true, HelpMessage = "Name of the application (LocalizedDisplayName, ApplicationName)")]
		[ValidateNotNullorEmpty()]
		[string]$Appname,
		
		[parameter(Mandatory = $true, HelpMessage = "Pass a list of Application (string:LocalizedDisplayName, ApplicationName) of the suppersedence to be added")]
		[ValidateNotNullOrEmpty()]
		[System.Collections.ArrayList]$Supersedences,

        [Parameter(Mandatory=$false, HelpMessage = "Set this parameter to true to uninstall the superseded application. Default is true")]
		[bool]$IsAutoUninstallSup=$true

    )
	
    Begin {
        $ErrorActionPreference = "Stop"
    }
	
    Process {    
		try{
			foreach($Supersedence in $Supersedences){
				
				# Get application
				$newapp=Get-CMApplication -Name $Appname
				Write-Host "Successfully fetched Application with ID $($newapp.CI_ID)"

				# Get corresponding Deployment Type
				$DT=Get-CMDeploymentType -ApplicationName $Appname
				Write-Host "Successfully fetched DT with ID $($DT.CI_ID)"

				# Get superseded ap
				$AppSuperseded=Get-CMApplication -Name $Supersedence
				Write-Host "Successfully fetched superseded Application with ID $($($AppSuperseded.CI_ID))"
				
				# Get superseded dt
				$DTSuperseded=Get-CMDeploymentType -ApplicationName $Supersedence
				Write-Host "Successfully fetched Deployment Type for Supersededed App $Supersedence with ID $($($DTSuperseded.CI_ID))"
				
				if($DTSuperseded.Count -ne 1)
				{
					Write-Error "Application has more than 1 Deployment Type. Not Supported and Aborting."
					return
				}
				
				#Fire
				Set-CMApplicationSupersedence -ApplicationId ($newapp.CI_ID) -CurrentDeploymentTypeId $($DT.CI_ID) -SupersededApplicationId $($AppSuperseded.CI_ID) -OldDeploymentTypeId $($DTSuperseded.CI_ID) -IsUninstall $IsAutoUninstallSup
				Write-Host "Successfully Added Supersedence $Supersedence)"
			}
		}
		catch{
			Write-Error "Error adding supersedence: $Error[0].Exception.Message"
			return
		}
	}
	End {

	}
}

[System.Collections.ArrayList]$Supersedences=New-Object -TypeName System.Collections.ArrayList
$Supersedences.Add("Taxware_2-40-89_x64_001") | Out-Null
$Supersedences.Add("Taxware_2-42-6_x64_001") | Out-Null

New-AppSuppersedence -Appname "Taxware_242-12_x64_001" -Supersedences $Supersedences 