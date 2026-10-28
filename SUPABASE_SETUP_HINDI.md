# Broiler Farm Manager — Supabase + Online Rates (मोबाइल से सेटअप)

यह Flutter Android प्रोजेक्ट है। Supabase database/auth के लिए नीचे दिए चरण पूरे करने होंगे। यह ZIP अपने-आप आपके Supabase अकाउंट में प्रोजेक्ट नहीं बना सकती; उसके लिए आपके अकाउंट में लॉगिन करके प्रोजेक्ट बनाना जरूरी है।

## इस ZIP में
- `supabase/schema.sql` — users, broiler_batches, daily_logs और mandi_rates tables, RLS policies और API grants.
- `lib/main.dart` — ईमेल/पासवर्ड login/signup, फार्म बैच, दैनिक रिकॉर्ड, प्रोफाइल और क्लाउड मंडी रेट.
- ` .github/workflows/build-apk.yml` — GitHub Actions से APK बनाने का workflow.
- ऑनलाइन रेट टैब सार्वजनिक वेबसाइट को ऐप के अंदर दिखाता है और स्क्रीन खुली होने पर पेज को समय-समय पर रीफ्रेश करता है। यह अपने-आप वेबसाइट के नंबर निकालकर डेटाबेस में इम्पोर्ट नहीं करता।

## भाग 1 — Supabase प्रोजेक्ट बनाएं
1. मोबाइल ब्राउज़र में https://supabase.com/ खोलें और अपने अकाउंट में लॉगिन करें।
2. नया Project बनाएं। मजबूत database password रखें; इसे किसी के साथ साझा न करें।
3. प्रोजेक्ट के Ready होने तक प्रतीक्षा करें।

## भाग 2 — Database तैयार करें
1. Supabase Dashboard में **SQL Editor** खोलें।
2. **New query** चुनें।
3. इस ZIP में `supabase/schema.sql` खोलें और उसका पूरा SQL कॉपी करके SQL Editor में पेस्ट करें।
4. **Run** दबाएं।
5. Table Editor में `users`, `broiler_batches`, `daily_logs`, `mandi_rates` tables दिखने चाहिए। अगर SQL error आए, आगे बढ़ने से पहले error ठीक करें।

## भाग 3 — Email login चालू करें
1. Dashboard → **Authentication** → **Sign In / Providers** (या Providers) खोलें।
2. Email provider enabled रखें।
3. Email confirmation चालू है तो signup के बाद ईमेल में आए link से verify करें। अगर user profile अपने-आप नहीं बना, ऐप के Profile टैब में जानकारी भरकर Save करें।

## भाग 4 — ऐप को अपने प्रोजेक्ट से जोड़ें
1. Dashboard में **Connect** (या Project Settings → API Keys) खोलें।
2. **Project URL** कॉपी करें।
3. **Publishable key** कॉपी करें। पुराने dashboard में `anon` key दिख सकती है; client app के लिए वही public key इस्तेमाल की जा सकती है।
4. ZIP के `lib/main.dart` में ये दो पंक्तियां खोजें:
   - `const supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';`
   - `const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';`
5. placeholders की जगह अपने Project URL और publishable/anon key डालें, quotes रहने दें।
6. **कभी भी `service_role` या `secret` key ऐप, ZIP या GitHub में न डालें।**

## भाग 5 — फोन से APK बनाएं
1. ZIP को extract करें।
2. GitHub में private repository बनाएं और extract किए गए प्रोजेक्ट के अंदर की files/folders upload करें। `.github/workflows/build-apk.yml` भी upload होनी चाहिए।
3. Repository → **Actions** → **Build Android APK** → **Run workflow** चुनें।
4. सफल run के बाद Artifacts से `broiler-farm-manager-apk` डाउनलोड करें; artifact ZIP extract करके `app-release.apk` लें।

## Supabase में क्या सेव होगा?
- `users`: प्रत्येक login user की प्रोफाइल
- `broiler_batches`: चूजों की संख्या, नस्ल, placement date और active status
- `daily_logs`: mortality, feed, weight, water और age
- `mandi_rates`: यूज़र द्वारा पुष्टि करके सेव किए गए प्रति kg रेट

RLS policies farm batches और daily logs को signed-in user के अपने records तक सीमित करती हैं। Mandi rates authenticated users को पढ़ने देती हैं; rate लिखने वाला यूज़र अपने record को manage कर सकता है।

## महत्वपूर्ण सीमाएं
- यह फाइल आपके Supabase अकाउंट में लॉगिन करके प्रोजेक्ट नहीं बना सकती और न ही आपके लिए SQL Editor में Run दबा सकती है। ऊपर के चरण एक बार आपके फोन पर करने होंगे।
- इस संस्करण में वेबसाइट का पेज रीफ्रेश होता है, लेकिन मंडी रेट की संख्याएं अपने-आप पढ़कर `mandi_rates` में नहीं डाली जातीं। उसके लिए स्रोत की अनुमति वाला API/feed या server-side importer चाहिए।
- Multi-device sync के लिए हर मोबाइल में वही APK और वही login account इस्तेमाल करें। इंटरनेट जरूरी है।
- अपनी project key या password चैट में न भेजें। यदि setup में error आता है तो error message का screenshot भेजें, key छिपाकर रखें।
