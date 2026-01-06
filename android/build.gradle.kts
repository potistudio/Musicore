import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                // Fix Namespace for on_audio_query_android
                if (project.name == "on_audio_query_android") {
                    try {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        setNamespace.invoke(android, "com.lucasjosino.on_audio_query")
                    } catch (e: Exception) {
                        println("Failed to set namespace for on_audio_query_android: $e")
                    }
                }

                // Fix Java Version for all android projects
                try {
                    val getCompileOptions = android.javaClass.getMethod("getCompileOptions")
                    val compileOptions = getCompileOptions.invoke(android)

                    val setSource = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                    val setTarget = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)

                    setSource.invoke(compileOptions, JavaVersion.VERSION_17)
                    setTarget.invoke(compileOptions, JavaVersion.VERSION_17)
                } catch (e: Exception) {
                     println("Failed to set Java 17 for ${project.name}: $e")
                }
            }
        }
    }

    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
