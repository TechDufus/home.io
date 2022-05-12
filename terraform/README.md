# Terraform

This is a Terraform project to deploy my home lab environment within `ProxMox`.

## Installation

Install Terraform with:

```bash
$ brew install terraform
```
or
```bash
$ apt-get install terraform
```
or
```bash
$ pip install terraform
```

## Usage

Use Terraform to create and manage infrastructure.

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Configuration Variables

The following variables are not included in this project's committed code:

- pm_user
- pm_password

The reason is these are sensitive information and should not be committed to a public repository.
Additionally, I don't have a way to store these in a secure way, home vault, etc. I just create a `credentials.auto.tfvars` file in the project root when I clone this project.

