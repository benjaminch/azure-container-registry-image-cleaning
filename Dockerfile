FROM debian:stable-slim

ARG REGISTRY_NAME
ARG DAYS_TO_KEEP

RUN apt-get update && apt-get install -y \
  curl \
  apt-transport-https \
  lsb-release \
  gnupg \
  jq \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash

CMD az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID && \
  repositories=$(az acr repository list --name $REGISTRY_NAME -o tsv) && \
  for repo in $repositories; do \
  echo "Cleaning repository : $repo"; \
  tags=$(az acr repository show-tags --name $REGISTRY_NAME --repository $repo --orderby time_desc -o tsv); \
  tags_to_keep=$(echo "$tags" | head -n $DAYS_TO_KEEP); \
  tags_to_delete=$(echo "$tags" | tail -n +$((DAYS_TO_KEEP + 1))); \
  for tag in $tags_to_delete; do \
  echo "Deleting image : $repo:$tag"; \
  az acr repository delete --name $REGISTRY_NAME --image $repo:$tag --yes; \
  done; \
  done
