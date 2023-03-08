[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12   

Function Set-MECMMachineVariableAdminService {
	param(
             [parameter(Mandatory=$true, HelpMessage="Site server FQDN")]
             [ValidateNotNullOrEmpty()]
             [string]$Siteserver,

             [parameter(Mandatory=$true, HelpMessage="Site Code")]
             [ValidateNotNullOrEmpty()]
             [string]$SiteCode,

             [parameter(Mandatory=$true, HelpMessage="MECM Machine Object to add Variable to")]
             [ValidateNotNullOrEmpty()]
             [string]$MachineName,

             [parameter(Mandatory=$true, HelpMessage="Credentials do Operate on MECM")]
             [ValidateNotNullOrEmpty()]
             [System.Management.Automation.PSCredential ]$Credentials,

             [parameter(Mandatory=$true, HelpMessage="Hashtable of all Variables that need to get added to the machine object")]
             [ValidateNotNullOrEmpty()]
             [hashtable]$MachineVariables
       )
    #Create array of Variables as .NET object for further deserialization to json
    $newVars = @() 
    $MachineVariables.GetEnumerator() | ForEach-Object {
    $newVars += New-Object –TypeName PSObject -Property @{IsMasked = $False;
                                                          Name = $_.Name;
                                                          Value = $_.Value
                                                         }}

    #Get machine resource id
    $DeviceID = (Invoke-RestMethod "https://$($CMProvider)/AdminService/V1.0/Device?`$filter=contains(Name,%27$devicename%27)" -Credential $Cred).value[0].MachineID
    if (-not $DeviceID){
        throw "Device not found: $devicename"
    }

    #this method fetches lazy properties
    $MachineSettings=(Invoke-RestMethod -Method 'Get' -Uri "https://$($CMProvider)/AdminService/wmi/SMS_machinesettings($DeviceID)" -Credential $Cred).value
    
    #$countmember=$($newVars.Count)
    #Create Body
    if($($newVars.Count) -le 0){
        $BodyContent="{`"SourceSite`": `"$SiteCode`",`"ResourceID`": $DeviceID,`"MachineVariables`": [$($newVars |ConvertTo-Json -depth 50)]}" # initialisiere body mit einer variable -> braucht '[' und ']'
    }
    else{
        $BodyContent="{`"SourceSite`": `"$SiteCode`",`"ResourceID`": $DeviceID,`"MachineVariables`": $($newVars |ConvertTo-Json -depth 50)}"
    }

    
    #check if already vars exist and expand if so
    if($MachineSettings) # new machine no machine_settings available
    {
        #es gibt schon variablen
        $arrayMachineVariables=$MachineSettings[0].MachineVariables #via index da Array als rückgabe vom Get
        if($arrayMachineVariables.Count -gt 0){
            $newVars | ForEach-Object {
                $arrayMachineVariables+=$_
            }
            $BodyContent="{`"SourceSite`": `"$SiteCode`",`"ResourceID`": $DeviceID,`"MachineVariables`": $($arrayMachineVariables |ConvertTo-Json -depth 50)}"
        }
    }

    #fire
    $Mach = (Invoke-RestMethod -Method Post -Uri "https://$($CMProvider)/AdminService/wmi/SMS_MachineSettings" -Body $BodyContent -ContentType 'application/json' -Credential $Cred).value

}

$secpasswd = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ('sofia.knull@SofieKnull.lab', $secpasswd)
$devicename = "knof-VCXX"
$mac = "00:00:00:00:00:20"
$cmprovider = "srv01.SofieKnull.lab"
$SiteCode="PS1"


# Create new Device
$machine = Invoke-RestMethod -Method Post -Uri https://$($CMProvider)/AdminService/wmi/SMS_Site.ImportMachineEntry -Body "{`"NetbiosName`": `"$devicename`", `"MACAddress`": `"$mac`"}" -ContentType 'application/json' -Credential $Cred

#Machine Variables to be added to Device
$vars = @{"CU_Domain"="SofieKnull.lab";`
          "CU_City"="ZRH";`
          "CU_Country"="CH";`
          "CU_SerialNumber"="Serial";`
          "CU_TimeZone"="W. Europe Standard Time";`
}

Set-MECMMachineVariableAdminService -Siteserver $cmprovider -SiteCode $SiteCode -MachineName $devicename -Credentials $Cred -MachineVariables $vars