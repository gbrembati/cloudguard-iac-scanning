# CloudGuard IaC Security with Spectral
This repository is a collection of Terraform projects that can be used with CloudGuard Platform to implement and show IaC scanning. Later below we also have some example of Jenkins files to be used in conjunction with these to integrate it as part of a Pipeline.

## How to start?
First, you need to have a CloudGuard CSPM account, and if you don't, you can create one with these links:
1. Create an account in [Europe Region](https://secure.eu1.dome9.com/v2/register/invite)
2. Create an account in [Asia Pacific Region](https://secure.ap1.dome9.com/v2/register/invite)
3. Create an account in [United States Region](https://secure.dome9.com/v2/register/invite)

## Get Spectral DSN credentials in your CloudGuard CPSM Portal
Then you will need to get the API credentials that you will be using on Jenkins to send the findings to the CloudGuard Platform.

![CSPM Service Account](/zimages/create-cpsm-serviceaccount.jpg)

## Jenkins Prerequisites
On the Jenkins server that you use you would need to have:
1. **Terraform Installed**: Please refer to Terraform documentation on how to download it: [Terraform Installation](https://www.terraform.io/downloads.html)

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
5. In the CloudGuard Portal create a **Spectral environment and copy its ID**, you will use it in the pipeline later.

## Example | Jenkins Pipeline on the AWS Terraform Project
This pipeline is structured to perform four simple steps.
1. **Syntax Validation**: Get the Terraform code from this repository and it checks its terraform syntax
2. **Terraform Code Scan**: Scan the Terraform code against Cloudguard-managed best practice rules
3. **Cleanup of the files**: It cleans the file created by the pipeline

```pipeline
pipeline {
    agent any
    stages {
        stage('Syntax Validation') {
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
        stage('Spectral Install & Config') {
            environment {
               SPECTRAL_DSN = credentials('spectral-dsn')
            }
            steps {
                sh '''
                    curl -L 'https://get.spectralops.io/latest/x/sh?dsn=$SPECTRAL_DSN' | sh
                    $HOME/.spectral/spectral config --dsn $SPECTRAL_DSN
                '''
            }
        }

        stage('Spectral Scan') {
            steps {
                sh '''
                    cd iac-code/aws
                    spectral scan --ok --table --include-tags base,audit,iac 
                '''
            }
        }
        
        stage('Provider Cleanup') {
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