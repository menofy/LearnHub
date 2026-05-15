# شرح مبسط لتطبيق LearnHub

هذا الملف مكتوب بشكل بسيط وواضح حتى يمكن مشاركته مع العميل لفهم فكرة التطبيق، طريقة عمله، وتقسيم الملفات الأساسية داخل المشروع.

## 1. ما هو التطبيق؟

`LearnHub` هو تطبيق تعليم إلكتروني مبني بـ `Flutter` ويخدم نوعين رئيسيين من المستخدمين:

- `Student` الطالب: يتصفح الكورسات، يبحث، يحفظ، يلتحق، ويتابع التقدم.
- `Instructor` المدرّب: يدير ملفه، ينشئ كورسات، يرفع فيديوهات أو يربط يوتيوب، وينشر المحتوى للطلاب.

التطبيق يعتمد على:

- `Firebase Auth` لتسجيل الدخول والحسابات
- `Cloud Firestore` لتخزين البيانات
- `Firebase Cloud Messaging` للإشعارات
- `SharedPreferences` للتخزين المحلي
- `YouTube API` لجلب دروس البلاي ليست
- `Cloudinary` لرفع الفيديوهات المستضافة

## 2. رحلة المستخدم داخل التطبيق

### البداية

عند فتح التطبيق:

- يتم تشغيل التطبيق من `lib/main.dart`
- يتم تجهيز الـ app واللغة والثيم من `lib/app.dart`
- يتم تحديد هل المستخدم:
  - أول مرة يدخل
  - مسجل دخول
  - طالب
  - مدرب

الملفات المسؤولة:

- `lib/main.dart`
- `lib/app.dart`
- `lib/features/onboarding/splash_screen.dart`
- `lib/features/onboarding/onboarding_screen.dart`
- `lib/features/shared/root/root_screen.dart`
- `lib/features/shared/root/app_entry_gate.dart`
- `lib/core/navigation/app_router.dart`
- `lib/core/navigation/app_routes.dart`

### بعد تسجيل الدخول

- إذا كان المستخدم `Student` ينتقل إلى تجربة الطالب
- إذا كان المستخدم `Instructor` ينتقل إلى لوحة المدرّب

الملفات المسؤولة:

- `lib/features/shared/auth/providers/auth_provider.dart`
- `lib/features/shared/main/main_shell_screen.dart`
- `lib/features/instructor/screens/instructor_shell_screen.dart`

## 3. تقسيم المشروع بشكل مبسط

### Core

هذا الجزء يحتوي على الأشياء المشتركة في المشروع كله:

- `lib/core/navigation/`
  - `app_router.dart`: التنقل بين الشاشات
  - `app_routes.dart`: أسماء الروتات
  - `route_args.dart`: البيانات التي تنتقل بين الشاشات
  - `app_navigator.dart`: أدوات تنقل عامة
  - `auth_guard.dart`: حماية بعض المسارات

- `lib/core/theme/`
  - `app_theme.dart`: الثيم العام
  - `app_colors.dart`: الألوان

- `lib/core/shared_widgets/`
  - عناصر UI مشتركة مثل الأزرار، البحث، حالات التحميل، الفارغ، الأخطاء، الصور

- `lib/core/utils/`
  - أدوات مساعدة مثل التحقق من المدخلات ورسائل الأخطاء

- `lib/core/config/`
  - إعدادات يوتيوب والكتالوج

### Domain

هذا الجزء يمثل الكيانات الأساسية للتطبيق:

- `lib/domain/entities/app_user.dart`
- `lib/domain/entities/course.dart`
- `lib/domain/entities/lesson.dart`
- `lib/domain/entities/instructor.dart`
- `lib/domain/entities/course_review.dart`
- `lib/domain/entities/certificate.dart`
- `lib/domain/entities/app_notification.dart`
- `lib/domain/entities/notification_preferences.dart`
- `lib/domain/entities/user_learning_state.dart`
- `lib/domain/entities/youtube_video_item.dart`

الواجهات الأساسية:

- `lib/domain/repositories/auth_repository.dart`
- `lib/domain/repositories/course_repository.dart`

### Data

هذا الجزء مسؤول عن جلب وتخزين البيانات:

- `lib/data/repositories/auth_repository_impl.dart`
- `lib/data/repositories/course_repository_impl.dart`

