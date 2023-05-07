# blue-green

A template for Blue Green deployment using GCP and Terraform. Inspired by the design described [here](https://github.com/psimakov/gcp-mig-simple)

![blue-green](https://user-images.githubusercontent.com/5305984/236659370-ac2c9ea9-fe69-4bb3-aaf4-19f36596657d.png)

# usage

### Initial setup (one time)

```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v1 \
TF_VAR_green_version=v1 \
TF_VAR_deployment=false \
terraform apply
```

### On deployment bring up a new stack 
```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v1 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

### Traffic switch

##### Switch traffic to the new stack
```sh
TF_VAR_active_stack=green \
TF_VAR_blue_version=v1 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

##### Update the Old stack
```sh
TF_VAR_active_stack=green \
TF_VAR_blue_version=v2 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

##### Switch traffic back to (updated) old stack
```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v2 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=true \
terraform apply
```

### Clean up deployment stack
```sh
TF_VAR_active_stack=blue \
TF_VAR_blue_version=v2 \
TF_VAR_green_version=v2 \
TF_VAR_deployment=false \
terraform apply
```
