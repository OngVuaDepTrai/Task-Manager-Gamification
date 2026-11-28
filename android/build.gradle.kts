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

// Ép các plugin (vd: home_widget) biên dịch Java/Kotlin cùng JVM 17.
// PHẢI đặt TRƯỚC khối evaluationDependsOn bên dưới.
subprojects {
    // 1) Java -> 17 (và home_widget -> compileSdk 37 vì thư viện Glance yêu cầu)
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
                if (project.name == "home_widget") {
                    compileSdk = 37
                }
            }
        }
    }

    // 2) Kotlin -> 17 (dùng reflection để không cần import class của Kotlin plugin)
    if (project.name != "app") {
        tasks.configureEach {
            if (this.javaClass.name.contains("KotlinCompile")) {
                runCatching {
                    val compilerOptions =
                        this.javaClass.getMethod("getCompilerOptions").invoke(this)
                    @Suppress("UNCHECKED_CAST")
                    val jvmTarget =
                        compilerOptions.javaClass.getMethod("getJvmTarget")
                            .invoke(compilerOptions) as org.gradle.api.provider.Property<Any>
                    val jvmTargetClass = this.javaClass.classLoader
                        .loadClass("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                    val jvm17 = jvmTargetClass.enumConstants
                        .first { (it as Enum<*>).name == "JVM_17" }
                    jvmTarget.set(jvm17)
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}