- `lib/data/services/auth_service.dart`
- `lib/data/services/firestore_service.dart`
- `lib/data/services/fcm_service.dart`
- `lib/data/services/email_service.dart`
- `lib/data/services/cloudinary_video_upload_service.dart`
- `lib/data/services/video_thumbnail_service.dart`
- `lib/data/services/youtube_thumbnail_service.dart`

- `lib/data/sources/mock_data_source.dart`
- `lib/data/sources/youtube_playlist_data_source.dart`

- `lib/data/models/`
  - موديلات التحويل بين Firebase / API وبين الـ entities

### Presentation / Providers

إدارة الحالة العامة في التطبيق:

- `lib/features/shared/auth/providers/auth_provider.dart`
- `lib/features/shared/auth/providers/auth_state.dart`
- `lib/features/course/providers/course_provider.dart`
- `lib/presentation/providers/app_state_provider.dart`
- `lib/presentation/providers/youtube_playlist_provider.dart`

## 4. شرح أجزاء التطبيق بالملفات

## 4.1 البداية والترحيب

هذا الجزء مسؤول عن أول تجربة للمستخدم.

الملفات الرئيسية:

- `lib/features/onboarding/splash_screen.dart`
- `lib/features/onboarding/onboarding_screen.dart`
- `lib/features/onboarding/widgets/onboarding_intro_page.dart`
- `lib/features/onboarding/widgets/onboarding_page_indicator.dart`
- `lib/features/onboarding/widgets/onboarding_primary_action_button.dart`
- `lib/features/onboarding/widgets/onboarding_skip_button.dart`

وظيفته:

- عرض شاشة البداية
- شرح أولي للتطبيق
- تحديد إن كان المستخدم شاهد الـ onboarding من قبل أم لا

## 4.2 تسجيل الدخول والحسابات

هذا الجزء مسؤول عن إنشاء الحساب والدخول واسترجاع كلمة المرور.

### الشاشات

- `lib/features/shared/auth/screens/login_screen.dart`
- `lib/features/shared/auth/screens/register_screen.dart`
- `lib/features/shared/auth/screens/forgot_password_screen.dart`
- `lib/features/shared/auth/screens/create_new_password_screen.dart`
- `lib/features/shared/auth/screens/otp_verification_screen.dart`
- `lib/features/shared/auth/screens/signup_otp_screen.dart`
- `lib/features/shared/auth/screens/fill_profile_screen.dart`
- `lib/features/shared/auth/screens/create_pin_screen.dart`
- `lib/features/shared/auth/screens/set_fingerprint_screen.dart`
- `lib/features/shared/auth/screens/account_ready_screen.dart`
- `lib/features/shared/auth/screens/reset_password_success_screen.dart`

### الويدجتس المساعدة

- `lib/features/shared/auth/widgets/login_credentials_form.dart`
- `lib/features/shared/auth/widgets/login_google_button.dart`
- `lib/features/shared/auth/widgets/role_picker_sheet.dart`
- `lib/features/shared/auth/widgets/auth_switch_prompt.dart`
- `lib/features/shared/auth/widgets/login_intro_section.dart`
- `lib/features/shared/auth/widgets/signup_otp_code_boxes.dart`
- `lib/features/shared/auth/widgets/signup_otp_pin_pad.dart`
- `lib/features/shared/auth/widgets/signup_otp_intro_section.dart`
- `lib/features/shared/auth/widgets/signup_otp_resend_section.dart`

### منطق الحسابات

- `lib/features/shared/auth/providers/auth_provider.dart`
- `lib/data/repositories/auth_repository_impl.dart`
- `lib/data/services/auth_service.dart`
- `lib/data/services/auth_exceptions.dart`
- `lib/data/services/auth_interceptor.dart`
- `lib/data/models/auth/login_request.dart`
- `lib/data/models/auth/register_request.dart`
- `lib/data/models/auth/auth_response.dart`

الوظائف الحالية:

- تسجيل دخول بالإيميل والباسورد
- تسجيل دخول بجوجل
- إنشاء حساب جديد
- تحديد نوع المستخدم
- تحديث البروفايل
- تسجيل خروج
- استرجاع كلمة المرور

## 4.3 تجربة الطالب

هذا هو الجزء الخاص بالمستخدم الطالب بعد تسجيل الدخول.

### الهيكل الرئيسي

- `lib/features/shared/main/main_shell_screen.dart`
- `lib/features/shared/main/widgets/main_shell_bottom_nav_bar.dart`

الأقسام الرئيسية داخل تجربة الطالب:

