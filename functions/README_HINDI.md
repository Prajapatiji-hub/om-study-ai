# पुराना Firebase Functions AI Backend

यह directory पुराने Firebase Cloud Functions implementation को संदर्भ/इतिहास के लिए रखती है।

**Firebase Spark (Free) project में इसे deploy न करें।** अब AI backend के लिए `workers/` directory में Cloudflare Workers Free implementation उपयोग करें। `firebase.json` में Functions deploy target जानबूझकर हटा दिया गया है, ताकि गलती से paid Cloud Functions deployment न हो।

Gemini API key कभी इस directory, GitHub source, Android app या chat में न डालें। नई key केवल Cloudflare Worker secret `GOOGLE_GENAI_API_KEY` में रखें।
