# Flutter App Readme

This guide provides instructions on how to set up, run, and troubleshoot the Flutter application.

---

## 🚀 Setup

To get started with this project, ensure you have the following installed:

* **Flutter Version**: 3.19.5
* **Dart Version**: 3.3.3
* **DevTools Version**: 2.31.1
* **Android SDK Version**: 36.0.0
* **Android NDK Version**: 27.1.12297006
* **Java**: Java 17 (ensure it's installed and configured correctly).

---

## 🏃‍♀️ Running the App

Follow these steps to run the application:

1.  **Clone the Repository**: First, clone the application's repository to your local machine.
2.  **Install Dependencies**: Navigate to the root directory of the cloned project in your terminal and run:
    ```bash
    flutter pub get
    ```
3.  **Select Device**: Ensure you have a device (emulator or physical device) selected and running. You can list available devices with `flutter devices`.
4.  **Run the App**: Execute the following command in your terminal from the root directory:
    ```bash
    flutter run
    ```

---

## 🛠️ Troubleshooting

If you encounter issues while running the app, try the following steps:

### Version Incompatibility

If the app doesn't work with the specified versions:

1.  **Modify `gradle.properties`**: Open `android/gradle/gradle.properties` and **remove the very last line** from the file.
2.  **Clean Project**: Run the following commands in sequence:
    ```bash
    flutter clean
    flutter pub get
    flutter run
    ```

### Persistent Version Issues

If problems persist due to version issues, you have two options:

1.  **Recheck Versions**: Double-check that all your Flutter, Dart, SDK, NDK, and Java versions exactly match those listed in the Setup section.
2.  **Download Pre-built APK**: As an alternative, you can download the pre-built application from the following Google Drive link:
    <https://drive.google.com/file/d/1W_x2-wBrCeq_eRgz0_HMiZ-dsTQz7vKu/view?usp=share_link>

---

Enjoy using the app!
