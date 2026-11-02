# OM STUDY AI — सुरक्षित AI Backend

## यह Backend क्या करता है
- Firebase Authentication के बिना AI callable नहीं चलता।
- हर अनुरोध में UID Firebase के सत्यापित Auth token से लिया जाता है; ऐप से भेजे UID पर भरोसा नहीं होता।
- Gemini API key केवल Google Cloud Secret Manager में रहती है; Flutter ऐप और Public GitHub में नहीं।
- हर खाते के लिए 12 अनुरोध प्रति मिनट की शुरुआती सीमा है।
- सवाल/बातचीत का पाठ इस शुरुआती संस्करण में Firestore में सेव नहीं होता।
- विद्यार्थी की मौजूदा प्रोफ़ाइल से नाम, भाषा और चुने हुए लक्ष्य संदर्भ के रूप में पढ़े जाते हैं।
- सामान्य AI Teacher और प्रश्न समझाने के दो मोड हैं।

## Provider
पहला provider Google Gemini Developer API है। मॉडल अभी `gemini-2.5-flash` है। Provider और model को बाद में लागत/गुणवत्ता परीक्षण के आधार पर बदला जा सकता है।

## Deploy करने से पहले
1. Firebase project `prajapati-507d7` में Cloud Functions/Cloud Build/Secret Manager की आवश्यक सेवाएँ चालू हों।
2. Firebase project को Blaze billing plan की जरूरत पड़ सकती है। Deploy से पहले Firebase Console में billing और संभावित शुल्क देखें।
3. Google AI Studio में Gemini API key बनाएँ। इसे GitHub issue, source file, ऐप या chat में paste न करें।
4. अपने सुरक्षित कंप्यूटर/टर्मिनल पर Firebase CLI और Node.js 20 स्थापित करें।
5. Repository की root directory में ये commands चलाएँ:

```bash
firebase use prajapati-507d7
firebase functions:secrets:set GOOGLE_GENAI_API_KEY
```

CLI key को छिपाकर पूछेगा। उसे command में लिखकर shell history में न डालें।

6. फिर deploy करें:

```bash
cd functions
npm install
npm run check
cd ..
firebase deploy --only functions:askStudyTeacher
```

## Android app
Flutter app Firebase Callable Functions SDK से `asia-south1` region में `askStudyTeacher` बुलाती है। Function deploy होने के बाद ही live AI response आएगा। APK build सफल होना अपने-आप Backend deploy होना नहीं है।

## सुरक्षा और सीमाएँ
- शुरुआती rate limit 12 requests / minute / authenticated UID है; इसे वास्तविक उपयोग और लागत देखकर समायोजित करें।
- App Check अभी enforce नहीं है। सार्वजनिक लॉन्च से पहले Android App Check (Play Integrity) सेटअप और enforcement जरूरी है।
- Chat history केवल मौजूदा स्क्रीन/session में है; स्थायी AI memory अभी नहीं बनाई गई।
- AI की सामग्री गलत हो सकती है। आधिकारिक परीक्षा/सरकारी जानकारी को आधिकारिक स्रोत से सत्यापित करें।
- API key rotate/revoke करने का अधिकार Firebase/Google Cloud project owner के पास है।
- Firebase Functions का वास्तविक deploy और Android device test किए बिना AI को live/complete न कहें।
