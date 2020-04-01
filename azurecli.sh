export APP_PE_DEMO_RG=attpedemo-rg
export LOCATION=eastus  
export DEMO_VNET=attpedemo-vnet
export DEMO_VNET_CIDR=10.0.0.0/16
export DEMO_VNET_APP_SUBNET=app_subnet
export DEMO_VNET_APP_SUBNET_CIDR=10.0.1.0/24
export DEMO_VNET_PL_SUBNET=pl_subnet
export DEMO_VNET_PL_SUBNET_CIDR=10.0.2.0/24
export DEMO_APP_PLAN=att-linux-app-plan
export DEMO_APP_NAME=att-linux-demo-app
export DEMO_APP_VM=pldemovm
export DEMO_APP_VM_ADMIN=azureuser
export DEMO_VM_IMAGE=MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest
export DEMO_VM_SIZE=Standard_DS2_v2
export DEMO_APP_KV=att-linux-demo-kv
export DEMO_APP_MYSQL=att-linux-demo-mysql
export DEMO_APP_MYSQL_DB=demodb
export MYSQL_DB_USERNAME=mysqladmin
export MYSQL_DB_PASSWORD=P@ssw0rd1
export MYSQL_DB_URI=
export APP_MSI=
export KV_SECRET_DB_URI=MYSQL-URL
export KV_SECRET_DB_UID=MYSQL-USERNAME
export KV_SECRET_DB_PWD=MYSQL-PASSWORD
export KV_SECRET_DB_URI_FULLPATH=
export KV_SECRET_DB_UID_FULLPATH=
export KV_SECRET_DB_PWD_FULLPATH=
export APP_SETTING_NAME_DB_UID=MYSQL_USERNAME
export APP_SETTING_NAME_DB_PWD=MYSQL_PASSWORD
export APP_SETTING_NAME_DB_URI=MYSQL_URL
export WEB_APP_RESOURCE_ID=
export KV_RESOURCE_ID=
export MYSQL_RESOURCE_ID=

# Create Resource Group
az group create -l $LOCATION -n $APP_PE_DEMO_RG

# Create VNET and App Service delegated Subnet
az network vnet create -g $APP_PE_DEMO_RG -n $DEMO_VNET --address-prefix $DEMO_VNET_CIDR \
 --subnet-name $DEMO_VNET_APP_SUBNET --subnet-prefix $DEMO_VNET_APP_SUBNET_CIDR

# Create Subnet to create PL, VMs etc.
az network vnet subnet create -g $APP_PE_DEMO_RG --vnet-name $DEMO_VNET -n $DEMO_VNET_PL_SUBNET \
    --address-prefixes $DEMO_VNET_PL_SUBNET_CIDR

# Create VM to host
# - DNS
# - Java
# - VS Code
# - Azure CLI
# - Maven
az vm create -n $DEMO_APP_VM -g $APP_PE_DEMO_RG --image MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest \
    --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET --public-ip-sku Standard --size $DEMO_VM_SIZE --admin-username $DEMO_APP_VM_ADMIN

# Install VS Code - https://code.visualstudio.com/download
# Install Java Extension Pack for VSCode - https://code.visualstudio.com/blogs/2017/09/28/java-debug
# Install Azure CLI - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?view=azure-cli-latest
# Setup DNS server
# Windows DNS Server - https://www.wintelpro.com/install-and-configure-dns-on-windows-server-2019/

################ Complete the VM Setup before moving next #######################
# Create App Service Plan
az appservice plan create -g $APP_PE_DEMO_RG -l $LOCATION -n $DEMO_APP_PLAN \
    --is-linux --number-of-workers 1 --sku P1V2

# Create Java Web App
az webapp create -g $APP_PE_DEMO_RG -p $DEMO_APP_PLAN -n $DEMO_APP_NAME --runtime "JAVA|8-jre8"

# Assign MSI for Java Web App
# Please save the output and take a note of the ObjecID and save it as $APP_MSI
az webapp identity assign -g $APP_PE_DEMO_RG -n $DEMO_APP_NAME

# Attach Web App to the VNET
az webapp vnet-integration add -g $APP_PE_DEMO_RG -n $DEMO_APP_NAME --vnet $DEMO_VNET --subnet $DEMO_VNET_APP_SUBNET

# Create MySQL SERVER
az mysql server create -l $LOCATION -g $APP_PE_DEMO_RG -n $DEMO_APP_MYSQL -u $MYSQL_DB_USERNAME -p $MYSQL_DB_PASSWORD --sku-name GP_Gen5_2

# Create MySQL DB
az mysql db create -g $APP_PE_DEMO_RG -s $DEMO_APP_MYSQL -n $DEMO_APP_MYSQL_DB

