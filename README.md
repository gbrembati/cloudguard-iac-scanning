# CloudGuard IaC Security with ShiftLeft
This repository is a collection of Terraform projects that can be used with CloudGuard Platform to implement and show IaC scanning. Later below we also have some example of Jenkins files to be used in conjunction with these to integrate it as part of a Pipeline.

## How to start?
First, you need to have a CloudGuard CSPM account, and if you don't, you can create one with these links:
1. Create an account in [Europe Region](https://secure.eu1.dome9.com/v2/register/invite)
2. Create an account in [Asia Pacific Region](https://secure.ap1.dome9.com/v2/register/invite)
3. Create an account in [United States Region](https://secure.dome9.com/v2/register/invite)

## Get API credentials in your CloudGuard CPSM Portal
Then you will need to get the API credentials that you will be using on Jenkins to send the findings to the CloudGuard Platform.

![CSPM Service Account](/zimages/create-cpsm-serviceaccount.jpg)

## Jenkins Prerequisites
On the Jenkins server that you use you would need to have:
1. **Terraform Installed**: Please refer to Terraform documentation on how to download it: [Terraform Installation](https://www.terraform.io/downloads.html)
2. **ShiftLeft Installed**: Please refer to our public documentation on how to download it: [ShiftLeft Installation](https://sc1.checkpoint.com/documents/CloudGuard_Dome9/Documentation/Shift-Left/Installing-shiftleft.htm?tocpath=ShiftLeft%20%7C_____1)

## Configuration Steps
Once you have these two components running on your system:
1. In **Jenkins menu**, select **Manage Jenkins** and, under **System Configuration**, select **Manage Plugins**.
2. In **Plugin Manager**, under Available, find two entities **Credentials** and **Pipeline** and install them.
3. In **Jenkins menu**, select **Manage Jenkins** and, under Security, select **Manage Credentials**:      
    Add credentials for CloudGuard:      
    In **Username**, enter the ID from the CloudGuard access token.      
    In **Password**, enter the Secret.      
    In **ID**, enter the name to distinguish these credentials, for example, CloudGuard_Credentials.      
4. In **Jenkins menu**, select **Manage Jenkins** and, under Security, select **Manage Credentials**:       
    Add credentials for AWS:      
    In **Username**, enter the ACCESS_KEY_ID gathered from the AWS Console.      
    In **Password**,enter the AWS_SECRET_ACCESS_KEY gathered from the AWS Console.      
    In **ID**, enter the name to distinguish these credentials, for example, AWS_Credentials.         
5. In the CloudGuard Portal create a **ShiftLeft environment and copy its ID**, you will use it in the pipeline later.

## Example | Jenkins Pipeline on the AWS Terraform Project
This pipeline is structured to perform four simple steps.
1. **Syntax Validation**: Get the Terraform code from this repository and it checks its terraform syntax
2. **Terraform Code Scan**: Scan the Terraform code against Cloudguard-managed **Terraform AWS CIS Foundations**
3. **Terraform Execution Plan Scan**: Scan the Terraform execution plan against Cloudguard-managed **Terraform AWS CIS Foundations**
4. **Cleanup of the files**: It cleans the file created by the pipeline

```pipeline
pipeline {
    agent any
    stages {
        stage('IaC-Syntax-Validation') {
            steps {
                dir('iac-code') {
                    git branch: 'main',
                    url: 'https://github.com/gbrembati/terraform-iac-scanning.git'
                }
                sh '''
                    cd iac-code/aws

                    terraform --version
                    terraform init
                    terraform validate 
                '''
            }
        }
        
        stage('IaC-Shiftleft-Code-Scan') {
            environment {
               CHKP_CLOUDGUARD_CREDS = credentials('CloudGuard_Credentials')
            }
            steps {
                sh '''
                    export SHIFTLEFT_REGION=us
                    export CHKP_CLOUDGUARD_ID=$CHKP_CLOUDGUARD_CREDS_USR
                    export CHKP_CLOUDGUARD_SECRET=$CHKP_CLOUDGUARD_CREDS_PSW
                    shiftleft iac-assessment --Infrastructure-Type terraform --path iac-code/aws --ruleset -64 --severity-level Critical --Findings-row --environmentId <SHIFTLEFT-ENVIRONMENT-ID>
                '''
            }
        }
        
        stage('IaC-Shiftleft-Execution-Plan') {
            environment {
               AWS_CREDS = credentials('AWS_Credentials')
               CHKP_CLOUDGUARD_CREDS = credentials('CloudGuard_Credentials')
            }
            steps {
                sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_CREDS_USR
                    export AWS_SECRET_ACCESS_KEY=$AWS_CREDS_PSW
                    export AWS_DEFAULT_REGION="eu-west-1"

                    terraform --version                    
                    terraform plan --out=tf-plan-file 
                    terraform show --json tf-plan-file > plan-file.json
                    
                    export SHIFTLEFT_REGION=us
                    export CHKP_CLOUDGUARD_ID=$CHKP_CLOUDGUARD_CREDS_USR
                    export CHKP_CLOUDGUARD_SECRET=$CHKP_CLOUDGUARD_CREDS_PSW
                    shiftleft iac-assessment --Infrastructure-Type terraform --path ./plan-file.json --ruleset -64 --severity-level Critical --Findings-row --environmentId <SHIFTLEFT-ENVIRONMENT-ID>
                '''
            }
        }
        
        stage('IaC-Provider-Cleanup') {
            steps {
                sh '''
                    du -sh
                    rm plan-file.json
                    rm -r .terraform
                    rm -r .terraform.lock.hcl
                    du -sh
                '''
            }
        }
    }
}
```