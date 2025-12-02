# 🧭 Guide: Setting Up New BigQuery Project Workspaces for MCP in Cursor

This document explains how to create new local folders (Cursor workspaces) that connect directly to different **BigQuery projects** using the **Google MCP Toolbox**.

---

## 1️⃣ Prerequisites (One-Time Setup)

These steps were already completed once on your computer:

| Item | Status | Notes |
|------|---------|-------|
| ✅ **MCP Toolbox downloaded** | Done | You downloaded it directly via Chrome from:<br>https://storage.googleapis.com/genai-toolbox/v0.18.0/windows/amd64/toolbox.exe |
| ✅ **Stored at path** | `C:\Users\russe\toolbox.exe` | Keep this file here permanently — reuse for all projects |
| ✅ **Google Cloud SDK installed** | Done | Required for `gcloud auth` |
| ✅ **Authenticated via ADC** | Done | Run once: `gcloud auth application-default login` |
| ✅ **BigQuery API enabled** | Done | Each project must have BigQuery API turned on in the Google Cloud Console |

---

## 2️⃣ Folder Layout for Multiple Projects

Each BigQuery project should have its own local folder that acts as a **Cursor workspace**.

### Example Layout

```
C:\Projects\
  savvy-gtm-analytics\
    .cursor\mcp.json
  marketing-data-prod\
    .cursor\mcp.json
  finance-reporting\
    .cursor\mcp.json
```

Each folder = one BigQuery project workspace.

---

## 3️⃣ Steps to Set Up a New Project Folder

### Step 1 — Create the Project Folder

In PowerShell:

```powershell
cd C:\Projects
mkdir your-new-project-name
cd your-new-project-name
mkdir .cursor
```

*(Windows hides folders starting with a dot — that’s normal.)*

---

### Step 2 — Create the MCP Config File

Run:

```powershell
notepad .cursor\mcp.json
```

Paste this template and replace `YOUR_PROJECT_ID` with your **BigQuery project ID** (not the display name):

```json
{
  "mcpServers": {
    "bigquery": {
      "command": "C:\\Users\\russe\\toolbox.exe",
      "args": ["--prebuilt", "bigquery", "--stdio"],
      "env": {
        "BIGQUERY_PROJECT": "YOUR_PROJECT_ID"
      }
    }
  }
}
```

**Example:**

```json
{
  "mcpServers": {
    "bigquery": {
      "command": "C:\\Users\\russe\\toolbox.exe",
      "args": ["--prebuilt", "bigquery", "--stdio"],
      "env": {
        "BIGQUERY_PROJECT": "marketing-data-prod"
      }
    }
  }
}
```

Save and close the file.

---

### Step 3 — Open the Folder in Cursor

1. In Cursor, choose **File → Open Folder…**
2. Select the folder you just created (e.g., `marketing-data-prod`).
3. Go to **Settings → MCP**.  
   You should see a connected server named **bigquery**.

That’s it — Cursor is now connected to that project’s BigQuery environment.

---

## 4️⃣ Verify the Connection

In Cursor chat, test with:

```sql
SELECT 1 AS ok;
```

or

```
List my BigQuery datasets.
```

If you get results, your connection is live 🎉

---

## 5️⃣ Optional Configuration

### Read-Only Mode (Safe for Exploration)

If you want to block write operations (e.g., CREATE/REPLACE), update the `args` line to include:

```json
"args": ["--prebuilt", "bigquery", "--stdio", "--writeMode", "blocked"]
```

---

### Switching Google Accounts

If you need to authenticate with a different account, run:

```powershell
gcloud auth application-default login
```

---

### Upgrading the Toolbox

When a new version is released:

1. Download the latest version via Chrome from  
   [https://storage.googleapis.com/genai-toolbox/latest/windows/amd64/toolbox.exe](https://storage.googleapis.com/genai-toolbox/latest/windows/amd64/toolbox.exe)
2. Replace your existing file at  
   `C:\Users\russe\toolbox.exe`
3. Verify the version:

   ```powershell
   C:\Users\russe\toolbox.exe --version
   ```

---

## ✅ Quick Reference

| Task | What to Do |
|------|-------------|
| Add new BigQuery project | Create new folder → `.cursor/mcp.json` with correct project ID |
| Switch projects | Open a different folder in Cursor |
| Toolbox binary location | Always `C:\Users\russe\toolbox.exe` |
| Authentication | One-time `gcloud auth application-default login` |
| Test connection | Run `SELECT 1;` or `List my datasets.` |

---

## 🧠 Example Prompts in Cursor

Once connected, you can ask:

- “List datasets in this BigQuery project.”
- “Show the schema for `my_dataset.events`.”
- “Write a query to summarize conversions by month.”
- “Create a view that counts SQOs daily.”
- “Compare the schema for `marketing.events` and `finance.events` across workspaces.”

---

## 🗂 Summary

You only need **one copy** of `toolbox.exe`.  
Each **Cursor workspace folder** connects to a different BigQuery project by changing the `BIGQUERY_PROJECT` environment variable inside `.cursor/mcp.json`.

That’s it — new folder, new project, instant connection.
