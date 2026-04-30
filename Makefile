KEYS = --dart-define-from-file=api_keys.json

run:
	flutter run $(KEYS)

run-web:
	flutter run -d chrome $(KEYS)

run-release:
	flutter run --release $(KEYS)

build-apk:
	flutter build apk $(KEYS)

build-aab:
	flutter build appbundle $(KEYS)

build-web:
	flutter build web $(KEYS)
