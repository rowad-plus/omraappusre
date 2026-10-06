allprojects {
    repositories {
        google()
        mavenCentral()
        // Paymob native SDK (flutter_paymob_sdk): jitpack deps + the .aar
        // shipped inside the plugin's own android/libs maven repo.
        maven { url = uri("https://jitpack.io") }
        val flutterPluginsDeps = rootProject.file("../.flutter-plugins-dependencies")
        if (flutterPluginsDeps.exists()) {
            @Suppress("UNCHECKED_CAST")
            val json = groovy.json.JsonSlurper().parse(flutterPluginsDeps) as Map<String, Any>
            @Suppress("UNCHECKED_CAST")
            val androidPlugins = ((json["plugins"] as? Map<String, Any>)?.get("android")
                as? List<Map<String, Any>>) ?: emptyList()
            androidPlugins.find { it["name"] == "flutter_paymob_sdk" }
                ?.get("path")
                ?.let { maven { url = uri("${it}android/libs") } }
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
