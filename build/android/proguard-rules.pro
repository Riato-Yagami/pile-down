# Godot's native engine looks up Java classes and methods through JNI. Its
# prebuilt AAR has no consumer rules, so preserve this interface explicitly.
# AndroidX, Kotlin and other unreachable dependency code can still be optimized.
-keep class org.godotengine.** { *; }
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
