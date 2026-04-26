# n8n Database Initializer Stack

The `/postgresql/n8n_db` stack prepares PostgreSQL for n8n. It creates the n8n
application namespace, generates the application database password, synchronizes
the password into Kubernetes Secrets, and runs a local Helm chart that creates
the n8n database and database user.

This stack bridges the PostgreSQL stack and the n8n application stack.

## 🧭 What it creates

- Kubernetes namespace `n8n` by default
- Generated application database password
- Kubernetes Secret `n8n-db-secret` in the PostgreSQL namespace
- Kubernetes Secret `n8n-db-secret` in the n8n namespace
- Helm release `n8n-db-init`, using the local chart in `./chart`
- Remote-state outputs consumed by `/n8n`

## ✅ Prerequisites

Before applying this stack:

1. Apply the root stack and confirm `kubeconfig` exists in the repository root.
2. Apply `/postgresql` successfully.
3. Confirm `backend.hcl` exists in the repository root.
4. Authenticate with the OCI CLI using the `DEFAULT` profile:

   ```bash
   oci session authenticate
   ```

The apply scripts read backend settings and remote-state keys from the root and
PostgreSQL stacks, then initialize and apply this stack.

## 🚀 Create

Run from the repository root.

Linux/macOS:

```bash
cd ./postgresql/n8n_db
./apply-n8n-db.sh
```

Windows PowerShell:

```powershell
cd ./postgresql/n8n_db
.\ApplyN8nDb.ps1
```

After apply, the n8n database, user, and Kubernetes credentials are ready for
the `/n8n` stack.

## 🛑 Destroy

Destroy `/n8n` before destroying this stack. Then run:

Linux/macOS:

```bash
cd ./postgresql/n8n_db
./destroy-n8n-db.sh
```

Windows PowerShell:

```powershell
cd ./postgresql/n8n_db
.\DestroyN8nDb.ps1
```

## ⚙️ Configuration

Common variables are defined in `variables.tf`:

- `application_namespace`: namespace where n8n reads database credentials
- `db_name`: application database name, defaulting to `n8n`
- `db_user`: application database user, defaulting to `n8n`
- `db_password_secret_name`: Secret that stores the generated application password
- `postgresql_key`: remote-state key for the PostgreSQL stack

The default PostgreSQL service host is `postgresql.postgresql`. If needed,
override `db_host` to match your chart service name or DNS requirement.

## ⚠️ Notes

- This stack depends on the PostgreSQL admin Secret created by `/postgresql`.
- Passwords are generated and stored in Kubernetes Secrets.
- It should be applied after `/postgresql` and before `/n8n`.
