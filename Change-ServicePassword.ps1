<#
.SYNOPSIS
This script manages Windows services based on a JSON configuration file.

.DESCRIPTION
The script reads a JSON file containing service names and credentials, stops each service, updates its credentials, and then restarts it. If the JSON file does not exist, it creates a new one with a default template.

.EXAMPLE
PS> .\ServiceManager.ps1
This example runs the script which will read the 'services.json' file and update the services in the array to run under the user credentials specified.

.NOTES
Requires PowerShell 7 or higher.
#>

# Define the path to the services JSON file.
$servicesJSON = "services.json"

# Check if the services JSON file exists.
if(Test-Path $servicesJSON){
    # Import the JSON file content, convert it to a PowerShell object.
    $svcimport = Get-Content $servicesJSON -ErrorAction Stop | Out-String | ConvertFrom-Json
    # Extract the services, username, and password from the JSON object.
    $Services = $svcimport.services
    $ServiceAccountName = $svcimport.username
    $PW = $svcimport.password
}else{
    # If the JSON file does not exist, create a new one with default structure.
    New-Item -Path "services.json" -ItemType File
    $svcjson = @{
        services = @()
        username = ""
        password = ""
    }
    # Convert the default structure to JSON and write it to the services.json file.
    $svcjson | ConvertTo-Json -Depth 100 | Set-Content -Path "services.json"
    # Stop the script execution and display an error message prompting to populate the JSON file.
    Write-Error "Services.json did not already exist, file has been created. Please populate the JSON and re-run this script." -ErrorAction Stop
}

# Iterate over each service name defined in the services array.
foreach($serviceName in $Services){
    # Display the service name being processed.
    Write-Host "Service Name: $serviceName"
    # Stop the service with the current service name.
    Stop-Service $serviceName

    # Convert the plain text password to a secure string.
    $SecurePassword = ConvertTo-SecureString $PW -AsPlainText -Force
    # Create a new credential object using the service account name and the secure password.
    $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList "$ServiceAccountName", $SecurePassword
    # Update the service with the new credential.
    Set-Service -Name $serviceName -Credential $Cred

    # Start the service with the current service name.
    Start-Service $serviceName
}

# Clear the username and password from the imported JSON object.
$svcimport.username = ""
$svcimport.password = ""

# Convert the modified JSON object back to JSON format and write it to the services JSON file.
$svcimport | ConvertTo-Json -Depth 100 | Set-Content -Path $servicesJSON
