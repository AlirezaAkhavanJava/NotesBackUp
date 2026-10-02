
## Overview

**Spring AMQP** and **Spring Kafka** are Spring modules for integrating with messaging systems like **RabbitMQ** (AMQP protocol) and **Apache Kafka** (distributed streaming platform). These tools enable asynchronous, decoupled communication in event-driven architectures, allowing scalable and resilient systems.

**Why Use Messaging?**

- **Decoupling**: Producers and consumers operate independently, reducing tight coupling.
- **Scalability**: Handle high volumes of messages across distributed systems.
- **Resilience**: Buffers messages to manage load spikes and failures.
- **Event-Driven**: Supports real-time processing of events (e.g., notifications, updates).

**How It Works**:

- Add `spring-boot-starter-amqp` for RabbitMQ or `spring-kafka` for Kafka.
- Use `@RabbitListener` for AMQP message consumption or Kafka’s `KafkaTemplate` and `@KafkaListener` for producing/consuming messages.
- Configure queues (RabbitMQ) or topics (Kafka) to send and receive messages.

**Resources**:

- [Spring AMQP Documentation](https://docs.spring.io/spring-amqp/reference/html/)
- [Spring Kafka Documentation](https://docs.spring.io/spring-kafka/reference/html/)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- _Spring in Action_ by Craig Walls (Chapter 8)

**Prerequisites**:

- Basic understanding of message queues and topics (e.g., RabbitMQ queues, Kafka partitions).
- Familiarity with Spring Boot and REST APIs.

**Additional Tools**:

- Learn RabbitMQ basics: queues, exchanges, bindings.
- Learn Kafka basics: topics, partitions, producers, consumers.

**Practice Goal**: Extend the Todo API to send `Todo` creation events to a RabbitMQ queue and process them asynchronously using Spring AMQP. (Kafka example provided for reference.)

---

## Messaging Basics

### RabbitMQ (AMQP)

- **Queue**: A buffer where messages are stored until consumed.
- **Exchange**: Routes messages to queues based on routing keys.
- **Binding**: Links queues to exchanges with routing keys.
- **Spring AMQP**: Simplifies RabbitMQ integration with `@RabbitListener` for consumers and `RabbitTemplate` for producers.

**Example Flow**:

1. Producer sends a message to an exchange.
2. Exchange routes the message to a queue based on the routing key.
3. Consumer listens to the queue and processes the message.

### Kafka

- **Topic**: A category for messages, divided into partitions.
- **Partition**: Ordered, immutable sequence of messages.
- **Producer**: Sends messages to a topic.
- **Consumer**: Subscribes to a topic to read messages.
- **Spring Kafka**: Uses `KafkaTemplate` for producing and `@KafkaListener` for consuming.

**Example Flow**:

1. Producer sends a message to a topic.
2. Kafka stores the message in a partition.
3. Consumer group reads messages from partitions.

---

## RabbitMQ vs. Kafka

|Feature|RabbitMQ (AMQP)|Kafka|
|---|---|---|
|**Protocol**|AMQP|Custom (Kafka protocol)|
|**Model**|Queues, exchanges, bindings|Topics, partitions|
|**Use Case**|Task queues, point-to-point|Event streaming, high throughput|
|**Message Retention**|Messages consumed or expire|Messages retained based on policy|
|**Scalability**|Good for smaller-scale systems|Excellent for large-scale systems|

**Choice for Practice**: This guide uses **RabbitMQ** with Spring AMQP for simplicity, as it’s easier to set up for beginners. A Kafka example is provided for reference.

---

## Setting Up RabbitMQ with Spring AMQP

### 1. Install RabbitMQ

- **Docker (Recommended)**:
    
    ```bash
    docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
    ```
    
    - Access RabbitMQ management UI at `http://localhost:15672` (default: guest/guest).
- **Manual Installation**: Follow [RabbitMQ installation guide](https://www.rabbitmq.com/download.html).

### 2. Project Setup

Create a Spring Boot project with Spring AMQP and Spring Data JPA.

#### `pom.xml`

```xml
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>todo-messaging-app</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.4</version>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-amqp</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### 3. Configure Application

Set up RabbitMQ and H2 database in `src/main/resources/application.properties`.

```properties
spring.datasource.url=jdbc:h2:mem:tododb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=update
spring.h2.console.enabled=true

# RabbitMQ configuration
spring.rabbitmq.host=localhost
spring.rabbitmq.port=5672
spring.rabbitmq.username=guest
spring.rabbitmq.password=guest
```

---

## Practice: Sending and Processing Todo Creation Events

### Project Structure

```
todo-messaging-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   ├── com/example/
│   │   │   │   ├── TodoApplication.java
│   │   │   │   ├── model/
│   │   │   │   │   ├── Todo.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── TodoRepository.java
│   │   │   │   ├── service/
│   │   │   │   │   ├── TodoService.java
│   │   │   │   │   ├── TodoEventListener.java
│   │   │   │   ├── controller/
│   │   │   │   │   ├── TodoController.java
│   │   │   │   ├── config/
│   │   │   │   │   ├── RabbitMQConfig.java
│   │   ├── resources/
│   │   │   ├── application.properties
├── pom.xml
```

### 1. Entity Class (`Todo.java`)

```java
package com.example.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Todo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String title;
    private boolean completed;

    public Todo() {}

    public Todo(String title, boolean completed) {
        this.title = title;
        this.completed = completed;
    }

    // Getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public boolean isCompleted() { return completed; }
    public void setCompleted(boolean completed) { this.completed = completed; }

    @Override
    public String toString() {
        return "Todo{id=" + id + ", title='" + title + "', completed=" + completed + "}";
    }
}
```

### 2. Repository (`TodoRepository.java`)

```java
package com.example.repository;

import com.example.model.Todo;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TodoRepository extends JpaRepository<Todo, Long> {
}
```

### 3. RabbitMQ Configuration (`RabbitMQConfig.java`)

Define the queue, exchange, and binding.

```java
package com.example.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String QUEUE_NAME = "todo-queue";
    public static final String EXCHANGE_NAME = "todo-exchange";
    public static final String ROUTING_KEY = "todo.created";

    @Bean
    public Queue queue() {
        return new Queue(QUEUE_NAME, true); // Durable queue
    }

    @Bean
    public TopicExchange exchange() {
        return new TopicExchange(EXCHANGE_NAME);
    }

    @Bean
    public Binding binding(Queue queue, TopicExchange exchange) {
        return BindingBuilder.bind(queue).to(exchange).with(ROUTING_KEY);
    }
}
```

**Notes**:

- `Queue`: Creates a durable queue (`todo-queue`).
- `TopicExchange`: Routes messages based on routing keys.
- `Binding`: Links the queue to the exchange with the routing key `todo.created`.

### 4. Service (`TodoService.java`)

Send Todo creation events to RabbitMQ.

```java
package com.example.service;

import com.example.model.Todo;
import com.example.repository.TodoRepository;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

@Service
public class TodoService {
    private final TodoRepository todoRepository;
    private final RabbitTemplate rabbitTemplate;

    public TodoService(TodoRepository todoRepository, RabbitTemplate rabbitTemplate) {
        this.todoRepository = todoRepository;
        this.rabbitTemplate = rabbitTemplate;
    }

    public Todo createTodo(Todo todo) {
        Todo savedTodo = todoRepository.save(todo);
        rabbitTemplate.convertAndSend("todo-exchange", "todo.created", savedTodo);
        return savedTodo;
    }
}
```

**Notes**:

- `RabbitTemplate`: Sends the `Todo` object as a message to the `todo-exchange` with routing key `todo.created`.
- The message is serialized to JSON automatically.

### 5. Message Listener (`TodoEventListener.java`)

Process messages asynchronously.

```java
package com.example.service;

import com.example.model.Todo;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
public class TodoEventListener {

    @RabbitListener(queues = "todo-queue")
    public void handleTodoCreated(Todo todo) {
        System.out.println("Received Todo creation event: " + todo);
        // Process the event (e.g., send notification, update analytics)
    }
}
```

**Notes**:

- `@RabbitListener`: Listens to the `todo-queue` and deserializes messages into `Todo` objects.
- Prints the received todo (in a real app, this could trigger notifications or analytics).

### 6. Controller (`TodoController.java`)

```java
package com.example.controller;

import com.example.model.Todo;
import com.example.service.TodoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/todos")
public class TodoController {
    private final TodoService todoService;

    public TodoController(TodoService todoService) {
        this.todoService = todoService;
    }

    @PostMapping
    public ResponseEntity<Todo> createTodo(@RequestBody Todo todo) {
        return new ResponseEntity<>(todoService.createTodo(todo), HttpStatus.CREATED);
    }
}
```

### 7. Main Application (`TodoApplication.java`)

```java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TodoApplication {
    public static void main(String[] args) {
        SpringApplication.run(TodoApplication.class, args);
    }
}
```

---

## Running and Testing the Application

### 1. Start RabbitMQ

```bash
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```

### 2. Run the Application

```bash
mvn spring-boot:run
```

### 3. Test with Postman

- **Create a Todo**:
    
    ```bash
    curl -X POST http://localhost:8080/api/todos \
    -H "Content-Type: application/json" \
    -d '{"title":"Learn Messaging","completed":false}'
    ```
    
    **Response** (HTTP 201):
    
    ```json
    {
        "id": 1,
        "title": "Learn Messaging",
        "completed": false
    }
    ```
    
    **Console Output**:
    
    ```
    Received Todo creation event: Todo{id=1, title='Learn Messaging', completed=false}
    ```
    

### 4. Verify in RabbitMQ Management UI

- Access `http://localhost:15672` (guest/guest).
- Check the `todo-queue` under the "Queues" tab to confirm messages are processed.

---

## How the Code Works

1. **Configuration (`RabbitMQConfig`)**:
    
    - Defines a durable queue (`todo-queue`), a topic exchange (`todo-exchange`), and a binding with routing key `todo.created`.
    - Spring AMQP automatically creates these resources in RabbitMQ.
2. **Producer (`TodoService`)**:
    
    - When a todo is created via `createTodo`, the `Todo` object is saved to the database.
    - `RabbitTemplate.convertAndSend` serializes the `Todo` to JSON and sends it to the `todo-exchange` with routing key `todo.created`.
    - The exchange routes the message to `todo-queue` based on the binding.
3. **Consumer (`TodoEventListener`)**:
    
    - `@RabbitListener(queues = "todo-queue")` listens for messages in `todo-queue`.
    - Spring AMQP deserializes the JSON message back into a `Todo` object.
    - The `handleTodoCreated` method processes the message (e.g., logging it).
4. **Flow**:
    
    - POST `/api/todos` → `TodoController` → `TodoService` saves to database and sends message.
    - Message routed to `todo-queue` → `TodoEventListener` processes asynchronously.
    - The consumer runs in a separate thread, decoupling the producer from the consumer.
5. **Benefits**:
    
    - **Asynchronous Processing**: The API responds immediately after saving the todo, while the event is processed in the background.
    - **Decoupling**: The producer (`TodoService`) doesn’t need to know about consumers.
    - **Scalability**: Multiple consumers can process messages from the same queue.

---

## Kafka Alternative (Reference)

For comparison, here’s how the same functionality could be implemented with **Spring Kafka**.

### 1. Add Kafka Dependency

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

### 2. Configure Kafka

In `application.properties`:

```properties
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.producer.key-serializer=org.apache.kafka.common.serialization.StringSerializer
spring.kafka.producer.value-serializer=org.springframework.kafka.support.serializer.JsonSerializer
spring.kafka.consumer.group-id=todo-group
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.key-deserializer=org.apache.kafka.common.serialization.StringDeserializer
spring.kafka.consumer.value-deserializer=org.springframework.kafka.support.serializer.JsonDeserializer
spring.kafka.consumer.properties.spring.json.trusted.packages=com.example.model
```

### 3. Kafka Configuration (`KafkaConfig.java`)

```java
package com.example.config;

import com.example.model.Todo;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaConfig {

    public static final String TOPIC_NAME = "todo-topic";

    @Bean
    public NewTopic todoTopic() {
        return TopicBuilder.name(TOPIC_NAME)
                .partitions(1)
                .replicas(1)
                .build();
    }
}
```

### 4. Update `TodoService.java`

```java
package com.example.service;

import com.example.config.KafkaConfig;
import com.example.model.Todo;
import com.example.repository.TodoRepository;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class TodoService {
    private final TodoRepository todoRepository;
    private final KafkaTemplate<String, Todo> kafkaTemplate;

    public TodoService(TodoRepository todoRepository, KafkaTemplate<String, Todo> kafkaTemplate) {
        this.todoRepository = todoRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    public Todo createTodo(Todo todo) {
        Todo savedTodo = todoRepository.save(todo);
        kafkaTemplate.send(KafkaConfig.TOPIC_NAME, String.valueOf(savedTodo.getId()), savedTodo);
        return savedTodo;
    }
}
```

### 5. Update `TodoEventListener.java`

```java
package com.example.service;

import com.example.config.KafkaConfig;
import com.example.model.Todo;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class TodoEventListener {

    @KafkaListener(topics = KafkaConfig.TOPIC_NAME, groupId = "todo-group")
    public void handleTodoCreated(Todo todo) {
        System.out.println("Received Todo creation event: " + todo);
    }
}
```

### 6. Run Kafka

- Install Kafka (e.g., via Docker):
    
    ```bash
    docker run -d --name zookeeper -p 2181:2181 zookeeper
    docker run -d --name kafka -p 9092:9092 \
        -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
        -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
        confluentinc/cp-kafka
    ```
    

### 7. Test Kafka

- Same POST request as RabbitMQ.
- Console output will show the event processed by the Kafka listener.

**Key Differences**:

- Kafka uses topics and partitions instead of queues and exchanges.
- Messages are retained in Kafka based on retention policies, not consumed immediately like RabbitMQ.
- `KafkaTemplate` sends messages to a topic, and `@KafkaListener` consumes from a topic with a consumer group.

---

## Advanced Features

1. **Error Handling (RabbitMQ)**:  
    Configure a dead-letter queue:
    
    ```java
    @Bean
    public Queue deadLetterQueue() {
        return new Queue("todo-dlq", true);
    }
    @Bean
    public Queue queue() {
        return QueueBuilder.durable(QUEUE_NAME)
                .withArgument("x-dead-letter-exchange", "")
                .withArgument("x-dead-letter-routing-key", "todo-dlq")
                .build();
    }
    ```
    
2. **Retries**:  
    Add retry logic for failed messages:
    
    ```java
    @RabbitListener(queues = "todo-queue")
    public void handleTodoCreated(Todo todo, Message message) {
        try {
            System.out.println("Processing: " + todo);
            // Simulate failure
            if (todo.getTitle().contains("fail")) {
                throw new RuntimeException("Simulated failure");
            }
        } catch (Exception e) {
            throw new AmqpRejectAndDontRequeueException("Failed to process", e);
        }
    }
    ```
    
3. **Kafka Consumer Groups**:  
    Scale consumers by adding more listeners in the same group:
    
    ```java
    @KafkaListener(topics = KafkaConfig.TOPIC_NAME, groupId = "todo-group", concurrency = "3")
    public void handleTodoCreated(Todo todo) { ... }
    ```
    
4. **Message Filtering**:  
    Filter messages in RabbitMQ using routing keys or in Kafka using a `RecordFilterStrategy`.
    

---

## Best Practices

- **Use Durable Queues/Topics**: Ensure messages are not lost on broker restart.
- **Handle Errors**: Implement dead-letter queues or retry mechanisms.
- **Monitor Queues**: Use RabbitMQ’s management UI or Kafka’s monitoring tools.
- **Secure Messaging**: Enable SSL/TLS for RabbitMQ/Kafka in production.
- **Test Messaging**:
    
    ```java
    @SpringBootTest
    class TodoServiceTest {
        @Autowired
        private TodoService todoService;
        @Autowired
        private RabbitTemplate rabbitTemplate;
    
        @Test
        void testSendTodoEvent() {
            Todo todo = new Todo("Test", false);
            todoService.createTodo(todo);
            Message message = rabbitTemplate.receive("todo-queue", 1000);
            assertNotNull(message);
        }
    }
    ```
    

---

## Conclusion

Spring AMQP and Spring Kafka enable asynchronous messaging for decoupled, event-driven systems. The Todo application demonstrates sending `Todo` creation events to a RabbitMQ queue and processing them asynchronously with `@RabbitListener`. Spring AMQP simplifies RabbitMQ integration, while Spring Kafka offers similar functionality for Kafka. Explore advanced features like error handling and retries, and refer to the Spring AMQP and Kafka documentation for deeper insights.

[[0 - Spring Framework]]