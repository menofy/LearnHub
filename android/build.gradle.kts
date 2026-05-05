import com.android.build.gradle.LibraryExtension
import javax.xml.parsers.DocumentBuilderFactory

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

    plugins.withId("com.android.library") {
        extensions.findByType(LibraryExtension::class.java)?.let { libraryExt ->
            if (libraryExt.namespace.isNullOrBlank()) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                val packageFromManifest =
                    if (manifestFile.exists()) {
                        runCatching {
                            val factory = DocumentBuilderFactory.newInstance()
                            val builder = factory.newDocumentBuilder()
                            val document = builder.parse(manifestFile)
                            document.documentElement.getAttribute("package")
                        }.getOrNull()
                    } else {
                        null
                    }

                libraryExt.namespace =
                    if (!packageFromManifest.isNullOrBlank()) {
                        packageFromManifest
                    } else {
                        "com.autofix.${project.name.replace("-", "_")}"
                    }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
