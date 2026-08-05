# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Originally Created by Microsoft Corporation
#
# Defender Extended PowerShell Telemetry Harvester (DEPTH)
# Version 2.1.0.0


function Get-BIOSInfo {
    try {
        $win32_bios = Get-CimInstance -ClassName Win32_Bios | Select-Object -Property Name, Manufacturer, SMBIOSBIOSVersion, SerialNumber -ErrorAction Stop
        $win32_ComputerSystemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct -Property UUID -ErrorAction Stop

        $bios = [pscustomobject]@{
            BiosManufacturer = $win32_bios.Manufacturer
            BiosName         = $win32_bios.Manufacturer + ' ' + $win32_bios.Name
            BiosVersion      = $win32_bios.SMBIOSBIOSVersion
            BiosSerialNumber = $win32_bios.SerialNumber
            BiosUUID         = $win32_computerSystemProduct.UUID
        }

        return $bios
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving BIOS data" }
    }
}
function Get-Cpu {
    try {
        $win32_processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property DeviceId, CurrentClockSpeed, Manufacturer, Name -ErrorAction Stop

        $cpu = @()
        foreach ($processor in $win32_processor) {
            $cpu += [pscustomobject]@{
                CpuId           = $processor.DeviceId
                CpuModel        = $processor.Name
                CurrentCpuSpeed = $processor.CurrentClockSpeed
                CpuManufacturer = $processor.Manufacturer

            }
        }
        

        return $cpu
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving CPU data" }
    }
}
function Get-CpuTag {
    try {

        $cpuInfo = Get-CimInstance -ClassName CIM_Processor 
        $maxSpeed = $cpuInfo.MaxClockSpeed
        $overallClockSpeed = ($maxSpeed | Measure-Object -Average).Average

        $returnValue = Get-ValidDisplayNameString "cpuspeed.dod.mil" "CPU Speed" $overallClockSpeed
        return $returnValue
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "cpuspeed.dod.mil:CPU Speed:;Invalid Error"
    }
}
function Get-DepthData {
    [cmdletbinding()]
    param
    (
        [Parameter()]
        [Switch]$NoMDER,
        [Parameter()]
        [Switch]$NoEventLog,
        [Parameter()]
        [Switch]$NoWindowsStoreApp,
        [Parameter()]
        [Switch]$NoRemoveOld
    )
    $moduleInfo = Test-ModuleManifest -Path 'C:\program files\MDER Sensor Package\tagScripts\mder.psd1' -ErrorAction SilentlyContinue
    $version = $moduleInfo.Version

    $status = $true;

    $dataElements = [pscustomobject]@{
        ScanInfo                = @{
            ScanTime   = [System.DateTime]::Now.ToString("dd/MM/yyyy HH:mm:ss")
            ScanSource = 'DEPTH Local Job'
            Version    = $version.ToString()
            Status     = 'Normal'
        }
        Bios                    = Get-BIOSInfo
        Cpu                     = Get-Cpu
        ListeningProcess        = Get-ListeningProcess
        Memory                  = Get-Memory
        Network                 = Get-Network
        OperatingSystem         = Get-OperatingSystem
        Patches                 = Get-Patch
        PhysicalDisk            = Get-PhysicalDisk
        Proxy                   = Get-Proxy
        RouteTable              = Get-RouteTable
        SecurityProducts        = Get-SecurityProduct
        System                  = Get-System
        TpmInfo                 = Get-TpmInfo
        Usb                     = Get-USB
        WindowsOptionalFeatures = Get-WindowsOptionalFeature
    }

    if (-not $NoMDER.IsPresent) {
        # write to registry keys for MDE retrieval
        # note that max length that MDE will pick up is 17948 characters for the registry value
        try {
            foreach ($key in $dataElements.PSObject.Properties.Name) {
                if ($dataElements.$key) {
                    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DEPTH_' + $key
                    if (-not (Test-Path $registryPath)) {
                        $null = New-Item -Path $registryPath -Force
                    }
                    $element = 'DEPTH_' + $key
                    $data = @{
                        $element = $dataElements.$key
                    } | ConvertTo-Json -Depth 5 -Compress
					
                    #call the truncation logic on the JSON before inserting it into the Registry
                    $data = Get-TruncatedJsonString -jsonObject $data
					
                    $null = Set-ItemProperty -Path $registryPath -Name 'UninstallString' -Value $data
                    $null = Set-ItemProperty -Path $registryPath -Name 'DEPTH' -Value 'MDER'
                }
            } 
            $successAddingTags = $true
        }
        catch {
            $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
            $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
            $successAddingTags = $false
            $status = $false;
        }
    }

    ##############adding logic to write the Display name to the tags that just got added##############
    if ($successAddingTags) {
        
        $tagElements = [pscustomobject]@{
            Cpu              = Get-CpuTag
            Memory           = Get-MemoryTag
            Network          = Get-NetworkTag
            OperatingSystem  = Get-OperatingSystemTag
            PhysicalDisk     = Get-PhysicalDiskTag
            SecurityProducts = Get-SecurityProductTag
            System           = Get-SystemTag
            TpmInfo          = Get-TpmInfoTag
        }
 
        $currentDate = Get-Date -Format "yyyyMMdd" 
        $currentTime = (Get-Date).ToUniversalTime().ToString("HH:mm:ss.ffff+0000") ##match DATT 1.6 time format
        
        try {
            foreach ($key in $tagElements.PSObject.Properties.Name) {
                if ($tagElements.$key) {
                    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DEPTH_' + $key
                    $registryValueName = "DisplayName"
                    if (-not (Test-Path $registryPath)) {
                        $null = New-Item -Path $registryPath -Force
                    }
                    $value = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
                    $data = $tagElements.$key
                    $registryValue = $value.$registryValueName
                    if ($registryValue -ne $data) {
                        $null = Set-ItemProperty -Path $registryPath -Name 'DisplayName' -Value $data
                        $null = Set-ItemProperty -Path $registryPath -Name 'DisplayVersion' -Value 'DATT-DISA'
                        $null = Set-ItemProperty -Path $registryPath -Name 'InstallDate' -Value $currentDate
                        $null = Set-ItemProperty -Path $registryPath -Name 'InstallTime' -Value $currentTime
                        $null = Set-ItemProperty -Path $registryPath -Name 'Publisher' -Value 'DATT'
                    }
                }
            } 
        }
        catch {
            $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
            $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
            $status = $false;
        }

        #########adding DATT-specific tags without the uninstall data###########
        $DATTtagElements = [pscustomobject]@{
            LTSOS     = Get-OSLTSTag
            SN        = Get-SNTag
            UID       = Get-UIDTag
            LocalUser = Get-LocalUserTag

        }

        try {
            foreach ($key in $DATTtagElements.PSObject.Properties.Name) {
                if ($DATTtagElements.$key) {
                    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\DEPTH_' + $key
                    $registryValueName = "DisplayName"
                    if (-not (Test-Path $registryPath)) {
                        $null = New-Item -Path $registryPath -Force
                    }
                    $element = 'DEPTH_' + $key
                    $data = @{
                        $element = $DATTtagElements.$key
                    } | ConvertTo-Json -Depth 5 -Compress

                    $value = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
                    $data = $DATTtagElements.$key
                    $registryValue = $value.$registryValueName
                    if ($registryValue -ne $data) {
                        $data = $DATTtagElements.$key
                        $null = Set-ItemProperty -Path $registryPath -Name 'DisplayName' -Value $data
                        $null = Set-ItemProperty -Path $registryPath -Name 'DisplayVersion' -Value 'DATT-DISA'
                        $null = Set-ItemProperty -Path $registryPath -Name 'InstallDate' -Value $currentDate
                        $null = Set-ItemProperty -Path $registryPath -Name 'InstallTime' -Value $currentTime
                        $null = Set-ItemProperty -Path $registryPath -Name 'Publisher' -Value 'DATT'
                        $null = Set-ItemProperty -Path $registryPath -Name 'DEPTH' -Value 'MDER'
                    }
                }
            } 
        }
        catch {
            $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
            $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
            $status = $false;
        }

        ###### end new logic for DATT-like tags###############################################################

    }
    ###################### end new logic to write display name stuff ##########################################

    if (-not $NoEventLog.IsPresent) {
        # write to event log for AMA retrieval
        # note that max length is 32766 characters for the event log body
        try {
            $eventSource = 'DEPTH'
            $eventLog = 'System'
            $eventType = 'Information'
            $eventId = 5075
            $category = 0

            # create the log source if not exists
            if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
                New-EventLog -LogName $eventLog -Source $eventSource
            }

            # write the data to the event log
            foreach ($key in $dataElements.PSObject.Properties.Name) {
                if ($dataElements.$key) {
                    $element = 'DEPTH_' + $key
                    $data = @{
                        $element = $dataElements.$key
                    } | ConvertTo-Json -Depth 5 -Compress
                    $null = Write-EventLog -LogName $eventLog -Source $eventSource -EventId $eventId -EntryType $eventType -Message $data -Category $category
                }
            }
        }
        catch {
            $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
            $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
            $status = $false;
        }
    }

    if (-not $NoWindowsStoreApp.IsPresent) {
        # write the Windows Store Apps to the uninstall key for easy retrieval
        try {
            ###$null = Remove-DepthData -WindowsStoreApps | Out-Null

            ####Set all of the Windows Store tags that have DEPTH set to 'WindowsStoreApp' IsActive flag to false

            $null = Get-WSToFalse

            $windowsStoreApps = Get-WindowsStoreApp
            foreach ($windowsStoreApp in $windowsStoreApps) {
                $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + $windowsStoreApp.Name
                $registryValueName = "UninstallString"
                if (-not (Test-Path $registryPath)) {
                    $null = New-Item -Path $registryPath -Force
                }
                $installDate = $null
                $installTime = $null
                if ($windowsStoreApp.AddTimeStamp) {
                    try {
                        $date = [datetime]$windowsStoreApp.AddTimeStamp
                        $installDate = $date.ToString('yyyyMMdd')
                        $installTime = $date.ToString('hh:mm:ss tt') 
                    }
                    catch {
                        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
                        $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
                        $status = $false;
                    }
                }
                $value = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
                $registryValue = $value.$registryValueName
                $data = $windowsStoreApp.Name
                $Uninstall = $windowsStoreApp.CPE
                if ($registryValue -ne $Uninstall) {                
                    $null = Set-ItemProperty -Path $registryPath -Name 'DisplayName' -Value "$data-ws"
                    $null = Set-ItemProperty -Path $registryPath -Name 'DisplayVersion' -Value $windowsStoreApp.Version
                    $null = Set-ItemProperty -Path $registryPath -Name 'InstallDate' -Value $installDate
                    $null = Set-ItemProperty -Path $registryPath -Name 'InstallTime' -Value $installTime
                    $null = Set-ItemProperty -Path $registryPath -Name 'Publisher' -Value $windowsStoreApp.Vendor
                    $null = Set-ItemProperty -Path $registryPath -Name 'UninstallString' -Value $Uninstall
                    $null = Set-Itemproperty -Path $registryPath -Name 'DEPTH' -Value 'WindowsStoreApp'
                    $null = Set-ItemProperty -Path $registryPath -Name isActive -Value $true
                }
                else {
                    ## if nothing has changed then all we do is set the isActive back to true
                    $null = Set-ItemProperty -Path $registryPath -Name isActive -Value $true
                }
            }
        }
        catch {
            $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
            $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
            $status = $false;
        }

        ##Remove any Windows Store tags that are still set to false

        $null = Get-RemoveFalse      
    }
    if ( $status -eq $true) {
        return "DEPTH $version Success"
    }
    else {
        return "DEPTH $version Failure"
    }

}
function Get-WSToFalse {
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'
    $propertyName = "isActive"

    $DepthName = "DEPTH"
    $DepthValue = "WindowsStoreApp"

    $subKeys = Get-ChildItem -Path $registryPath -Recurse | ForEach-Object {
        $key = $_.PSPath
        $property = Get-ItemProperty -Path $key -Name $DepthName -ErrorAction SilentlyContinue
        if ($property -and $property.$DepthName -eq $DepthValue) {
            $key
        }
    }
    
    foreach ($subKey in $subKeys) {
        try {            
            ##if isActive already exists            
            Get-ItemProperty -Path $subKey -Name $propertyName -ErrorAction Stop            
            Set-ItemProperty -Path $subKey -Name isActive -Value $false        
        }        
        catch {            
            ##if isActive does not exists, create it and set it to false               
            New-ItemProperty -Path $subKey -Name isActive -Value $false -PropertyType DWord
        } 
    }
}

