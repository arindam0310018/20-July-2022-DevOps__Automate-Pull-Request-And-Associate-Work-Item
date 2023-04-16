# AUTOMATE PULL REQUEST &amp; ASSOCIATE WORK-ITEMS USING AZ DEVOPS

Greetings my fellow Technology Advocates and Specialists.

In this Session, I will demonstrate how to Automate Pull Request (PR) and Associate Work-Items Using Azure DevOps.

I had the Privilege to talk on this topic in __TWO__ Azure Communities:-

| __NAME OF THE AZURE COMMUNITY__ | __TYPE OF SPEAKER SESSION__ |
| --------- | --------- |
| __Microsoft Azure Bern User Group__ | __In-Person__ |
| __Microsoft Azure Pakistan Community__ | __Virtual__ |

| __IN-PERSON SESSION:-__ |
| --------- |
| I presented this Demo as a part of __AZURE DEVOPS: TAKEAWAYS BEST PRACTISES AND LIVE DEMOS__ In-Person Speaker Session in __MICROSOFT AZURE BERN USER GROUP__ Forum/Platform. |
| __Event Meetup Announcement:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cpz6voitr8v43psbgsii.jpg) |
| __Moment Captured with Founders of MICROSOFT AZURE BERN USER GROUP "STEFAN JOHNER", "STEFAN ROTH", "PAUL AFFENTRANGER" and Co-organizer "DAMIEN BOWDEN":-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jxz1bp0dw976e7s3j3c0.JPG) |

