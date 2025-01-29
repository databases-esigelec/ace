# .devcontainer/Dockerfile
FROM mcr.microsoft.com/vscode/devcontainers/python:3.9

ARG TERRAFORM_VERSION
ARG KUBECTL_VERSION
ARG GOOGLE_CLOUD_SDK_VERSION
ARG USERNAME=vscode

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    gnupg \
    lsb-release \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt-get update \
    && apt-get install -y terraform=${TERRAFORM_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update -y \
    && apt-get install -y google-cloud-sdk=${GOOGLE_CLOUD_SDK_VERSION}-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Setup non-root user
USER $USERNAME

# Add autocompletion for various tools
RUN echo 'source <(kubectl completion bash)' >> ~/.bashrc \
    && echo 'source /usr/lib/google-cloud-sdk/completion.bash.inc' >> ~/.bashrc \
    && echo 'complete -C /usr/bin/terraform terraform' >> ~/.bashrc