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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Temporary QEMU NDK shim for the JNI Android library only.
subprojects {
    if (project.name == "jni") {
        plugins.withId("com.android.library") {
            val androidExtension = extensions.findByName("android")
                ?: error("JNI Android extension not found")

            val setter = androidExtension.javaClass.methods.firstOrNull {
                it.name == "setNdkPath" && it.parameterCount == 1
            } ?: error("AGP Android extension has no setNdkPath method")

            setter.invoke(androidExtension, "/tmp/jni-ndk-shim")
            println("JNI_NDK_SHIM_SET=" + androidExtension.javaClass.methods
                .first { it.name == "getNdkPath" && it.parameterCount == 0 }
                .invoke(androidExtension))
        }
    }
}