| __VIRTUAL SESSION:-__ |
| --------- |
| __Event Meetup Announcement:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/xve54ff8gdkj8fm6ecy5.JPG) |
| __LIVE DEMO__ was Recorded as part of my Presentation in __MICROSOFT AZURE PAKISTAN COMMUNITY__ Forum/Platform |
| Duration of My Demo = __48 Mins 23 Secs__ |
| [![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/acyE2gWiLdI&t=1853s/0.jpg)](https://www.youtube.com/watch?v=acyE2gWiLdI&t=1853s) |  

| __AUTOMATION OBJECTIVE:-__ |
| --------- |
| Create Random Generated Work-Items in Azure DevOps Boards. |
| Create Pull Request (PR). |
| Associate Work-Item with Pull Request (PR). |
| Complete Pull Request (PR) with Squash Commit. |
| Delete the Working Branch (For Example: "Dev" or "Feature/AM". |

| __REQUIREMENTS:-__ |
| --------- |

1. Azure Subscription.
2. Azure DevOps Organisation and Project.
3. Azure DevOps Personal Access Token (PAT). 
4. Service Principal with Required RBAC ( __Contributor__) applied on Subscription or Resource Group(s).
5. Azure Resource Manager Service Connection in Azure DevOps.
6. Microsoft DevLabs Terraform Extension Installed in Azure DevOps.

| __CODE REPOSITORY:-__ |
| --------- |
| {% github arindam0310018/20-July-2022-DevOps__Automate-Pull-Request-And-Associate-Work-Item %} |

| __HOW DOES MY CODE PLACEHOLDER LOOKS LIKE:-__ |
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/a4hdclb7q11taepi5z9c.png) |

| PIPELINE CODE SNIPPET:- | 
| --------- |

| AZURE DEVOPS YAML PIPELINE (azure-pipelines-automate-pr-workitems-v1.0.yml):- | 
| --------- |

```
#####################################################
# TRIGGER CONDITION CAN BE ALTERED LIKE BELOW :-
#####################################################
# trigger:
#   branches:
#     include:
#     - feature/*
#   paths:
#     include:
#     - Automate-PR-and-Associate-WorkItems/*
#####################################################


#######################
# TRIGGER CONDITION :-
#######################
trigger: none

########################################################################
#DECLARE VARIABLES:-
# ONLY VARIABLE VALUES NEEDS TO BE ALTERED TO MAKE THE PIPELINE WORK.
########################################################################
variables:
  PlanFilename: tfplan
  TfvarFilename: usrmid.tfvars
  KV-Name: ampockv
  ServiceConnection: amcloud-cicd-service-connection
  ResourceGroup: tfpipeline-rg
  StorageAccount: tfpipelinesa
  Container: terraform
  TfstateFile: PR/createprworkitem.tfstate
  BuildAgent: ubuntu-latest
  PipelineEnv: NonProd
  Terraform_Version: 1.2.3
  WorkingDir: $(System.DefaultWorkingDirectory)/Automate-PR-and-Associate-WorkItems
  Target: $(build.artifactstagingdirectory)/AMTF
  Artifact: AM
  anyTfChanges: false
  DevOpsOrganisation: https://dev.azure.com/ArindamMitra0251
  DevOpsProjName: AMCLOUD
  DevOpsRepoName: PR
  DevOpsDestinationBranch: main
  
######################
#DECLARE BUILD AGENT:-
######################
pool:
  vmImage: $(BuildAgent)

###################
#DECLARE STAGES:-
###################

#################
# STAGE: BUILD
#################

stages:

- stage: BUILD
  jobs:
  - job: BUILD
    displayName: BUILD
    steps:
# Install Terraform Installer in the Build Agent:-
    - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
      displayName: INSTALL LATEST TERRAFORM VERSION
      inputs:
        terraformVersion: '$(Terraform_Version)'
# Terraform Init:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM INIT
      inputs:
        command: 'init'
        provider: 'azurerm'
        workingDirectory: '$(WorkingDir)'
        backendServiceArm: '$(ServiceConnection)' 
        backendAzureRmResourceGroupName: '$(ResourceGroup)' 
        backendAzureRmStorageAccountName: '$(StorageAccount)'
        backendAzureRmContainerName: '$(Container)'
        backendAzureRmKey: '$(TfstateFile)'
# Terraform Validate:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM VALIDATE
      inputs:
        command: 'validate'
        provider: 'azurerm'
        workingDirectory: '$(WorkingDir)'
        environmentServiceNameAzureRM: '$(ServiceConnection)'
# Terraform Plan:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM PLAN
      inputs:
        command: 'plan'
        provider: 'azurerm'
        workingDirectory: '$(WorkingDir)'
        commandOptions: '--var-file=$(TfvarFilename) --out=$(PlanFilename)'
        environmentServiceNameAzureRM: '$(ServiceConnection)'
# Detect Terraform Changes:-
    - task: PowerShell@2
      name: DetectTFChanges
      displayName: DETECT TERRAFORM CHANGES
      inputs:
        workingDirectory: '$(workingDir)'
        targetType: 'inline'
        script: |
          Write-Host "#######################################################"
          Write-Host "Intial value of variable: $(anyTfChanges)"
          Write-Host "#######################################################"
          $plan = $(terraform show -json tfplan | ConvertFrom-Json)
          $count = $plan.resource_changes.change.actions.length
          $actions = ($plan.resource_changes | where { 'no-op' -notcontains $_.change.actions }).length -ne 0
          Write-Host "##vso[task.setvariable variable=anyTfChanges;isOutput=true]$actions"
          Write-Host "#######################################################"
          Write-Host "Are there Changes in Infrastruture: $actions"
          Write-Host "#######################################################"
          Write-Host "TOTAL NO OF CHANGES: $count"
          Write-Host "#######################################################"
# Copy Files to Artifacts Staging Directory:-
    - task: CopyFiles@2
      displayName: COPY FILES ARTIFACTS STAGING DIRECTORY
      inputs:
        SourceFolder: '$(WorkingDir)'
        Contents: |
          **/*.tf
          **/*.tfvars
          **/*$(PlanFilename)*
        TargetFolder: '$(Target)'
# Publish Artifacts:-
    - task: PublishBuildArtifacts@1
      displayName: PUBLISH ARTIFACTS
      inputs:
        targetPath: '$(Target)'
        artifactName: '$(Artifact)'

#################
# STAGE: DEPLOY
#################

- stage: DEPLOY
  condition: |
     and(succeeded(),
       ne(variables['Build.SourceBranch'], 'refs/heads/main'),
       eq(dependencies.BUILD.outputs['build.DetectTFChanges.anyTfChanges'], 'true')
     )
  jobs:
  - deployment: 
    displayName: Deploy
    environment: '$(PipelineEnv)'
    pool:
      vmImage: '$(BuildAgent)'
    strategy:
      runOnce:
        deploy:
          steps:
# Download Artifacts:-
          - task: DownloadBuildArtifacts@0
            displayName: DOWNLOAD ARTIFACTS
            inputs:
              buildType: 'current'
              downloadType: 'single'
              artifactName: '$(Artifact)'
              downloadPath: '$(System.ArtifactsDirectory)' 
# Install Terraform Installer in the Build Agent:-
          - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
            displayName: INSTALL LATEST TERRAFORM VERSION
            inputs:
              terraformVersion: '$(Terraform_Version)'
# Terraform Init:-
          - task: TerraformTaskV2@2
            displayName: TERRAFORM INIT
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF/'
              backendServiceArm: '$(ServiceConnection)' 
              backendAzureRmResourceGroupName: '$(ResourceGroup)' 
              backendAzureRmStorageAccountName: '$(StorageAccount)'
              backendAzureRmContainerName: '$(Container)'
              backendAzureRmKey: '$(TfstateFile)'
# Terraform Apply:-
          - task: TerraformTaskV2@2
            displayName: TERRAFORM APPLY
            inputs:
              provider: 'azurerm'
              command: 'apply'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF'
              commandOptions: '--var-file=$(TfvarFilename)'
              environmentServiceNameAzureRM: '$(ServiceConnection)'

##################################################################################################
# STAGE: CREATE PR
# CREATE AND COMPLETE PULL REQUEST BY ASSOCIATING WORKITEMS AND DELETING SOURCE BRANCH
#################################################################################################

- stage: PULL_REQUEST_ASSOCIATE_WORKITEMS
  condition: |
     and(succeeded(), 
       ne(variables['Build.SourceBranch'], 'refs/heads/main') 
     )
  dependsOn: DEPLOY
  jobs:
  - job: PULL_REQUEST_WORKITEMS
    displayName: CREATE PR | ASSOCIATE WORKITEMS | COMPLETE
    steps:
# Download Keyvault Secrets:-
    - task: AzureKeyVault@2
      inputs:
        azureSubscription: '$(ServiceConnection)'
        KeyVaultName: '$(KV-Name)'
        SecretsFilter: '*'
        RunAsPreJob: false
# Install Az DevOps CLI Extension in the Build Agent:-
    - task: AzureCLI@1
      displayName: INSTALL DEVOPS CLI EXTENSION
      inputs:
        azureSubscription: '$(ServiceConnection)'
        scriptType: ps
        scriptLocation: inlineScript
        inlineScript: |
          az extension add --name azure-devops
          az extension show --name azure-devops --output table
# Validate Az DevOps CLI Extension in the Build Agent:-
    - task: PowerShell@2
      displayName: VALIDATE AZ DEVOPS CLI
      inputs:
        targetType: 'inline'
        script: |
          az devops -h
# Set Default DevOps Organization and Project:-
    - task: PowerShell@2
      displayName: DEVOPS LOGIN + SET DEFAULT DEVOPS ORG & PROJECT
      inputs:
        targetType: 'inline'
        script: |
         echo "$(PAT)" | az devops login  
         az devops configure --defaults organization=$(DevOpsOrganisation) project=$(DevOpsProjName)
# Create Workitem + Create PR + Associate Workitem with PR + Complete the PR + Delete Source Branch:-
    - task: PowerShell@2
      displayName: CREATE & COMPLETE PULL REQUEST + WORKITEMS + DELETE SOURCE BRANCH
      inputs:
        targetType: 'inline'
        script: |
          Write-Host "#######################################################"
          Write-Host "NAME OF THE SOURCE BRANCH: $(Build.SourceBranchName)"
          Write-Host "#######################################################"
          $i="PR-"
          $j=Get-Random -Maximum 1000
          Write-Host "###################################################"
          Write-Host "WORKITEM NUMBER GENERATED IN DEVOPS BOARD: $i$j"
          Write-Host "###################################################"
          $wid = az boards work-item create --title $i$j --type "Issue" --query "id"
          Write-Host "#######################################################" 
          Write-Host "WORKITEM ID is: $wid"
          Write-Host "#######################################################"
          $prid = az repos pr create --repository $(DevOpsRepoName) --source-branch $(Build.SourceBranchName) --target-branch $(DevOpsDestinationBranch) --work-items $wid --transition-work-items true --query "pullRequestId"
          Write-Host "#######################################################"
          Write-Host "PULL REQUEST ID is: $prid"
          Write-Host "#######################################################"
          Write-Host "##### TO BE MERGED FROM $(Build.SourceBranchName) TO Main #####"
          az repos pr update --id $prid --auto-complete true --squash true --status completed --delete-source-branch true
          Write-Host "##### MERGE SUCCESSFULL #####"

```

Now, let me explain each part of YAML Pipeline for better understanding.

| PART #1:- | 
| --------- |

| BELOW FOLLOWS PIPELINE VARIABLES CODE SNIPPET:- | 
| --------- |

```
########################################################################
#DECLARE VARIABLES:-
# ONLY VARIABLE VALUES NEEDS TO BE ALTERED TO MAKE THE PIPELINE WORK.
########################################################################
variables:
  PlanFilename: tfplan
  TfvarFilename: usrmid.tfvars
  KV-Name: ampockv
  ServiceConnection: amcloud-cicd-service-connection
  ResourceGroup: tfpipeline-rg
  StorageAccount: tfpipelinesa
  Container: terraform
  TfstateFile: PR/createprworkitem.tfstate
  BuildAgent: ubuntu-latest
  PipelineEnv: NonProd
  Terraform_Version: 1.2.3
  WorkingDir: $(System.DefaultWorkingDirectory)/Automate-PR-and-Associate-WorkItems
  Target: $(build.artifactstagingdirectory)/AMTF
  Artifact: AM
  anyTfChanges: false
  DevOpsOrganisation: https://dev.azure.com/ArindamMitra0251
  DevOpsProjName: AMCLOUD
  DevOpsRepoName: PR
  DevOpsDestinationBranch: main

```

| __NOTE:-__ |
| --------- |
| Please feel free to change the values of the variables. | 
| The entire YAML pipeline is build using variables. No Values are Hardcoded. |
| "**Working Directory**" Path should be based on your Code Placeholder. |


| PART #2:- | 
| --------- |

| __PIPELINE STAGE DETAILS FOLLOW BELOW:-__ |
| --------- |

1. This is a __3 Stage__ Pipeline.
2. The Names of the Stages are - 1) BUILD 2) DEPLOY, and 3) PULL_REQUEST_ASSOCIATE_WORKITEMS