function Get-RemoveFalse {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"

    $DepthName = "DEPTH"
    $DepthValue = "WindowsStoreApp"

    $subKeys = Get-ChildItem -Path $registryPath -Recurse | ForEach-Object {
        $key = $_.PSPath
        $property = Get-ItemProperty -Path $key -Name $DepthName -ErrorAction SilentlyContinue
        if ($property -and $property.$DepthName -eq $DepthValue) {
            $key
        }
    }
    foreach ($subKey in $subKeys) {
        # Get the isActive property        
        try {            
            $isActiveValue = Get-ItemProperty -Path $subKey -Name isActive -ErrorAction SilentlyContinue            
            if ($isActiveValue.isActive -eq $false) {                
                # Delete the registry key                
                Remove-Item -Path $subKey -Recurse -Force                
                Write-Output "Deleted registry key: $($subKey)"            
            }        
        }        
        catch {            
            $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'            
            $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)            
            $log | Out-File -FilePath $logPath -Append            
            return @{'Error' = $log }        
        }    
    }
}

function Get-ValidDisplayNameString {
    param(
        [string]$tagType,
        [string]$FQHN,
        [string]$value
    )

    $totalDisplayNameCharacters = 256
    $totalLengthForDelimeters = 3 #3 for delimeters in the DisplayName string   : :;

    [string]$outputDisplayName = $tagType + ":" + $FQHN + ":;Invalid Error" 
      
    
    #Is the display name going to be larger than the character limit. Add 3 for delimeters in the string
    if ( ($tagType.Length + $FQHN.Length + $value.Length + $totalLengthForDelimeters) -gt $totalDisplayNameCharacters) {
        #The displayName will be too long need to remove characters
        
        #Check to make sure with the FQHN completely deleted it will be under the limit
        if ( ($tagType.Length + $value.Length + $totalLengthForDelimeters) -gt $totalDisplayNameCharacters) {
            #Even with removing the entire FQHN the DisplayName will still be too long

            #get total number of characters of what needs to be deleted from the tagName to get it under the character limit
            $totalToDelete = ($tagType.Length + $value.Length + $totalLengthForDelimeters) - $totalDisplayNameCharacters
                        
            if ($tagType.Length -gt $totalToDelete) {
                #remove the right most characters up to the total amount to delete. Account for index = 0
                $substring = $tagType.Substring(0, ($tagType.Length - $totalToDelete)) 

                #generate the displayName syntax without the FQHN and using the substring of the tagType
                $outputDisplayName = $substring + "::;" + $value
            }
            else {
                $outputDisplayName = $tagType + "::;Value too long"
            }
        }
        else {
            #Removing part or all of the FQHN will get it below the value.

            #get total number of characters of what needs to be deleted from the FQHN to get it under the character limit
            $totalToDelete = ($tagType.Length + $FQHN.Length + $value.Length + $totalLengthForDelimeters) - $totalDisplayNameCharacters
                        
            #remove the left most characters up to the total amount to delete. Start the substring index at the totalToDelete
            $substring = $FQHN.Substring($totalToDelete, ($FQHN.Length - $totalToDelete)) 

            #generate the displayName syntax using the substring of the FQHN
            $outputDisplayName = $tagType + ":" + $substring + ":;" + $value
        }
    }
    else {
        #DisplayName does not need any truncation
        $outputDisplayName = $tagType + ":" + $FQHN + ":;" + $value
    }

    return $outputDisplayName

}

function Get-ListeningProcess {
    try {
        $tcpListeners = Get-NetTCPConnection -State Listen | Select-Object -Unique -Property LocalPort, OwningProcess | Sort-Object LocalPort
        $listeningProcess = @()

        foreach ($tcpListener in $tcpListeners) {
            $processId = $tcpListener.OwningProcess
            $port = $tcpListener.LocalPort

            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

            if ($process) {
                $listeningProcess += [pscustomobject]@{
                    DisplayName = $process.ProcessName
                    Executable  = $process.Path
                    LocalPort   = $port
                }
            }
        }
		
        return $listeningProcess
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving listening process data" }
    }
}

function Get-LocalUserTag {
    try {
        $filter = @{
            LogName = 'Security'
            Id      = 4624
        }
        $lastLoginEvent = Get-WinEvent -FilterHashtable $filter | Select-Object -First 1

        $username = $env:USERNAME
        $loginTime = $lastLoginEvent.TimeCreated  

        $returnValue = Get-ValidDisplayNameString "lastuser.dod.mil" "Last User Login" "$username.$loginTime"
        return $returnValue
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "lastuser.dod.mil:Last User Login:;Invalid Error"

    }
}

