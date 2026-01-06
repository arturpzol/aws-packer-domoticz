# AWS Domoticz AMI Builder

This project automates the creation of a **Domoticz Home Automation** Amazon Machine Image (AMI) on AWS using **HashiCorp Packer**.

It builds image based on **Ubuntu 24.04 LTS**, pre-configured with systemd services and necessary dependencies, ready for deployment in the cloud.

---

## Features

* **Infrastructure as Code (IaC):** Fully automated build process using Packer (HCL2).
* **Base Image:** Uses the official **Ubuntu 24.04 LTS (Noble Numbat)** Server.
* **Security:**
    * Domoticz runs as a dedicated non-root user (`ubuntu`).
    * SSL configured on port `8443` (avoiding root privileges requirement).
* **Reliability:** Configured as a `systemd` service with auto-restart capability (`Restart=on-failure`).
* **Dependencies:** Automatically installs Python, LibUSB, Curl, and other required libraries.

## Prerequisites

Before you begin, ensure you have the following installed:

* [HashiCorp Packer](https://www.packer.io/downloads) (v1.7+)
* [AWS CLI](https://aws.amazon.com/cli/) (configured with `aws configure`)
* An active AWS Account

## Usage

### 1. Clone the repository
```bash
git clone [https://github.com/arturpzol/aws-packer-domoticz.git](https://github.com/arturpzol/aws-packer-domoticz.git)
cd aws-packer-domoticz
packer build domoticz.pkr.hcl
