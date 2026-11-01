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