function Get-Memory {
    try {
        $win32_physicalMemory = Get-CimInstance -ClassName win32_PhysicalMemory | Select-Object -Property SerialNumber, DeviceLocator, Capacity, Speed, ConfiguredClockSpeed, Manufacturer, MemoryType -ErrorAction Stop
        $memory = @()

        foreach ($node in $win32_physicalMemory) {
            switch ($node.MemoryType) {
                0 { $memoryType = 'Unknown' }
                1 { $memoryType = 'Other' }
                2 { $memoryType = 'DRAM' }
                3 { $memoryType = 'Synchronous DRAM' }
                4 { $memoryType = 'Cache DRAM' }
                5 { $memoryType = 'EDO' }
                6 { $memoryType = 'EDRAM' }
                7 { $memoryType = 'VRAM' }
                8 { $memoryType = 'SRAM' }
                9 { $memoryType = 'RAM' }
                10 { $memoryType = 'ROM' }
                11 { $memoryType = 'Flash' }
                12 { $memoryType = 'EEPROM' }
                13 { $memoryType = 'FEPROM' }
                14 { $memoryType = 'EPROM' }
                15 { $memoryType = 'CDRAM' }
                16 { $memoryType = '3DRAM' }
                17 { $memoryType = 'SDRAM' }
                18 { $memoryType = 'SGRAM' }
                19 { $memoryType = 'RDRAM' }
                20 { $memoryType = 'DDR' }
                21 { $memoryType = 'DDR2' }
                22 { $memoryType = 'DDR2 FB-DIMM' }
                23 { $memoryType = 'Unknown' }
                24 { $memoryType = 'DDR3' }
                25 { $memoryType = 'FBD2' }
                26 { $memoryType = 'DDR4' }
            }

            $memory += [pscustomobject]@{
                Size         = $node.Capacity
                Speed        = $node.ConfiguredClockSpeed
                SerialNumber = $node.SerialNumber
                Manufacturer = $node.Manufacturer
                MaxSpeed     = $node.Speed
                Type         = $memoryType
                Description  = $node.DeviceLocator
            }
        }

        return $memory
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving memory data" }
    }
}
function Get-MemoryTag {
    try {
        $win32_physicalMemory = Get-CimInstance -ClassName win32_PhysicalMemory | Select-Object -Property Capacity -ErrorAction Stop
        $total_memory = $win32_physicalMemory.Capacity
        $returnValue = Get-ValidDisplayNameString "memory.dod.mil" "Memory" $total_memory
        return $returnValue
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "memory.dod.mil:Memory:;Invalid Error"
    }
}
function Get-Network {
    try {
        $network = @()
        $physicalNicIfIndexes = (Get-NetAdapter).ifIndex
        $win32_NetworkAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.InterfaceIndex -in $physicalNicIfIndexes } | Select-Object * -ErrorAction Stop
        $win32_NetworkAdapterConfiguration = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Select-Object * -ErrorAction Stop
        $network = @()

        foreach ($networkAdapter in $win32_NetworkAdapter) {
            $networkAdapterConfiguration = $win32_NetworkAdapterConfiguration | Where-Object { $_.InterfaceIndex -eq $networkAdapter.InterfaceIndex }
            $ipAddress = $null
            $defaultGateway = $null
            $primaryDNS = $null

            if ($networkAdapterConfiguration.IPAddress) {
                $ipAddress = $networkAdapterConfiguration.IPAddress[0]
                $ipAddressV6 = $networkAdapterConfiguration.IPAddress[1]
            }
            if ($networkAdapterConfiguration.DefaultIPGateway) {
                $defaultGateway = $networkAdapterConfiguration.DefaultIPGateway[0]
            }
            if ($networkAdapterConfiguration.DNSServerSearchOrder) {
                $primaryDNS = $networkAdapterConfiguration.DNSServerSearchOrder[0]
                $secondaryDNS = $networkAdapterConfiguration.DNSServerSearchOrder[1]
            }
            if ($networkAdapterConfiguration.DNSHostName) {
                $dnsHostName = $networkAdapterConfiguration.DNSHostName
            }

            $network += [pscustomobject]@{
                Name           = $networkAdapter.Name
                Vendor         = $networkAdapter.Manufacturer
                Model          = $networkAdapter.ProductName
                DhcpEnabled    = $networkAdapterConfiguration.DHCPEnabled
                MacAddress     = $networkAdapter.MACAddress
                IPAddress      = $ipAddress
                IPAddressV6    = $ipAddressV6
                DnsPrimary     = $primaryDNS
                DnsSecondary   = $secondaryDNS
                DefaultGateway = $defaultGateway
                DnsServer      = $dnsHostName
                NetworkName    = $networkAdapterConfiguration.DNSDomain
            }
        }

        return $network
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving network data" }
    }
}
function Get-NetworkTag {
    try {
		
        $certUtilPath = "C:\Windows\System32\certutil.exe"

        if (Test-Path -Path $certUtilPath) {
            $out = & $certUtilPath -scinfo -silent
            $outSlice = $out -split "======================================================="

            if ($outSlice.Count -eq 0) {
                return "cn.dod.mil:Certificate Common Name:;Invalid: No cert found"
            }
            else {
                for ($i = 1; $i -lt $outSlice.Length; $i++) {
                    $certSlice = $outSlice[$i] -split "--------------===========================--------------"

                    $regex = [regex]::new("Subject:\s(CN=.+?),")
                    foreach ($cert in $certSlice) {
                        $subjectMatches = $regex.Match($cert)
                        if ($subjectMatches.Success) {
                            $cn = $subjectMatches.Groups[1].Value -split "CN="
                            $cn1 = $cn[1]
                            $returnValue = Get-ValidDisplayNameString "cn.dod.mil" "Certificate Common Name" $cn1
                            return $returnValue
                        }
                    }
                }
            }
        }

        return "cn.dod.mil:Certificate Common Name:;Invalid: Error"
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "cn.dod.mil:Certificate Common Name:;Invalid Error"
    }
}
function Get-OperatingSystem {
    try {
        $win32_operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property SerialNumber, OSArchitecture, Manufacturer, Caption, Version, BuildNumber, OperatingSystemSKU, OSProductSuite, Name, LastBootUpTime -ErrorAction Stop

        $supportPlan = 'Semi-Annual Channel'
        if ($win32_operatingSystem.Caption -like '*LTSB*') {
            $supportPlan = 'LTSB'
        }
        elseif ($win32_operatingSystem.Caption -like '*LTSC*') {
            $supportPlan = 'LTSC'
        }

        $captionArray = $win32_operatingSystem.Caption.Split(' ')
        if ($win32_operatingSystem.Caption.Contains('Server')) {
            $product = $captionArray[1] + '_' + $captionArray[2] + '_' + $captionArray[3]
        }

        else {
            $release = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).DisplayVersion
            $product = $captionArray[1] + '_' + $captionArray[2] + '_' + $release
        }

        $ubr = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).UBR
        $version = $win32_operatingSystem.Version + '.' + $ubr

        $cpe = ('cpe:/o:microsoft:' + $($product) + ':' + $($version)).ToLower()

        $operatingSystem = [pscustomobject]@{
            CPE             = $cpe
            Vendor          = $win32_operatingSystem.Manufacturer
            Name            = $win32_operatingSystem.Caption
            Version         = $win32_operatingSystem.Version
            Build           = $win32_operatingSystem.BuildNumber
            Architecture    = $win32_operatingSystem.OSArchitecture
            Edition         = $win32_operatingSystem.Caption
            SupportPlan     = $supportPlan
            CompositeName   = $win32_operatingSystem.Caption
            WindowsDeviceId = $win32_operatingSystem.SerialNumber
            SKU             = $win32_operatingSystem.OperatingSystemSKU
            ProductSuite    = $win32_operatingSystem.OSProductSuite
            SerialNumber    = $win32_operatingSystem.SerialNumber
            InstallDetails  = $win32_operatingSystem.Name
            Uptime          = ((Get-Date) - $win32_operatingSystem.LastBootUpTime).Days
        }

        return $operatingSystem
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving OS data" }
    }
}
function Get-OperatingSystemTag {
    try {
        $win32_operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption -ErrorAction Stop

        $osName = $win32_operatingSystem.Caption

        $returnValue = Get-ValidDisplayNameString "osedition.dod.mil" "OS Edition" $osName
        return $returnValue
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "osedition.dod.mil:OS Edition:;Error Name"
    }
}
function Get-Patch {
    try {
        $win32_quickFixEngineering = Get-CimInstance -ClassName Win32_QuickFixEngineering | Select-Object -Property Caption, Description, HotFixID, InstalledBy, InstalledOn -ErrorAction Stop
        $win32_OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption, Version
        $patches = @()
        $product = $win32_operatingSystem.Caption.Replace(' ', '_')
        $cpeStart = 'cpe:/o:microsoft:' + $($product) + ':' + $($win32_operatingSystem.Version) + ':'

        foreach ($quickFixEngineering in $win32_quickFixEngineering) {
            if ($quickFixEngineering.InstalledOn) {
                $installedOn = ($quickFixEngineering.InstalledOn).ToString().Split(' ')[0]
            }
            $patches += [pscustomobject]@{
                CPE         = ($cpeStart + $quickFixEngineering.HotFixID).ToLower()
                Vendor      = 'Microsoft'
                Version     = $win32_operatingSystem.Version
                HotFixID    = $quickFixEngineering.HotFixID
                URL         = $quickFixEngineering.Caption
                Description = $quickFixEngineering.Description
                InstalledBy = $quickFixEngineering.InstalledBy
                InstalledOn = $installedOn
            }
        }

        return $patches
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving patch data" }
    }
}
function Get-PhysicalDisk {
    try {
        $win32_diskDrive = Get-CimInstance -ClassName Win32_DiskDrive -KeyOnly -ErrorAction Stop
        $physicalDisk = @()
        foreach ($diskDrive in $win32_diskDrive) {
            $volumes = @()
            $freeSpace = 0
            $partitions = Get-CimAssociatedInstance -InputObject $diskDrive -ResultClassName win32_DiskPartition -KeyOnly -ErrorAction Stop
            foreach ($partition in $partitions) {
                $win32_logicalDisk = Get-CimAssociatedInstance -InputObject $partition -ResultClassName Win32_LogicalDisk -ErrorAction Stop
                foreach ($logicalDisk in $win32_logicalDisk) {
                    $freeSpace += $logicalDisk.FreeSpace
                    $volumes += [pscustomobject]@{
                        SerialNumber     = $logicalDisk.VolumeSerialNumber
                        SizeMB           = [math]::Round($($logicalDisk.Size / 1MB))
                        UsedSpaceMB      = [math]::Round($(($logicalDisk.Size - $logicalDisk.FreeSpace) / 1MB))
                        AvailableSpaceMB = [math]::Round($($logicalDisk.FreeSpace / 1MB))
                        Path             = $logicalDisk.DeviceID
                        MediaType        = $logicalDisk.Description
                    }
                }
            }
            $physicalDiskInstance = Get-CimInstance -InputObject $diskDrive | Select-Object -Property Index, Size, MediaType, Model, SerialNumber, DeviceId
            $physicalDisk += [pscustomobject]@{
                ID           = $physicalDiskInstance.DeviceID
                Size         = [math]::Round($($physicalDiskInstance.Size / 1MB), 0)
                UsedSpace    = [math]::Round($(($physicalDiskInstance.Size - $freeSpace) / 1MB))
                FreeSpace    = [math]::Round($($freeSpace / 1MB))
                MediaType    = $physicalDiskInstance.MediaType
                Model        = $physicalDiskInstance.Model
                SerialNumber = $physicalDiskInstance.SerialNumber
                Index        = $physicalDiskInstance.Index
                Volumes      = $volumes
            }
        }

        return $physicalDisk
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving physical disk data" }
    }
}
function Get-PhysicalDiskTag {
    try {
        $physicalDisk = Get-PhysicalDisk | Select-Object DeviceID, Size
        $sizeMBString = ($physicalDisk | Select-Object -ExpandProperty Size) -join ", "    
        $returnValue = Get-ValidDisplayNameString "bootdisksize.dod.mil" "Boot Disk Size" $sizeMBString    
        return $returnValue
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "bootdisksize.dod.mil:Boot Disk Size:;Invalid Error"
    }
}

