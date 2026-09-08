allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Plugins in the pub ecosystem pin their own Java level, and some still say
// 1.8 while Kotlin follows whatever JDK Gradle is running on. Gradle fails
// that mismatch rather than degrading, so every subproject is pulled to the
// same level as the app.
//
// This has to come before evaluationDependsOn below: that line evaluates the
// subprojects, and afterEvaluate on an evaluated project is an error.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            (android as com.android.build.gradle.BaseExtension).compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
            .configureEach {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
                )
            }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