| __PIPELINE STAGE - BUILD:-__ |
| --------- |

```
#################
# STAGE: BUILD
#################

stages:

- stage: BUILD
  jobs:
  - job: BUILD
    displayName: BUILD
    steps:
# Install Terraform Installer in the Build Agent:-
    - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
      displayName: INSTALL LATEST TERRAFORM VERSION
      inputs:
        terraformVersion: '$(Terraform_Version)'
# Terraform Init:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM INIT
      inputs:
        command: 'init'
        provider: 'azurerm'
        workingDirectory: '$(WorkingDir)'
        backendServiceArm: '$(ServiceConnection)' 
        backendAzureRmResourceGroupName: '$(ResourceGroup)' 
        backendAzureRmStorageAccountName: '$(StorageAccount)'
        backendAzureRmContainerName: '$(Container)'
        backendAzureRmKey: '$(TfstateFile)'
# Terraform Validate:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM VALIDATE
      inputs:
        command: 'validate'
        provider: 'azurerm'
        workingDirectory: '$(WorkingDir)'
        environmentServiceNameAzureRM: '$(ServiceConnection)'
# Terraform Plan:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM PLAN
      inputs:
        command: 'plan'
        provider: 'azurerm'
        workingDirectory: '$(WorkingDir)'
        commandOptions: '--var-file=$(TfvarFilename) --out=$(PlanFilename)'
        environmentServiceNameAzureRM: '$(ServiceConnection)'
# Detect Terraform Changes:-
    - task: PowerShell@2
      name: DetectTFChanges
      displayName: DETECT TERRAFORM CHANGES
      inputs:
        workingDirectory: '$(workingDir)'
        targetType: 'inline'
        script: |
          Write-Host "#######################################################"
          Write-Host "Intial value of variable: $(anyTfChanges)"
          Write-Host "#######################################################"
          $plan = $(terraform show -json tfplan | ConvertFrom-Json)
          $count = $plan.resource_changes.change.actions.length
          $actions = ($plan.resource_changes | where { 'no-op' -notcontains $_.change.actions }).length -ne 0
          Write-Host "##vso[task.setvariable variable=anyTfChanges;isOutput=true]$actions"
          Write-Host "#######################################################"
          Write-Host "Are there Changes in Infrastruture: $actions"
          Write-Host "#######################################################"
          Write-Host "TOTAL NO OF CHANGES: $count"
          Write-Host "#######################################################"
# Copy Files to Artifacts Staging Directory:-
    - task: CopyFiles@2
      displayName: COPY FILES ARTIFACTS STAGING DIRECTORY
      inputs:
        SourceFolder: '$(WorkingDir)'
        Contents: |
          **/*.tf
          **/*.tfvars
          **/*$(PlanFilename)*
        TargetFolder: '$(Target)'
# Publish Artifacts:-
    - task: PublishBuildArtifacts@1
      displayName: PUBLISH ARTIFACTS
      inputs:
        targetPath: '$(Target)'
        artifactName: '$(Artifact)'

```

