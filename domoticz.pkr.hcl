packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

# --- Variables ---

variable "aws_region" {
  type        = string
  default     = "eu-north-1"
  description = "AWS Region where the image will be built (default: Stockholm)"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type used for building (t3.micro is cheap/free tier eligible)"
}

# --- Builder Configuration (AWS) ---

source "amazon-ebs" "domoticz" {
  ami_name      = "domoticz-server-{{timestamp}}"
  instance_type = var.instance_type
  region        = var.aws_region
  ssh_username  = "ubuntu"

  # Base image configuration: Ubuntu 24.04 LTS Server (Standard)
  # This version includes standard network tools required by Packer
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }

  # Tagging the image for organization in AWS Console
  tags = {
    Name    = "Domoticz Server"
    Builder = "Packer"
    OS      = "Ubuntu 24.04 LTS"
  }
}

# --- Build Steps (Provisioners) ---

build {
  sources = ["source.amazon-ebs.domoticz"]

  # Step 1: System and dependency preparation
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "echo '=== Waiting for Cloud-Init (30s) ==='",
      "sleep 30",

      "echo '=== System Update ==='",
      "sudo apt-get update",

      "echo '=== Installing dependencies ==='",
      "sudo apt-get install -y \\",
      "  unzip \\",
      "  wget \\",
      "  curl \\",
      "  libusb-1.0-0 \\",
      "  libusb-0.1-4 \\",
      "  libcurl4-gnutls-dev \\",
      "  python3 \\",
      "  python3-dev"
    ]
  }

  # Step 2: Domoticz Installation
  provisioner "shell" {
    inline = [
      "echo '=== Downloading Domoticz ==='",
      "mkdir domoticz",
      "cd domoticz",
      # Using -q (quiet) flag to reduce log noise
      "wget -q https://releases.domoticz.com/release/domoticz_linux_x86_64.tgz",
      "tar -xzf domoticz_linux_x86_64.tgz",
      "rm domoticz_linux_x86_64.tgz",

      "echo '=== Installing to /opt/domoticz ==='",
      "cd ..",
      "sudo mv domoticz /opt/domoticz",
      "sudo chown -R ubuntu:ubuntu /opt/domoticz"
    ]
  }

  # Step 3: Systemd Service Configuration
  provisioner "shell" {
    inline = [
      "echo '=== Creating service file ==='",
      "sudo bash -c 'cat > /etc/systemd/system/domoticz.service <<EOF",
      "[Unit]",
      "Description=Domoticz Home Automation Server",
      "After=network.target",
      "",
      "[Service]",
      "User=ubuntu",
      "Group=ubuntu",
      "WorkingDirectory=/opt/domoticz",
      # SSL set to port 8443 to allow non-root user execution
      "ExecStart=/opt/domoticz/domoticz -www 8080 -sslwww 8443",
      "Restart=on-failure",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF'",

      "echo '=== Enabling service ==='",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable domoticz"
    ]
  }
}
