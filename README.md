# Draft notes

## Approach

1. Ansible (seems like i will deprecate it, bash does the job so far)
1. `gcloud` CLI.
1. Ansible calling `gcloud` CLI via shell module.
1. Ensure `cfssl` is installed. And most recent version of `openssl` is installed too. Ensure bash v > 4.x. For OSX install openssl with brew and make sure to export PATH.
