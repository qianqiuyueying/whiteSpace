buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 修复 isar_flutter_libs 的 AndroidManifest.xml package 属性问题和 compileSdk 问题
subprojects {
    afterEvaluate {
        if (project.name == "isar_flutter_libs") {
            // 修复 AndroidManifest.xml 中的 package 属性
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                var content = manifestFile.readText()
                if (content.contains("package=")) {
                    content = content.replace(Regex("""\s*package="[^"]*""""), "")
                    manifestFile.writeText(content)
                }
            }
            // 强制使用更高的 compileSdk
            project.extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
                compileSdk = 34
            }
        }
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}