| __BUILD STAGE PERFORMS BELOW:-__ |
| --------- |

| __##__ | __TASKS__ |
| --------- | --------- |
| 1. | Terraform Installer installed in Azure DevOps Build Agent.|
| 2. | Terraform Init. |
| 3. | Terraform Validate. |
| 4. | Terraform Plan. |
| 5. | Detect Terraform Changes (Powershell Inline Script). |
| 6. | Copy the Terraform files (Most Importantly __Terraform Plan Output__) to Artifacts Staging Directory. |
| 6. | Publish Artifacts. |


| NOTE:- |
| --------- |

```
- task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0

```
| EXPLANATION:- |
| --------- |
| Instead of using __TerraformInstaller@0__ YAML Task, I have specified the Full Name. This is because I have __two Terraform Extensions__ in my DevOps Organisation and with each of the Terraform Extension, exists the Terraform Install Task |
| The Names of the Extensions are listed below:- |
| 1. Terraform by Microsoft DevLabs   |
| 2. Azure Pipelines Terraform Tasks by Charles Zipp |
| If __Full Name is not provided__, then __below Error is Encountered__:- | 
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/tvul3qk468st3qbshyrj.png) |
 
| DETECT TERRAFORM CHANGES:- |
| --------- |

```
# Detect Terraform Changes:-
    - task: PowerShell@2
      name: DetectTFChanges
      displayName: DETECT TERRAFORM CHANGES
      inputs:
        workingDirectory: '$(workingDir)'
        targetType: 'inline'
        script: |
          Write-Host "#######################################################"
          Write-Host "Intial value of variable: $(anyTfChanges)"
          Write-Host "#######################################################"
          $plan = $(terraform show -json tfplan | ConvertFrom-Json)
          $count = $plan.resource_changes.change.actions.length
          $actions = ($plan.resource_changes | where { 'no-op' -notcontains $_.change.actions }).length -ne 0
          Write-Host "##vso[task.setvariable variable=anyTfChanges;isOutput=true]$actions"
          Write-Host "#######################################################"
          Write-Host "Are there Changes in Infrastruture: $actions"
          Write-Host "#######################################################"
          Write-Host "TOTAL NO OF CHANGES: $count"
          Write-Host "#######################################################"

```

