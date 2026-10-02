
Here’s a minimal working Spring Boot + Kafka example that both **produces** and **consumes** messages. It assumes Kafka is running on `localhost:9092`.

## 1. Dependencies

### Maven
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

### Gradle
```groovy
implementation 'org.springframework.boot:spring-boot-starter-web'
implementation 'org.springframework.kafka:spring-kafka'
```

Spring Boot manages the Spring Kafka version automatically.

---

## 2. `application.yml`

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092

    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer

    consumer:
      group-id: demo-group
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer

app:
  kafka:
    topic: demo-topic
```

---

## 3. Main Spring Boot Application

```java
package com.example.kafkademo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class KafkaDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(KafkaDemoApplication.class, args);
    }
}
```

---

## 4. Optional: Auto-create the Topic

Spring Kafka can create the topic automatically if it does not exist.

```java
package com.example.kafkademo.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

    @Bean
    public NewTopic demoTopic(@Value("${app.kafka.topic}") String topic) {
        return TopicBuilder.name(topic)
                .partitions(3)
                .replicas(1)
                .build();
    }
}
```

---

## 5. Producer Service

```java
package com.example.kafkademo.producer;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class KafkaProducerService {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final String topic;

    public KafkaProducerService(KafkaTemplate<String, String> kafkaTemplate,
                                @Value("${app.kafka.topic}") String topic) {
        this.kafkaTemplate = kafkaTemplate;
        this.topic = topic;
    }

    public void send(String message) {
        kafkaTemplate.send(topic, message)
                .whenComplete((result, ex) -> {
                    if (ex == null) {
                        System.out.println("Sent message: " + message
                                + " | offset: " + result.getRecordMetadata().offset());
                    } else {
                        System.err.println("Failed to send message: " + ex.getMessage());
                    }
                });
    }
}
```

You can also send with a key:

```java
kafkaTemplate.send(topic, "my-key", message);
```

---

## 6. Consumer Service

```java
package com.example.kafkademo.consumer;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class KafkaConsumerService {

    @KafkaListener(topics = "${app.kafka.topic}")
    public void consume(String message) {
        System.out.println("Received message: " + message);
    }
}
```

The `group-id` comes from `spring.kafka.consumer.group-id` in `application.yml`.

---

## 7. REST Controller to Trigger Sending

```java
package com.example.kafkademo.web;

import com.example.kafkademo.producer.KafkaProducerService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/messages")
public class MessageController {

    private final KafkaProducerService producerService;

    public MessageController(KafkaProducerService producerService) {
        this.producerService = producerService;
    }

    @PostMapping
    public String send(@RequestBody String message) {
        producerService.send(message);
        return "Sent: " + message;
    }
}
```

---

## 8. Run and Test

Start Kafka locally on `localhost:9092`, then run the Spring Boot app.

Send a message:

```bash
curl -X POST \
  -H "Content-Type: text/plain" \
  -d "Hello Kafka from Spring Boot" \
  http://localhost:8080/api/messages
```

You should see logs like:

```text
Sent message: Hello Kafka from Spring Boot | offset: 0
Received message: Hello Kafka from Spring Boot
```

---

## What Spring Boot + Spring Kafka Adds Here

Without Spring Kafka, you would manually create:

- `KafkaProducer`
- `KafkaConsumer`
- serializers/deserializers
- polling loops
- error handling
- thread management
- configuration wiring

With Spring Boot + Spring Kafka, you get:

- Auto-configured `KafkaTemplate`
- Auto-configured `ConsumerFactory` and `ProducerFactory`
- Declarative `@KafkaListener` consumers
- Automatic listener container lifecycle management
- Easy configuration through `application.yml`
- Built-in error handling, retries, and offset management
- Actuator health checks and metrics
- Testing support with `@EmbeddedKafka`





[[1 - Kafka]]