# OM STUDY AI — Free AI backend (Cloudflare Workers)

This worker replaces the Firebase Cloud Functions AI endpoint for projects that must remain on Firebase Spark.

## Free-plan deployment

1. Create a free Cloudflare account at https://dash.cloudflare.com/sign-up.
2. From Cloudflare dashboard, open **Workers & Pages** and create a Worker named `om-study-ai-free`.
3. Connect this public GitHub repository and select branch `main`, or deploy this `workers` folder using Wrangler.
4. Set the Worker variable `FIREBASE_PROJECT_ID` to `prajapati-507d7`.
5. Add a Worker secret named `GOOGLE_GENAI_API_KEY`. Enter the new Gemini key only in Cloudflare's secret field. Never paste it into GitHub, source files, or this chat.
6. Deploy the Worker. Copy its `https://....workers.dev` URL.
7. Set that URL as the Flutter build-time value `AI_WORKER_URL` when building the APK.

## Local checks / deploy (optional)

From this folder:
```sh
npm install
npm run check
npx wrangler login
npx wrangler secret put GOOGLE_GENAI_API_KEY
npx wrangler deploy
```

The Worker validates Firebase ID tokens against Google's public signing keys and checks the exact Firebase project issuer and audience. The Gemini key stays on the Worker. It does not accept a client-supplied UID as identity.

## Free-plan notes

- Cloudflare Workers Free currently has a 100,000 request/day limit and 10 ms CPU time per request. Network wait time for Gemini does not count as CPU time.
- Gemini API Free tier has model-specific quotas and can return 429 when exhausted. Check current quotas in Google AI Studio.
- Free tiers can change. This setup is designed to avoid paid deployment and does not guarantee unlimited AI usage.
- Do not add a payment method or upgrade a plan to follow this guide.
- Gemini Free-tier data handling may differ from paid-tier privacy terms. Do not send passwords, payment details, or highly sensitive personal information to the AI model.

## Security limitations before public launch

- Firebase ID token verification is implemented.
- Tutor, quiz and image endpoints use Cloudflare Rate Limiting bindings keyed by the verified Firebase UID. These are approximate per-edge limits, not a strict global or daily cap; all endpoints fail closed if their limiter is unavailable.
- The app stores private Study Memory and chat sessions under each student's `users/{uid}` Firestore path; checked-in Rules and Emulator tests exist, but production Rules are not published. The Worker does not persist prompts or generated images. Firebase App Check enforcement is not implemented.
- Do not deploy or share the Worker URL until the secret is configured.


## Explicit image generation (source implementation; not deployed)

- The dashboard exposes **AI चित्र बनाएँ**. It sends a short prompt only after the student taps Generate; ordinary chat never triggers image generation.
- The Worker authenticates the Firebase ID token, checks a separate UID-keyed rate limiter (one request per minute), and fails closed if the limiter is missing.
- Llama Guard 3 must explicitly return `safe`; unsafe, unknown or failed moderation blocks generation.
- FLUX.1 [schnell] runs at four steps and returns a 512-class image as temporary bytes. The app does not upload it to Firestore/R2 or retain it after leaving the screen.
- Image generation uses only the existing Workers AI binding. It has no Gemini or paid-provider fallback. On Workers Free, the shared Workers AI allocation is 10,000 Neurons/day; exceeding it causes further operations to fail. If the account is on a Paid plan, overage billing may apply, so do not upgrade or enable billing for this feature.
- Cloudflare Rate Limiting is approximate per edge location and is not a daily quota. Do not describe the one-per-minute limit as a global cost cap.
- This is code only. No Worker has been deployed and no Cloudflare account setting or secret has been changed. Deploy only after owner approval and confirm the account remains on Free.