- الرئيسية
- كورساتي
- المحفوظات
- البروفايل

## 4.4 الصفحة الرئيسية للطالب

هذه الصفحة تعرض أهم ما يراه الطالب عند الدخول.

### الشاشات

- `lib/features/home/screens/home_screen.dart`
- `lib/features/home/screens/popular_courses_screen.dart`

### الويدجتس المستخدمة

- `lib/features/home/widgets/home_course_strip_section.dart`
- `lib/features/student_side/home/widgets/home_greeting_header.dart`
- `lib/features/student_side/home/widgets/home_category_selector.dart`
- `lib/features/student_side/home/widgets/home_learning_focus_card.dart`
- `lib/features/student_side/home/widgets/home_new_instructors_section.dart`
- `lib/features/student_side/home/widgets/home_promo_carousel.dart`
- `lib/features/student_side/home/widgets/home_top_mentors_strip.dart`
- `lib/features/student_side/home/widgets/home_instructor_avatar_tile.dart`
- `lib/features/student_side/home/widgets/home_course_strip_section.dart`

المحتوى الذي يظهر:

- الترحيب بالمستخدم
- خانة بحث
- كروت ترويجية
- الاستمرار في التعلم
- توصيات
- تصنيفات
- كورسات مشهورة
- كورسات المدرّبين
- مدربين جدد
- أفضل المرشدين

## 4.5 البحث والتصنيفات

هذا الجزء يسمح للطالب بالوصول السريع للكورسات المناسبة.

### الشاشات

- `lib/features/student_side/search/search_screen.dart`
- `lib/features/student_side/categories/categories_screen.dart`
- `lib/features/student_side/categories/category_courses_screen.dart`

### الويدجتس

- `lib/features/student_side/search/widgets/search_header.dart`
- `lib/features/student_side/search/widgets/search_query_field.dart`
- `lib/features/student_side/search/widgets/search_filter_chips.dart`
- `lib/features/student_side/search/widgets/search_discovery_view.dart`
- `lib/features/student_side/search/widgets/search_results_view.dart`
- `lib/features/student_side/categories/widgets/category_filter_bottom_sheet.dart`
- `lib/features/student_side/categories/widgets/category_tab_switcher.dart`

الوظائف:

- البحث النصي
- البحث بالتصنيف
- البحث بالمستوى
- الترتيب حسب التوصية أو التقييم أو السعر أو الأحدث
- حفظ آخر عمليات البحث

## 4.6 الكورس والدروس والمشاهدة

هذا الجزء يمثل تجربة الكورس نفسها.

### الشاشات

- `lib/features/course/screens/course_details_screen.dart`
- `lib/features/course/screens/video_player_screen.dart`
- `lib/features/course/screens/youtube_playlist_screen.dart`
- `lib/features/course/screens/youtube_fullscreen_player_screen.dart`
- `lib/features/course/screens/course_reviews_screen.dart`
- `lib/features/course/screens/write_review_screen.dart`
- `lib/features/course/screens/lesson_notes_screen.dart`
- `lib/features/course/screens/lesson_resources_screen.dart`

### الويدجتس

- `lib/features/course/widgets/course_hero_image_header.dart`
- `lib/features/course/widgets/course_header_card.dart`
- `lib/features/course/widgets/course_curriculum_row.dart`
- `lib/features/course/widgets/course_instructor_card.dart`
- `lib/features/course/widgets/course_reviews_section.dart`
- `lib/features/course/widgets/course_what_you_get_section.dart`
- `lib/features/course/widgets/course_tab_button.dart`
- `lib/features/course/widgets/course_meta_pill.dart`
- `lib/features/course/widgets/course_get_row.dart`
- `lib/features/course/widgets/course_card.dart`
- `lib/features/course/widgets/lesson_tile.dart`
- `lib/features/course/widgets/course_bullet_text.dart`

الوظائف:

- عرض تفاصيل الكورس
- عرض المنهج والدروس
- تشغيل الدروس
- دعم فيديوهات يوتيوب أو الفيديوهات المستضافة
- إضافة الكورس إلى المحفوظات
- الالتحاق بالكورس
- متابعة التقدم
- كتابة ومشاهدة التقييمات
- ملاحظات وموارد الدرس

## 4.7 كورساتي، التقدم، والشهادات

هذا الجزء يتابع رحلة التعلم للطالب.

### الشاشات

