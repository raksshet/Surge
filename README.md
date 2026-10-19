Provider block - mention about the which provider service we are going to use 

example : azurerm - for azure
resource 

  example 
  ```resource "azurerm_resource_group" "example" {}```

  
In above example "azurerm_resource_group" known as and this can't be changed

"example" this is the deployment name which can be used later in the block.

AZURE CLI is used to authenticate from local system 

**terraform init** to initiate the repo with terraform

**terraform plan** to chekc what resource changes happens based on the main.tf file

**terraform apply** apply the changes

```resource "azurerm_resource_group" "example" {}```

learn about **state file**

**terraform destroy** deletes all the resource from main.tf file

if the code block is commented then terraform will detroy

In resource group some fields are mandatory and some are optional. In mandatory field can be modified some properties can't be modified

example: resource group name can't be modified .Tag properties can be modified.










