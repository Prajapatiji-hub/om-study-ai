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
- AI टीचर का शुरुआती UI और Gemini Backend callable; deploy और live test बाकी
- प्रैक्टिस प्रश्न पर AI से चरण-दर-चरण स्पष्टीकरण; live AI के लिए Backend deploy जरूरी
- GitHub Actions से Android APK build

## अभी किन चीज़ों पर काम बाकी है
स्थायी AI memory, AI chat history, App Check enforcement, आधिकारिक सत्यापित syllabus सामग्री, विषयवार नोट्स/अटैचमेंट/PDF import, वीडियो संसाधन, विस्तृत प्रश्न बैंक, परीक्षा-विशिष्ट सत्यापित PYQ, विषयवार कमजोरियों का विस्तृत विश्लेषण, व्यक्तिगत AI memory, reminders, offline सामग्री, admin panel और account deletion।
इनमें से किसी सुविधा को पूरा नहीं मानें जब तक उसका कोड, सुरक्षा और फोन पर परीक्षण पूरा न हो।

## GitHub repository
Repository **Public** ही रखनी है, जैसा तय हुआ है। Visibility न बदलें।

## Firebase
- मौजूदा Firebase project और Android package com.omstudy.om_study_ai ही उपयोग करें।
- Firestore Rules को main branch की firestore.rules से Firebase Console → Firestore Database → Rules में Publish करें, लेकिन केवल संबंधित PR merge होने के बाद।
- Rules Publish करने के बाद दो अलग-अलग खातों से cross-user access जाँचें।
- कोई खुला allow rule न लगाएँ; catch-all deny-all बना रहना चाहिए।

## GitHub Actions और APK
1. Repository → Actions → Build APK खोलें।
2. सबसे नया main push run पूरा होने दें और हरा Success देखें।
3. उस run के Artifacts में om-study-ai-apk ZIP डाउनलोड करें।
4. ZIP से app-release.apk निकालकर Android में install करें।
5. PR build सफल होना उपयोगी जाँच है, लेकिन अंतिम main build और फोन पर परीक्षण भी आवश्यक हैं।

## Firebase build configuration
Workflow को repository Actions secrets चाहिए:
- FB_API_KEY
- FB_APP_ID
- FB_PROJECT_ID
- FB_SENDER_ID

ये Firebase Android client configuration values हैं। AI provider की निजी API keys अलग backend secrets में रहेंगी; उन्हें Android app या Public GitHub source में कभी commit न करें।

## सुरक्षा और डेटा
- सभी निजी छात्र डेटा का रास्ता users/{uid}/... के नीचे हो।
- Firestore rules में authenticated UID का document path UID से मिलना जरूरी है।
- Admin role client से assign नहीं होगा।
- पुराने छात्र डेटा या Firebase project को बिना backup और स्पष्ट migration योजना के delete न करें।