- `lib/features/student_side/learning/screens/my_learning_screen.dart`
- `lib/features/student_side/profile/screens/certificates_screen.dart`
- `lib/features/student_side/profile/screens/certificate_details_screen.dart`

### الويدجتس

- `lib/features/student_side/learning/widgets/learning_screen_header.dart`
- `lib/features/student_side/learning/widgets/learning_course_tile.dart`
- `lib/features/student_side/learning/widgets/progress_course_tile.dart`
- `lib/features/learning/widgets/progress_course_tile.dart`

الوظائف:

- عرض الكورسات الجارية
- عرض الكورسات المكتملة
- متابعة آخر درس
- توليد الشهادات من الكورسات المكتملة

## 4.8 المحفوظات

هذا الجزء خاص بالكورسات التي قام الطالب بحفظها.

الملف الرئيسي:

- `lib/features/student_side/wishlist/wishlist_screen.dart`

الوظائف:

- إضافة كورسات للمحفوظات
- إزالة كورسات من المحفوظات
- فتح الكورس من قائمة المحفوظات

## 4.9 الملف الشخصي والإعدادات

هذا الجزء يدير بيانات المستخدم وتفضيلاته.

### الشاشات

- `lib/features/student_side/profile/screens/profile_screen.dart`
- `lib/features/student_side/profile/screens/edit_profile_screen.dart`
- `lib/features/settings/screens/language_settings_screen.dart`
- `lib/features/settings/screens/change_password_screen.dart`
- `lib/features/student_side/settings/screens/notification_settings_screen.dart`
- `lib/features/common/info/terms_screen.dart`

### الويدجتس

- `lib/features/student_side/profile/widgets/profile_header_card.dart`
- `lib/features/student_side/profile/widgets/profile_menu_section.dart`
- `lib/features/student_side/profile/widgets/profile_avatar.dart`
- `lib/features/student_side/profile/widgets/edit_profile_avatar_picker.dart`
- `lib/features/student_side/profile/widgets/edit_profile_text_field.dart`
- `lib/features/student_side/settings/widgets/settings_toggle_row.dart`
- `lib/features/student_side/settings/widgets/settings_screen_header.dart`
- `lib/features/student_side/settings/widgets/language_option_card.dart`
- `lib/features/student_side/settings/widgets/language_settings_intro_card.dart`

الوظائف:

- عرض بيانات الحساب
- تعديل الاسم والصورة
- تغيير اللغة
- تغيير الثيم
- تغيير كلمة المرور
- التحكم في الإشعارات
- عرض صفحة الشروط

## 4.10 الإشعارات

هذا الجزء مسؤول عن إشعارات التطبيق محليًا ومن خلال Firebase.

### الشاشات

- `lib/features/common/notifications/notifications_screen.dart`
- `lib/features/common/notifications/notification_details_screen.dart`

### الويدجتس

- `lib/features/common/notifications/widgets/notifications_header.dart`
- `lib/features/common/notifications/widgets/notifications_section.dart`
- `lib/features/common/notifications/widgets/notification_list_tile.dart`

### الخدمات

- `lib/presentation/providers/app_state_provider.dart`
- `lib/data/services/fcm_service.dart`
- `lib/data/services/firestore_service.dart`

الوظائف:

- استقبال الإشعارات
- عرض الإشعار داخل التطبيق
- فتح شاشة الإشعارات عند الضغط
- تحديد المقروء وغير المقروء
- حذف الإشعارات

## 4.11 عرض المدرّبين للطلاب

هذا الجزء يعرّف الطالب على المدرّبين.

### الشاشات

- `lib/features/common/instructor_public/screens/instructors_screen.dart`
- `lib/features/common/instructor_public/screens/instructor_details_screen.dart`
- `lib/features/instructor_public/screens/instructor_details_screen.dart`

### الويدجتس

- `lib/features/common/instructor_public/widgets/instructor_details_header.dart`
- `lib/features/common/instructor_public/widgets/instructor_details_action_row.dart`
- `lib/features/common/instructor_public/widgets/instructor_profile_card.dart`
- `lib/features/common/instructor_public/widgets/instructor_ratings_section.dart`
- `lib/features/common/instructor_public/widgets/instructor_courses_section.dart`
- `lib/features/common/instructor_public/widgets/instructor_tab_navigation.dart`
- `lib/features/common/instructor_public/widgets/instructor_follow_button.dart`
- `lib/features/common/instructor_public/widgets/instructor_edit_profile_button.dart`
- `lib/features/common/instructor_public/widgets/instructor_primary_button.dart`
- `lib/features/common/instructor_public/widgets/instructor_stat_item.dart`
- `lib/features/profile/widgets/followers_list_bottom_sheet.dart`
- `lib/features/student_side/profile/widgets/followers_list_bottom_sheet.dart`

