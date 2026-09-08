# Flutter and plugin classes reached only through reflection.
-keep class io.flutter.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ML Kit ships optional model bundles; R8 warns about the ones we do not use.
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }

# Gson-style models inside plugins.
-keepattributes Signature
-keepattributes *Annotation*
