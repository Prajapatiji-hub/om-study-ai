# OM STUDY AI — Hindi-first Android learning app

## अभी तक क्या काम करता है
- Welcome, Signup, Login, Forgot Password और Logout
- Dashboard और विद्यार्थी की प्रोफ़ाइल
- एक-एक सवाल वाला Onboarding; जवाब खाते में सेव होते हैं और बाद में बदले जा सकते हैं
- निजी Firestore profile, onboarding और syllabus progress के लिए owner-based rules
- मेरा सिलेबस स्क्रीन (अभी verified syllabus catalog खाली है; आधिकारिक पाठ्यक्रम जोड़ना बाकी है)
- मेरा स्टडी प्लान: दैनिक समय लक्ष्य, पढ़ाई के काम जोड़ना/पूरा करना/हटाना और Firebase में प्रति-यूज़र सेव करना
- मेरे नोट्स: नोट बनाना, पढ़ना, बदलना और हटाना; अलग-अलग per-user documents
- प्रैक्टिस टेस्ट: 5 शुरुआती नमूना प्रश्न, चार विकल्प, उत्तर की जाँच, स्पष्टीकरण और निजी खाते में परिणाम सेव करना
- मेरी प्रगति: पिछले अधिकतम 50 टेस्ट के परिणाम, औसत प्रतिशत और सर्वश्रेष्ठ प्रतिशत
- मेरी गलतियाँ: नए टेस्ट प्रयासों के गलत उत्तर, सही उत्तर और समझाने वाला हल निजी खाते से दिखाना
- AI टीचर UI और Gemini Worker backend का Free-plan implementation; Cloudflare Worker deploy और phone test बाकी
- GitHub Actions से Android APK build

## AI और Free plan
- Firebase Spark plan पर ही रहें। Firebase Functions deploy न करें।
- AI backend `workers/` में Cloudflare Workers Free के लिए है।
- Gemini API की free-tier quota सीमित है; quota पूरी होने पर AI अस्थायी रूप से जवाब नहीं देगा।
- Cloudflare Worker में Firebase ID token सत्यापित होता है। Gemini API key केवल Cloudflare Worker secret में रखें।
- Worker URL को GitHub repository secret `AI_WORKER_URL` में तभी जोड़ें जब Worker deploy हो जाए।
- Gemini Free-tier data handling अलग हो सकती है; AI में password, payment details या संवेदनशील निजी जानकारी न भेजें।
- Free tiers बदल सकते हैं; किसी भी plan को paid में upgrade न करें।

## अभी किन चीज़ों पर काम बाकी है
स्थायी AI memory, AI chat history, App Check enforcement, durable per-user rate limiting, आधिकारिक सत्यापित syllabus सामग्री, विषयवार नोट्स/PDF import, वीडियो संसाधन, विस्तृत प्रश्न बैंक, सत्यापित PYQ, विस्तृत कमजोरी विश्लेषण, reminders, offline सामग्री, admin panel और account deletion।
इनमें से किसी सुविधा को पूरा न मानें जब तक उसका कोड, सुरक्षा और फोन पर परीक्षण पूरा न हो।

## GitHub repository
Repository **Public** ही रखनी है। Visibility न बदलें।

## Firebase
- मौजूदा Firebase project और Android package com.omstudy.om_study_ai ही उपयोग करें।
- Firestore Rules को main branch की firestore.rules से Firebase Console → Firestore Database → Rules में Publish करें, लेकिन केवल संबंधित PR merge होने के बाद।
- Rules Publish करने के बाद दो अलग-अलग खातों से cross-user access जाँचें।
- कोई खुला allow rule न लगाएँ; catch-all deny-all बना रहना चाहिए।

## GitHub Actions और APK
1. Repository → Settings → Secrets and variables → Actions में `AI_WORKER_URL` secret जोड़ें, deploy के बाद।
2. Repository → Actions → Build APK खोलें।
3. सबसे नया main push run पूरा होने दें और हरा Success देखें।
4. उस run के Artifacts में om-study-ai-apk ZIP डाउनलोड करें।
5. ZIP से app-release.apk निकालकर Android में install करें।
6. PR build सफल होना उपयोगी जाँच है, लेकिन अंतिम main build और फोन पर परीक्षण भी आवश्यक हैं।

## GitHub Actions secrets
- FB_API_KEY
- FB_APP_ID
- FB_PROJECT_ID
- FB_SENDER_ID
- AI_WORKER_URL (Cloudflare Worker deploy के बाद)

Firebase Android client configuration values और Worker URL secrets में रहें। Gemini provider की निजी API key केवल Cloudflare Worker secret में रहे; उसे GitHub या Android app में कभी न रखें।

## सुरक्षा और डेटा
- सभी निजी छात्र डेटा का रास्ता users/{uid}/... के नीचे हो।
- Firestore rules में authenticated UID का document path UID से मिलना जरूरी है।
- Admin role client से assign नहीं होगा।
- पुराने छात्र डेटा या Firebase project को बिना backup और स्पष्ट migration योजना के delete न करें।
