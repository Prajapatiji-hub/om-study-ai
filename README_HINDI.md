# OM STUDY AI — चरण 1 (Phase 1–3 की नींव)

## इसमें क्या बना है
- Welcome, Signup (नाम यहीं लिया जाता है), Login, Forgot Password, Logout
- Dashboard (14 मॉड्यूल; पसंद के हिसाब से स्कूल / सरकारी परीक्षा / ITI कार्ड दिखते हैं)
- एक-एक सवाल वाला Onboarding (हर जवाब तुरंत आपके खाते में सेव, बीच में छोड़ें तो वहीं से शुरू)
- Profile (नाम, भाषा बदलना, सेटअप के जवाब बदलना)
- Firestore rules का प्रारंभिक owner-only ढाँचा; Firebase में नियम publish और दो-खाते वाला access test अभी बाकी है
- GitHub Actions से Android APK build (नवीनतम main build सफल)

## अभी नहीं बना (ईमानदारी से)
AI टीचर, वास्तविक syllabus catalog, study plan, notes, videos, tests, progress analytics, persistent AI memory, reminders, offline mode, Admin panel और account deletion।
Dashboard पर इनके कुछ विकल्प अभी “जल्द आएगा” दिखाते हैं। सफल APK build का अर्थ यह नहीं कि हर सुविधा पूरी या security-tested है।

## GitHub repository
यह repository फिलहाल **Public** रखी गई है, जैसा तय हुआ है। इसे Private में न बदलें।

## Firebase सेटअप
1. Firebase Console में project खोलें।
2. Build → Authentication → Get started → **Email/Password** चालू करें।
3. Build → Firestore Database बनाएँ और **Production mode** चुनें।
4. Firestore → Rules में repository की `firestore.rules` फ़ाइल की पूरी सामग्री paste करके **Publish** करें।
5. Project settings → Add app → Android → package name: `com.omstudy.om_study_ai`।
6. `google-services.json` डाउनलोड करें और उसमें से ये मान लें:
   - `current_key` (api_key के अंदर) → **FB_API_KEY**
   - `mobilesdk_app_id` → **FB_APP_ID**
   - `project_id` → **FB_PROJECT_ID**
   - `project_number` → **FB_SENDER_ID**

Firebase की free सीमाएँ और शर्तें बदल सकती हैं। इस्तेमाल से पहले Firebase pricing देखें।

## GitHub Actions Secrets
Repo → Settings → Secrets and variables → Actions → New repository secret में ये चारों secrets जोड़ें:
- `FB_API_KEY`
- `FB_APP_ID`
- `FB_PROJECT_ID`
- `FB_SENDER_ID`

Build workflow अब इन secrets से Firebase configuration लेता है। इनमें से कोई secret न होने पर build जानबूझकर रुक जाएगा, ताकि बिना Firebase configuration वाला APK गलती से सही build न समझा जाए। Firebase client config कोई AI provider secret नहीं है; असली database access सुरक्षा Firestore Rules से लागू होती है।

## APK बनाना
1. Repo → Actions → **Build APK** → Run workflow।
2. Build सफल होने पर हरे निशान को देखें।
3. Run के Artifacts में `om-study-ai-apk` ZIP डाउनलोड करें और उसके अंदर `app-release.apk` निकालें।
4. Android पर APK खोलें और install करें। केवल भरोसेमंद build ही install करें।

## सुरक्षा नोट
- AI की निजी API key कभी Android app या GitHub source code में नहीं डालेंगे। उसे बाद में सुरक्षित backend secret के रूप में रखा जाएगा।
- Firestore rules को Firebase Console में publish करना और दो अलग accounts से cross-user access test करना अभी बाकी है।
