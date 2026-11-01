# OM STUDY AI — चरण 1 (Phase 1–3 की नींव)

## इसमें क्या बना है
- Welcome, Signup (नाम यहीं लिया जाता है), Login, Forgot Password, Logout
- Dashboard (14 मॉड्यूल; पसंद के हिसाब से स्कूल / सरकारी परीक्षा / ITI कार्ड दिखते हैं)
- एक-एक सवाल वाला Onboarding (हर जवाब तुरंत आपके खाते में सेव, बीच में छोड़ें तो वहीं से शुरू)
- Profile (नाम, भाषा बदलना, सेटअप के जवाब बदलना)
- `firestore.rules`: हर user सिर्फ़ अपना डेटा पढ़/लिख सकता है
- GitHub Actions से APK बनाने की फ़ाइल

## अभी नहीं बना (ईमानदारी से)
AI टीचर, सिलेबस, स्टडी प्लान, नोट्स, वीडियो, टेस्ट, प्रगति, AI मेमोरी, रिमाइंडर, ऑफलाइन मोड, Admin panel, खाता डिलीट करने की सुविधा।
ये डैशबोर्ड पर "जल्द आएगा" दिखते हैं। यह कोड इस वातावरण में compile या टेस्ट नहीं हो सका, इसलिए पहली बार build में गलतियाँ आ सकती हैं। तब error मुझे भेज दें।

## कदम 1: GitHub पर repository
1. GitHub में नया repository बनाएँ, नाम: `om-study-ai` (Private रखें)।
2. इस ZIP की सारी फ़ाइलें repo में डालें (फ़ोल्डर समेत: `lib`, `.github/workflows` वगैरह)।
   फ़ोन के browser में "Add file → Upload files" फ़ोल्डर नहीं लेता। आसान तरीका: repo खोलकर `.` दबाएँ (github.dev editor) या Codespaces इस्तेमाल करें, और फ़ाइलें एक-एक बनाकर paste करें। अटक जाएँ तो मुझे बताएँ।

## कदम 2: Firebase (Spark / free plan)
1. console.firebase.google.com पर नया project बनाएँ।
2. Build → Authentication → Get started → **Email/Password** चालू करें।
3. Build → Firestore Database → Create database → **Production mode**।
4. Firestore → Rules में `firestore.rules` की पूरी लिखाई paste करके **Publish** करें।
5. Project settings → Add app → Android → package name: `com.omstudy.om_study_ai`।
6. `google-services.json` डाउनलोड करें और खोलकर ये 4 मान नोट करें:
   - `current_key` (api_key के अंदर) → **FB_API_KEY**
   - `mobilesdk_app_id` → **FB_APP_ID**
   - `project_id` → **FB_PROJECT_ID**
   - `project_number` → **FB_SENDER_ID**

Firebase की free सीमाएँ और शर्तें समय-समय पर बदलती हैं। इस्तेमाल से पहले Firebase की pricing page देख लें।

## कदम 3: GitHub Secrets
Repo → Settings → Secrets and variables → Actions → New repository secret
ऊपर के चारों नाम और मान जोड़ें।

## कदम 4: APK बनाना
1. Repo → Actions → **Build APK** → Run workflow।
2. हरा निशान आने तक रुकें (5–10 मिनट)। लाल हो तो log खोलकर आख़िरी error मुझे भेजें।
3. Run के नीचे Artifacts से `om-study-ai-apk` डाउनलोड करें (ZIP है, खोलकर `app-release.apk` निकालें)।
4. फ़ोन में APK खोलें → "Unknown sources" की अनुमति दें → Install।

## सुरक्षा नोट
- `FB_*` मान Firebase के public config हैं, AI की secret keys नहीं। असली सुरक्षा `firestore.rules` से आती है।
- AI की API key कभी app या GitHub में नहीं डालेंगे। वह चरण 5 में Cloudflare Worker जैसे backend में रहेगी।