function Get-Proxy {
    try {
        $proxyProperties = @()
        $browserProxy = @(
            @{
                Browser     = 'Edge'
                RegistryKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
                Type        = 'Chromium'
            }
            @{
                Browser     = 'Chrome'
                RegistryKey = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
                Type        = 'Chromium'
            }
            @{
                Browser     = 'Firefox'
                RegistryKey = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Proxy'
                Type        = 'Firefox'
            }
        )

        foreach ($currentBrowserProxy in $browserProxy) {
            switch ($currentBrowserProxy.Type) {
                'Chromium' {
                    $propertyJson = Get-ItemProperty -Path $currentBrowserProxy.RegistryKey -Name 'ProxySettings' -ErrorAction SilentlyContinue
                    if ($propertyJson) {
                        try {
                            $properties = $propertyJson.ProxySettings | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
                            $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
                            return $null
                        }

                        if ($properties) {
                            $proxyProperties += @{
                                Browser = $currentBrowserProxy.Browser
                                Mode    = $properties.ProxyMode
                                URL     = $properties.ProxyPacUrl
                            }
                        }
                    }
                }

                'Firefox' {
                    $properties = Get-ItemProperty -Path $currentBrowserProxy.RegistryKey -Name Mode, AutoConfigURL -ErrorAction SilentlyContinue
                    if ($properties) {
                        $proxyProperties += @{
                            Browser = $currentBrowserProxy.Browser
                            Mode    = $properties.Mode
                            URL     = $properties.AutoConfigURL
                        }
                    }
                }
            }
        }

        if ($proxyProperties) {
            return $proxyProperties
        }
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving proxy data" }
    }
}
function Get-RouteTable {
    try {
        $win32_ip4RouteTable = Get-CimInstance -ClassName Win32_IP4RouteTable | Select-Object -Property * | Sort-Object InterfaceIndex, Metric1 -ErrorAction Stop
        $routeTable = @()

        foreach ($route in $win32_ip4RouteTable) {
            $routeTable += [pscustomobject]@{
                Destination    = $route.Destination
                InterfaceIndex = $route.InterfaceIndex
                SubnetMask     = $route.Mask
                NextHop        = $route.NextHop
                Metric         = $route.Metric1
            }
        }

        return $routeTable
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving route table data" }
    }
}
function Get-SecurityProduct {
    try {
        $mpComputerStatus = Get-MpComputerStatus
        $firewallStatus = Get-NetFirewallProfile | Select-Object -Property Name, Enabled
        $bitlocker = Get-BitLockerVolume | Select-Object -Property MountPoint, VolumeStatus, VolumeType, ProtectionStatus

        $dateProperties = @(
            'AntivirusSignatureLastUpdated'
            'FullScanEndTime'
            'NISSignatureLastUpdated'
            'QuickScanEndTime'
            'QuickScanStartTime'
        )
        foreach ($dateProperty in $dateProperties) {
            if ($mpComputerStatus.$dateProperty) {
                New-Variable -Name $dateProperty -Value $mpComputerStatus.$dateProperty.ToString()
            }
        }

        #region Antimalware
        $mdavStatus = 'Not Running'
        if ($mpComputerStatus.AntivirusEnabled) {
            $mdavStatus = 'Running'
        }
        if ($mpComputerStatus.AmRunningMode -eq 'Normal') {
            $antiMalware = [pscustomobject]@{
                Name             = 'Microsoft Defender Antivirus'
                Status           = $mdavStatus
                SignatureUpdate  = $AntivirusSignatureLastUpdated
                SignatureVersion = $mpComputerStatus.AntivirusSignatureVersion
                OnAccessScan     = $mpComputerStatus.OnAccessProtectionEnabled
                LastFullScan     = $FullScanEndTime
                CloudEnabled     = $mpComputerStatus.RealTimeProtectionEnabled
            }
        }
        else {
            # McAfee/Trellix checks
            $antiVirusProduct = Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct | Where-Object { $_.displayName -ne 'Windows Defender' }
            if ($antiVirusProduct) {
                $mcafeePath = 'HKLM:\SOFTWARE\McAfee\AVSolution\AVSolutionSettings'
                if (Test-Path -Path $mcafeePath) {
                    $mcafeeSignatureUpdate = (Get-ItemProperty 'HKLM:\SOFTWARE\McAfee\AVSolution\AVSolutionSettings').DATDate
                    $mcafeeSignatureVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\McAfee\AVSolution\AVSolutionSettings').DATVersion
                    $mcafeeOnAccessScan = Get-CimInstance -Namespace 'root\cimv2\applications\mfe' -ClassName 'MFE_RealTimeScannerSettings' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty enabled -ErrorAction SilentlyContinue
                    $mcafeeLastFullScan = Get-CimInstance -Namespace 'root\cimv2\applications\mfe' -ClassName 'MFE_FullScanReport' -ErrorAction SilentlyContinue | Sort-Object StartTime -Descending | Select-Object -First 1 -ExpandProperty StartTime
                    $mcafeeCloudEnabled = Get-CimInstance -Namespace 'root\cimv2\applications\mfe' -ClassName 'MFE_CloudProtection' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CloudEnabled
                }
                $antiMalware = [pscustomobject]@{
                    Name             = $antiVirusProduct.displayName
                    Status           = 'Running'
                    SignatureUpdate  = $mcafeeSignatureUpdate
                    SignatureVersion = $mcafeeSignatureVersion
                    OnAccessScan     = $mcafeeOnAccessScan
                    LastFullScan     = $mcafeeLastFullScan
                    CloudEnabled     = $mcafeeCloudEnabled
                }
            }
        }
        #endregion

        #region HostFirewall
        $firewall = Get-Service -Name 'MpsSvc' -ErrorAction SilentlyContinue
        if ($firewall) {
            $firewallServiceStatus = $firewall.Status.ToString()
            $hostFirewall = [pscustomobject]@{
                Name                   = 'Windows Firewall'
                Status                 = $firewallServiceStatus
                DomainProfileEnabled   = ($firewallStatus | Where-Object { $_.Name -eq 'Domain' }).Enabled.ToString()
                PublicProfileEnabled   = ($firewallStatus | Where-Object { $_.Name -eq 'Private' }).Enabled.ToString()
                StandardProfileEnabled = ($firewallStatus | Where-Object { $_.Name -eq 'Public' }).Enabled.ToString()
            }
        }
        else {
            # McAfee/Trellix checks
        }
        #endregion

        #region DLP
        $blockUsbPolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices'
        $blockUsbPolicyDenyAll = Get-ItemProperty -Path $blockUsbPolicyPath -Name 'Deny_All' -ErrorAction SilentlyContinue
        if ($blockUsbPolicyDenyAll.Deny_All -eq 1) {
            $dlp = [pscustomobject]@{
                Name     = 'Removable Storage Registry Policy'
                Status   = 'Enabled'
                Blocking = 'Deny All'
            }
        }
        elseif ($mpComputerStatus.DeviceControlState -eq 'Enabled') {
            $dlp = [pscustomobject]@{
                Name     = 'Defender Device Control'
                Status   = 'Enabled'
                Blocking = $mpComputerStatus.DeviceControlDefaultEnforcement
            }
        }
        else {
            # McAfee/Trellix checks
        }
        #endregion

        #region Application Control
        $win32_DeviceGuard = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName 'Win32_DeviceGuard' | Select-Object -Property CodeIntegrityPolicyEnforcementStatus, UsermodeCodeIntegrityPolicyEnforcementStatus
        $applockerExe = (Get-AppLockerPolicy -Effective).RuleCollections | Select-Object -Property RuleCollectionType, EnforcementMode | Where-Object { $_.RuleCollectionType -eq 'Exe' }
        $applockerMsi = (Get-AppLockerPolicy -Effective).RuleCollections | Select-Object -Property RuleCollectionType, EnforcementMode | Where-Object { $_.RuleCollectionType -eq 'Msi' }
        if ($win32_DeviceGuard.CodeIntegrityPolicyEnforcementStatus -eq 2 -or $win32_DeviceGuard.UsermodeCodeIntegrityPolicyEnforcementStatus -eq 2) {
            $appControl = [pscustomobject]@{
                Name                = 'Windows Defender Application Control'
                Status              = 'Enabled'
                EnforceInstallation = 'Enforced'
                EnforceExecution    = 'Enforced'
            }
        }
        elseif ($applockerExe.EnforcementMode) {
            if ($applockerExe.EnforcementMode -ne 'NotConfigured') {
                $appControl = [pscustomobject]@{
                    Name                = 'AppLocker'
                    Status              = 'Enabled'
                    EnforceInstallation = $applockerMsi.EnforcementMode.ToString()
                    EnforceExecution    = $applockerExe.EnforcementMode.ToString()
                }
            }
        }
        else {
            # McAfee/Trellix checks
        }
        #endregion

        #region Patch and SW Deployment
        $imeService = Get-Service -Name 'IntuneManagementExtension' -ErrorAction SilentlyContinue
        $ccm_SoftwareUpdate = Get-CimInstance -Namespace 'ROOT\CCM\ClientSDK' -ClassName CCM_SoftwareUpdate -ErrorAction SilentlyContinue | Select-Object -Property LocalizedDisplayName, ComplianceState, LastEnforcementMessageID, ArticleID, LastStatusCheckTime
        if ($imeService) {
            $patchSwDeployment = @{
                Name   = 'Intune'
                Status = $imeService.Status.ToString()
            }
        }
        elseif ($ccm_SoftwareUpdate) {
            $ccm_Client = Get-CimInstance -Namespace 'ROOT\CCM' -ClassName CCM_Client -ErrorAction SilentlyContinue | Select-Object -Property LastMPServerCommunicationTime
            $patchSwDeployment = @{
                Name        = 'Microsoft Configuration Manager'
                Status      = 'Running'
                LastCheckin = $ccm_Client.LastMPServerCommunicationTime
            }
        }
        #endregion

        #region Drive Encryption
        $driveEncryption = @()
        foreach ($drive in $bitlocker) {
            $driveEncryption += [pscustomobject]@{
                DriveIdentifier     = $drive.MountPoint.ToString()
                EncryptionStatus    = $drive.VolumeStatus.ToString()
                BootDriveDesignator = $drive.VolumeType.ToString()
                Enabled             = $drive.ProtectionStatus.ToString()
            }
        }
        #endregion

        $securityProducts = [pscustomobject]@{
            MicrosoftDefenderInfo   = [pscustomobject]@{
                AntiMalwareName                              = 'Microsoft Defender Antivirus'
                AntiMalwareEngineVersion                     = $mpComputerStatus.AMEngineVersion
                AntiMalwareProductVersion                    = $mpComputerStatus.AMProductVersion
                AntiMalwareRunningMode                       = $mpComputerStatus.AMRunningMode
                AntiMalwareServiceEnabled                    = $mpComputerStatus.AMServiceEnabled
                AntiMalwareServiceVersion                    = $mpComputerStatus.AMServiceVersion
                AntivirusEnabled                             = $mpComputerStatus.AntivirusEnabled
                AntivirusSignatureLastUpdated                = $AntivirusSignatureLastUpdated
                AntivirusSignatureVersion                    = $mpComputerStatus.AntivirusSignatureVersion
                FullScanEndTime                              = $FullScanEndTime
                IOfficeAntivirusProtectionEnabled            = $mpComputerStatus.IoavProtectionEnabled
                NetworkInspectionServiceEnabled              = $mpComputerStatus.NISEnabled
                NetworkInspectionServiceEngineVersion        = $mpComputerStatus.NISEngineVersion
                NetworkInspectionServiceSignatureLastUpdated = $NISSignatureLastUpdated
                NetworkInspectionServiceSignatureVersion     = $mpComputerStatus.NISSignatureVersion
                OnAccessProtectionEnabled                    = $mpComputerStatus.OnAccessProtectionEnabled
                QuickScanEndTime                             = $QuickScanEndTime
                QuickScanSignatureVersion                    = $mpComputerStatus.QuickScanSignatureVersion
                QuickScanStartTime                           = $QuickScanStartTime
                RealTimeProtectionEnabled                    = $mpComputerStatus.RealTimeProtectionEnabled
                TamperProtectionSource                       = $mpComputerStatus.TamperProtectionSource
                DeviceControlStatus                          = $mpComputerStatus.DeviceControlState
            }
            AntiMalware             = $antiMalware
            HostFirewall            = $hostFirewall
            DLP                     = $dlp
            ApplicationWhitelisting = $appControl
            PatchSWDeployment       = $patchSwDeployment
            DriveEncryption         = $driveEncryption
        }

        return $securityProducts
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving security product data" }
    }
}
function Get-SecurityProductTag {
    try {

        $registryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Features'
        $valueName = 'DeviceControlEnabled'
        if (Test-Path $registryPath) {
            $value = Get-ItemPropertyValue -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
            if ($null -ne $value) {
                if ($value -eq 1) {
                    return "winregdlp.dod.mil:Windows DLP Status:;enforced"
                }
                elseif ($value -ne 1) {
                    return "winregdlp.dod.mil:Windows DLP Status:;not enforced"
                }
                else {
                    return "winregdlp.dod.mil:Windows DLP Status:;does not exist"
                }
            }
            else {
                return "winregdlp.dod.mil:Windows DLP Status:;does not exist"
            }
        }
        else {
            return "winregdlp.dod.mil:Windows DLP Status:;does not exist"
        }
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "winregdlp.dod.mil:;Invalid Error"
    }
}
function Get-System {
    Import-Module PKI
    try {
        $win32_baseBoard = Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -Property SerialNumber, Manufacturer, Model, Product -ErrorAction Stop
        $win32_computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Name, DNSHostName, Domain, Model, DomainRole -ErrorAction Stop

        $uniqueProperties = @(
            'SerialNumber'
            'Manufacturer'
            'Product'
        )
        $uniqueString = ''
        foreach ($uniqueProperty in $uniqueProperties) {
            $uniqueString += $($win32_baseBoard.$uniqueProperty)
        }
        $uniqueString += $(Get-CimInstance Win32_ComputerSystemProduct -Property 'UUID').UUID
        $systemGUID = New-DeterministicGuid -UniqueString $uniqueString

        $virtualizationStatus = 'False'
        $domainType = 'FQDN'
        if ($win32_computerSystem.Model -like '*Virtual*') {
            $virtualizationStatus = 'True'
        }
        if ($Win32_ComputerSystem.Domain -eq 'WORKGROUP') {
            $domainType = 'NETBIOS'
        }

        switch ($win32_computerSystem.DomainRole) {
            0 { $domainRole = 'Standalone Workstation' }
            1 { $domainRole = 'Member Workstation' }
            2 { $domainRole = 'Standalone Server' }
            3 { $domainRole = 'Member Server' }
            4 { $domainRole = 'Backup Domain Controller' }
            5 { $domainRole = 'Primary Domain Controller' }
            default { $domainRole = 'Unknown' }
        }

        if ($win32_computerSystem.DomainRole -in (5, 6)) {
            try {
                $managedDomains = (Get-ADForest).Domains
            }
            catch {
                $managedDomains = $null
            }
        }

        $dnsServer = $false
        $dnsService = Get-Service -Name 'DNS' -ErrorAction SilentlyContinue

        # Check if the service exists and is running
        if ($dnsService -and $dnsService.Status -eq 'Running') {
            $dnsServer = $true
        }

        try {
            $aadDeviceId = $(Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Issuer -like '*CN=MS-Organization-Access*' }).Subject.Replace('CN=', '')
        }
        catch {
            $aadDeviceId = $null
        }

        $intuneDeviceIdRegPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\Diagnostics\Autopilot\EstablishedCorrelations'
        $intuneDeviceIdValueName = 'EntDMID'
        $intuneDeviceId = [Microsoft.Win32.Registry]::GetValue($intuneDeviceIdRegPath, $intuneDeviceIdValueName, $null)

        $mdeDeviceIdRegPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Advanced Threat Protection'
        $mdeDeviceIdValueName = 'senseId'
        $mdeDeviceId = [Microsoft.Win32.Registry]::GetValue($mdeDeviceIdRegPath, $mdeDeviceIdValueName, $null)

        $system = [pscustomobject]@{
            DeviceName               = $win32_computerSystem.Name
            SystemGUID               = $systemGUID
            FQDN                     = $win32_computerSystem.DNSHostName
            Domain                   = $Win32_ComputerSystem.Domain
            DomainType               = $domainType
            DomainRole               = $domainRole
            DomainManagedDomains     = $managedDomains
            DNSServer                = $dnsServer
            MotherBoardSerialNumber  = $win32_baseBoard.SerialNumber
            MotherBoardManufacturer  = $win32_baseBoard.Manufacturer
            MotherBoardModel         = $win32_baseBoard.Product
            SystemDescription        = $win32_computerSystem.Model
            IsVirtualMachine         = $virtualizationStatus
            USCYBERCOMClassification = 'Workstations and Servers'
            AadDeviceId              = $aadDeviceId
            IntuneDeviceId           = $intuneDeviceId
            MdeDeviceId              = $mdeDeviceId
        }

        return $system
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving system data" }
    }
}
function Get-SystemTag {
    try {
        $hostname = [System.Environment]::MachineName
        $returnValue = Get-ValidDisplayNameString "hostname.dod.mil" "Hostname" $hostname
        return $returnValue
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "hostname.dod.mil:Hostname:;Invalid Error"
    }
}
function Get-OSLTSTag {

    $win32_operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption

    try {
        $supportPlan = 'Not Applicable'
        if ($win32_operatingSystem.Caption -like '*LTSB*') {
            $supportPlan = 'LTSB'
        }
        elseif ($win32_operatingSystem.Caption -like '*LTSC*') {
            $supportPlan = 'LTSC'
        }
        $returnValue = Get-ValidDisplayNameString "oslts.dod.mil" "OS LTSC LTSB" $supportPlan
        return $returnValue
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "oslts.dod.mil:OS LTSC LTSB:;Invalid Error"
    }

}

