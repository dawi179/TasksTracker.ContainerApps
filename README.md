- [Introduction](#introduction)
- [Preparation](#preparation)
  - [Install and Initialize DAPR](#install-and-initialize-dapr)
  - [Az Cli Extensions](#az-cli-extensions)
  - [Create Azure resources](#create-azure-resources)


# Introduction

This folder is used to follow the workshop [Azure Container Apps - Workshop](https://azure.github.io/aca-dotnet-workshop/)

# Preparation

## Install and Initialize DAPR

```shell
brew install dapr/tap/dapr-cli
dapr init
docker ps
```

## Az Cli Extensions

```shell
az extension add --name containerapp --upgrade
az extension add --name application-insights
```

## Create Azure resources

see file [CommandsToExecute.sh](./CLI/CommandsToExecute.sh) for more information


