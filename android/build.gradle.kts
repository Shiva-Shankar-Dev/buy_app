plugins{
    id("com.google.gms.google-services") version "4.4.2" apply false
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for AGP 8.x: old Flutter plugins don't declare a namespace in build.gradle.
// gradle.afterProject fires after each project is evaluated, avoiding the
// "Cannot run afterEvaluate when project is already evaluated" error.
gradle.afterProject {
    if (extensions.findByName("android") != null) {
        val androidExt = extensions.getByName("android")
        val namespaceGetter = try {
            androidExt::class.java.getMethod("getNamespace")
        } catch (e: NoSuchMethodException) { null }
        val currentNamespace = namespaceGetter?.invoke(androidExt) as? String
        if (currentNamespace.isNullOrEmpty()) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val packageName = groovy.xml.XmlParser()
                    .parse(manifestFile)
                    .attribute("package") as? String
                if (!packageName.isNullOrEmpty()) {
                    val namespaceSetter = try {
                        androidExt::class.java.getMethod("setNamespace", String::class.java)
                    } catch (e: NoSuchMethodException) { null }
                    namespaceSetter?.invoke(androidExt, packageName)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}