الوظائف:

- عرض قائمة المدرّبين
- عرض صفحة تفصيلية لكل مدرب
- عرض كورسات المدرب
- متابعة / إلغاء متابعة المدرب
- عرض عدد المتابعين

## 4.12 تجربة المدرّب

هذا الجزء مخصص للمستخدم من نوع `Instructor`.

### الهيكل الرئيسي

- `lib/features/instructor/screens/instructor_shell_screen.dart`

الأقسام الرئيسية:

- نظرة عامة
- الكورسات
- إنشاء / تعديل كورس
- الملف الشخصي

## 4.13 لوحة المدرّب

الملفات:

- `lib/features/instructor/screens/instructor_dashboard_screen.dart`
- `lib/features/instructor/widgets/dashboard_hero_banner.dart`
- `lib/features/instructor/widgets/dashboard_action_card.dart`
- `lib/features/instructor/widgets/dashboard_course_card.dart`

الوظائف:

- عرض ملخص لحالة المدرّب
- الوصول السريع إلى إنشاء كورس
- عرض آخر الكورسات أو أهمها

## 4.14 كورسات المدرّب

الملفات:

- `lib/features/instructor/screens/instructor_my_courses_screen.dart`
- `lib/features/instructor/widgets/my_courses_management_card.dart`
- `lib/features/instructor/widgets/my_courses_summary_tile.dart`
- `lib/features/instructor/widgets/my_courses_library_meta_pill.dart`

الوظائف:

- عرض كل كورسات المدرّب
- فتح كورس للتعديل
- إدارة النشر والمسودة

## 4.15 إنشاء / تعديل الكورس

هذا من أهم أجزاء التطبيق.

### الشاشة الرئيسية

- `lib/features/instructor/screens/instructor_add_course_screen.dart`

### الويدجتس الفرعية

- `lib/features/instructor/widgets/add_course_hero_banner.dart`
- `lib/features/instructor/widgets/add_course_core_details_form.dart`
- `lib/features/instructor/widgets/add_course_category_chips.dart`
- `lib/features/instructor/widgets/add_course_media_source_section.dart`
- `lib/features/instructor/widgets/add_course_outcomes_requirements_form.dart`
- `lib/features/instructor/widgets/add_course_pricing_visibility_section.dart`
- `lib/features/instructor/widgets/add_course_student_preview.dart`

### الخدمات المرتبطة

- `lib/data/services/cloudinary_video_upload_service.dart`
- `lib/data/services/firestore_service.dart`
- `lib/data/services/video_thumbnail_service.dart`
- `lib/core/utils/cloudinary_video_thumbnail_helper.dart`

الوظائف:

- إدخال عنوان ووصف وصورة الكورس
- اختيار التصنيف والمستوى
- إضافة Tags وRequirements وOutcomes
- اختيار مصدر الفيديو:
  - رابط خارجي
  - فيديو يوتيوب
  - Playlist يوتيوب
  - فيديوهات مرفوعة
- رفع فيديوهات إلى Cloudinary
- حفظ الكورس كمسودة أو نشره
- تعديل كورس موجود

## 4.16 ملف المدرّب الشخصي

الملفات:

- `lib/features/instructor/screens/instructor_profile_screen.dart`
- `lib/features/instructor/screens/instructor_shared.dart`
- `lib/features/instructor/widgets/profile_hero_card.dart`
- `lib/features/instructor/widgets/profile_action_row.dart`

الوظائف:

- عرض بروفايل المدرب
- عرض بياناته الأساسية
- الوصول إلى المتابعين والكورسات

## 5. كيف تتحرك البيانات داخل التطبيق؟

بشكل مبسط جدًا:

1. الشاشة تطلب فعلًا معينًا
2. الـ Provider يستقبل الطلب
3. الـ Repository يحدد مصدر البيانات
4. الـ Service يتعامل مع Firebase أو YouTube أو Cloudinary
5. النتيجة ترجع إلى الـ Provider
6. الـ UI يتحدث

أمثلة الملفات:

