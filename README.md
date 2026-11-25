# Enterprise Regulated Payment Platform: AKS, Terraform & FIPS 140-3 / PCI-DSS Reference Architecture

> **Confidentiality Notice:** All client identifiers, internal domains, subscription IDs, and proprietary secrets have been sanitized in accordance with NDA and enterprise security policies. This repository documents the reference cloud architecture, security guardrails, and engineering decisions behind a regulated payment processing workload.

---

## 1. Executive Summary & Business Context

A major enterprise operating high-throughput digital payment and e-card services required migrating legacy workloads onto a **PCI-DSS and FIPS 140-3 compliant** Kubernetes platform on Microsoft Azure.

### Key Challenges
* **End-of-Life (EOL) Runtime & OS Exposure:** Legacy `.NET 6` microservices running on outdated Debian-based container images faced expired upstream package repositories, unpatched OpenSSL CVEs, and impending PCI audit blockers.
* **Strict Cryptographic Enforcement:** Compliance auditors mandated **FIPS 140-3 validated cryptography** across both the host kernel/OS layer and the application runtime (`OpenSSL` / `SymCrypt`), disabling non-compliant cipher suites (e.g., ChaCha20).
* **Zero-Drift Infrastructure & Governance:** Multiple environments (`UAT`, `Staging`, `Production`) required deterministic provisioning via Infrastructure as Code (IaC) under strict Cloud Center of Excellence (CCoE) RBAC policies.

---

## 2. Repository Structure

```text
client2-case-study/
├── README.md                          # Architecture overview, compliance posture & outcomes
├── docker/
│   ├── Dockerfile                     # Multi-stage .NET 10 on Azure Linux 3.0 (SymCrypt FIPS)
│   └── NuGet.config                   # Hermetic Nexus proxy & signature validation policy
├── terraform/
│   ├── main.tf                        # AKS cluster with FIPS-enabled node pools & CCoE RBAC
│   └── variables.tf                   # Environment-parameterized cluster configuration
├── pipelines/
│   └── azure-pipelines.yml            # Multi-stage CI/CD with Trivy CVE gates & approvals
└── kubernetes/
    └── deployment.yaml                # Hardened non-root pod spec, ServiceAccount & PVC mounts
```

---

## 3. High-Level Architecture

```text
+--------------------+      +-------------------------+      +-----------------------------+
|  DevOps & App Devs | ---> |  Azure DevOps CI/CD     | ---> |  Nexus / Private Registry   |
|  (Git / PR Gates)  |      |  - Trivy CVE Scanning   |      |  - Signed Container Images  |
+--------------------+      |  - Artifact Signing     |      |  - Verified NuGet Proxies   |
                            +------------+------------+      +--------------+--------------+
                                         |                                  |
                                         v                                  v
                            +------------+------------+      +--------------+--------------+
                            |  Terraform IaC          | ---> |  Azure Kubernetes Service   |
                            |  - AKS Node Pools       |      |  (FIPS-Enabled Node Pools)  |
                            |  - VNet / NSG / CCoE    |      |  +-----------------------+  |
                            +-------------------------+      |  | Azure Linux 3.0 Pod   |  |
                                                             |  | .NET 10 + SymCrypt    |  |
                                                             |  | OpenSSL FIPS Provider |  |
                                                             |  +-----------------------+  |
                                                             +-----------------------------+
```

---

## 4. Core Engineering Solutions

### A. Container Hardening: .NET 10 on Azure Linux 3.0 with SymCrypt
* **Base Image Migration:** Standardized workload images on **Microsoft Azure Linux 3.0 (Mariner)**, removing unnecessary shell utilities and reducing the attack surface.
* **Runtime Upgrade & Roll-Forward:** Migrated legacy services to **.NET 10** runtime images (leveraging `DOTNET_ROLL_FORWARD` where required for backward-compatible assemblies).
* **Cryptographic Compliance (`SymCrypt`):** Configured the OpenSSL `symcryptprovider` (`1.10+`) inside the container runtime and verified active FIPS algorithm enforcement at the pod level (`openssl list -providers`), ensuring strict TLS 1.2/1.3 compliance.

### B. Shift-Left CI/CD & Supply Chain Security (Azure DevOps + Nexus)
* **Automated Vulnerability Gates:** Integrated **Trivy** container scanning directly into Azure DevOps CI pipelines to block builds containing critical/high CVEs before registry promotion.
* **Hermetic Dependency Resolution:** Routed NuGet and container base image pulls through an internal **Sonatype Nexus** repository with cryptographic signature validation (`NuGet.config` policy enforcement) to prevent supply-chain tampering.
* **Sequential Release Governance:** Structured multi-stage Azure DevOps release pipelines with parallel branch validation, automated smoke tests, and mandatory approval gates prior to production rollout.

### C. Infrastructure as Code & AKS Cluster Operations (Terraform)
* **FIPS-Enabled AKS Node Pools:** Provisioned dedicated system and user node pools (`Standard_D`-series) with `fips_enabled = true` at the VMSS/OS level.
* **Zero-Downtime Upgrade Strategy:** Managed Kubernetes control plane and node pool version upgrades alongside Azure regional vCPU quota planning (`max_surge` tuning) to avoid quota or version skew disruptions.
* **Identity & Storage Isolation:** Scoped workload permissions via dedicated Kubernetes Service Accounts, Azure Key Vault secret injection, and isolated Azure File Share persistent volumes.

---

## 5. Measurable Outcomes & Impact

| Dimension | Before | After |
| :--- | :--- | :--- |
| **Cryptographic Posture** | Mixed/non-FIPS OpenSSL ciphers; EOL OS packages | **100% FIPS 140-3 / SymCrypt validated** across host & pod runtime |
| **Vulnerability Exposure** | Recurring high/critical OS & runtime CVEs | **Zero critical CVEs** in production via Azure Linux 3.0 & Trivy gates |
| **Audit & Compliance** | Manual evidence gathering per release | **Audit-ready by default** (PCI-DSS & CCoE policy-enforced) |
| **Deployment Reliability** | Manual configuration drift between UAT & Prod | **Immutable Terraform IaC** + automated multi-stage CI/CD |

---

## Author
**Ilias Papadodimas** — Cloud DevOps & Platform Engineering Lead  
Portfolio: [devops-ipap.vercel.app](https://devops-ipap.vercel.app/)
