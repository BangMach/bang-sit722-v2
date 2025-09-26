#!/bin/bash

# Jenkins Setup Script for bang-sit722-v2 Project
# This script helps set up Jenkins with required tools and configurations

set -e

echo "=========================================="
echo "Jenkins Setup for bang-sit722-v2 Project"
echo "=========================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root for security reasons."
   echo "Please run as a regular user with sudo privileges."
   exit 1
fi

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Java (required for Jenkins)
echo "Installing Java 11..."
sudo apt install -y openjdk-11-jdk

# Add Jenkins repository and install Jenkins
echo "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins

# Install Docker
echo "Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Terraform
echo "Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# Install Python and pip
echo "Installing Python 3.10 and pip..."
sudo apt install -y python3.10 python3-pip python3.10-venv

# Install Git (if not already installed)
sudo apt install -y git

# Start and enable Jenkins
echo "Starting Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Start and enable Docker
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 30

# Get Jenkins initial admin password
echo "=========================================="
echo "Jenkins Setup Complete!"
echo "=========================================="
echo "Jenkins is now running on: http://localhost:8080"
echo ""
echo "Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "Next Steps:"
echo "1. Open http://localhost:8080 in your browser"
echo "2. Use the initial admin password above to unlock Jenkins"
echo "3. Install suggested plugins"
echo "4. Create an admin user"
echo "5. Install additional required plugins:"
echo "   - Pipeline"
echo "   - Blue Ocean"
echo "   - Azure CLI Plugin"
echo "   - Docker Pipeline"
echo "   - Kubernetes CLI Plugin"
echo "   - Email Extension Plugin"
echo "   - Credentials Binding Plugin"
echo ""
echo "Required Tools Installed:"
echo "- Java $(java -version 2>&1 | head -n 1)"
echo "- Docker $(docker --version)"
echo "- Azure CLI $(az --version | head -n 1)"
echo "- kubectl $(kubectl version --client --short 2>/dev/null || echo 'kubectl installed')"
echo "- Terraform $(terraform --version | head -n 1)"
echo "- Python $(python3 --version)"
echo ""
echo "=========================================="

# Create a sample Jenkins job configuration
echo "Creating sample job configurations..."
mkdir -p ~/jenkins-jobs

cat > ~/jenkins-jobs/bang-sit722-ci-job.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>CI Pipeline for bang-sit722-v2 microservices application</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.92">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/BangMach/bang-sit722-v2.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/testing</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>jenkins/Jenkinsfile.ci</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

echo "Sample Jenkins job configuration created at: ~/jenkins-jobs/bang-sit722-ci-job.xml"
echo "Import this into Jenkins after setup is complete."