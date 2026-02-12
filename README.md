# Documenting my DevOps journey

This repo aims to document my DevOps learning journey, something I didn’t expect to enjoy as much as I do. It also serves as a reference as I build and expand my homelab even if, I will factory reset everything to cleanly*? remake everything.

Every day should be documented inside the `day` folder

## Security Notice
Since ive seen at least 80 unique clone in the past day, Ill try my best to not share anything private but, in production:
- Secrets are managed with `Sealed Secrets` (Which now should be working for this repo)
- Credentials are stored in either `Azure Key Vault` or `AWS Secrets Manager`
- Actual Network policies and roles are enforced, not simple port forwarding
- All sensitive values are encrypted at rest

**Current demo credentials:**
- Grafana: `admin/admin`

## Debug scripts
Added a light debugging script to feed my local llm that capture Flux state for troubleshooting
```bash
./scripts/debug_flux.sh
```
