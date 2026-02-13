# TSValidator

Приложение для проверки соответствия программного продукта техническому заданию (на Flutter).

## Требования

- Flutter SDK 3.9.2 или выше
- Google Chrome (для запуска в браузере)
- Git

## Установка и запуск

### 1. Установка Flutter SDK

Скачайте Flutter SDK с официального сайта:

```
https://docs.flutter.dev/get-started/install
```

Выберите вашу ОС и следуйте инструкциям. После установки добавьте Flutter в PATH.

Проверьте установку:

```bash
flutter --version
```

### 2. Проверка окружения

Убедитесь, что всё настроено корректно:

```bash
flutter doctor
```

Для запуска в браузере необходимо, чтобы в выводе `flutter doctor` отображался Chrome. Если веб-платформа не включена, выполните:

```bash
flutter config --enable-web
```

### 3. Клонирование репозитория

```bash
git clone <url-репозитория>
cd Frontend/aichecker
```

### 4. Установка зависимостей

```bash
flutter pub get
```

### 5. Запуск в браузере

```bash
flutter run -d chrome
```

Приложение откроется в Google Chrome.

Для запуска на конкретном порту:

```bash
flutter run -d chrome --web-port=8080
```

### 6. Сборка для веба (продакшн)

```bash
flutter build web
```

Собранные файлы будут в папке `build/web/`. Их можно разместить на любом веб-сервере.
