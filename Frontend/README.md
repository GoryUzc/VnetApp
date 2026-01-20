# Documentación del proyecto Frontend

Esta documentación resume la estructura principal del proyecto Flutter contenido en la carpeta `Frontend` y los comandos de terminal más útiles para desarrollar, probar y compilar la aplicación.

**Estructura del Proyecto**
- **Frontend/**: carpeta raíz de la app Flutter.
- **lib/**: código fuente principal.
  - `main.dart`: punto de entrada de la aplicación.
  - `core/`, `screens/`, `services/`, `widgets/`, `theme/`, `strings/`: organización típica del proyecto.
- **pubspec.yaml**: dependencias, assets y configuración del paquete.
- **assets/**: recursos estáticos (ej. `assets/images`).
- **android/**: proyecto Android (Gradle, configuración nativa).
- **ios/**: proyecto iOS (Xcode, configuraciones específicas de Apple).
- **web/**: entrada web y archivos estáticos (`index.html`, `manifest.json`).
- **windows/**, **linux/**, **macos/**: proyectos de escritorio por plataforma.
- **test/**: pruebas unitarias y de widgets (`widget_test.dart`).
- **.dart_tool/**, **build/**: artefactos generados — no se deben comitear.
- **.idea/**, `vnet_agenda.iml`: configuración del IDE (archivos locales).

**Archivos clave**
- `lib/main.dart`: punto de arranque de la app.
- `pubspec.yaml`: declarar dependencias, assets y configuraciones de Flutter.
- `android/app/build.gradle.kts` y `ios/Runner.xcodeproj`: ajustes nativos y signing.
- `web/index.html`: plantilla para la versión web.

**Comandos de terminal Flutter (útiles para este repo)**

- Verificación del entorno:

```bash
flutter doctor
```

- Instalar dependencias:

```bash
flutter pub get
```

- Ejecutar la aplicación (dispositivo/emulador por defecto):

```bash
flutter run
```

- Listar dispositivos disponibles:

```bash
flutter devices
```

- Ejecutar en un dispositivo específico:

```bash
flutter run -d <deviceId>
```

- Ejecutar en navegador (web, p. ej. Chrome):

```bash
flutter run -d chrome
```

- Compilar release Android (APK):

```bash
flutter build apk --release
```

- Compilar Android App Bundle (para Play Store):

```bash
flutter build appbundle
```

- Compilar web:

```bash
flutter build web
```

- Compilar iOS (requiere macOS/Xcode):

```bash
flutter build ios --release
```

- Compilar escritorio:

```bash
flutter build windows
flutter build macos
flutter build linux
```

- Limpiar artefactos generados:

```bash
flutter clean
```

- Formatear código Dart:

```bash
dart format .
# o
flutter format .
```

- Analizar el código (estático):

```bash
flutter analyze
```

- Ejecutar tests:

```bash
flutter test
```

- Actualizar paquetes:

```bash
flutter pub upgrade
```

- Generación de código (si aplica, p. ej. json_serializable/build_runner):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- Ver logs del dispositivo/emulador:

```bash
flutter logs
```

**Flujo típico de desarrollo**

1. Abrir la carpeta del proyecto:

```bash
cd Frontend
```

2. Instalar dependencias:

```bash
flutter pub get
```

3. Iniciar emulador o conectar dispositivo y ejecutar:

```bash
flutter run
```

4. Para builds de producción (Android):

```bash
flutter build appbundle
```

**Consejos y notas**
- Ejecuta `flutter doctor` si hay fallos al compilar para una plataforma (p. ej. falta Xcode para iOS).
- Asegúrate de declarar los `assets` dentro de `pubspec.yaml` para que se empaqueten correctamente.
- No comitees `build/`, `.dart_tool/` ni archivos de configuración locales (`.idea/`) — están normalmente en `.gitignore`.
- Para CI: `flutter pub get`, `flutter analyze`, `flutter test`, y finalmente `flutter build <platform>`.

---

Si quieres, puedo:
- Añadir secciones adicionales (ej. firmar APK, CI/CD, integración con Firebase).
- Adaptar el README con instrucciones específicas de tu flujo de trabajo.
# vnet_eclipse

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
