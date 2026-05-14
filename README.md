![Architecture Diagram](assets/serverlessWebApp.drawio.svg)

# 🔐 Zero-Trust Serverless Web Application: Secure File Vault
### Secure, Encrypted & Self-Healing Cloud Architecture

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

### 5️⃣ Logging, Monitoring & Threat Detection
- **AWS CloudTrail:** Continuously records all API activity across the AWS account.
- **Amazon GuardDuty:** Provides intelligent threat detection and continuous monitoring of AWS accounts and workloads.
- **AWS Config:** Evaluates and monitors the compliance of AWS resources against security rules.

### 6️⃣ Automated Threat Response
- **Amazon EventBridge:** Routes security findings from GuardDuty and non-compliance events from AWS Config.
- **Amazon SNS:** Sends alerts and notifications regarding security events.
- **Automated Remediation (Lambda):** EventBridge triggers specialized Lambda functions to automatically revert unsafe configurations (e.g., misconfigured S3 bucket policies) or isolate compromised identities.

---

## 📂 Repository Structure

```
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
        ├── app.js / auth.js / vault.js     # Frontend Logic & Cognito Integration
        └── config.js                       # AWS Resource Configuration
```

---

## 🎯 Zero-Trust Design Principles Applied

- **Never trust network traffic:** WAF strictly filters and monitors incoming requests.
- **Never trust identity without verification:** Cognito and API Gateway ensure all API calls carry a valid, unexpired token.
- **Enforce least privilege:** Every Lambda function and AWS resource operates under strict IAM policies.
- **Encrypt data at rest and in transit:** TLS for all API and frontend traffic, with KMS managing at-rest encryption for S3 and DynamoDB.
- **Continuously monitor for anomalies:** GuardDuty and CloudTrail actively log and analyze environment behavior.
- **Automatically respond to threats:** EventBridge and Remediation Lambdas ensure self-healing capabilities.

---

## 🏁 Conclusion

This project serves as a comprehensive reference architecture for building secure, scalable, and resilient modern web applications. By seamlessly integrating front-end delivery, back-end compute, identity management, and automated security monitoring, it demonstrates the practical implementation of Zero-Trust principles in a fully serverless AWS environment.

  ## 💰 You can help me by Donating
  [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/grandeemir) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/grandeemir) 