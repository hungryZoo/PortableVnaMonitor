# Flutter 앱 환경 및 빌드 보고서

## 1. 소개
본 보고서는 flutter 앱의 개발 환경과 빌드 과정에 대해 설명함. 이 앱은 **portable vna monitor**으로, **심박수 측정 및 분석 기능**을 제공함.

작성자 : 김재현

## 2. 개발 환경
- **운영 체제**: Windows
- **Flutter 버전**: 3.24.5
- **IDE**: Visual Studio Code
- **Dart 버전**:  3.5.4
- **JDK 버전**:  1.7
- **Gradle 버전**:  7.6.3
- **Kotlin 버전**:  1.7.0

Flutter SDK와 관련된 도구는 `flutter doctor` 명령어로 확인할 수 있음.

Android Studio를 설치하는 것이 좋음.
```bash
flutter doctor
```

## 3. 프로젝트 구조

```bash
project_name/
├── android/               # 안드로이드 관련 파일
├── ios/                   # iOS 관련 파일
├── lib/                   # 앱의 주요 코드
│   ├── main.dart          # 앱의 진입점
│   ├── screens/           # 화면 관련 코드
│   │   └──ControlScreen.dart   # 앱의 주요 기능을 포함한 메인화면 관련 코드
│   └── widgets/           # 재사용 가능한 위젯들
├── pubspec.yaml           # 의존성 관리 파일
└── test/                  # 테스트 파일
```

android 폴더에는 주로 빌드시에 사용할 설정파일들이 포함되고, lib 폴더에는 앱의 주요 코드들이 위치함

특히 screens 폴더에는 여러 파일이 존재하는데, 실제로 사용되는 것은 ControlScreen.dart 하나임

## 4. 의존성

앱에서 사용된 주요 패키지는 다음과 같음.

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.3.3
  cupertino_icons: ^1.0.6
  flutter_blue_plus: ^1.32.8
  permission_handler: ^11.3.1
  fluttertoast: ^8.2.6
  syncfusion_flutter_charts: ^26.1.39
  path_provider: ^2.1.3
  provider: ^6.1.2
  scidart: ^0.0.2-dev.12
  scidart_plot: ^0.0.2-dev.1
  scidart_io: ^0.0.2-dev.1
  wakelock_plus: ^1.2.5
  equations: ^5.0.2
  ```

`pubspec.yaml` 파일에 의존성 리스트가 정의되어 있음.

## 5. 빌드 과정

project\android 경로의 설정파일을 수정해야함.

자동으로 수정되는 것도 있지만, 직접 바꿔줘야할 수도 있음.

각각 두 파일의 자바 및 sdk 경로를 수정해줘야함.


gradle.properties
```properties
org.gradle.java.home=C:\\Program Files\\OpenLogic\\jdk-17.0.14.7-hotspot #예시
org.gradle.jvmargs=-Xmx4G -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
```

자바의 경로는 사용자 환경변수의 JAVA_HOME과 똑같이 설정해주면 됨

local.propertie
```properties
sdk.dir=C:\\Users\\kjh1\\AppData\\Local\\Android\\sdk #예시
flutter.sdk=C:\\Users\\kjh1\\fvm\\versions\\3.24.5 #예시
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
```

sdk의 경로는 Android Studio 설치시 일반적으로 위의 디렉토리에 설치됨.


앱 빌드는 flutter build apk 명령어를 통해 이루어짐.

빌드 과정에서 발생할 수 있는 에러와 해결방법은 후술함.

```bash
flutter pub get
cd C:\project_dir
flutter clean
flutter build apk
```

## 6. 마주할 수 있는 에러

### 1. Java 호환성 오류

```plain
BUG! exception in phase 'semantic analysis' in source unit '_BuildScript_' Unsupported class file major version 65
```

빌드, 혹은 gradle 관련 명령어를 실행했을 때 마주할 수 있는 자바 호환 오류.

jdk 17을 설치한 뒤 환경변수 세팅까지 마쳐도 이러한 오류가 나타날 수가 있는데, 그 이유는 gradle 작업 시 시스템이 로컬에 설치된 자바가 아닌 Android Studio에 내장된 자바의 경로를 참조하기 때문임.

이러한 문제를 해결하기 위해서는 Android Studio의 gradle jdk 경로를 수정해야함

![studio_setting](/image/studio.png)

File -> setting -> Build, Execution, Deployment -> Build Tools -> Gradle 순으로 이동한 후, Gradle JDK 경로를 환경변수와 똑같이 맞춰준 뒤 재부팅하면 해결됨.

### 2. Gradle 캐시 관련 오류

```plain
Failed to create Jar file C:\Users\happy\.gradle\caches\jars-9\aabb2e1cb3fe16386e26e011577a8c2c\cp_settings.jar.
```

gradle 관련 캐시가 남아있어 JAR 파일을 만들지 못해 발생하는 오류.

캐시를 제거하면 해결됨.

```bash
cd projec_dir/android
gradle --stop
rm -r C:\사용자\.gradle\cashes
gradle clean
```

