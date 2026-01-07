pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "ModuleDependencyDemo"
include(":app")
include(":login-api")
include(":login")
include(":home")
include(":passenger")
include(":flightlist")
include(":baggage")
include(":seat")