function Get-SNTag {
    $win32_operatingSystem = Get-CimInstance -ClassName Win32_BIOS | Select-Object -Property SerialNumber
    try {
        $SN = $win32_operatingSystem.SerialNumber
        $returnValue = Get-ValidDisplayNameString "serialnumber.dod.mil" "Serial Number" $SN
        return $returnValue

    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "serialnumber.dod.mil:Serial Number:;Invalid Error"
    }
}

function Get-UIDTag {
    try {
        $UID += $(Get-CimInstance Win32_ComputerSystemProduct -Property 'UUID').UUID
        $returnValue = Get-ValidDisplayNameString "uid.dod.mil" "Device Unique Identifier" $UID
        return $returnValue

    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "uid.dod.mil:Device Unique Identifier:;Invalid Error"
    }
}

function Get-TpmInfo {
    try {
        $tpm = Get-Tpm
        $tpmExists = $tpm.TpmPresent

        if ($tpmExists) {
            $tpmEndorsementKeyInfo = Get-TpmEndorsementKeyInfo -HashAlgorithm 'Sha256'
            $tpmPublicKey = $tpmEndorsementKeyInfo.PublicKey
            $tpmPublicKeyFormatted = $($tpmPublicKey.Format($true))
            $tpmPublicKeyHash = $tpmEndorsementKeyInfo.PublicKeyHash
            $tpmVersion = $($tpm.ManufacturerVersion) -replace '\x00', ''
        }

        $win32_tpm = Get-CimInstance -Namespace 'Root\CIMv2\Security\MicrosoftTpm' -ClassName Win32_Tpm | Select-Object -Property PhysicalPresenceVersionInfo, SpecVersion

        $tpmInfo = [pscustomobject]@{
            ManufacturerId             = $tpm.ManufacturerId
            TpmManufacturerVersion     = $tpmVersion
            TpmManufacturerVersionInfo = $tpm.ManufacturerIdTxt
            TpmPhysicalPresenceVersion = $win32_tpm.PhysicalPresenceVersionInfo
            TpmSpecVersion             = $win32_tpm.SpecVersion
            TpmIsActivated             = $tpm.TpmActivated
            TpmIsEnabled               = $tpm.TpmEnabled
            TpmIsOwned                 = $tpm.TpmOwned
            TpmEkPublicKey             = $tpmPublicKeyFormatted
            TpmEkPublicKeyHash         = $tpmPublicKeyHash
        }

        return $tpmInfo
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving TPM data" }
    }
}
function Get-TpmInfoTag {
    try {

        $output = Get-WmiObject -Namespace "root\cimv2\security\microsofttpm" -Query "Select SpecVersion from win32_tpm" | Select-Object -ExpandProperty SpecVersion

        # Check if the output is not empty
        if ([string]::IsNullOrWhiteSpace($output)) {
            return "tpmversion.dod.mil:TPM Specification Version:;No TPM Present"
        }
        else {
            $returnValue = Get-ValidDisplayNameString "tpmversion.dod.mil" "TPM Specification Version" $output
            return $returnValue
        }
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return "tpmversion.dod.mil:TPM Specification Version:;Invalid Error"
    }
}
function Get-USB {
    try {
        $win32_usbDevice = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object -Property @{Name = 'UsbDeviceId'; Expression = { $_.DeviceId } }, @{Name = 'UsbName'; Expression = { $_.Name } } | Where-Object { $_.UsbDeviceId.StartsWith('USB\') } -ErrorAction Stop
        return $win32_usbDevice
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving USB data" }
    }
}
function Get-WindowsOptionalFeature {
    try {
        $commandAvailable = Get-Command -Name Get-WindowsFeature -ErrorAction SilentlyContinue
        if ($commandAvailable) {
            $versions = Get-WindowsFeature | Where-Object { $_.Installed -and $_.AdditionalInfo.MajorVersion -ne 0 } | Select-Object -Property @{name = 'Name'; expression = { $_.AdditionalInfo.InstallName } }, @{name = 'Version'; expression = { '{0}.{1}' -f $_.AdditionalInfo.MajorVersion, $_.AdditionalInfo.MinorVersion } } -ErrorAction SilentlyContinue
        }
        $win32_optionalFeature = Get-CimInstance -Class Win32_OptionalFeature | Select-Object -Property InstallState, Name, Caption, InstallDate | Where-Object { $_.InstallState -eq 1 } -ErrorAction Stop
        $windowsOptionalFeatures = @()

        foreach ($windowsOptionalFeature in $win32_optionalFeature) {
            $state = 'Unknown'
            switch ($windowsOptionalFeature.InstallState) {
                1 { $state = 'Enabled' }
                2 { $state = 'Disabled' }
                3 { $state = 'Absent' }
            }
            $version = $versions | Where-Object { $_.Name -eq $windowsOptionalFeature.Name }
            $windowsOptionalFeatures += [pscustomobject]@{
                Vendor      = 'Microsoft'
                Name        = $windowsOptionalFeature.Name
                Version     = $version.Version
                DisplayName = $windowsOptionalFeature.Caption
                InstallTime = $windowsOptionalFeature.InstallDate
                State       = $state
            }
        }

        return $windowsOptionalFeatures
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error retrieving Win optional features data" }
    }
}
function Get-WindowsStoreApp {
    try {
        $appxPackages = Get-AppxPackage -AllUsers | Select-Object -Property Name, Publisher, Version, InstallLocation
        $windowsStoreApps = @()

        foreach ($appxPackage in $appxPackages) {
            if ($appxPackage.Publisher -match 'O=([^,]+)') {
                $vendor = $matches[1]
            }
            else {
                $vendor = $appxPackage.Publisher
            }
            $cpe = ('cpe:/a:' + $($vendor) + ':' + $($appxPackage.Name) + ':' + $($appxPackage.Version)).ToLower().Replace(' ', '_')
            if ($appxPackage.InstallLocation) {
                $executable = Get-Item $appxPackage.InstallLocation
                if ($executable.LastWriteTime) {
                    $installDate = $executable.LastWriteTime.ToString()
                }
                if ($executable.LastAccessTime) {
                    $lastUsed = $executable.LastAccessTime.ToString()
                }
            }
            $windowsStoreApps += [pscustomobject]@{
                CPE          = $cpe
                Vendor       = $vendor
                Name         = $appxPackage.Name
                Version      = $appxPackage.Version
                AddTimeStamp = $installDate
                InstallPath  = $appxPackage.InstallLocation
                LastUsed     = $lastUsed
            }
        }

        return $windowsStoreApps
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
    }
}
function New-DeterministicGuid {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Creates in-memory object only.'
    )]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$UniqueString
    )
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($UniqueString)
        $sha1CryptoServiceProvider = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
        $hashedBytes = $sha1CryptoServiceProvider.ComputeHash($bytes)
        [System.Array]::Resize([ref]$hashedBytes, 16);
        return New-Object System.Guid -ArgumentList @(, $hashedBytes)
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $(Get-Date).ToString() + ':' + $($_ | Out-String) | Out-File -FilePath $logPath -Append
        return $null
    }
}
function Remove-DEPTHData {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter()]
        [Switch]$MDER,
        [Parameter()]
        [Switch]$WindowsStoreApps
    )
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    try {
        $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $subKeys = Get-ChildItem -Path $regPath
        foreach ($subKey in $subKeys) {
            $depthValue = Get-ItemProperty -Path $subKey.PSPath -Name 'DEPTH' -ErrorAction SilentlyContinue
            if ($MDER.IsPresent) {
                if ($depthValue.DEPTH -eq 'MDER') {
                    Remove-Item -Path $subKey.PSPath -Recurse -Force
                }
            }
            if ($windowsStoreApps.IsPresent) {
                if ($depthValue.DEPTH -eq 'WindowsStoreApp') {
                    Remove-Item -Path $subKey.PSPath -Recurse -Force
                }
            }
        }
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $(Get-Date).ToString() + ':' + $($_ | Out-String) + $windowsStoreApp.Name | Out-File -FilePath $logPath -Append
    }
}
function Get-TruncatedJsonString {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $jsonObject
    )
	
    $characterLimit = 12187 #Character limit for uninstall registry value
    $truncationMessage = "..." #message that replaces any data that is truncated to alert users to the truncation

    try {
		
        if ($jsonObject.Length -gt $characterLimit) {
            $totalToTruncateCounter = $jsonObject.Length - $characterLimit
						
            #convert from JSON object to Powershell Object to better traverse
            $truncatedJsonObject = ConvertFrom-Json -InputObject $jsonObject
			
            #call recursive method
            Get-TruncatedJsonProperty -pwrShellObject $truncatedJsonObject -totalToDelete $totalToTruncateCounter -truncationMessage $truncationMessage	
			
            #convert back to JSON object
            $truncatedJson = ConvertTo-Json -InputObject $truncatedJsonObject -Compress -Depth 5 
			
            #check to make sure the truncation was successful, if not return error instead of JSON that is too long
            if ($truncatedJson.Length -gt $characterLimit) {
                $truncatedJsonObject = @{'Error' = "Unable to properly truncate JSON. Value still too large." }
                $truncatedJson = ConvertTo-Json -InputObject $truncatedJsonObject -Compress -Depth 5
            }
			
            return $truncatedJson
        }
        else {
            return $jsonObject;
        }		
        
    }
    catch {
        $logPath = Join-Path -Path $env:Temp -ChildPath 'DEPTH.log'
        $log = $(Get-Date).ToString() + ':' + $($_ | Out-String)
        $log | Out-File -FilePath $logPath -Append
        return @{'Error' = "Error truncating JSON" } | ConvertTo-Json -Depth 5 -Compress
    }
}
function Get-TruncatedJsonProperty {
    Param(
        $pwrShellObject,
        [int]$totalToDelete,
        [string]$truncationMessage				
    )			
			
    if ($totalToDelete -gt 0) {
        if ($pwrShellObject -is [PSCustomObject] -or $pwrShellObject -is [System.Collections.Hashtable]) {
            #iterate through properties
            foreach ($property in $pwrShellObject.PSObject.Properties) {
                if ($property.Value -is [string] -and $totalToDelete -gt 0) {
                    $truncatedValue = $property.Value
                    #the value needs to have atleast one more character than the truncationn message to make truncating worth it. Otherwise replacing characters with the truncation message.
                    if ($truncatedValue.Length -gt $truncationMessage.Length) {
                        if ($truncatedValue.Length -gt $totalToDelete + $truncationMessage.Length) {
                            #The value is longer than what needs to be removed. 
                            #Get a substring of the value. make sure to subtract the message length as well so it doesn't put it back over the limit.
                            $truncatedValue = $truncatedValue.Substring(0, $truncatedValue.Length - $totalToDelete - $truncationMessage.Length) + $truncationMessage
                            $totalToDelete = 0
                        }
                        else {
                            #the entire value will be removed and replaced with the truncation message
                            #figure out how much will be deleted so it can be removed from the counter
                            $amountDeleted = $truncatedValue.Length - $truncationMessage.Length
                            $truncatedValue = $truncationMessage
                            $totalToDelete = $totalToDelete - $amountDeleted
                        }	
                        #save the truncatedValue back into the Property
                        $property.value = $truncatedValue
                    }							
                }
                #recursively process nested objects or arrays
                if ($property.Value -is [PSCustomObject] -or $property.Value -is [System.Collections.Hashtable] -or $property.Value -is [Array]) {
                    Get-TruncatedJsonProperty -pwrShellObject $property.Value -totalToDelete $totalToDelete -truncationMessage $truncationMessage
                }
            }
        }
        elseif ($pwrShellObject -is [Array]) {
            #if the object is an array, iterate through elements
            foreach ($element in $pwrShellObject) {
                #recursively process elements 
                Get-TruncatedJsonProperty -pwrShellObject $element -totalToDelete $totalToDelete -truncationMessage $truncationMessage
            }
        }
    }

            
}


