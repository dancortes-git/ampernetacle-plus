# Email Delivery Stack

The `/email` stack provisions OCI Email Delivery resources required for sending
email from n8n. It registers an approved sender and generates an SMTP credential
attached to an existing OCI IAM user.

This stack is intentionally small: it only owns the approved sender and the
SMTP credential. The n8n stack consumes this stack's outputs to configure SMTP
in the Helm release.

## 🧭 What it creates

- An OCI Email Delivery approved sender (`oci_email_sender`) in the root
  compartment
- An OCI IAM SMTP credential (`oci_identity_smtp_credential`) attached to the
  IAM user specified by `smtp_user_id`

## ✅ Prerequisites

Before applying this stack:

1. Apply the root stack so that `compartment_id` is available in remote state.
2. Ensure `backend.hcl` exists in the repository root.
3. Authenticate with the OCI CLI using the `DEFAULT` profile:

   ```bash
   oci session authenticate
   ```

Create the required variables file:

Linux/macOS:

```bash
cp email/terraform.tfvars.template email/terraform.tfvars
```

Windows PowerShell:

```powershell
Copy-Item .\email\terraform.tfvars.template .\email\terraform.tfvars
```

Then edit `email/terraform.tfvars` and update `smtp_sender_email` to match your
approved sender domain:

```hcl
smtp_sender_email = "noreply@example.com"
```

> **Note**: The `smtp_user_id` is automatically detected by the apply and destroy
> scripts using `oci iam user get-current-user` after authentication. You do not
> need to set it in `terraform.tfvars` unless you want to explicitly override it
> with a different user's OCID.

## 🚀 Create

Run from the `email/` directory:

Linux/macOS:

```bash
./email/apply-email.sh
```

Windows PowerShell:

```powershell
.\email\ApplyEmail.ps1
```

After a successful apply, review the outputs:

```bash
terraform -chdir=email output smtp_host
terraform -chdir=email output smtp_user
terraform -chdir=email output smtp_sender_state
```

The `smtp_password` output is sensitive. To read it:

```bash
terraform -chdir=email output smtp_password
```

## ⚠️ DNS verification (required before sending email)

OCI Email Delivery requires the sender domain to be verified before any email
can be sent. After applying this stack, complete the DNS verification in the
OCI console:

1. Open the OCI console → **Email Delivery** → **Email Domains**.
2. Click the domain (`scorestocks.qzz.io`) and follow the SPF and DKIM setup
   instructions.
3. Add the required TXT records in your DNS provider.
4. Wait for the sender state to change from `PENDING` to `ACTIVE`.

Until verification is complete, OCI will silently reject outbound email.

## 🛑 Destroy

Run from the `email/` directory:

Linux/macOS:

```bash
./email/destroy-email.sh
```

Windows PowerShell:

```powershell
.\email\DestroyEmail.ps1
```

> Destroying this stack removes the SMTP credential. If n8n is still running
> and using this credential, email sending will fail until a new credential is
> provisioned and the n8n stack is re-applied.

## ⚙️ Configuration

Variables are defined in `variables.tf`:

- `smtp_sender_email`: **required** approved sender email address in OCI Email
  Delivery. Update this in `terraform.tfvars` to match your sender domain.
- `smtp_user_id`: OCID of the IAM user that owns the SMTP credential.
  Automatically detected from `oci iam user get-current-user` unless overridden.
- `region`: OCI region, defaulting to `sa-saopaulo-1`

The scripts derive `bucket`, `oci_namespace`, and `root_key` automatically from
the repository root `backend.hcl` and root `state.tf`.

## 📋 Free tier

OCI Email Delivery includes 100 outbound emails per day at no cost. This is
sufficient for n8n workflow notifications and credential recovery emails.
