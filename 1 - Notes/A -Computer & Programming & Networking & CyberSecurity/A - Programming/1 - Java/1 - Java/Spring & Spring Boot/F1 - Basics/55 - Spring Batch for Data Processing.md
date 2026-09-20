
## Table of Contents
1. [Introduction to Spring Batch](#introduction-to-spring-batch)
2. [Key Concepts and Architecture](#key-concepts-and-architecture)
3. [Setting Up Spring Batch](#setting-up-spring-batch)
4. [Your First Batch Job](#your-first-batch-job)
5. [Reading and Writing Data](#reading-and-writing-data)
6. [Processing Data](#processing-data)
7. [Job Configuration and Flow](#job-configuration-and-flow)
8. [Error Handling and Retry](#error-handling-and-retry)
9. [Scaling and Performance](#scaling-and-performance)
10. [Monitoring and Management](#monitoring-and-management)
11. [Real-World Example: CSV to Database Processing](#real-world-example-csv-to-database-processing)

## Introduction to Spring Batch

Spring Batch is a lightweight, comprehensive framework designed for building robust batch processing applications. It provides reusable functions that are essential in processing large volumes of records, including:

- **Logging/tracing**
- **Transaction management**
- **Job processing statistics**
- **Job restart capabilities**
- **Skip and retry functionality**

### When to Use Spring Batch
- **ETL operations** (Extract, Transform, Load)
- **Scheduled report generation**
- **Database migration/cleanup**
- **Bulk data processing**
- **Import/export operations**

## Key Concepts and Architecture

### Core Components
1. **Job**: The entire batch process
2. **Step**: A phase within a job
3. **ItemReader**: Reads input data
4. **ItemProcessor**: Processes/transforms data
5. **ItemWriter**: Writes output data
6. **JobLauncher**: Starts jobs
7. **JobRepository**: Stores job metadata

### Batch Processing Pattern
```
Job → Step → [Chunk: Read → Process → Write] → Next Step → Job Completion
```

## Setting Up Spring Batch

### Dependencies
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-batch</artifactId>
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
```

### Enable Batch Processing
```java
@SpringBootApplication
@EnableBatchProcessing
public class BatchProcessingApplication {
    public static void main(String[] args) {
        SpringApplication.run(BatchProcessingApplication.class, args);
    }
}
```

## Your First Batch Job

### Simple Hello World Job
```java
@Configuration
public class HelloWorldJobConfig {

    @Autowired
    private JobBuilderFactory jobBuilderFactory;

    @Autowired
    private StepBuilderFactory stepBuilderFactory;

    @Bean
    public Job helloWorldJob() {
        return jobBuilderFactory.get("helloWorldJob")
                .incrementer(new RunIdIncrementer())
                .start(helloWorldStep())
                .build();
    }

    @Bean
    public Step helloWorldStep() {
        return stepBuilderFactory.get("helloWorldStep")
                .tasklet((contribution, chunkContext) -> {
                    System.out.println("Hello, World!");
                    return RepeatStatus.FINISHED;
                })
                .build();
    }
}
```

### Running the Job
```java
@Component
public class JobRunner implements ApplicationRunner {

    @Autowired
    private JobLauncher jobLauncher;

    @Autowired
    private Job helloWorldJob;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        JobParameters jobParameters = new JobParametersBuilder()
                .addLong("time", System.currentTimeMillis())
                .toJobParameters();
        
        jobLauncher.run(helloWorldJob, jobParameters);
    }
}
```

## Reading and Writing Data

### Flat File Reading (CSV)
```java
@Bean
public FlatFileItemReader<Person> reader() {
    return new FlatFileItemReaderBuilder<Person>()
            .name("personItemReader")
            .resource(new ClassPathResource("sample-data.csv"))
            .delimited()
            .names(new String[]{"firstName", "lastName", "email", "age"})
            .fieldSetMapper(new BeanWrapperFieldSetMapper<Person>() {{
                setTargetType(Person.class);
            }})
            .build();
}
```

### Database Writing (JPA)
```java
@Bean
public JpaItemWriter<Person> writer(EntityManagerFactory entityManagerFactory) {
    JpaItemWriter<Person> writer = new JpaItemWriter<>();
    writer.setEntityManagerFactory(entityManagerFactory);
    return writer;
}
```

### Database Reading
```java
@Bean
public JpaPagingItemReader<Person> reader(EntityManagerFactory entityManagerFactory) {
    return new JpaPagingItemReaderBuilder<Person>()
            .name("personReader")
            .entityManagerFactory(entityManagerFactory)
            .queryString("select p from Person p where p.processed = false")
            .pageSize(1000)
            .build();
}
```

## Processing Data

### Simple Item Processor
```java
@Component
public class PersonItemProcessor implements ItemProcessor<Person, Person> {

    private static final Logger log = LoggerFactory.getLogger(PersonItemProcessor.class);

    @Override
    public Person process(final Person person) throws Exception {
        final String firstName = person.getFirstName().toUpperCase();
        final String lastName = person.getLastName().toUpperCase();
        final String email = person.getEmail().toLowerCase();
        final int age = person.getAge();

        final Person transformedPerson = new Person(firstName, lastName, email, age);
        transformedPerson.setId(person.getId());

        log.info("Converting (" + person + ") into (" + transformedPerson + ")");

        return transformedPerson;
    }
}
```

### Validating Processor
```java
@Component
public class ValidatingItemProcessor implements ItemProcessor<Person, Person> {

    private final Validator validator;

    public ValidatingItemProcessor(Validator validator) {
        this.validator = validator;
    }

    @Override
    public Person process(Person person) throws Exception {
        Set<ConstraintViolation<Person>> violations = validator.validate(person);
        
        if (!violations.isEmpty()) {
            throw new ConstraintViolationException(violations);
        }
        
        return person;
    }
}
```

### Composite Processor
```java
@Bean
public CompositeItemProcessor<Person, Person> compositeProcessor() {
    List<ItemProcessor<Person, Person>> delegates = new ArrayList<>(2);
    delegates.add(validatorProcessor());
    delegates.add(transformationProcessor());
    
    CompositeItemProcessor<Person, Person> compositeProcessor = new CompositeItemProcessor<>();
    compositeProcessor.setDelegates(delegates);
    
    return compositeProcessor;
}
```

## Job Configuration and Flow

### Multi-Step Job
```java
@Bean
public Job importUserJob(JobCompletionNotificationListener listener, Step step1, Step step2) {
    return jobBuilderFactory.get("importUserJob")
            .incrementer(new RunIdIncrementer())
            .listener(listener)
            .flow(step1)
            .next(step2)
            .end()
            .build();
}

@Bean
public Step step1(JpaItemWriter<Person> writer) {
    return stepBuilderFactory.get("step1")
            .<Person, Person>chunk(10)
            .reader(reader())
            .processor(processor())
            .writer(writer)
            .build();
}

@Bean
public Step step2(JpaItemWriter<Report> reportWriter) {
    return stepBuilderFactory.get("step2")
            .<Person, Report>chunk(10)
            .reader(databaseReader())
            .processor(reportProcessor())
            .writer(reportWriter)
            .build();
}
```

### Conditional Flow
```java
@Bean
public Job conditionalJob() {
    return jobBuilderFactory.get("conditionalJob")
            .start(step1())
            .on("FAILED").to(step2())
            .from(step1())
            .on("*").to(step3())
            .end()
            .build();
}
```

### Decision-Based Flow
```java
@Bean
public Job decisionJob() {
    return jobBuilderFactory.get("decisionJob")
            .start(step1())
            .next(decision())
            .from(decision())
                .on("FAILED").to(step2())
                .on("COMPLETED").to(step3())
            .end()
            .build();
}

@Bean
public JobExecutionDecider decision() {
    return (jobExecution, stepExecution) -> {
        // Your decision logic here
        String status = jobExecution.getStatus().toString();
        return new FlowExecutionStatus(status);
    };
}
```

## Error Handling and Retry

### Skip and Retry Configuration
```java
@Bean
public Step faultTolerantStep() {
    return stepBuilderFactory.get("faultTolerantStep")
            .<Person, Person>chunk(10)
            .reader(reader())
            .processor(processor())
            .writer(writer())
            .faultTolerant()
            .skipLimit(10)
            .skip(FlatFileParseException.class)
            .skip(ConstraintViolationException.class)
            .noSkip(FileNotFoundException.class)
            .retryLimit(3)
            .retry(DeadlockLoserDataAccessException.class)
            .backOffPolicy(backOffPolicy())
            .build();
}

@Bean
public ExponentialBackOffPolicy backOffPolicy() {
    ExponentialBackOffPolicy backOffPolicy = new ExponentialBackOffPolicy();
    backOffPolicy.setInitialInterval(1000);
    backOffPolicy.setMultiplier(2.0);
    backOffPolicy.setMaxInterval(10000);
    return backOffPolicy;
}
```

### Custom Skip Listener
```java
@Component
public class CustomSkipListener implements SkipListener<Person, Person> {

    @Override
    public void onSkipInRead(Throwable t) {
        log.error("Skip in read due to: {}", t.getMessage());
    }

    @Override
    public void onSkipInWrite(Person item, Throwable t) {
        log.error("Skip in write for item: {} due to: {}", item, t.getMessage());
    }

    @Override
    public void onSkipInProcess(Person item, Throwable t) {
        log.error("Skip in process for item: {} due to: {}", item, t.getMessage());
        // You can save skipped items to a separate table
    }
}

// Add to step configuration
.listener(skipListener)
```

### Exception Handling in Processor
```java
@Component
public class ExceptionHandlingProcessor implements ItemProcessor<Person, Person> {

    @Override
    public Person process(Person person) throws Exception {
        try {
            // Processing logic that might throw exceptions
            if (person.getEmail() == null) {
                throw new InvalidDataException("Email is required");
            }
            return person;
        } catch (InvalidDataException e) {
            // Log and rethrow as unchecked exception to trigger skip/retry
            log.warn("Invalid data for person: {}", person.getId());
            throw new RuntimeException(e);
        }
    }
}
```

## Scaling and Performance

### Multi-threaded Step
```java
@Bean
public Step multiThreadedStep() {
    return stepBuilderFactory.get("multiThreadedStep")
            .<Person, Person>chunk(1000)
            .reader(reader())
            .processor(processor())
            .writer(writer())
            .taskExecutor(taskExecutor())
            .throttleLimit(20)
            .build();
}

@Bean
public TaskExecutor taskExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(10);
    executor.setMaxPoolSize(20);
    executor.setQueueCapacity(200);
    executor.setThreadNamePrefix("batch-");
    executor.initialize();
    return executor;
}
```

### Partitioning (Parallel Processing)
```java
@Bean
public Step masterStep() {
    return stepBuilderFactory.get("masterStep")
            .partitioner("slaveStep", partitioner())
            .step(slaveStep())
            .taskExecutor(taskExecutor())
            .build();
}

@Bean
public Partitioner partitioner() {
    ColumnRangePartitioner partitioner = new ColumnRangePartitioner();
    partitioner.setColumn("id");
    partitioner.setDataSource(dataSource);
    partitioner.setTable("people");
    return partitioner;
}

@Bean
public Step slaveStep() {
    return stepBuilderFactory.get("slaveStep")
            .<Person, Person>chunk(1000)
            .reader(partitionReader())
            .processor(processor())
            .writer(writer())
            .build();
}

@Bean
@StepScope
public ItemReader<Person> partitionReader(
        @Value("#{stepExecutionContext['minValue']}") Long minValue,
        @Value("#{stepExecutionContext['maxValue']}") Long maxValue) {
    
    return new JpaPagingItemReaderBuilder<Person>()
            .name("partitionReader")
            .entityManagerFactory(entityManagerFactory)
            .queryString("select p from Person p where p.id between :min and :max")
            .parameterValues(Map.of("min", minValue, "max", maxValue))
            .pageSize(1000)
            .build();
}
```

### Async Item Processing
```java
@Bean
public Step asyncStep() {
    return stepBuilderFactory.get("asyncStep")
            .<Person, CompletableFuture<Person>>chunk(100)
            .reader(reader())
            .processor(asyncProcessor())
            .writer(asyncWriter())
            .build();
}

@Bean
public AsyncItemProcessor<Person, Person> asyncProcessor() {
    AsyncItemProcessor<Person, Person> asyncProcessor = new AsyncItemProcessor<>();
    asyncProcessor.setDelegate(syncProcessor());
    asyncProcessor.setTaskExecutor(taskExecutor());
    return asyncProcessor;
}

@Bean
public AsyncItemWriter<Person> asyncWriter() {
    AsyncItemWriter<Person> asyncWriter = new AsyncItemWriter<>();
    asyncWriter.setDelegate(syncWriter());
    return asyncWriter;
}
```

## Monitoring and Management

### Job Execution Listener
```java
@Component
public class JobCompletionNotificationListener extends JobExecutionListenerSupport {

    private static final Logger log = LoggerFactory.getLogger(JobCompletionNotificationListener.class);

    private final JdbcTemplate jdbcTemplate;

    @Autowired
    public JobCompletionNotificationListener(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void afterJob(JobExecution jobExecution) {
        if(jobExecution.getStatus() == BatchStatus.COMPLETED) {
            log.info("!!! JOB FINISHED! Time to verify the results");

            jdbcTemplate.query("SELECT first_name, last_name, email, age FROM people",
                (rs, row) -> new Person(
                    rs.getString(1),
                    rs.getString(2),
                    rs.getString(3),
                    rs.getInt(4))
            ).forEach(person -> log.info("Found <" + person + "> in the database."));
        } else if (jobExecution.getStatus() == BatchStatus.FAILED) {
            log.error("Job failed with exit status: {}", jobExecution.getExitStatus());
            // Send notification or take corrective action
        }
    }

    @Override
    public void beforeJob(JobExecution jobExecution) {
        log.info("Starting job: {}", jobExecution.getJobInstance().getJobName());
    }
}
```

### Custom Job Repository
```java
@Configuration
public class BatchMetaDataConfig {

    @Bean
    public JobRepository jobRepository(DataSource dataSource, PlatformTransactionManager transactionManager) 
            throws Exception {
        JobRepositoryFactoryBean factory = new JobRepositoryFactoryBean();
        factory.setDataSource(dataSource);
        factory.setTransactionManager(transactionManager);
        factory.setIsolationLevelForCreate("ISOLATION_READ_COMMITTED");
        factory.setTablePrefix("BATCH_");
        factory.setMaxVarCharLength(1000);
        return factory.getObject();
    }
}
```

### Metrics and Monitoring
```java
@Component
public class BatchMetrics {
    
    @Autowired
    private MeterRegistry meterRegistry;
    
    @AfterStep
    public void afterStep(StepExecution stepExecution) {
        meterRegistry.counter("batch.step.executions", 
                "step", stepExecution.getStepName(),
                "status", stepExecution.getStatus().toString())
            .increment();
        
        meterRegistry.timer("batch.step.duration",
                "step", stepExecution.getStepName())
            .record(stepExecution.getEndTime().getTime() - stepExecution.getStartTime().getTime(), 
                    TimeUnit.MILLISECONDS);
    }
    
    @AfterJob
    public void afterJob(JobExecution jobExecution) {
        meterRegistry.counter("batch.job.executions",
                "job", jobExecution.getJobInstance().getJobName(),
                "status", jobExecution.getStatus().toString())
            .increment();
    }
}
```

## Real-World Example: CSV to Database Processing

### Complete Job Configuration
```java
@Configuration
public class CsvToDatabaseJobConfig {

    @Autowired
    private JobBuilderFactory jobBuilderFactory;

    @Autowired
    private StepBuilderFactory stepBuilderFactory;

    @Autowired
    private DataSource dataSource;

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    @Value("${input.file:classpath:input.csv}")
    private Resource inputFile;

    @Bean
    public FlatFileItemReader<Person> csvReader() {
        return new FlatFileItemReaderBuilder<Person>()
                .name("csvReader")
                .resource(inputFile)
                .delimited()
                .names("firstName", "lastName", "email", "age")
                .fieldSetMapper(new BeanWrapperFieldSetMapper<Person>() {{
                    setTargetType(Person.class);
                }})
                .linesToSkip(1) // Skip header
                .build();
    }

    @Bean
    public JpaItemWriter<Person> databaseWriter() {
        JpaItemWriter<Person> writer = new JpaItemWriter<>();
        writer.setEntityManagerFactory(entityManagerFactory);
        return writer;
    }

    @Bean
    public PersonItemProcessor processor() {
        return new PersonItemProcessor();
    }

    @Bean
    public Step csvToDatabaseStep() {
        return stepBuilderFactory.get("csvToDatabaseStep")
                .<Person, Person>chunk(1000)
                .reader(csvReader())
                .processor(processor())
                .writer(databaseWriter())
                .faultTolerant()
                .skipLimit(100)
                .skip(Exception.class)
                .noSkip(FileNotFoundException.class)
                .retryLimit(3)
                .retry(DeadlockLoserDataAccessException.class)
                .listener(skipListener())
                .build();
    }

    @Bean
    public Job csvToDatabaseJob(JobCompletionNotificationListener listener) {
        return jobBuilderFactory.get("csvToDatabaseJob")
                .incrementer(new RunIdIncrementer())
                .listener(listener)
                .flow(csvToDatabaseStep())
                .end()
                .build();
    }

    @Bean
    public SkipListener<Person, Person> skipListener() {
        return new CustomSkipListener();
    }
}
```

### Person Entity
```java
@Entity
@Table(name = "people")
public class Person {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String firstName;
    private String lastName;
    private String email;
    private int age;
    private boolean processed;
    
    // Constructors, getters, setters, toString
    public Person() {}
    
    public Person(String firstName, String lastName, String email, int age) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.age = age;
        this.processed = false;
    }
    
    // Getters and setters
}
```

### Running with Command Line
```java
@SpringBootApplication
@EnableBatchProcessing
public class BatchProcessingApplication implements CommandLineRunner {

    @Autowired
    private JobLauncher jobLauncher;

    @Autowired
    private Job csvToDatabaseJob;

    public static void main(String[] args) {
        SpringApplication.run(BatchProcessingApplication.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        JobParameters params = new JobParametersBuilder()
                .addString("JobID", String.valueOf(System.currentTimeMillis()))
                .toJobParameters();
        
        jobLauncher.run(csvToDatabaseJob, params);
    }
}
```

### Application Properties
```properties
# Batch properties
spring.batch.job.enabled=false
spring.batch.initialize-schema=always
spring.batch.job.names=csvToDatabaseJob

# Database properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=password

# JPA properties
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.h2.console.enabled=true

# Input file
input.file=classpath:data/input.csv

# Batch metadata table prefix
spring.batch.jdbc.table-prefix=BATCH_
```

This comprehensive guide covers Spring Batch from basic concepts to advanced features. Spring Batch provides a robust framework for building enterprise-grade batch processing applications with features for error handling, scalability, and monitoring.

[[0 - Spring Framework]]