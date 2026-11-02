# Testing plan (user isolation सहित)

स्थिति: नीचे के टेस्ट अभी किए नहीं गए हैं। इन्हें करके ही "पास" लिखें।

## Firestore Rules Playground (फ़ोन से भी चलता है)
Firebase console → Firestore → Rules → Rules Playground

| टेस्ट | उम्मीद |
|---|---|
| Authenticated uid=A, `get /users/A` | Allowed |
| Authenticated uid=A, `get /users/B` | Denied |
| uid=A, `update /users/B` | Denied |
| uid=A, `delete /users/B/onboarding/answers` | Denied |
| Unauthenticated, `get /users/A` | Denied |
| uid=A, `create /users/A` में extra field `role: "admin"` | Denied |
| uid=A, `write /admin_roles/A` | Denied |
| uid=A, `get /users/A/syllabus_progress/track1` | Allowed |
| uid=A, `write /users/A/syllabus_progress/track1` | Allowed |
| uid=A, `get /users/B/syllabus_progress/track1` | Denied |
| uid=A, `write /users/B/syllabus_progress/track1` | Denied |
| uid=A, `write /syllabus_catalog/x` | Denied |

## ऐप पर मैनुअल टेस्ट
1. Signup → नाम Dashboard पर दिखे।
2. गलत पासवर्ड → हिंदी error।
3. Onboarding आधा करके ऐप बंद करें → दोबारा खोलने पर अगले अनुत्तरित सवाल से शुरू।
4. Logout → दूसरे खाते से Login → पुराने खाते का नाम/जवाब न दिखे।
5. Forgot Password का ईमेल आए।


## अतिरिक्त Onboarding टेस्ट
9. Text सवाल में लिखना शुरू करें → “सहेजें” बटन सक्रिय हो।
10. सवाल छोड़ें → `__skipped` उसी यूज़र के onboarding दस्तावेज़ में सेव हो।
11. दो अलग खातों से लॉगिन करके एक-दूसरे के onboarding और syllabus progress पढ़ने की कोशिश करें → अनुमति न मिले।


## Notes मॉड्यूल टेस्ट (PR #7)
1. Firebase Console → Firestore → Rules में firestore.rules की नवीनतम main सामग्री Publish करें (केवल PR merge होने के बाद)।
2. खाते A से Login → Dashboard → मेरे नोट्स → नया नोट बनाएँ।
3. शीर्षक और सामग्री भरकर सेव करें → नोट सूची में दिखना चाहिए।
4. नोट खोलें → सामग्री पढ़ें; फिर बदलें → सेव के बाद बदला हुआ पाठ दिखना चाहिए।
5. नोट हटाएँ → पुष्टि माँगी जाए और पुष्टि के बाद सूची से हटे।
6. ऐप बंद करके दोबारा खोलें → सेव किया नोट मौजूद होना चाहिए।
7. खाते B से Login करें → खाते A का नोट खाते B में नहीं दिखना चाहिए।
8. खाली शीर्षक/खाली सामग्री सेव करने की कोशिश करें → फॉर्म रोकना चाहिए।
9. इंटरनेट बंद करके सेव करने की कोशिश करें → स्पष्ट त्रुटि दिखनी चाहिए; सफलता का झूठा संदेश नहीं आना चाहिए।

## Study Plan मॉड्यूल टेस्ट (PR #6)
1. Firebase Console → Firestore → Rules में नवीनतम firestore.rules Publish करें।
2. स्टडी प्लान खोलें → दैनिक लक्ष्य बदलें।
3. एक काम जोड़ें → सूची में दिखना चाहिए।
4. काम पूरा करें → प्रगति संख्या और बार बदलना चाहिए।
5. ऐप बंद करके दोबारा खोलें → लक्ष्य और काम सुरक्षित मिलने चाहिए।
6. दूसरे खाते से Login करें → पहले खाते के काम नहीं दिखने चाहिए।


## Practice Test मॉड्यूल टेस्ट (अभी PR में)
1. PR build सफल होने के बाद ही Merge करें।
2. Firebase Console → Firestore → Rules में नवीनतम main की firestore.rules सामग्री Publish करें (केवल PR merge होने के बाद)।
3. खाते A से Login → Dashboard → प्रैक्टिस टेस्ट खोलें।
4. सभी 5 नमूना प्रश्नों में विकल्प चुनें; बिना विकल्प चुने उत्तर जाँचें सक्रिय नहीं होना चाहिए।
5. उत्तर जाँचें → सही उत्तर और उसका स्पष्टीकरण दिखना चाहिए; उसके बाद अगला प्रश्न खुले।
6. अंतिम परिणाम में स्कोर और प्रतिशत दिखना चाहिए; परिणाम Firebase में सेव होने की पुष्टि दिखनी चाहिए।
7. टेस्ट दोबारा देकर नया परिणाम सेव करें।
8. खाते B से Login करें; खाते A का टेस्ट परिणाम खाते B को नहीं दिखना चाहिए (Rules Playground में cross-user read/write भी Denied जाँचें)।
9. ध्यान दें: ये शुरुआती अभ्यास के लिए बनाए गए नमूना प्रश्न हैं، आधिकारिक PYQ या किसी परीक्षा का सत्यापित प्रश्नपत्र नहीं।
