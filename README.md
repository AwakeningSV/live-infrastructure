# live-infrastructure

[Awakening Church][AC] uses CloudFlare and Microsoft Azure to host
[nginx-rtmp configured for H.264/AAC HLS streaming][awakening-nginx-rtmp]
running in Docker on CoreOS. This repositiory creates that infrastructure
using [Terraform][]. You can use this configuration to start your own
copy of our live video transcoding system.

We use this system for 4 hours a week. Costs are estimated at about $5 per week.
However, since Microsoft offers
[$5,000 per year in Azure credits to non-profits, including churches][azure-credit],
this costs us nothing to run. Thanks Microsoft!

## Usage

Gather the required [Azure credentials][azure-setup].
[Install Terraform.][install] Configure the [required Terraform variables][tfvars]:

 - `azure_region` Azure region, e.g. `West US 2`
 - `azure_tenant_id` Azure [Tenant ID][azure-setup]
 - `azure_client_id` Azure [Client ID][azure-setup]
 - `azure_client_secret` Azure [Client secret][azure-setup]
 - `azure_storage_prefix` Unique name for Azure storage, e.g. `livevideoadventure`
 - `cf_email` CloudFlare Email
 - `cf_token` CloudFlare API Token
 - `cf_domain` CloudFlare Domain, e.g. `awakeningchurch.com`
 - `cors_http_origin` Corresponds to [CORS_HTTP_ORIGIN][usage] setting in awakening-nginx-rtmp
 - `publish_secret` Corresponds to [PUBLISH_SECRET][usage] setting in awakening-nginx-rtmp
 - `ssh_key_file` File containing the public SSH key for the launched CoreOS instance

Check the plan:

    terraform plan

Apply to launch the infrastructure:

    terraform apply -parallelism=1

Note: `-parallelism=1` is required because of a [CloudFlare provider bug][eof].

We use these resources for a few hours. Once the broadcast is complete,
we simply destroy the resources:

    terraform destroy -force -parallelism=1

## License

MIT

[AC]: https://awakeningchurch.com
[Terraform]: https://www.terraform.io
[install]: https://www.terraform.io/intro/getting-started/install.html
[tfvars]: https://www.terraform.io/intro/getting-started/variables.html
[awakening-nginx-rtmp]: https://github.com/awakening-church/awakening-nginx-rtmp
[usage]: https://github.com/awakening-church/awakening-nginx-rtmp/blob/master/README.md#usage
[eof]: https://github.com/hashicorp/terraform/issues/8011
[azure-setup]: https://www.terraform.io/docs/providers/azurerm/index.html#creating-credentials
[azure-credit]: https://www.microsoft.com/en-us/philanthropies/product-donations/products/azure