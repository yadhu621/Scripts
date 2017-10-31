
### Creating a logger
$location = 'C:\Users\Administrator\Desktop\log.txt'

if (-Not (Test-Path $location)){
    New-Item $location -ItemType File
}
function Log {
    param(
        [string]$logmessage
    )
    $location = 'C:\Users\Administrator\Desktop\log.txt'
    Write-output $logmessage | Out-file $location -Append
}

### Create a pause function
function Pause {
    Param(
        [int]$seconds
    )
    Start-Sleep -s $seconds
}

### Install aws cli
Log("Downloading AWS CLI from the internet.....")
$location = 'C:\awscli.msi'
$URL = 'https://s3.amazonaws.com/aws-cli/AWSCLI64.msi'

if (-Not (Test-Path $location)){
    Invoke-WebRequest -Uri $URL -OutFile $location
}
Pause 10
Start-Process msiexec -ArgumentList @('/qn','/i C:\awscli.msi') -Wait
Log("Successfully installed AWS CLI.")

### Reloading a new powershell session to source AWS installation
.$profile
Pause 10

### Create a chef directory
Log("Creating an empty 'chef' directory........")
$folder = 'C:\chef'
if (-Not (Test-Path -Path $folder)){
    New-Item -Path $folder -ItemType Directory
}
Log("C:\chef folder created.")


### Download the chef-client installable
Log("Downloading the chef-client installable from the internet........")
$chef_client_URL = "https://packages.chef.io/files/stable/chef/13.6.0/windows/2016/chef-client-13.6.0-1-x64.msi" 
$outfile = "C:\chef-client.msi"
Invoke-WebRequest -Uri $chef_client_URL -OutFile $outfile
Log("Chef-client downloaded.")

Pause 10

### Install chef-client
Log("Starting installation of chef-client........")
Start-Process msiexec.exe -ArgumentList @('/qn','/lv C:\Windows\Temp\chef-log.txt','/i C:\chef-client.msi','ADDLOCAL="ChefClientFeature,ChefSchTaskFeature,ChefPSModuleFeature"') -Wait
Log("Chef-client installation completed.")


### Create a firstboot.json file
Log("Creating a first-boot json file for the first chef-client run........")
$firstboot = @{
    "run-list" = @("role[base]")
} 
Set-Content -Path "C:\chef\first-boot.json" -Value ($firstboot | ConvertTo-Json)
Log("Completed, first-boot.json file created and placed at C:\chef.")


### Find the node name of the server
Log("Finding the name of the node........")
$instance_id = (Invoke-WebRequest "http://169.254.169.254/latest/meta-data/instance-id").content
$region = ((Invoke-WebRequest "http://169.254.169.254/latest/meta-data/placement/availability-zone").content).TrimEnd("abc")
$tags = aws ec2 describe-tags --region $region --filter "resource-type=instance" --filter "Name=resource-id,Values=$instance_id"
Pause 5
$tags_array = ($tags | ConvertFrom-Json).tags
$name_tag = $tags_array | Where-Object {$_.Key -eq "Name"}
$node_name = $name_tag.Value.ToLower()
Log("The node name is " + $node_name)


### Create a client.rb file
Log("Creating the client.rb file........")
$clientrb = @"
chef_server_url             'https://ip-10-0-1-160.eu-west-2.compute.internal/organizations/rwest'
validation_client_name      'rwest-validator'
validation_key              'C:\chef\rwest-validator.pem'
node_name                   '{0}'
"@ -f $node_name
Set-Content -Path 'C:\chef\client.rb' -Value $clientrb
Log("Completed, client.rb file created and placed at C:\chef.")


### Place validator.pem and chef-server.crt files 
Log("Placing the required validator pem file and server SSL certificate........")
$validator_pem_file_local = 'C:\chef\rwest-validator.pem'
$validator_pem_file_s3 ='s3://oracle621/chef/rwest-validator.pem'
if (-Not (Test-Path -Path $validator_pem_file)){
    aws s3 cp $validator_pem_file_s3 $validator_pem_file_local
    Pause 5
}
Log("Completed, validator .pem file placed at C:\chef.")

Log("Creating a 'trusted_certs' folder within C:\chef........")
$folder = 'C:\chef\trusted_certs'
if (-Not (Test-Path -Path $folder)){
    New-Item -Path $folder -ItemType Directory
}
Log("C:\chef\trusted_certs folder created.")

$certificate_local = 'C:\chef\trusted_certs\ip-10-0-1-160_eu-west-2_compute_internal.crt'
$certificate_s3 = 's3://oracle621/chef/ip-10-0-1-160_eu-west-2_compute_internal.crt'
if (-Not (Test-Path -Path $certificate)){
    aws s3 cp $certificate_s3 $certificate_local 
    Pause 5
}
Log("Completed, chef-server .crtfile placed at C:\chef\trusted_certs.")


### Run chef-client
Log("Chef-Client now taking over........")
C:\opscode\chef\bin\chef-client.bat -j C:\chef\first-boot.json