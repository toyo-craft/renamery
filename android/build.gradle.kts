allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 複雑な Directory 型の操作を避け、推奨される単純なパス設定に変更
rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
