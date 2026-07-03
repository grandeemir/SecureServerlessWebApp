> **⚠️ Project Status: Under Development **  

<div align="center">
  <img src="assets/serverlessWebApp_2.drawio2.svg" alt="Architecture Diagram" width="800">
</div>

<h1 align="center">🔐 Secure Serverless Web Application: Secure File Vault</h1>

<div align="center">
  <h3>Secure, Encrypted & Self-Healing Cloud Architecture</h3>
</div>

<div align="center">
  <img src="https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS">
  <img src="https://img.shields.io/badge/Terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black" alt="JavaScript">
  <img src="https://img.shields.io/badge/Security-Zero_Trust-blue?style=for-the-badge" alt="Security: Zero Trust">
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License: MIT">
</div>

---

## 📌 Project Overview

This project demonstrates a **Zero-Trust serverless web application** built on AWS.  
It implements a "Secure File Vault" where users can safely store, access, and manage critical documents.
The architecture focuses heavily on API security, identity-based access control, frontend protection, data encryption, continuous logging, threat detection, and automated remediation.

By adopting a **defense-in-depth strategy**, this architecture assumes that breaches are inevitable and implements strict controls at every layer—from the user interface delivery to the backend data storage.

---

## 🛡️ Security Architecture & Components

This project implements Zero-Trust principles using a robust stack of AWS services:

### 1️⃣ Edge & Network Layer
- **Amazon CloudFront:** Secure content delivery network (CDN) for delivering the static web application frontend.
- **Amazon S3 (Frontend):** Hosts the static web application assets (HTML, CSS, JS).
- **AWS WAF (Web Application Firewall):** Protects CloudFront and API Gateway against Layer 7 attacks, including SQLi, XSS, and rate limiting.

### 2️⃣ Identity & Access Management
- **Amazon Cognito:** Manages user sign-up, sign-in, and provides JWT-based authentication.
- **Amazon API Gateway:** Serves as the backend API entry point, validating Cognito JWTs via Authorizers.

### 3️⃣ Compute Security
- **AWS Lambda:** Serverless backend compute executing with strictly scoped IAM roles.
- **AWS Secrets Manager:** Securely stores and dynamically retrieves application secrets without hardcoding them in the source code.

### 4️⃣ Data Protection
- **Amazon DynamoDB:** Stores file metadata and application state, encrypted at rest using AWS KMS.
- **Amazon S3 (Data Vault):** Securely stores uploaded files. Files are uploaded via presigned URLs and encrypted via KMS. Block Public Access is strictly enforced.

<details>
<summary><b>Click to view an example of our strict IAM S3 Policy</b></summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::secure-file-vault-data",
        "arn:aws:s3:::secure-file-vault-data/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```
</details>

### 5️⃣ Logging, Monitoring & Threat Detection
- **AWS CloudTrail:** Continuously records all API activity across the AWS account.
- **Amazon GuardDuty:** Provides intelligent threat detection and continuous monitoring of AWS accounts and workloads.
- **AWS Config:** Evaluates and monitors the compliance of AWS resources against security rules.

### 6️⃣ Automated Threat Response
- **Amazon EventBridge:** Routes security findings from GuardDuty and non-compliance events from AWS Config.
- **Amazon SNS:** Sends alerts and notifications regarding security events.
- **Automated Remediation (Lambda):** EventBridge triggers specialized Lambda functions to automatically revert unsafe configurations (e.g., misconfigured S3 bucket policies) or isolate compromised identities.

---

## 🎯 Zero-Trust Design Principles Applied

- **Never trust network traffic:** WAF strictly filters and monitors incoming requests.
- **Never trust identity without verification:** Cognito and API Gateway ensure all API calls carry a valid, unexpired token.
- **Enforce least privilege:** Every Lambda function and AWS resource operates under strict IAM policies.
- **Encrypt data at rest and in transit:** TLS for all API and frontend traffic, with KMS managing at-rest encryption for S3 and DynamoDB.
- **Continuously monitor for anomalies:** GuardDuty and CloudTrail actively log and analyze environment behavior.
- **Automatically respond to threats:** EventBridge and Remediation Lambdas ensure self-healing capabilities.

---

## 🚀 Quick Start / Deployment

> ⚠️ **Note:** Ensure you have the [AWS CLI](https://aws.amazon.com/cli/) configured and [Terraform](https://www.terraform.io/) installed before proceeding.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/zero-trust-serverless-application.git
   cd zero-trust-serverless-application
   ```

2. **Initialize and Deploy Infrastructure (DEV Environment):**
   ```bash
   cd environments/DEV
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

3. **Configure the Frontend:**
   After Terraform completes, note the generated `Cognito User Pool ID`, `Client ID`, and `API Gateway URL`. Update these values in `scripts/webapp/config.js`.

4. **Upload Frontend to S3:**
   Upload the contents of `scripts/webapp/` to your newly created Frontend S3 bucket.

---

## 📂 Repository Structure

```text
zero-trust-serverless-application/
│
├── README.md
├── assets/
│   └── serverlessWebApp.drawio.svg         # Architecture Diagram
│
├── environments/
│   ├── DEV/                                # Development Environment Terraform Variables
│   └── PROD/                               # Production Environment Terraform Variables
│
├── modules/                                # Terraform Infrastructure Modules
│   ├── api_gw/                             # API Gateway
│   ├── cognito/                            # User Authentication
│   ├── dynamoDB/                           # Metadata Storage
│   ├── lambda/                             # Backend Compute
│   ├── s3/                                 # Secure File Vault Storage
│   ├── S3&CDN/                             # Frontend Hosting (S3 + CloudFront)
│   ├── secret_manager/                     # Secrets Management
│   ├── security_layer/
│   │   ├── cloudtrail/                     # Audit Logging
│   │   ├── config/                         # Compliance Monitoring
│   │   ├── eventbridge/                    # Event Routing
│   │   ├── guardDuty/                      # Threat Detection
│   │   └── waf/                            # Web Application Firewall
│   └── sns/                                # Notifications
│
└── scripts/
    ├── todo_app.py
    └── webapp/                             # Vanilla JS Static Frontend App
        ├── index.html                      # Landing Page
        ├── auth.html                       # Login & Sign Up Page
        ├── vault.html                      # Main Secure Vault Interface
        ├── error.html                      # Error Page
        ├── styles.css                      # Application Styling
        ├── auth.js / vault.js              # Frontend Logic & Cognito Integration
        └── config.js                       # AWS Resource Configuration
```

---

<div align="center">

### 💰 You can help me by Donating
  [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/grandeemir) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/grandeemir)

</div>