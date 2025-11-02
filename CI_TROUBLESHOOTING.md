# CI Troubleshooting Guide

Common CI failures and how to fix them.

## Common Issues

### 1. Code Generation Failures

**Error**: `build_runner` fails or generates errors

**Fix**: Ensure all model classes have proper JSON serialization annotations:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Missing Dependencies

**Error**: `pub get` fails or packages not found

**Fix**: Check `pubspec.yaml` for correct versions. Common fixes:
- Update to latest compatible versions
- Check package availability
- Ensure all required packages are listed

### 3. Analysis Service Import Errors

**Error**: Analysis service not found or connection errors

**Fix**: The analysis service is optional - if unavailable, the app uses client-side fallback. This is expected behavior and shouldn't fail CI.

### 4. iOS Build Failures

**Error**: Missing Podfile or CocoaPods issues

**Fix**: 
```bash
cd ios
pod install
```
If `Podfile` is missing, it will be created on first `flutter run` or build.

### 5. Android Build Failures

**Error**: Missing Android SDK or license issues

**Fix**: Ensure Android SDK is properly configured. License acceptance may be required:
```bash
flutter doctor --android-licenses
```

### 6. Web Build Failures

**Error**: Web build fails with environment variable issues

**Fix**: Environment variables have defaults in code. CI should work without secrets, but they're optional.

## Quick Fixes for CI

1. **Skip optional services**: Analysis service is optional - failures there shouldn't break CI
2. **Make builds optional**: Use `continue-on-error: true` for non-critical builds
3. **Check logs**: Review GitHub Actions logs for specific error messages
4. **Test locally**: Run `flutter analyze` and `flutter test` locally first

## Status Check

If CI is failing, check:
- [ ] All files committed
- [ ] No syntax errors (`flutter analyze`)
- [ ] Tests pass locally (`flutter test`)
- [ ] Code generation works (`flutter pub run build_runner build`)
- [ ] Dependencies resolve (`flutter pub get`)

