## Deploy backend (free) on Render

### 1) Create a Render account and deploy
- Push this project to GitHub.
- On Render: **New → Blueprint** and select your repo.
- Render will read `render.yaml` and create **charity-backend** service.

### 2) Set environment variables on Render
In the created service, set:
- **PUBLIC_BASE_URL**: your Render URL, e.g. `https://charity-backend.onrender.com`
- **MYFATOORAH_API_KEY** and **MYFATOORAH_WEBHOOK_SECRET**
- **ZAINCASH_MSISDN**, **ZAINCASH_MERCHANT_ID**, **ZAINCASH_SECRET**

### 3) Configure provider callbacks
#### WebView landing pages (already hosted by backend)
- Success page: `${PUBLIC_BASE_URL}/payment/success?sessionId=...`
- Cancel page: `${PUBLIC_BASE_URL}/payment/cancel?sessionId=...`

#### MyFatoorah
- Redirection URL used by backend (auto): `${PUBLIC_BASE_URL}/api/payments/redirect/myfatoorah?sessionId=<internal>&paymentId=<from MF>`
- Webhook URL: `${PUBLIC_BASE_URL}/api/payments/webhooks/myfatoorah`

Enable Webhook V2 and set the secret in the MyFatoorah portal.

#### ZainCash
- Redirect URL used by backend (auto): `${PUBLIC_BASE_URL}/api/payments/redirect/zaincash?sessionId=<internal>`
ZainCash will append `token=...` on redirect; backend verifies it using `ZAINCASH_SECRET`.

### 4) Point the Flutter app to the backend
Build Flutter with:
- `--dart-define=API_BASE_URL=https://charity-backend.onrender.com`

### Important note about production readiness
The backend is configured to use **Postgres** on Render via `DATABASE_URL`.
If `DATABASE_URL` is not set, it falls back to in-memory storage (not recommended).

