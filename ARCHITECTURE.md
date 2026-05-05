# 📊 Architecture Documentation - توثيق البنية المعمارية

## نظرة عامة على البنية النظيفة (Clean Architecture)

```
lib/
├── core/                    # الأساسيات والثوابت
│   ├── auth_constants.dart     # ثوابت المصادقة
│   ├── utils/
│   │   └── auth_validators.dart # validators للمصادقة
│   └── navigation/
│       └── auth_guard.dart     # حماية الطرق
│
├── data/                    # طبقة البيانات
│   ├── models/
│   │   └── auth/
│   │       ├── login_request.dart
│   │       ├── register_request.dart
│   │       └── auth_response.dart
│   ├── services/
│   │   ├── auth_exceptions.dart  # استثناءات مخصصة
│   │   └── auth_interceptor.dart # معالج HTTP
│   ├── repositories/
│   │   └── auth_repository_impl.dart
│   └── sources/              # مصادر البيانات (API, Local)
│
├── domain/                  # طبقة المنطق (الأساسية)
│   ├── entities/
│   │   └── app_user.dart
│   └── repositories/
│       └── auth_repository.dart  # الواجهة
│
└── presentation/            # طبقة العرض
    ├── providers/
    │   ├── auth_provider.dart
    │   └── auth_state.dart       # حالات المصادقة
    └── screens/
        └── auth/
            ├── login_screen.dart     # Google Sign In ✅
            └── register_screen.dart  # Google Sign In ✅
```

## سير البيانات (Data Flow):

```
┌─────────────────┐
│ UI (Screens)    │
│ - LoginScreen   │
│ - RegisterScreen│
└────────┬────────┘
         │ (يستدعي)
         ▼
┌─────────────────────┐
│ AuthProvider        │
│ (State Management)  │
└────────┬────────────┘
         │ (يستدعي)
         ▼
┌──────────────────────┐
│ AuthRepository (Impl)│
│ (Business Logic)     │
└────────┬─────────────┘
         │ (يستدعي)
         ▼
┌────────────────────────────┐
│ Firebase Auth + Services   │
│ - LoginWithEmail           │
│ - LoginWithGoogle          │
│ - Register                 │
└────────┬───────────────────┘
         │ (يرجع)
         ▼
┌──────────────────────┐
│ AppUser (Entity)     │
│ - id, name, email    │
│ - role, avatar, etc  │
└──────────────────────┘
```

## طبقات المشروع:

### 1️⃣ Presentation Layer (طبقة العرض)
**المسؤولية**: عرض البيانات وتفاعل المستخدم

**الملفات**:
- `auth_provider.dart` - إدارة حالة المصادقة
- `auth_state.dart` - تمثيل حالات المصادقة
- `login_screen.dart` - شاشة تسجيل الدخول
- `register_screen.dart` - شاشة التسجيل

**المسؤوليات**:
- جمع مدخلات المستخدم
- التحقق من الصحة الأولي
- عرض الأخطاء والرسائل
- إعادة التوجيه

### 2️⃣ Domain Layer (طبقة الأساس)
**المسؤولية**: القواعد التجارية والعقود

**الملفات**:
- `app_user.dart` - كيان المستخدم
- `auth_repository.dart` - واجهة المستودع

**المسؤوليات**:
- تعريف العقود (interfaces)
- تعريف الكيانات (entities)
- قواعد المنطق التجاري

### 3️⃣ Data Layer (طبقة البيانات)
**المسؤولية**: جلب ومعالجة البيانات

**الملفات**:
- `auth_repository_impl.dart` - تطبيق المستودع
- `auth_exceptions.dart` - استثناءات مخصصة
- `auth_interceptor.dart` - معالج HTTP
- DTOs في `models/auth/`

**المسؤوليات**:
- التواصل مع الخادم
- تحويل البيانات (DTO ↔ Entity)
- معالجة الأخطاء
- تخزين البيانات محلياً

### 4️⃣ Core Layer (طبقة الأساسية)
**المسؤولية**: المساعدات والثوابت

**الملفات**:
- `auth_constants.dart` - ثوابت المصادقة
- `auth_validators.dart` - التحقق من الصحة
- `auth_guard.dart` - حماية الطرق

**المسؤوليات**:
- توفير ثوابت مشتركة
- التحقق من الصحة
- التحكم في الوصول