# Now build the MySQL URI Like this
export MYSQL_DB_URI="jdbc:mysql://"$DEMO_APP_MYSQL"mysql.database.azure.com:3306/"$DEMO_APP_MYSQL_DB

# Create Key Vault
az keyvault create --location $LOCATION --name $DEMO_APP_KV --resource-group $APP_PE_DEMO_RG

# Set Key Vault Secrets
# Please  take a note of the Secret Full Path and save it as KV_SECRET_DB_UID_FULLPATH
az keyvault secret set --vault-name $DEMO_APP_KV --name $KV_SECRET_DB_UID --value $MYSQL_DB_USERNAME

# Please  take a note of the Secret Full Path and save it as KV_SECRET_DB_PWD_FULLPATH
az keyvault secret set --vault-name $DEMO_APP_KV --name $KV_SECRET_DB_PWD --value $MYSQL_DB_PASSWORD

# Please  take a note of the Secret Full Path and save it as KV_SECRET_DB_URI_FULLPATH
az keyvault secret set --vault-name $DEMO_APP_KV --name $KV_SECRET_DB_URI --value $MYSQL_DB_URI

# Set Policy for Web App to access secrets
az keyvault set-policy --name "AppKV" --spn $APP_MSI --secret-permissions get, list

# set Web App Configuration
az webapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_APP_NAME --settings $APP_SETTING_NAME_DB_UID="@Microsoft.KeyVault(SecretUri="$KV_SECRET_DB_UID_FULLPATH")"
az webapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_APP_NAME --settings $APP_SETTING_NAME_DB_PWD="@Microsoft.KeyVault(SecretUri="$KV_SECRET_DB_PWD_FULLPATH")"
az webapp config appsettings set -g $APP_PE_DEMO_RG -n $DEMO_APP_NAME --settings $APP_SETTING_NAME_DB_URI="@Microsoft.KeyVault(SecretUri="$KV_SECRET_DB_URI_FULLPATH")"

# Now restart the webapp
az webapp restart -g $APP_PE_DEMO_RG -n $DEMO_APP_NAME

# Setup the App using VSCode
# Go to the VM that you creaded ealier
# Use git to downlaod the code from https://github.com/naveedzaheer/simplespringwebapp.git
# Use VS Code to open the Folder
# 
# Open VSCode terminal
# Create three environment variables in the Terminal using the following commands
#   setx MYSQL_URL "jdbc:mysql://[server-name]].eastus.cloudapp.azure.com:3306/[db-name]"
#   setx MYSQL_USERNAME [MySQL User Name]
#   setx MYSQL_PASSWORD [My SQl password]
# Build the code using - mvn clean package
# Run the App using - mvn spring-boot:run -P production
# You should be able to access the app at - http://localhost:8080


# Create Private Links

# Prepare the Subnet
az network vnet subnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET_PL_SUBNET --vnet-name $DEMO_VNET --disable-private-endpoint-network-policies
az network vnet subnet update -g $APP_PE_DEMO_RG -n $DEMO_VNET_PL_SUBNET --vnet-name $DEMO_VNET --disable-private-link-service-network-policies

# Create Web App Private Link
# Get the Resource ID of the Web App from the Portal, assign it to WEB_APP_RESOURCE_ID and create private link
az network private-endpoint create -g $APP_PE_DEMO_RG -n webpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id $WEB_APP_RESOURCE_ID --connection-name webpeconn -l $LOCATION

# Create Key Vault Private Link
# Get the Resource ID of the Key Vault from the Portal, assign it to KV_RESOURCE_ID and create private link
az network private-endpoint create -g $APP_PE_DEMO_RG -n kvpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id $KV_RESOURCE_ID --connection-name kvpeconn -l $LOCATION

# Create MySQL Private Link
# Get the Resource ID of the MySQL Server from the Portal, assign it to MYSQL_RESOURCE_ID and create private link
az network private-endpoint create -g $APP_PE_DEMO_RG -n mysqlpe --vnet-name $DEMO_VNET --subnet $DEMO_VNET_PL_SUBNET \
    --private-connection-resource-id $MYSQL_RESOURCE_ID --connection-name mysqlpeconn -l $LOCATION

# Creating Forward Lookup Zones in teh DNS server you created above
#   Create the zone for: mysql.database.azure.com
#       Create an A Record for the MYSQL DB with the name and its private endpoint address
#   Create the zone for: vault.azure.net
#       Create an A Record for the Key Vault with the name and its private endpoint address
#   Create the zone for: azurewebsites.net
#       Create an A Record for the Web App with the name and its private endpoint address
#   Create the zone for: scm.azurewebsites.net
#       Create an A Record for the Web App SCM with the name and its private endpoint address

# Now access the site from the VM using the address https://[WebApp Name].azurewebsites.net
# Use the following URL to deploy the site using maven plugin: https://docs.microsoft.com/en-us/azure/app-service/containers/quickstart-java