- `AuthProvider` → `lib/features/shared/auth/providers/auth_provider.dart`
- `CourseProvider` → `lib/features/course/providers/course_provider.dart`
- `AuthRepositoryImpl` → `lib/data/repositories/auth_repository_impl.dart`
- `CourseRepositoryImpl` → `lib/data/repositories/course_repository_impl.dart`
- `FirestoreService` → `lib/data/services/firestore_service.dart`
- `AuthService` → `lib/data/services/auth_service.dart`

## 6. التخزين المحلي والـ cache

التطبيق لا يعتمد فقط على الإنترنت، بل يحتفظ ببعض البيانات محليًا لتحسين التجربة.

المسؤولون عن ذلك:

- `lib/presentation/providers/app_state_provider.dart`
- `lib/features/course/providers/course_provider.dart`
- `lib/data/sources/youtube_playlist_data_source.dart`

البيانات التي يتم حفظها محليًا:

- حالة تسجيل الدخول
- حالة الـ onboarding
- اللغة والثيم
- آخر عمليات البحث
- المحفوظات
- التقدم في الكورسات
- الإشعارات
- الشهادات
- كاش بعض بيانات يوتيوب

## 7. التكاملات الخارجية

### Firebase

- `lib/firebase_options.dart`
- `lib/data/services/auth_service.dart`
- `lib/data/services/firestore_service.dart`
- `lib/data/services/fcm_service.dart`

يُستخدم في:

- تسجيل الدخول
- الحسابات
- الكورسات
- المدرّبين
- الالتحاقات
- التقييمات
- الإشعارات
- التقدم

### YouTube

- `lib/data/sources/youtube_playlist_data_source.dart`
- `lib/presentation/providers/youtube_playlist_provider.dart`
- `lib/core/config/youtube_config.dart`
- `lib/core/config/youtube_playlist_catalog.dart`

يُستخدم في:

- جلب فيديوهات البلاي ليست
- حساب مدة الفيديوهات
- تشغيل محتوى يوتيوب داخل التطبيق

### Cloudinary

- `lib/data/services/cloudinary_video_upload_service.dart`

يُستخدم في:

- رفع فيديوهات الكورسات الخاصة بالمدرّب

## 8. ما الذي يقدمه التطبيق حاليًا؟

النسخة الحالية تشمل بشكل واضح:

- Onboarding وبداية دخول منظمة
- تسجيل دخول وتسجيل حساب
- دعم Google Sign-In
- فصل واضح بين الطالب والمدرّب
- تصفح كورسات
- بحث وفلترة
- Wishlist
- Enrollment
- مشاهدة دروس
- تتبع التقدم
- التقييمات والمراجعات
- صفحات المدرّبين
- Follow / Unfollow
- إشعارات
- شهادات إكمال
- إعدادات اللغة والثيم
- لوحة مدرب
- إنشاء / تعديل / نشر كورس
- دعم فيديوهات يوتيوب أو فيديوهات مرفوعة

## 9. ملاحظات مهمة للعميل

- هيكل المشروع منظم بحيث يسهل تطويره لاحقًا
- إضافة أي ميزة جديدة ممكنة بدون إعادة بناء المشروع من الصفر
- التطبيق جاهز للتوسع سواء في:
  - عدد المستخدمين
  - عدد الكورسات
  - أنواع المحتوى
  - أنواع التنبيهات
  - أدوار إضافية مستقبلاً

## 10. أهم الملفات التي يبدأ منها أي مطور جديد

لو أي شخص سيدخل على المشروع ويفهمه بسرعة، يبدأ من الملفات التالية:

- `lib/main.dart`
- `lib/app.dart`
- `lib/core/navigation/app_router.dart`
- `lib/features/shared/root/app_entry_gate.dart`
- `lib/features/shared/auth/providers/auth_provider.dart`
- `lib/features/course/providers/course_provider.dart`
- `lib/presentation/providers/app_state_provider.dart`
- `lib/data/services/firestore_service.dart`
- `lib/data/repositories/auth_repository_impl.dart`
- `lib/data/repositories/course_repository_impl.dart`
- `lib/features/home/screens/home_screen.dart`
- `lib/features/course/screens/course_details_screen.dart`
- `lib/features/instructor/screens/instructor_add_course_screen.dart`

---

إذا أردت، يمكن عمل نسخة ثانية من هذا الملف بصياغة أكثر رسمية جدًا لتُرسل مباشرة للعميل على أنها `Project Overview` أو `Technical Handover Summary`.