| EXPLANATION:- |
| --------- |
| The Original Creator of this Powershell Script is __HOUSSEM DELLAI__. I modified his Script to meet my requirements. __TRUE__ or __FALSE__ value is returned along with Total Count of Changes observed in Terraform Plan. |

| __PIPELINE STAGE - DEPLOY:-__ |
| --------- |

```
#################
# STAGE: DEPLOY
#################

- stage: DEPLOY
  condition: |
     and(succeeded(),
       ne(variables['Build.SourceBranch'], 'refs/heads/main'),
       eq(dependencies.BUILD.outputs['build.DetectTFChanges.anyTfChanges'], 'true')
     )
  jobs:
  - deployment: 
    displayName: Deploy
    environment: '$(PipelineEnv)'
    pool:
      vmImage: '$(BuildAgent)'
    strategy:
      runOnce:
        deploy:
          steps:
# Download Artifacts:-
          - task: DownloadBuildArtifacts@0
            displayName: DOWNLOAD ARTIFACTS
            inputs:
              buildType: 'current'
              downloadType: 'single'
              artifactName: '$(Artifact)'
              downloadPath: '$(System.ArtifactsDirectory)' 
# Install Terraform Installer in the Build Agent:-
          - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
            displayName: INSTALL LATEST TERRAFORM VERSION
            inputs:
              terraformVersion: '$(Terraform_Version)'
# Terraform Init:-
          - task: TerraformTaskV2@2
            displayName: TERRAFORM INIT
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF/'
              backendServiceArm: '$(ServiceConnection)' 
              backendAzureRmResourceGroupName: '$(ResourceGroup)' 
              backendAzureRmStorageAccountName: '$(StorageAccount)'
              backendAzureRmContainerName: '$(Container)'
              backendAzureRmKey: '$(TfstateFile)'
# Terraform Apply:-
          - task: TerraformTaskV2@2
            displayName: TERRAFORM APPLY
            inputs:
              provider: 'azurerm'
              command: 'apply'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF'
              commandOptions: '--var-file=$(TfvarFilename)'
              environmentServiceNameAzureRM: '$(ServiceConnection)'

```

