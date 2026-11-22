
#!/usr/bin/env bash

set -Eeuo pipefail

BASE_DIR="$(pwd)"

if [[ ! -f "$BASE_DIR/1 - Build Automation Tool ✧.md" ]]; then
    echo "Error: Run this script inside your Maven directory."
    exit 1
fi

created=0
skipped=0

create_note() {
    local filename="$1"
    local destination="$BASE_DIR/$filename"

    if [[ -e "$destination" ]]; then
        echo "[SKIP] $filename"
        ((skipped+=1))
        return
    fi

    {
        echo "[[Maven]]"
        echo
    } > "$destination"

    echo "[CREATED] $filename"
    ((created+=1))
}

notes=(

# --------------------------------------------------
# 4. Build Automation Fundamentals
# --------------------------------------------------

"4 - Build Process.md"
"5 - Source Code Compilation.md"
"6 - Build Lifecycle.md"
"7 - Build Artifacts.md"
"8 - Build Reproducibility.md"
"9 - Declarative vs Imperative Build Systems.md"
"10 - Maven vs Gradle.md"
"11 - Maven vs Ant.md"

# --------------------------------------------------
# 5. Maven Architecture
# --------------------------------------------------

"12 - What Maven Is.md"
"13 - Maven Architecture.md"
"14 - Maven Core Components.md"
"15 - Maven Installation and Configuration.md"
"16 - Maven Wrapper.md"
"17 - Maven CLI.md"
"18 - Maven Command Structure.md"
"19 - Maven Project Coordinates.md"
"20 - GroupId ArtifactId and Version.md"
"21 - Maven Naming Conventions.md"
"22 - Maven Standard Directory Layout.md"
"23 - Convention over Configuration.md"

# --------------------------------------------------
# 6. Project Object Model (POM)
# --------------------------------------------------

"24 - Project Object Model (POM).md"
"25 - pom.xml Structure.md"
"26 - POM Elements.md"
"27 - Model Version.md"
"28 - Parent POM.md"
"29 - Super POM.md"
"30 - Effective POM.md"
"31 - POM Inheritance.md"
"32 - POM Aggregation.md"
"33 - POM Inheritance vs Aggregation.md"
"34 - POM Relationships.md"
"35 - Maven Properties.md"
"36 - Built In Properties.md"
"37 - User Defined Properties.md"
"38 - Property Interpolation.md"

# --------------------------------------------------
# 7. Dependencies
# --------------------------------------------------

"39 - Maven Dependencies.md"
"40 - Dependency Coordinates.md"
"41 - Direct and Transitive Dependencies.md"
"42 - Dependency Resolution.md"
"43 - Dependency Tree.md"
"44 - Dependency Scopes.md"
"45 - Compile Scope.md"
"46 - Provided Scope.md"
"47 - Runtime Scope.md"
"48 - Test Scope.md"
"49 - System Scope.md"
"50 - Import Scope.md"
"51 - Optional Dependencies.md"
"52 - Excluding Transitive Dependencies.md"
"53 - Dependency Exclusions.md"
"54 - Dependency Version Management.md"
"55 - Dependency Management Section.md"
"56 - Dependency Mediation.md"
"57 - Nearest Definition Strategy.md"
"58 - Dependency Convergence.md"
"59 - Version Conflicts.md"
"60 - BOM (Bill of Materials).md"
"61 - Importing a BOM.md"
"62 - Maven Enforcer Dependency Rules.md"

# --------------------------------------------------
# 8. Maven Lifecycle
# --------------------------------------------------

"63 - Maven Build Lifecycle.md"
"64 - Default Lifecycle.md"
"65 - Clean Lifecycle.md"
"66 - Site Lifecycle.md"
"67 - Lifecycle Phases.md"
"68 - Lifecycle Goals.md"
"69 - Phase and Goal Differences.md"
"70 - Plugin Goal Binding.md"
"71 - validate Phase.md"
"72 - compile Phase.md"
"73 - test Phase.md"
"74 - package Phase.md"
"75 - verify Phase.md"
"76 - install Phase.md"
"77 - deploy Phase.md"
"78 - clean Phase.md"
"79 - Lifecycle Execution Order.md"
"80 - Skipping Build Phases.md"
"81 - Maven Command Lifecycle Examples.md"

# --------------------------------------------------
# 9. Maven Plugins
# --------------------------------------------------

"82 - Maven Plugins.md"
"83 - Plugin Architecture.md"
"84 - Plugin Coordinates.md"
"85 - Plugin Goals.md"
"86 - Plugin Configuration.md"
"87 - Plugin Management.md"
"88 - Plugins vs Plugin Management.md"
"89 - Maven Compiler Plugin.md"
"90 - Maven Surefire Plugin.md"
"91 - Maven Failsafe Plugin.md"
"92 - Maven Resources Plugin.md"
"93 - Maven Clean Plugin.md"
"94 - Maven JAR Plugin.md"
"95 - Maven WAR Plugin.md"
"96 - Maven Shade Plugin.md"
"97 - Maven Assembly Plugin.md"
"98 - Maven Dependency Plugin.md"
"99 - Maven Help Plugin.md"
"100 - Maven Enforcer Plugin.md"
"101 - Maven Source Plugin.md"
"102 - Maven Javadoc Plugin.md"
"103 - Maven Deploy Plugin.md"
"104 - Maven Release Plugin.md"
"105 - Maven Plugin Prefixes.md"
"106 - Plugin Version Management.md"
"107 - Custom Maven Plugins.md"

# --------------------------------------------------
# 10. Repositories and Artifact Resolution
# --------------------------------------------------

"108 - Maven Repositories.md"
"109 - Local Repository.md"
"110 - Remote Repository.md"
"111 - Central Repository.md"
"112 - Internal Maven Repository.md"
"113 - Repository Configuration.md"
"114 - Distribution Management.md"
"115 - Repository Policies.md"
"116 - Snapshot Versions.md"
"117 - Release Versions.md"
"118 - SNAPSHOT vs RELEASE.md"
"119 - Maven Metadata.md"
"120 - Artifact Resolution Process.md"
"121 - Repository Mirrors.md"
"122 - settings.xml.md"
"123 - Maven User Settings.md"
"124 - Maven Global Settings.md"
"125 - Authentication for Private Repositories.md"
"126 - Repository Credentials.md"
"127 - Maven Local Repository Structure.md"
"128 - Maven Cache Management.md"
"129 - Forcing Dependency Updates.md"
"130 - Offline Maven Builds.md"

# --------------------------------------------------
# 11. Multi Module Projects
# --------------------------------------------------

"131 - Multi Module Maven Projects.md"
"132 - Aggregator Projects.md"
"133 - Parent Projects.md"
"134 - Reactor Build.md"
"135 - Reactor Build Order.md"
"136 - Reactor Sorting.md"
"137 - Module Declaration.md"
"138 - Cross Module Dependencies.md"
"139 - Selective Module Builds.md"
"140 - Maven -pl Option.md"
"141 - Maven -am Option.md"
"142 - Maven -amd Option.md"
"143 - Maven -rf Option.md"
"144 - Shared Dependency Management.md"
"145 - Multi Module Project Best Practices.md"

# --------------------------------------------------
# 12. Profiles and Environment Configuration
# --------------------------------------------------

"146 - Maven Profiles.md"
"147 - Profile Activation.md"
"148 - Active Profiles.md"
"149 - Property Based Activation.md"
"150 - JDK Based Activation.md"
"151 - OS Based Activation.md"
"152 - File Based Activation.md"
"153 - Environment Specific Profiles.md"
"154 - Development Test and Production Profiles.md"
"155 - Profile Inheritance.md"
"156 - Profile Properties.md"
"157 - Profile Specific Dependencies.md"
"158 - Profile Specific Plugins.md"
"159 - Profile Best Practices.md"

# --------------------------------------------------
# 13. Testing and Code Quality
# --------------------------------------------------

"160 - Maven Testing Integration.md"
"161 - Unit Testing with Maven.md"
"162 - Maven Surefire Test Execution.md"
"163 - Maven Failsafe Integration Tests.md"
"164 - Test Lifecycle.md"
"165 - Test Resource Management.md"
"166 - Test Dependencies.md"
"167 - JaCoCo Code Coverage.md"
"168 - Static Code Analysis.md"
"169 - Checkstyle.md"
"170 - PMD.md"
"171 - SpotBugs.md"
"172 - SonarQube Integration.md"
"173 - Maven Enforcer Rules.md"
"174 - Quality Gates.md"

# --------------------------------------------------
# 14. Packaging and Distribution
# --------------------------------------------------

"175 - Maven Packaging Types.md"
"176 - JAR Packaging.md"
"177 - WAR Packaging.md"
"178 - POM Packaging.md"
"179 - Executable JAR.md"
"180 - Fat JAR and Uber JAR.md"
"181 - Thin JAR.md"
"182 - Manifest Configuration.md"
"183 - Resource Filtering.md"
"184 - Resource Directories.md"
"185 - Artifact Installation.md"
"186 - Artifact Deployment.md"
"187 - Artifact Versioning.md"
"188 - Semantic Versioning.md"
"189 - Maven Release Management.md"

# --------------------------------------------------
# 15. Spring Boot and Maven
# --------------------------------------------------

"190 - Spring Boot Maven Integration.md"
"191 - Spring Boot Starter Parent.md"
"192 - Spring Boot Dependencies BOM.md"
"193 - Spring Boot Maven Plugin.md"
"194 - Spring Boot Repackage Goal.md"
"195 - Spring Boot Executable JAR.md"
"196 - Spring Boot Layered JAR.md"
"197 - Spring Boot Build Info.md"
"198 - Spring Boot Dependency Management.md"
"199 - Spring Boot Starter Dependencies.md"
"200 - Excluding Dependencies in Spring Boot.md"
"201 - Maven and Spring Boot Profiles.md"
"202 - Building Spring Boot Applications.md"
"203 - Running Spring Boot with Maven.md"
"204 - Spring Boot Build Optimization.md"

# --------------------------------------------------
# 16. Advanced Maven
# --------------------------------------------------

"205 - Maven Build Extensions.md"
"206 - Maven Core Extensions.md"
"207 - Maven Event Listeners.md"
"208 - Maven Lifecycle Extensions.md"
"209 - Maven Build Customization.md"
"210 - Maven Archetypes.md"
"211 - Creating Custom Archetypes.md"
"212 - Maven Toolchains.md"
"213 - Java Toolchain Configuration.md"
"214 - Maven Compiler Release Option.md"
"215 - Maven Java Compatibility.md"
"216 - Reproducible Builds.md"
"217 - Maven Build Cache.md"
"218 - Parallel Maven Builds.md"
"219 - Maven Build Performance.md"
"220 - Incremental Build Concepts.md"
"221 - Maven Daemon (mvnd).md"
"222 - Maven Wrapper Internals.md"
"223 - Maven Plugin Development.md"
"224 - Maven Core Internals.md"

# --------------------------------------------------
# 17. CI CD and Production
# --------------------------------------------------

"225 - Maven in CI CD.md"
"226 - Maven in GitHub Actions.md"
"227 - Maven in GitLab CI.md"
"228 - Maven Build Pipelines.md"
"229 - Automated Testing Pipelines.md"
"230 - Artifact Publishing.md"
"231 - Private Artifact Registries.md"
"232 - Nexus Repository Manager.md"
"233 - JFrog Artifactory.md"
"234 - Maven Credentials in CI.md"
"235 - Secure Maven Builds.md"
"236 - Dependency Vulnerability Scanning.md"
"237 - Software Bill of Materials (SBOM).md"
"238 - Supply Chain Security.md"
"239 - Docker and Maven.md"
"240 - Multi Stage Docker Builds with Maven.md"
"241 - Maven Production Build Strategy.md"

# --------------------------------------------------
# 18. Troubleshooting and Best Practices
# --------------------------------------------------

"242 - Maven Troubleshooting.md"
"243 - Maven Debug Mode.md"
"244 - Maven Verbose Output.md"
"245 - Maven Dependency Tree Debugging.md"
"246 - Dependency Resolution Failures.md"
"247 - Plugin Resolution Failures.md"
"248 - Compilation Failures.md"
"249 - Test Execution Failures.md"
"250 - Repository Connection Problems.md"
"251 - SSL and Certificate Errors.md"
"252 - Maven Cache Corruption.md"
"253 - Out of Memory During Builds.md"
"254 - Maven Build Best Practices.md"
"255 - Dependency Management Best Practices.md"
"256 - Plugin Management Best Practices.md"
"257 - POM Maintainability.md"
"258 - Maven Security Best Practices.md"
"259 - Common Maven Mistakes.md"
"260 - Maven Project Checklist.md"

)

echo
echo "Starting Maven curriculum completion..."
echo "Target: $BASE_DIR"
echo

for note in "${notes[@]}"; do
    create_note "$note"
done

echo
echo "========================================"
echo "Maven curriculum completion finished."
echo "Created: $created"
echo "Skipped: $skipped"
echo "========================================"
