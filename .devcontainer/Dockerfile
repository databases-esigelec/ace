# .devcontainer/Dockerfile
FROM mcr.microsoft.com/vscode/devcontainers/python:3.9 as base

# Use official HashiCorp Terraform image
FROM hashicorp/terraform:latest as terraform

# Use official Google Cloud SDK image
FROM google/cloud-sdk:latest as gcloud

# Use official Bitnami kubectl image
FROM bitnami/kubectl:latest as kubectl

# Use official Docker image
FROM docker:latest as docker

# Final stage
FROM base as final
ARG USERNAME=vscode

# Copy binaries from official images
COPY --from=terraform /bin/terraform /usr/local/bin/
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
# # Install Google Cloud SDK the proper way
RUN curl -sSL https://sdk.cloud.google.com > /tmp/gcl && bash /tmp/gcl --install-dir=~/gcloud --disable-prompts
# ENV PATH $PATH:~/gcloud/google-cloud-sdk/bin
# Install Python packages
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Setup non-root user and ensure proper permissions
USER ${USERNAME}

# Add autocompletion and aliases
RUN echo 'source <(kubectl completion bash)' >> ~/.bashrc \
    && echo 'source /usr/share/google-cloud-sdk/completion.bash.inc' >> ~/.bashrc \
    && echo 'complete -C /usr/bin/terraform terraform' >> ~/.bashrc

# Verify installations (with proper error handling)
RUN set -e; \
    terraform version; \
    kubectl version --client; 
    