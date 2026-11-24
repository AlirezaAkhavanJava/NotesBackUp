#!/usr/bin/env bash

set -euo pipefail

# Pack 09 — Jackson and Mappings
# All notes are created directly in this directory.
# Existing notes are never overwritten.

notes=(
  "Jackson ObjectMapper Internals"
  "Jackson Configuration in Spring Boot"
  "Jackson Modules and Dependencies"
  "Jackson Property Naming Strategies"
  "Jackson Serialization Customization"
  "Jackson Deserialization Customization"

  "@JsonProperty"
  "@JsonAlias"
  "@JsonIgnore"
  "@JsonIgnoreProperties"
  "@JsonIgnoreType"
  "@JsonInclude"
  "@JsonIncludeProperties"
  "@JsonPropertyOrder"
  "@JsonNaming"
  "@JsonRootName"
  "@JsonFormat"
  "@JsonGetter and @JsonSetter"
  "@JsonAnyGetter and @JsonAnySetter"
  "@JsonUnwrapped"
  "@JsonRawValue"
  "@JsonValue"
  "@JsonCreator"
  "@JsonDeserialize"
  "@JsonSerialize"
  "@JsonPOJOBuilder"
  "@JsonMerge"
  "@JsonSetter and Null Handling"
  "@JsonEnumDefaultValue"

  "@JsonManagedReference"
  "@JsonBackReference"
  "@JsonIdentityInfo"
  "@JsonIdentityReference"
  "Jackson Object Identity and Circular References"

  "@JsonTypeInfo"
  "@JsonSubTypes"
  "@JsonTypeName"
  "@JsonTypeId"
  "Jackson Polymorphic Deserialization"
  "Jackson Type Metadata and Security"

  "@JsonView"
  "@JsonFilter"
  "@JsonAutoDetect"
  "@JsonAppend"
  "@JsonIgnoreProperties allowGetters and allowSetters"
  "Jackson Mix-in Annotations"
  "Custom Jackson Annotations"

  "Custom JsonSerializer"
  "Custom JsonDeserializer"
  "ContextualSerializer and ContextualDeserializer"
  "Jackson Deserialization Problem Handlers"
  "Jackson Property Naming and Visibility Internals"
  "Jackson Handling of Java Time Types"
  "Jackson Handling of Collections and Maps"
  "Jackson Handling of Enums"
  "Jackson Handling of Records"
  "Jackson Handling of Generics"

  "Entity to DTO Mapping"
  "DTO to Entity Mapping"
  "Mapping Nested Objects"
  "Mapping Collections and Lists"
  "Mapping Bidirectional Relationships"
  "MapStruct Expressions and Qualified Methods"
  "MapStruct @MappingTarget"
  "MapStruct @InheritConfiguration"
  "MapStruct @InheritInverseConfiguration"
  "MapStruct @Named and @Qualifier"
  "MapStruct Null Value Strategies"
  "MapStruct Collection Mapping"
  "MapStruct Nested Mapping"
  "MapStruct Update Mapping"
  "MapStruct Generated Code Internals"
  "MapStruct with Spring Dependency Injection"
  "MapStruct Testing Strategies"

  "Mapping Boundaries and Separation of Concerns"
  "Where Mapping Belongs in a Spring Boot Application"
  "Why Entities Should Not Be API Response Objects"
  "Handling Mapping Errors and Validation"
)

next=16
created=0
skipped=0

for title in "${notes[@]}"; do
  filename=$(printf "%02d - %s.md" "$next" "$title")

  if [[ -e "$filename" ]]; then
    echo "SKIP: $filename"
    ((skipped += 1))
  else
    printf '[[Java]]\n' >"$filename"
    echo "CREATED: $filename"
    ((created += 1))
  fi

  ((next += 1))
done

echo
echo "Finished."
echo "Created: $created"
echo "Skipped: $skipped"