## أمثلة على الاستخدام:

### مثال 1: تسجيل الدخول
```dart
// في UI
final auth = context.read<AuthProvider>();
final success = await auth.login(
  email: email,
  password: password,
);

// في AuthProvider
Future<bool> login({
  required String email,
  required String password,
}) async {
  _startAction();
  try {
    _currentUser = await _authRepository.login(
      email: email.trim(),
      password: password,
    );
    return true;
  } catch (error) {
    _errorMessage = _friendlyError(error);
    return false;
  } finally {
    _endAction();
  }
}

// في AuthRepositoryImpl
Future<AppUser> login({
  required String email,
  required String password,
}) async {
  try {
    final result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    if (user == null) throw UserNotFoundException();
    return _mapFirebaseUserToAppUser(user);
  } on FirebaseAuthException catch (e) {
    throw _mapFirebaseException(e);
  }
}
```

### مثال 2: تسجيل الدخول بـ Google
```dart
// في UI
final role = await _showRolePicker();
final success = await auth.loginWithGoogle(
  roleForNewUser: role,
);

// في AuthProvider
Future<bool> loginWithGoogle({
  AppUserRole? roleForNewUser,
}) async {
  _startAction();
  try {
    _currentUser = await _authRepository.loginWithGoogle(
      roleForNewUser: roleForNewUser,
    );
    return true;
  } on RoleSelectionRequiredException {
    _requiresRoleSelection = true;
    _errorMessage = 'Please choose a role to continue with Google.';
    return false;
  } catch (error) {
    _errorMessage = _friendlyError(error);
    return false;
  } finally {
    _endAction();
  }
}

// في AuthRepositoryImpl
Future<AppUser> loginWithGoogle({
  AppUserRole? roleForNewUser,
}) async {
  try {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw GoogleSignInException();
    
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final result = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = result.user;
    if (firebaseUser == null) throw UserNotFoundException();
    
    // إذا كان المستخدم جديداً، نتطلب اختيار الدور
    if (result.additionalUserInfo?.isNewUser == true) {
      if (roleForNewUser == null) {
        throw RoleSelectionRequiredException();
      }
      // حفظ الدور في قاعدة البيانات
      await _saveUserRole(firebaseUser.uid, roleForNewUser);
    }
    
    return _mapFirebaseUserToAppUser(firebaseUser);
  } on GoogleSignInException rethrow;
  on RoleSelectionRequiredException rethrow;
  on FirebaseAuthException catch (e) {
    throw _mapFirebaseException(e);
  }
}
```

## معالجة الأخطاء:

```
Firebase Exception
        ↓
AuthRepositoryImpl catches & maps
        ↓
Custom Exception (e.g., InvalidCredentialsException)
        ↓
AuthProvider catches & formats message
        ↓
Friendly error message shown to UI
```

## التطوير المستقبلي:

### إضافة ميزة جديدة:
1. **عرّف الكيان** (Domain Layer)
   ```dart
   // domain/entities/new_feature.dart
   class NewFeature {
     final String id;
     final String name;
     // ...
   }
   ```

2. **عرّف الواجهة** (Domain Layer)
   ```dart
   // domain/repositories/new_repository.dart
   abstract class NewRepository {
     Future<NewFeature> getFeature(String id);
   }
   ```

3. **طبّق الواجهة** (Data Layer)
   ```dart
   // data/repositories/new_repository_impl.dart
   class NewRepositoryImpl implements NewRepository {
     @override
     Future<NewFeature> getFeature(String id) async {
       // Implementation
     }
   }
   ```

4. **أضف Provider** (Presentation Layer)
   ```dart
   // presentation/providers/new_provider.dart
   class NewProvider extends ChangeNotifier {
     // Provider logic
   }
   ```

5. **أنشئ UI** (Presentation Layer)
   ```dart
   // presentation/screens/new_screen.dart
   class NewScreen extends StatelessWidget {
     // UI implementation
   }
   ```

## الفوائد:

✅ **Separation of Concerns** - فصل المسؤوليات
✅ **Testability** - قابل للاختبار
✅ **Reusability** - قابل لإعادة الاستخدام
✅ **Maintainability** - سهل الصيانة
✅ **Scalability** - قابل للتوسع
✅ **Independence** - مستقل عن الأطر الخارجية

---

**تم الإنجاز! 🎊**
