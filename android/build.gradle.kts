import java.io.ByteArrayOutputStream
import java.util.Properties
import javax.inject.Inject
import org.gradle.process.ExecOperations

group = "com.specure.nettest.cell_info"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.4.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.3.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

// ---------------------------------------------------------------------------------------------
// NetMonster Core, pinned by commit.
//
// Upstream does not publish per-commit artifacts, so the sources are fetched with git at the
// exact commit from netmonster.properties and compiled into this module. Git itself guarantees
// that the content matches the SHA. The result is cached in the build directory, so the network
// is only needed after the pin changes or after `flutter clean`.
// ---------------------------------------------------------------------------------------------
val netMonster = Properties().apply {
    file("netmonster.properties").inputStream().use { load(it) }
}

abstract class FetchNetMonsterCore @Inject constructor(
    private val execOperations: ExecOperations,
    private val fileOperations: FileSystemOperations,
) : DefaultTask() {
    @get:Input
    abstract val repository: Property<String>

    @get:Input
    abstract val commit: Property<String>

    @get:Input
    abstract val sourcePath: Property<String>

    @get:OutputDirectory
    abstract val outputDir: DirectoryProperty

    @TaskAction
    fun fetch() {
        val sha = commit.get()
        require(Regex("[0-9a-f]{40}").matches(sha)) {
            "netmonster.properties: `commit` must be a full 40-character commit SHA, got '$sha'"
        }

        val checkout = temporaryDir.resolve("checkout")
        fileOperations.delete { delete(checkout) }
        checkout.mkdirs()

        fun git(vararg args: String): String {
            val stdout = ByteArrayOutputStream()
            execOperations.exec {
                workingDir = checkout
                commandLine(listOf("git") + args)
                standardOutput = stdout
            }
            return stdout.toString().trim()
        }

        git("init", "--quiet")
        git("fetch", "--quiet", "--depth", "1", repository.get(), sha)
        git("-c", "advice.detachedHead=false", "checkout", "--quiet", "FETCH_HEAD")
        val head = git("rev-parse", "HEAD")
        check(head == sha) { "Expected NetMonster Core at $sha but git checked out $head" }

        val sources = checkout.resolve(sourcePath.get())
        check(sources.isDirectory) { "'${sourcePath.get()}' not found in ${repository.get()} at $sha" }
        fileOperations.sync {
            from(sources)
            into(outputDir)
        }
        fileOperations.delete { delete(checkout) }
    }
}

val fetchNetMonsterCore = tasks.register<FetchNetMonsterCore>("fetchNetMonsterCore") {
    group = "netmonster"
    description = "Fetches NetMonster Core sources at the commit pinned in netmonster.properties"
    repository.set(netMonster.getProperty("repository"))
    commit.set(netMonster.getProperty("commit"))
    sourcePath.set(netMonster.getProperty("sourcePath"))
    outputDir.set(layout.buildDirectory.dir("netmonster-core/src"))
}

androidComponents {
    onVariants { variant ->
        variant.sources.java?.addGeneratedSourceDirectory(fetchNetMonsterCore, FetchNetMonsterCore::outputDir)
    }
}

android {
    namespace = "com.specure.nettest.cell_info"

    // Kept one step behind the newest SDK on purpose: AGP records this as the minimum compileSdk
    // of every app that uses the plugin, and nothing here needs a newer API.
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
        // Lets the app read which NetMonster Core commit it was built with.
        buildConfigField("String", "NETMONSTER_CORE_COMMIT", "\"${netMonster.getProperty("commit")}\"")
    }

    buildFeatures {
        buildConfig = true
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            // NetMonster models touch android.jar stubs (e.g. android.os.Build) in plain JVM tests.
            isReturnDefaultValues = true
            all {
                it.useJUnitPlatform()
                it.outputs.upToDateWhen { false }
                // Contract fixtures are shared with the Dart tests in <plugin>/test/fixtures.
                it.systemProperty("cellInfo.fixturesDir", file("../test/fixtures").absolutePath)
                it.systemProperty(
                    "cellInfo.updateFixtures",
                    (project.findProperty("updateFixtures") ?: "false").toString(),
                )
                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Required by the NetMonster Core sources.
    implementation("androidx.annotation:annotation:1.11.0")
    implementation("com.google.code.gson:gson:2.15.0")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
}