| __DEPLOY STAGE PERFORMS BELOW:-__ |
| --------- |

| __##__ | __TASKS__ |
| --------- | --------- |
| 1. | __DEPLOY__ Stage will Execute only if the following conditions are met -  1) __BUILD__ Stage gets completed successfully.  2) Source/Working Branch __NOT EQUAL__ to __Main__ Branch. 3) If there are __CHANGES__ detected in Terraform Plan. |
| 2. | __DEPLOY__ Stage will Execute only after Approval. The Approval is integrated with Pipeline Environment defined and applied in Deploy Stage. |
| 3. | Download the Published Artifacts. |
| 4. | Terraform Installer installed in Azure DevOps Build Agent.|
| 5. | Terraform Init. |
| 6. | Terraform Apply. |


| __PIPELINE STAGE - PULL_REQUEST_ASSOCIATE_WORKITEMS:-__ |
| --------- |

```
##################################################################################################
# STAGE: CREATE PR
# CREATE AND COMPLETE PULL REQUEST BY ASSOCIATING WORKITEMS AND DELETING SOURCE BRANCH
#################################################################################################

- stage: PULL_REQUEST_ASSOCIATE_WORKITEMS
  condition: |
     and(succeeded(), 
       ne(variables['Build.SourceBranch'], 'refs/heads/main') 
     )
  dependsOn: DEPLOY
  jobs:
  - job: PULL_REQUEST_WORKITEMS
    displayName: CREATE PR | ASSOCIATE WORKITEMS | COMPLETE
    steps:
# Download Keyvault Secrets:-
    - task: AzureKeyVault@2
      inputs:
        azureSubscription: '$(ServiceConnection)'
        KeyVaultName: '$(KV-Name)'
        SecretsFilter: '*'
        RunAsPreJob: false
# Install Az DevOps CLI Extension in the Build Agent:-
    - task: AzureCLI@1
      displayName: INSTALL DEVOPS CLI EXTENSION
      inputs:
        azureSubscription: '$(ServiceConnection)'
        scriptType: ps
        scriptLocation: inlineScript
        inlineScript: |
          az extension add --name azure-devops
          az extension show --name azure-devops --output table
# Validate Az DevOps CLI Extension in the Build Agent:-
    - task: PowerShell@2
      displayName: VALIDATE AZ DEVOPS CLI
      inputs:
        targetType: 'inline'
        script: |
          az devops -h
# Set Default DevOps Organization and Project:-
    - task: PowerShell@2
      displayName: DEVOPS LOGIN + SET DEFAULT DEVOPS ORG & PROJECT
      inputs:
        targetType: 'inline'
        script: |
         echo "$(PAT)" | az devops login  
         az devops configure --defaults organization=$(DevOpsOrganisation) project=$(DevOpsProjName)
# Create Workitem + Create PR + Associate Workitem with PR + Complete the PR + Delete Source Branch:-
    - task: PowerShell@2
      displayName: CREATE & COMPLETE PULL REQUEST + WORKITEMS + DELETE SOURCE BRANCH
      inputs:
        targetType: 'inline'
        script: |
          Write-Host "#######################################################"
          Write-Host "NAME OF THE SOURCE BRANCH: $(Build.SourceBranchName)"
          Write-Host "#######################################################"
          $i="PR-"
          $j=Get-Random -Maximum 1000
          Write-Host "###################################################"
          Write-Host "WORKITEM NUMBER GENERATED IN DEVOPS BOARD: $i$j"
          Write-Host "###################################################"
          $wid = az boards work-item create --title $i$j --type "Issue" --query "id"
          Write-Host "#######################################################" 
          Write-Host "WORKITEM ID is: $wid"
          Write-Host "#######################################################"
          $prid = az repos pr create --repository $(DevOpsRepoName) --source-branch $(Build.SourceBranchName) --target-branch $(DevOpsDestinationBranch) --work-items $wid --transition-work-items true --query "pullRequestId"
          Write-Host "#######################################################"
          Write-Host "PULL REQUEST ID is: $prid"
          Write-Host "#######################################################"
          Write-Host "##### TO BE MERGED FROM $(Build.SourceBranchName) TO Main #####"
          az repos pr update --id $prid --auto-complete true --squash true --status completed --delete-source-branch true
          Write-Host "##### MERGE SUCCESSFULL #####"

```

