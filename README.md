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

In variables.tf file create the variables 

```
variable "resource_group_name" {
  description="The name of the resource group"
  type = string
}
```
variable accepts user input while running terraform command.

This approach is not practical as this requires to give all the inputs.

to overcome this problem create a tfvars file with variables specific to environments.

dev.tfvars
hom.tfvars

int this mention the variables

dev.tfvars
  resource_group_name="dev"

qa.tfvars
  resource_group_name="qa"

while running the terraform plan --var-file="dev.tfvars"
  











