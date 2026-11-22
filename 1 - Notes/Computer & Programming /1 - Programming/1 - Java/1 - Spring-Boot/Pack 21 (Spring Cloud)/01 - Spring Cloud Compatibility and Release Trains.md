
Spring Cloud isn't one artifact with one version number — it's a collection of a dozen-plus separate projects (Config, Gateway, OpenFeign, Circuit Breaker, Stream, Bus, Contract, and so on, all of which you've now met), each released and versioned independently. That creates an obvious problem: if `spring-cloud-config` is on version 4.2.1 and `spring-cloud-openfeign` is on version 4.3.0, how do you know those two actually work together, and which versions of _those_ work with the specific Spring Boot version you're running? **Release trains** are Spring's answer: instead of picking versions for each sub-project yourself, you pick one release train version, and it pins a tested, mutually-compatible set of versions for every sub-project plus the Spring Boot version they were built against.

## How a release train is named and versioned

Since 2020, release trains follow calendar versioning in the form `YYYY.MINOR.MICRO` — so `2023.0.6` means: generation released in 2023, its first minor line, patch 6. The first two numbers (`YYYY.MINOR`) identify the _generation_ — that's the part that matters for compatibility; the `MICRO` is just bug-fix patches within that generation. Before 2020, Spring Cloud used London Tube Station names for versions, and that naming scheme continues as a codename alongside the calendar version even though it's no longer used in the actual Maven version string. So "2023.0" and "Leyton" are the same generation — one is the version number, the other is the nickname people actually say out loud.

## The mechanism: one BOM import, everything else follows

In practice you never set a version number on each individual `spring-cloud-*` dependency. You import one Bill of Materials (BOM) for the release train, and every `spring-cloud-starter-*` you add afterward inherits its version from it automatically:

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>2023.0.6</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-config</artifactId>
        <!-- no version here — the BOM decides it -->
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-openfeign</artifactId>
    </dependency>
</dependencies>
```

This is the actual payoff of release trains: change one `<version>` tag — the BOM's — and your Config Server client, Eureka client, OpenFeign, Gateway, and everything else all shift together to a set of versions that's actually been tested as compatible with each other.

## Why it's tied to a specific Spring Boot version, not any Boot version

Each release train generation is built and tested against one specific Spring Boot line, not "whatever Boot version you happen to have." As of now, the current trains and what they pair with:

- Spring Cloud 2025.1 (Oakwood) targets Spring Boot 4.0.x and was released around late November 2025
- Spring Cloud 2025.0 (Northfields) targets Spring Boot 3.5.x
- Spring Cloud 2024.0 (Moorgate) targets Spring Boot 3.4.x
- Spring Cloud 2023.0 (Leyton) targets Spring Boot 3.3.x and 3.2.x

This is why "what Spring Boot version am I on" is the first question when picking a release train — pairing, say, a 2023.0 release train with a Spring Boot 4.0 app isn't a style choice, it's broken: the sub-projects were compiled and tested against Boot APIs from that specific generation, and mismatches show up as runtime `NoSuchMethodError`s or beans that silently fail to wire, often nowhere near the actual incompatible line of code.

## Support lifecycle: a train doesn't support itself independently

Spring Cloud follows the Tanzu OSS support policy for critical bugs and security issues, major versions get at least 3 years of support from release, and minor versions get at least 12 months. But individual sub-projects don't get their own support clock — a release train is considered supported for as long as the newest Spring Boot version it pairs with is still supported. Concretely: the 2022.0 (Kilburn) train, paired with Spring Boot 3.1.x/3.0.x, had its open-source support end mid-2024, which means by now every project inside that train — Config, Gateway, Eureka client, all of it — is past free support, regardless of how recently any individual one of them shipped a patch. This is the detail people miss: you don't track EOL per-library in the Spring Cloud ecosystem, you track it per-release-train, because that's the unit the support clock actually applies to.

## Tying it back: what this changes about everything you've already built

Every project you've learned so far — Config Server, Eureka, the Gateway, Zipkin/tracing, OpenFeign, the circuit breaker — is a `spring-cloud-starter-*` dependency sitting under one BOM import in your `pom.xml`. The release train is the thing that silently guaranteed all of them actually talk to each other correctly. Practically, this means: when you upgrade Spring Boot in a real project, the release train version is the _first_ thing you check and bump — not each `spring-cloud-starter` individually — and the compatibility table above is what tells you which train generation your new Boot version requires.

[[Spring Framework]]