| __PULL REQUEST STAGE PERFORMS BELOW:-__ |
| --------- |

| __##__ | __TASKS__ |
| --------- | --------- |
| 1. | __PULL REQUEST__ Stage will Execute only if the following conditions are met -  1) __DEPLOY__ Stage gets completed successfully.  2) Source/Working Branch __NOT EQUAL__ to __Main__ Branch. |
| 2. | Download Secrets from Keyvault (DevOps Personal Access Token [PAT]). |
| 3. | Install Azure DevOps CLI Extension in Build Agent. |
| 4. | Validate Azure DevOps CLI Extension in Build Agent. |
| 5. | Set Default DevOps Organization and Project. |
| 6. | Create Work-Item In DevOps Board. |
| 7. | Create Pull Request. |
| 8. | Associate Work-Item with Pull Request. |
| 9. | Complete Pull Request with Squash Commit. |
| 10. | Delete Source Branch. |

| PART #3:- | 
| --------- |

| __OBJECTIVE OF TERRAFORM CODE SNIPPET:-__ |
| --------- |
| Create a Resource Group. |
| Create a User Assigned System Managed Identity. |

| __TERRAFORM (main.tf):-__ |
| --------- |

```
terraform {
  required_version = ">= 1.2.3"

   backend "azurerm" {
    resource_group_name  = "tfpipeline-rg"
    storage_account_name = "tfpipelinesa"
    container_name       = "terraform"
    key                  = "PR/createprworkitem.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.2"
    }   
  }
}
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

```

| __TERRAFORM (usrmid.tf):-__ |
| --------- |

```
## Azure Resource Group:-
resource "azurerm_resource_group" "rg" {
 name     = var.rg-name
 location = var.rg-location
}

## Azure User Assigned Managed Identities:-
resource "azurerm_user_assigned_identity" "az-usr-mid" {
  
 name                = var.usr-mid-name
 resource_group_name = azurerm_resource_group.rg.name
 location            = azurerm_resource_group.rg.location
  
 depends_on          = [azurerm_resource_group.rg]
 }

```

