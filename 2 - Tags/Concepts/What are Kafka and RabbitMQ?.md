

Kafka and RabbitMQ are both **message brokers** — middleware that lets different parts of a system (often separate microservices) exchange data without calling each other directly. Instead of Service A calling Service B's REST endpoint, Service A publishes a message to the broker, and Service B consumes it whenever it's ready. This decouples producers from consumers: they don't need to know about each other, don't need to be online at the same time, and a slow or temporarily-down consumer doesn't block the producer.

Where they differ is _what kind of broker they are_. RabbitMQ is a traditional **message queue** built on the AMQP protocol — it's optimized for routing individual messages to the right consumer and then forgetting them. Kafka is a **distributed event log** — it's optimized for storing a continuous, ordered stream of events that can be replayed, read by many independent consumers, and kept for a long time. Both can be used for "send a message from A to B," but they were designed around different core ideas, and that difference drives every other design decision in each tool.

## Core concepts: RabbitMQ

RabbitMQ's model: a **producer** sends a message to an **exchange**, the exchange routes it to one or more **queues** based on rules (bindings), and **consumers** read from queues. Once a message is consumed and acknowledged, it's typically gone.

- **Exchange** — the routing logic. Types: `direct` (exact routing key match), `topic` (pattern match like `orders.*`), `fanout` (broadcast to every bound queue), `headers` (match on message headers).
- **Queue** — an ordered buffer of messages waiting for a consumer.
- **Binding** — the rule connecting an exchange to a queue.
- **Acknowledgment (ack)** — a consumer tells RabbitMQ "I processed this," and only then is the message removed from the queue.

```java
@Configuration
public class RabbitConfig {

    @Bean
    public Queue orderQueue() {
        return new Queue("order.queue", true); // durable
    }

    @Bean
    public TopicExchange orderExchange() {
        return new TopicExchange("order.exchange");
    }

    @Bean
    public Binding binding(Queue orderQueue, TopicExchange orderExchange) {
        return BindingBuilder.bind(orderQueue)
                .to(orderExchange)
                .with("order.created.*");
    }
}
```

```java
@Service
@RequiredArgsConstructor
public class OrderProducer {
    private final RabbitTemplate rabbitTemplate;

    public void publish(Order order) {
        rabbitTemplate.convertAndSend("order.exchange", "order.created.standard", order);
    }
}

@Component
public class OrderConsumer {

    @RabbitListener(queues = "order.queue")
    public void handle(Order order) {
        // process order
    }
}
```

## Core concepts: Kafka

Kafka's model: a **producer** writes records to a **topic**, a topic is split into **partitions**, and each partition is an append-only, ordered log stored on disk. **Consumers**, organized into **consumer groups**, read from partitions at their own pace by tracking an **offset** (a position in the log). Messages are _not_ deleted when read — they stay until a retention policy (time or size based) removes them, which means multiple independent consumer groups can each read the same stream from the beginning if they want.

- **Topic** — a named stream of records (conceptually like a table name).
- **Partition** — a topic is split into partitions for parallelism; order is only guaranteed _within_ a partition, not across the whole topic.
- **Offset** — each consumer group tracks its own read position per partition, independent of other groups.
- **Consumer group** — consumers in the same group split partitions between them (each partition goes to exactly one consumer in the group); different groups each get their own full copy of the stream.

```java
@Configuration
public class KafkaConfig {

    @Bean
    public NewTopic orderTopic() {
        return TopicBuilder.name("order-created")
                .partitions(3)
                .replicas(1)
                .build();
    }
}
```

```java
@Service
@RequiredArgsConstructor
public class OrderProducer {
    private final KafkaTemplate<String, Order> kafkaTemplate;

    public void publish(Order order) {
        // key = order.getId() -> same key always lands on the same partition,
        // which preserves order for that key
        kafkaTemplate.send("order-created", order.getId().toString(), order);
    }
}

@Component
public class OrderConsumer {

    @KafkaListener(topics = "order-created", groupId = "inventory-service")
    public void handle(Order order) {
        // process order
    }
}
```

Notice the key difference already visible in the code: RabbitMQ routes by exchange/binding rules, Kafka partitions by key. That single difference is why Kafka can guarantee per-key ordering at massive scale while RabbitMQ's ordering guarantee is simpler but less parallel.

## Side-by-side comparison

|Aspect|RabbitMQ|Kafka|
|---|---|---|
|Model|Smart broker, routes messages|Dumb broker, durable append-only log|
|Message lifetime|Deleted after ack (by default)|Retained per policy, replayable|
|Ordering|Per-queue (FIFO)|Per-partition only|
|Multiple consumers of same message|Needs fanout exchange + separate queues|Natural — each consumer group gets its own copy|
|Throughput|High, but tuned for complex routing|Very high, tuned for raw sequential I/O|
|Typical use case|Task queues, RPC-style messaging, complex routing|Event streaming, event sourcing, log aggregation, high-volume pipelines|
|Protocol|AMQP (also STOMP, MQTT)|Custom binary protocol over TCP|

## When you'd reach for each one

- **RabbitMQ** fits "do this job, once, for one consumer" problems: sending a confirmation email, processing a payment, a background task queue where you want fine-grained routing (priority queues, delayed retries via dead-letter exchanges, RPC-style request/reply).
- **Kafka** fits "many things need to know this happened, possibly later, possibly more than once" problems: an `order-created` event that the inventory service, the billing service, and an analytics pipeline all need to consume independently; audit logs; event sourcing, where the log itself is the source of truth and state is rebuilt by replaying it.

A related concept worth knowing in one line: **event-driven architecture** is the broader pattern both of these tools serve — services communicating through events rather than direct calls — and Kafka in particular is often the backbone of **event sourcing**, where instead of storing current state in a database, you store the full sequence of events and derive state by replaying them.


[[Spring Framework]]