#    MIT License
#
#    Copyright (c) Microsoft Corporation.
#
#    Permission is hereby granted, free of charge, to any person obtaining a copy
#    of this software and associated documentation files (the Software), to deal
#    in the Software without restriction, including without limitation the rights
#    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#    copies of the Software, and to permit persons to whom the Software is
#    furnished to do so, subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be included in all
#    copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#    SOFTWARE


# SIG # Begin signature block
# MIIkJgYJKoZIhvcNAQcCoIIkFzCCJBMCAQExDzANBglghkgBZQMEAgMFADCBmwYK
# KwYBBAGCNwIBBKCBjDCBiTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63
# JNLGKX7zUQIBAAIBAAIBAAIBAAIBADBRMA0GCWCGSAFlAwQCAwUABEBksZpRWuvO
# wNmUvpv78VXfwslJXzAAkbaI36Y0aBCmrsj3Y62C8e2xPoDd1pJdKzE0sqPoHRZP
# gsNK9mlZv/y3oIIJcDCCBI8wggN3oAMCAQICAgcNMA0GCSqGSIb3DQEBCwUAMFsx
# CzAJBgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQxDDAKBgNVBAsT
# A0RvRDEMMAoGA1UECxMDUEtJMRYwFAYDVQQDEw1Eb0QgUm9vdCBDQSAzMB4XDTIy
# MTIwNjE3MTM0OVoXDTI4MTIwNjE3MTM0OVowWjELMAkGA1UEBhMCVVMxGDAWBgNV
# BAoTD1UuUy4gR292ZXJubWVudDEMMAoGA1UECxMDRG9EMQwwCgYDVQQLEwNQS0kx
# FTATBgNVBAMTDERPRCBTVyBDQS03NTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAKZwD1SZnE8Nf3BkcBIb8+EK0936NHw7gLL9EN83mwwwJEfxOtoyYLSm
# fm5KyCUUbXHRgOayqP+lXgFI9/99M0UxNjQ9IrfFMuv5X1KVJm59BnwThMYjowGf
# NZx70sFsU6TpQuRGl453fgLYzg5RA8P1MB7J7EFDY/PzSSiRMTLoEHsi5+YzT2b5
# 6H9azywJN0o778E8V/pMVpskMqkAzcSFSmoy4AaREzXpsRaJwxY7cGY/DvDHsPVX
# UvtwkzWS87/SY7mKPAyPQ0mqcByC8lkBkFBO+gyqD8vAqPT0vXDentjOaVok5rcs
# dVx15qZkl+49ylHdwfcl5jJx3Xp3dGMCAwEAAaOCAVwwggFYMB8GA1UdIwQYMBaA
# FGyKlKJ3sYByHYF6Fqry3M5m7kXAMB0GA1UdDgQWBBToWK6zR627Ud4gDYfzFeTq
# PryLOjAOBgNVHQ8BAf8EBAMCAYYwPQYDVR0gBDYwNDALBglghkgBZQIBCyQwCwYJ
# YIZIAWUCAQsnMAsGCWCGSAFlAgELKjALBglghkgBZQIBCzswEgYDVR0TAQH/BAgw
# BgEB/wIBADAMBgNVHSQEBTADgAEAMDcGA1UdHwQwMC4wLKAqoCiGJmh0dHA6Ly9j
# cmwuZGlzYS5taWwvY3JsL0RPRFJPT1RDQTMuY3JsMGwGCCsGAQUFBwEBBGAwXjA6
# BggrBgEFBQcwAoYuaHR0cDovL2NybC5kaXNhLm1pbC9pc3N1ZWR0by9ET0RST09U
# Q0EzX0lULnA3YzAgBggrBgEFBQcwAYYUaHR0cDovL29jc3AuZGlzYS5taWwwDQYJ
# KoZIhvcNAQELBQADggEBADIIgI9eFJBbHLGTCRHhrCFubfDGzcvcW7L4wjKTqrAJ
# nBB6JaEbkTWqz3rKEIcpM9Jh8mk5jFF7Bo3zeKEP4By5/hdZN2fjh8aPg50j08zk
# 0lIISpyheVFKzw6uiXSHy41qz2y7j0ii8SZT6jBNavetvqpfn+TIOcPQngYtTkSc
# p5F/8s999rMnQoENxpC8/GEcr2R+Sa3YOrw0K+KhTLdpJgVCFqu1AyPxtX5lCO0O
# 0e6rH58h4ajnVDQTYorPMqKHu4UQZdE2iIjQpiLTBWk5ext/GSPIC9qawBjRyE6U
# 422lq5QtgmAoLQqFqBppTapWAf6j4Ar5OdLEr8RS+3UwggTZMIIDwaADAgECAgMA
# 464wDQYJKoZIhvcNAQELBQAwWjELMAkGA1UEBhMCVVMxGDAWBgNVBAoTD1UuUy4g
# R292ZXJubWVudDEMMAoGA1UECxMDRG9EMQwwCgYDVQQLEwNQS0kxFTATBgNVBAMT
# DERPRCBTVyBDQS03NTAeFw0yNTA1MjgxNjIyMDlaFw0yODEyMDYxNzEzNDlaMHAx
# CzAJBgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQxDDAKBgNVBAsT
# A0RvRDEMMAoGA1UECxMDUEtJMQ0wCwYDVQQLEwRESVNBMRwwGgYDVQQDExNDUy5E
# SVNBLklEMy4wOC0wMDQzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# 0jDgaqnUxB/76bGuNhIp2fVOxYo8F9JRp4LHCapop/30rSuG/DTGQ7tTjpkl2oFj
# 19G7WinF1ZJgQkTK1iEiZM0rJll0jI1B5kFjr1+xNC/Ga9uIlgZqEPAzYwrjJ5Z6
# ljN+VNvfOggc98kwh+uCQKVhvnvK3qdKpMLiqnlaWSkza/VDzUlzGvK+lTl0dgy6
# doZXL7Iq2mgYuL7mFugzKx7KEnB3xMSyCqAURD4WJRQpg0K3wJOYFe8LND5wfUVL
# c4eQygL+g3J9sVOG2LUzfvByS1oLK6aR3Z23oCs7oRBRqtWJRmJ8KL5AmoPkjT5S
# 0/8dyS/c69ImIPje2MomtwIDAQABo4IBkDCCAYwwHwYDVR0jBBgwFoAU6Fius0et
# u1HeIA2H8xXk6j68izowHQYDVR0OBBYEFEU6Q+EQ3Ut4BxBet1S28gugApcOMGUG
# CCsGAQUFBwEBBFkwVzAzBggrBgEFBQcwAoYnaHR0cDovL2NybC5kaXNhLm1pbC9z
# aWduL0RPRFNXQ0FfNzUuY2VyMCAGCCsGAQUFBzABhhRodHRwOi8vb2NzcC5kaXNh
# Lm1pbDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwbQYDVR0R
# BGYwZKRiMGAxCzAJBgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQx
# DDAKBgNVBAsTA0RvRDEMMAoGA1UECxMDUEtJMQ0wCwYDVQQLEwRESVNBMQwwCgYD
# VQQDEwNJRDMwFgYDVR0gBA8wDTALBglghkgBZQIBCyowNwYDVR0fBDAwLjAsoCqg
# KIYmaHR0cDovL2NybC5kaXNhLm1pbC9jcmwvRE9EU1dDQV83NS5jcmwwDQYJKoZI
# hvcNAQELBQADggEBAD6AmoySflD+VwnjWaKlFbXs5VBvG0p8uI0iN8uiQS7XiJL1
# gb93WTFdCkGoCvRAny9FmhEX5JVhcy0aK0K0TlwQrKdTOuoap6B0w+H2b12U6JDj
# z/VKUTlLO7GW8RaA0AhsC+99NQeA6zMNU1IRBcUFVGRVPSkn3KE1V+l83eQH1SAX
# FTVhvvUI6UsZPrPV19m4XG9P6BYUNmd4uXfK6KnC42eH+hUoGkV4En/PC+EfWxx3
# SdCaJJDzRbGfZhSHSGjZdAByRi5zdEZ/KPiaMjvxW2BG1AGq60E25CXC775LZUOp
# bXZgqPK/PbyT2p2Cqy88/M7G7q5NsVTb0vyBF0AxghnpMIIZ5QIBATBhMFoxCzAJ
# BgNVBAYTAlVTMRgwFgYDVQQKEw9VLlMuIEdvdmVybm1lbnQxDDAKBgNVBAsTA0Rv
# RDEMMAoGA1UECxMDUEtJMRUwEwYDVQQDEwxET0QgU1cgQ0EtNzUCAwDjrjANBglg
# hkgBZQMEAgMFAKCBnDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTBPBgkqhkiG
# 9w0BCQQxQgRAuz6jgDY2yoFgQgWFn0V7uiOi6Jo55lVQuBGI9V5c/YfiY5P+jsXC
# ouW13IkIHB17qbI5nD9l/QWPQD7IN7MHNTANBgkqhkiG9w0BAQEFAASCAQCdTLG8
# E2M7DgN87+mT11hrViFVa4dE4h2D5xc8Erz1hL8KhV1UtHDUgYV0V5YxeaH+xP/O
# l41SbH+h2BZ6k0DVTcPzpvv5PYu+pO/P6TiikZDaQD6flHybKVMWvWiiJom5ljVi
# s3xrGBARKEaJEeYvtmeOaujuSNAEdCZe2VSaUOGjB0ZomIrb/DUtGroi2pcjBt9F
# h9yEmY9LNAGZFVYBghFMq6Mjx1IabF7KIQ0tYzcsuAHSwwFYnqy8QtjoOc2ZGHxX
# yE6v6IvhTr208G1ClmbTgI94zqhYBIrxfe4aIzGOFOGgJL4t0u24W30LrYui3NMy
# vkRnJsdWL1yOPJP0oYIXujCCF7YGCisGAQQBgjcDAwExghemMIIXogYJKoZIhvcN
# AQcCoIIXkzCCF48CAQMxDzANBglghkgBZQMEAgMFADCBmgYLKoZIhvcNAQkQAQSg
# gYoEgYcwgYQCAQEGCWCGSAGG/WwHATBRMA0GCWCGSAFlAwQCAwUABEBxBGyO+YNV
# EY9aW9DH+6jvGTp17fTWoH4eF2sMvDM+NuyxQBrivGnwZ/9BNwmZmKXxtRmpV4dg
# /7OM+MzR8NFaAhAPZSVKcqQJnw33LfJ3FpjsGA8yMDI1MDcxNjIyMTEwOVqgghM6
# MIIG7TCCBNWgAwIBAgIQCBl1/om0+zBLE4B30tP+QjANBgkqhkiG9w0BAQ0FADBp
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xQTA/BgNVBAMT
# OERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQwOTYgU0hBMjU2
# IDIwMjUgQ0ExMB4XDTI1MDYwNDAwMDAwMFoXDTM2MDkwMzIzNTk1OVowYzELMAkG
# A1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdp
# Q2VydCBTSEE1MTIgUlNBNDA5NiBUaW1lc3RhbXAgUmVzcG9uZGVyIDIwMjUgMTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALO5ZSqi/QoqYSxukE3CZ3N+
# KeW6r8lSx+6G+3uwEBmLMdljXEEUpJYzG99IHAWVwSQIamAf7yfZU6kfgOs9JKv8
# Y6Lkj0RV3AP1C7csXrY3zz3VVtUiTe8MCv/3oHoXmhaDqh8tpYFSqedW9fHeGd0Z
# LIormCiEDANab6rUUaDrs1TCKIty2tSRxfX03R41lofqwf49z1WP+X6zMrv9k0S6
# 46THYdPyQZ9J/tqO4ZDJKeEA9k8Cr3djllaBE1DIHGrVoywwKfAyCh7cA3udYB3U
# 6v/Xm4dZJxFZyHQmgmk7hQqls1VuFgoZ3dZO5YiJpzlvUyMBbNsWr/yuEPeqp/7F
# +Do5DWKCeLNiqz9WVdvWuaG68hG/4bXP93a4unw8acheM2CxOlKVYYgAwJp8LJ+R
# MOzOy6SImapyt99aqVqYWdfCX0X1LUCHzMOQGYyEaC6HvKub5hgLNWqRzqNPFzs3
# v39O8qjjGBg8g7AYiR5kvvHITqfGECzFMR+6RaTKInxl8FMRZJIbPnRjFeQ+B5Bb
# yJBYMk8sp7T1a4yK5rUrZf9O8BeNwqvSfiaIDrvoh1LC1Smp8dOq0vFnDsHCjmUK
# UDRZVH5SoKQWiPDtf+vkKVi1OBxYG3Z9onvrXrORly2a0b+FNabVie6cFJsyQ7un
# zNpj5EExYng5CL6jVrNfAgMBAAGjggGVMIIBkTAMBgNVHRMBAf8EAjAAMB0GA1Ud
# DgQWBBSTOTfBEvXZdAFie4tUHz2PPGStHDAfBgNVHSMEGDAWgBTvb1NK6eQGfHrK
# 4pBW9i/USezLTjAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwgZUGCCsGAQUFBwEBBIGIMIGFMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wXQYIKwYBBQUHMAKGUWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVTdGFtcGluZ1JTQTQwOTZTSEEyNTYy
# MDI1Q0ExLmNydDBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRUaW1lU3RhbXBpbmdSU0E0MDk2U0hBMjU2
# MjAyNUNBMS5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0G
# CSqGSIb3DQEBDQUAA4ICAQCKkPOZVbgoCKeERGqRQFYypn8VSP++iBLs5x6GqSLz
# qvex2wkhdWjw2C3oaEVQnUauO1xEbGFF7yE28LLwEuNHx7tWuYcWiluHmyz8F32A
# 5Fy16tATkr+V8MnNrjcYzVpcIEGEFXjiFgqtTCREW91YEANIYKqjd3HBRK5gq/sr
# 0/eyiULFDpw2m4CUaDIKGYYk4U/R8yjL+pj/6iO0aSe9ZdbDCfNjlumPq1bhFtjz
# x7F3IKWV3f9lQcx4lKRLLdN0QQSNwc1G7GUPTeR4+PomcAQ78xmTKaNV9Aa97CHS
# 9ZM4sznr4sDEn/sf/r/v2r83XoSywIK8/Kux8Hfu5YtDLEkszCWEpvZ5lvNHmWSV
# R3G51yqbIS7He1UskIOSXMStdHzs9/j7ahmKdJxPaPVqnUSIdV1r+2XKGDc5nTPj
# n6+dH4WcIi+S/LuT9BkzmXOEJvZ+XM4aTdJlk7F0xDpc/Hur0sPUDdFfZ0W5HyGy
# obCWkjINIjlfhaFkNYygluNZ5JtDaDxjjxN6GcG7O7nFO1VE9Ce6n4/AWAkbwS+O
# tWLA+B55eoWPpiScAcqGxEEAztkbovZbhg7zr4SZnyZUs4ApkVjst7u8rLB26den
# 0DM2HR/LKML/I8uTrcKBMpqaeA5UBaCNIG0m1TJNDUsWnq4WScPQ7CkRZN7kgA4w
# XDCCBrQwggScoAMCAQICEA3HrFcF/yGZLkBDIgw6SYYwDQYJKoZIhvcNAQELBQAw
# YjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290
# IEc0MB4XDTI1MDUwNzAwMDAwMFoXDTM4MDExNDIzNTk1OVowaTELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBU
# cnVzdGVkIEc0IFRpbWVTdGFtcGluZyBSU0E0MDk2IFNIQTI1NiAyMDI1IENBMTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALR4MdMKmEFyvjxGwBysdduj
# Rmh0tFEXnU2tjQ2UtZmWgyxU7UNqEY81FzJsQqr5G7A6c+Gh/qm8Xi4aPCOo2N8S
# 9SLrC6Kbltqn7SWCWgzbNfiR+2fkHUiljNOqnIVD/gG3SYDEAd4dg2dDGpeZGKe+
# 42DFUF0mR/vtLa4+gKPsYfwEu7EEbkC9+0F2w4QJLVSTEG8yAR2CQWIM1iI5PHg6
# 2IVwxKSpO0XaF9DPfNBKS7Zazch8NF5vp7eaZ2CVNxpqumzTCNSOxm+SAWSuIr21
# Qomb+zzQWKhxKTVVgtmUPAW35xUUFREmDrMxSNlr/NsJyUXzdtFUUt4aS4CEeIY8
# y9IaaGBpPNXKFifinT7zL2gdFpBP9qh8SdLnEut/GcalNeJQ55IuwnKCgs+nrpuQ
# NfVmUB5KlCX3ZA4x5HHKS+rqBvKWxdCyQEEGcbLe1b8Aw4wJkhU1JrPsFfxW1gao
# u30yZ46t4Y9F20HHfIY4/6vHespYMQmUiote8ladjS/nJ0+k6MvqzfpzPDOy5y6g
# qztiT96Fv/9bH7mQyogxG9QEPHrPV6/7umw052AkyiLA6tQbZl1KhBtTasySkuJD
# psZGKdlsjg4u70EwgWbVRSX1Wd4+zoFpp4Ra+MlKM2baoD6x0VR4RjSpWM8o5a6D
# 8bpfm4CLKczsG7ZrIGNTAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEA
# MB0GA1UdDgQWBBTvb1NK6eQGfHrK4pBW9i/USezLTjAfBgNVHSMEGDAWgBTs1+OC
# 0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYB
# BQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSG
# Mmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQu
# Y3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0B
# AQsFAAOCAgEAF877FoAc/gc9EXZxML2+C8i1NKZ/zdCHxYgaMH9Pw5tcBnPw6O6F
# TGNpoV2V4wzSUGvI9NAzaoQk97frPBtIj+ZLzdp+yXdhOP4hCFATuNT+ReOPK0mC
# efSG+tXqGpYZ3essBS3q8nL2UwM+NMvEuBd/2vmdYxDCvwzJv2sRUoKEfJ+nN57m
# QfQXwcAEGCvRR2qKtntujB71WPYAgwPyWLKu6RnaID/B0ba2H3LUiwDRAXx1Neq9
# ydOal95CHfmTnM4I+ZI2rVQfjXQA1WSjjf4J2a7jLzWGNqNX+DF0SQzHU0pTi4dB
# wp9nEC8EAqoxW6q17r0z0noDjs6+BFo+z7bKSBwZXTRNivYuve3L2oiKNqetRHdq
# fMTCW/NmKLJ9M+MtucVGyOxiDf06VXxyKkOirv6o02OoXN4bFzK0vlNMsvhlqgF2
# puE6FndlENSmE+9JGYxOGLS/D284NHNboDGcmWXfwXRy4kbu4QFhOm0xJuF2EZAO
# k5eCkhSxZON3rGlHqhpB/8MluDezooIs8CVnrpHMiD2wL40mm53+/j7tFaxYKIqL
# 0Q4ssd8xHZnIn/7GELH3IdvG2XlM9q7WP/UwgOkw/HQtyRN62JK4S1C8uw3PdBun
# vAZapsiI5YKdvlarEvf8EA+8hcpSM9LHJmyrxaFtoza2zNaQ9k+5t1wwggWNMIIE
# daADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAe
# Fw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# ITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC
# 4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWl
# fr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1j
# KS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dP
# pzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3
# pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJ
# pMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aa
# dMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXD
# j/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB
# 4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ
# 33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amy
# HeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC
# 0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823I
# DzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNl
# cnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYD
# VR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcN
# AQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxpp
# VCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6
# mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPH
# h6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCN
# NWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg6
# 2fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggOcMIIDmAIBATB9MGkxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNl
# cnQgVHJ1c3RlZCBHNCBUaW1lU3RhbXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBD
# QTECEAgZdf6JtPswSxOAd9LT/kIwDQYJYIZIAWUDBAIDBQCggfEwGgYJKoZIhvcN
# AQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yNTA3MTYyMjExMDla
# MCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFHQ3wj6CUXxtvvXa0xW0tAuqoWVLMDcG
# CyqGSIb3DQEJEAIvMSgwJjAkMCIEIPwMwCo+kBfdX7rbAP8AEqbrYo6dxe62nEGl
# vOCryoiZME8GCSqGSIb3DQEJBDFCBED9x+qZlr3TPcjrDx0rS+gzHsq75m24EdaV
# hXTmTHISYeERjqbmYbtv13KQCSMAkA1H7nukuBnzIImG3lBhdUgFMA0GCSqGSIb3
# DQEBAQUABIICAHvGhWyLmhFgLX8zJ4GmGWj1ryQ8uRYsMACKoVJrB1ZX0NRywm1P
# 0WW6mYyiVrRoOSyizjV3AboD7JeCF8UUWJtFnwcMt+opHkzTqZGmKszW355myQJ3
# Dyi76gFBWwSm7wVHgfPYWEXBtzZFDIP+4xoCFO1wEd9nN4gQEDN0c4xisEWYQ/ai
# dhe6QSDzV2grBQOqr31xiEt8FwHb0r+qcR7U9hleyPM2CJBMC89yUfL6+2Lakzg5
# pXED8B7cce3n9sbbXEGp1/jcMq6kJQWcKzn9vgiNd7tOUg36Z/TJ2UamLaHbDVLL
# MJjC0u+w6x3RCzC6AX+XQEt5EXEE7Ab7BGWbqsm74k3auESFFh/bHwRhkz2Bkv6a
# 07Q6qUadtycdTfdJBhQcJ7hIja/lKGjgr075eYaYFYJLubWCPMIsEnIFWR+BdkXF
# OEl86wHWtA5700WGAbB3qYEL1POcuRT60OZOdgHv8/C1G/dJtJ3ivh0oHRP51meI
# 0ehQZ2vYoTO/yVTk0C+2CuMTv0bTa6JA8nbaa700NzX4Etm5M7AgLmMWLZsPGYJq
# ZllfwvZ1s3mB55s1Rptu5I5E/XUGHRhjR5fjOuLM1L6+EddhjdxLLA477MbKSty7
# r8zRAGgowrXbV26eCrGBKlWj3bfnkPm/Z0NHwAB62v3ZeEDRwEpouLnG
# SIG # End signature block