| __TERRAFORM (variables.tf):-__ |
| --------- |

```
variable "rg-name" {
  type        = string
  description = "Name of the Resource Group"
}

variable "rg-location" {
  type        = string
  description = "Resource Group Location"
}

variable "usr-mid-name" {
  type        = string
  description = "Name of the User Assigned Managed Identity"
}

```

| __TERRAFORM (usrmid.tfvars):-__ |
| --------- |

```
rg-name         = "AMTest100"
rg-location     = "West Europe"
usr-mid-name    = "AMUSRMID100"

```

__NOW ITS TIME TO TEST !!!...__

| __TEST CASES:-__ |
| --------- |

| __TEST CASE #1: PIPELINE EXECUTED FROM WORKING BRANCH (FOR EXAMPLE: DEV) WITH CHANGES:-__ |
| --------- |
| __DESIRED OUTPUT: BUILD, DEPLOY AND PR STAGE EXECUTED SUCCESSFULLY.__ |
| __BRANCHES:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/pzcze5srq0txcgwhuzl0.png) |
| __PIPELINE RUN:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jq5crxhiu3p1wsmbxb7y.png) |
| __PIPELINE STAGE BUILD EXECUTED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ls8exet6oryt1bdyteyz.png) |
| __PIPELINE STAGE DEPLOY WAITING APPROVAL:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ka6hf7257av62wvnrhqw.png) |
| __PIPELINE STAGE DEPLOY EXECUTED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/zzgx0chzc1k6wvnb3cdg.png) |
| __PIPELINE STAGE PULL REQUEST EXECUTED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/zz0yqjt2v71ewspiliaa.png) |
| __OVERALL PIPELINE RUN STATUS:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/uke77ty7wrorlsq6a69c.png) |
| __WORK-ITEMS WITH RANDOM NAME CREATED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/9jnym113s4f0ajv8xr9q.png) |
| __PR ASSOCIATING WORK-ITEM COMPLETED SUCCESSFULLY WITH SQUASH COMMIT:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/8uo6tir3vie38wjy45cn.png) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/qxogn58au5uh4rbqvrd3.png) |
| __SOURCE/WORKING BRANCH DELETED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7gf95f72hxv1s8sv427u.png) |
| __AZURE RESOURCES DEPLOYED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/nvwo54q4yju5lbcdosy3.png) |

| __TEST CASE #2:- PIPELINE EXECUTED FROM WORKING BRANCH (FOR EXAMPLE: DEV) WITH NO CHANGES:-__ |
| --------- |
| __DESIRED OUTPUT:- BUILD STAGE EXECUTED SUCCESSFULLY. DEPLOY AND PR STAGES ARE SKIPPED.__ |
| __BRANCHES:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/izhne1ndo9rk7mujxuzm.png) |
| __PIPELINE RUN:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jq5crxhiu3p1wsmbxb7y.png) |
| __PIPELINE STAGE BUILD EXECUTED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/oea2a11880sf0g6cjs8t.png) |
| __PIPELINE STAGE DEPLOY AND PR GETS SKIPPED:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ttvpr8iwcj9qdialcfut.png) |
| __WORKING BRANCH REMAINS (FOR EXAMPLE - DEV):-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/c4vzgvxnl7t4s1z1nxxh.png) |
 

| __TEST CASE #3:__ PIPELINE EXECUTED FROM MAIN BRANCH:- |
| --------- |
| __DESIRED OUTPUT:-__ BUILD STAGE EXECUTED SUCCESSFULLY. DEPLOY AND PR STAGES ARE SKIPPED. |
| __BRANCHES:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/npvq4xywa73222tz1tlk.png) |
| __PIPELINE RUN:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/0ape2qeyih5e3ldjaj47.png) |
| __PIPELINE STAGE BUILD EXECUTED SUCCESSFULLY:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/vbptaqxftjkse20sqbbm.png) |
| __PIPELINE STAGE DEPLOY AND PR GETS SKIPPED:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wadnnusytas19h04xce7.png) |

__Hope You Enjoyed the Session!!!__

__Stay Safe | Keep Learning | Spread Knowledge__
