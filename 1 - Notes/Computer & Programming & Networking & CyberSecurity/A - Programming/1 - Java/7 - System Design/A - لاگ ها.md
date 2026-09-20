# مفاهیم پایه‌ای و جامع در مورد لاگینگ (Logging)

## لاگینگ چیست؟

لاگینگ (Logging) فرآیند ثبت و ذخیره اطلاعات مربوط به فعالیت‌ها، رویدادها یا خطاهای یک برنامه یا سیستم در حین اجرا است. این اطلاعات که به آن‌ها **لاگ** (Log) گفته می‌شود، به توسعه‌دهندگان، مدیران سیستم و تیم‌های پشتیبانی کمک می‌کند تا رفتار برنامه را تحلیل کنند، خطاها را شناسایی کنند، عملکرد را بررسی کنند یا مشکلات را دیباگ کنند.

لاگ‌ها معمولاً شامل اطلاعاتی مثل:

- **زمان وقوع رویداد** (Timestamp)
- **سطح اهمیت رویداد** (مثل INFO، DEBUG، ERROR)
- **پیام توصیفی** (مثل توضیح خطا یا شرح یک عملیات)
- **منبع رویداد** (مثلاً کدام کلاس یا ماژول)

### چرا لاگینگ مهم است؟

- **دیباگ کردن**: پیدا کردن خطاها و مشکلات در کد.
- **نظارت (Monitoring)**: بررسی سلامت و عملکرد سیستم.
- **امنیت**: ردیابی دسترسی‌های غیرمجاز یا فعالیت‌های مشکوک.
- **تحلیل داده**: بررسی رفتار کاربران یا سیستم برای بهبود عملکرد.
- **مستندسازی**: ثبت تاریخچه عملکرد سیستم برای مراجعات بعدی.

---

## مفاهیم پایه‌ای لاگینگ

### ۱. اجزای اصلی لاگ

هر پیام لاگ معمولاً شامل این بخش‌هاست:

- **Timestamp**: زمان دقیق وقوع رویداد (مثل `2025-10-18 12:12:34`).
- **Log Level**: سطح اهمیت رویداد (مثل DEBUG، INFO، WARN، ERROR، FATAL).
- **Message**: توضیحی درباره رویداد (مثل "اتصال به دیتابیس برقرار شد").
- **Context**: اطلاعات اضافی مثل نام کلاس، شماره خط کد، یا شناسه کاربر.

### ۲. سطوح لاگ (Log Levels)

سطوح لاگ برای مشخص کردن اهمیت یا نوع پیام استفاده می‌شوند. رایج‌ترین سطوح لاگ در فریم‌ورک‌های لاگینگ (مثل Log4j، SLF4J، Logback) عبارتند از:

- **TRACE**: جزئی‌ترین سطح برای ردیابی دقیق (مثل مراحل داخلی یک متد).
- **DEBUG**: برای دیباگ کردن در حین توسعه (مثل مقادیر متغیرها).
- **INFO**: اطلاعات عمومی درباره عملکرد سیستم (مثل "سرور شروع به کار کرد").
- **WARN**: هشدار درباره مشکلات احتمالی که هنوز خطا نیستند (مثل "فایل تنظیمات یافت نشد، از پیش‌فرض استفاده می‌شود").
- **ERROR**: خطاهای واقعی که روی عملکرد تأثیر می‌گذارند (مثل "اتصال به دیتابیس ناموفق بود").
- **FATAL**: خطاهای بحرانی که باعث توقف برنامه می‌شوند (کمتر استفاده می‌شود).

### ۳. مقصد لاگ‌ها (Log Destination)

لاگ‌ها می‌توانند در مکان‌های مختلفی ذخیره یا نمایش داده شوند:

- **کنسول (Console)**: نمایش در خروجی کنسول (مثل ترمینال یا IDE).
- **فایل (File)**: ذخیره در فایل‌های متنی (مثل `app.log`).
- **دیتابیس**: ذخیره لاگ‌ها در جداول دیتابیس برای تحلیل بعدی.
- **سیستم‌های خارجی**: ارسال به ابزارهای مانیتورینگ مثل ELK Stack، Splunk یا Grafana.
- **شبکه**: ارسال لاگ‌ها به سرورهای ریموت از طریق پروتکل‌هایی مثل Syslog.

### ۴. فریم‌ورک‌های لاگینگ

برای مدیریت لاگ‌ها در برنامه‌ها، معمولاً از فریم‌ورک‌های لاگینگ استفاده می‌شود. در جاوا، فریم‌ورک‌های محبوب عبارتند از:

- **SLF4J**: یک API انتزاعی که به‌عنوان واسطه بین برنامه و فریم‌ورک‌های لاگینگ عمل می‌کند.
- **Log4j**: یک فریم‌ورک قدرتمند برای لاگینگ با قابلیت تنظیم بالا.
- **Logback**: جانشین Log4j با عملکرد بهتر و تنظیمات ساده‌تر.
- **Java Util Logging (JUL)**: کتابخانه داخلی جاوا برای لاگینگ (کمتر استفاده می‌شود).

---

## روش درست لاگ‌نویسی

برای نوشتن لاگ‌های مؤثر و حرفه‌ای، باید به اصول زیر توجه کنید:

### ۱. انتخاب سطح مناسب لاگ

- از **DEBUG** برای اطلاعات توسعه و دیباگ استفاده کنید (این لاگ‌ها معمولاً در محیط Production خاموش می‌شوند).
- از **INFO** برای ثبت رویدادهای کلیدی مثل شروع/پایان پروسه‌ها استفاده کنید.
- از **WARN** و **ERROR** برای مشکلات و خطاها استفاده کنید و اطلاعات کافی برای تشخیص مشکل ارائه دهید.
- از **TRACE** فقط برای ردیابی‌های بسیار جزئی استفاده کنید (چون حجم لاگ را زیاد می‌کند).

### ۲. ارائه اطلاعات کافی

- لاگ‌ها باید شامل اطلاعات کافی برای تحلیل باشند، اما نباید بیش از حد شلوغ شوند.
    - مثال خوب: `ERROR: Failed to connect to database 'users_db' at host 'localhost:5432', reason: Connection timeout`
    - مثال بد: `ERROR: Database connection failed`
- اطلاعاتی مثل **شناسه کاربر**، **شناسه درخواست (Request ID)** یا **Stack Trace** برای خطاها مفید هستند.

### ۳. استفاده از Context و Structured Logging

- به‌جای لاگ‌های متنی ساده، از لاگ‌های ساختاریافته (Structured Logging) استفاده کنید. مثلاً به‌جای رشته‌های متنی، از فرمت JSON استفاده کنید تا تحلیل لاگ‌ها با ابزارهای مانیتورینگ راحت‌تر باشد.
    - مثال: `{ "timestamp": "2025-10-18T12:12:34", "level": "ERROR", "message": "Database connection failed", "details": { "host": "localhost", "port": 5432 } }`
- از **MDC (Mapped Diagnostic Context)** در فریم‌ورک‌هایی مثل SLF4J برای افزودن اطلاعات زمینه‌ای (مثل User ID یا Session ID) به لاگ‌ها استفاده کنید.

### ۴. اجتناب از لاگ‌نویسی بیش از حد

- لاگ‌های بیش از حد (مثلاً لاگ کردن هر خط کد) می‌توانند:
    - فضای دیسک را پر کنند.
    - عملکرد برنامه را کاهش دهند.
    - تحلیل لاگ‌ها را سخت کنند.
- فقط رویدادهای مهم را لاگ کنید و از لاگ‌های تکراری یا غیرضروری پرهیز کنید.

### ۵. تنظیمات مناسب برای محیط‌های مختلف

- در **محیط توسعه (Development)**: سطح لاگ را روی DEBUG یا TRACE تنظیم کنید تا جزئیات بیشتری ببینید.
- در **محیط تولید (Production)**: سطح لاگ را روی INFO یا WARN تنظیم کنید تا حجم لاگ‌ها کم شود.
- از **Rolling File Appender** استفاده کنید تا فایل‌های لاگ به‌صورت خودکار آرشیو شوند و دیسک پر نشود.

### ۶. استفاده از پارامترها در لاگ

- به‌جای الحاق رشته‌ها (String Concatenation)، از قالب‌بندی پارامتری استفاده کنید تا عملکرد بهتری داشته باشید:
    - بد: `logger.info("User " + username + " logged in at " + timestamp);`
    - خوب: `logger.info("User {} logged in at {}", username, timestamp);`

### ۷. امنیت در لاگ‌نویسی

- اطلاعات حساس مثل رمزعبور، شماره کارت بانکی یا توکن‌ها را لاگ نکنید.
- اگر نیاز به لاگ کردن اطلاعات کاربر دارید، آن‌ها را Mask کنید (مثلاً فقط ۴ رقم آخر شماره کارت).

---

## پیاده‌سازی لاگینگ در جاوا (مثال با SLF4J و Logback)

برای شروع، می‌توانید از SLF4J به همراه Logback استفاده کنید. در زیر یک مثال ساده آورده شده است:

### تنظیمات پروژه

1. اضافه کردن وابستگی‌ها به `pom.xml` (برای Maven):

```xml
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-api</artifactId>
    <version>2.0.9</version>
</dependency>
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-classic</artifactId>
    <version>1.4.11</version>
</dependency>
```

2. فایل تنظیمات `logback.xml`:

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/app.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/app.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    <root level="INFO">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="FILE" />
    </root>
</configuration>
```

3. نمونه کد جاوا:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MyApp {
    private static final Logger logger = LoggerFactory.getLogger(MyApp.class);

    public static void main(String[] args) {
        logger.trace("This is a TRACE message");
        logger.debug("Debugging application");
        logger.info("Application started");
        try {
            int result = 10 / 0;
        } catch (Exception e) {
            logger.error("An error occurred: {}", e.getMessage(), e);
        }
        logger.warn("This is a warning");
    }
}
```

### خروجی لاگ:

```
2025-10-18 12:12:34 [main] INFO  com.example.MyApp - Application started
2025-10-18 12:12:34 [main] ERROR com.example.MyApp - An error occurred: / by zero
java.lang.ArithmeticException: / by zero
    at com.example.MyApp.main(MyApp.java:10)
```

---

## مفاهیم پیشرفته‌تر در لاگینگ

### ۱. Structured Logging

- به‌جای لاگ‌های متنی ساده، از فرمت‌های ساختاریافته مثل JSON استفاده کنید. این کار تحلیل لاگ‌ها با ابزارهایی مثل ELK یا Splunk را راحت‌تر می‌کند.
- مثال با Logback:

```xml
<encoder class="ch.qos.logback.classic.encoder.JsonEncoder" />
```

### ۲. MDC (Mapped Diagnostic Context)

- MDC برای افزودن اطلاعات زمینه‌ای به لاگ‌ها استفاده می‌شود. مثلاً می‌توانید User ID یا Request ID را به همه لاگ‌های یک درخواست اضافه کنید.
- مثال:

```java
import org.slf4j.MDC;

public void processRequest(String userId) {
    MDC.put("userId", userId);
    logger.info("Processing request");
    MDC.remove("userId");
}
```

### ۳. ارتباط با سیستم‌های خارجی

- **Syslog**: پروتکلی برای ارسال لاگ‌ها به سرورهای ریموت.
- **ELK Stack**: شامل Elasticsearch (ذخیره و جستجو)، Logstash (پردازش لاگ‌ها) و Kibana (نمایش داشبورد).
- **Splunk**: ابزار قدرتمند برای تحلیل و تجسم لاگ‌ها.
- **Grafana Loki**: سیستم لاگینگ سبک برای جمع‌آوری و تحلیل لاگ‌ها.

### ۴. Async Logging

- برای بهبود عملکرد، از لاگینگ ناهمگام (Asynchronous) استفاده کنید تا نوشتن لاگ‌ها روی اجرای برنامه تأثیر نگذارد.
- در Logback، می‌توانید از `AsyncAppender` استفاده کنید:

```xml
<appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE" />
</appender>
```

### ۵. مانیتورینگ و هشدار

- لاگ‌ها را به سیستم‌های مانیتورینگ متصل کنید تا در صورت وقوع خطاهای خاص (مثل ERROR یا FATAL)، هشدار (Alert) دریافت کنید.
- ابزارهایی مثل Prometheus یا Grafana می‌توانند لاگ‌ها را با متریک‌های دیگر ترکیب کنند.

---

## ارتباطات لاگینگ با سیستم‌های دیگر

- **دیتابیس**: لاگ‌ها را می‌توان در دیتابیس ذخیره کرد تا بعداً با SQL تحلیل شوند. مثلاً جدولی با ستون‌های `timestamp`, `level`, `message`, `context`.
- **مانیتورینگ سرور**: ابزارهایی مثل ELK یا Splunk لاگ‌ها را از سرورها جمع‌آوری کرده و داشبوردهای تحلیلی ارائه می‌دهند.
- **سیستم‌های CI/CD**: لاگ‌ها در فرآیندهای CI/CD (مثل Jenkins یا GitLab) برای ردیابی خطاهای بیلد یا استقرار استفاده می‌شوند.
- **امنیت**: لاگ‌ها به سیستم‌های SIEM (Security Information and Event Management) مثل Splunk یا QRadar متصل می‌شوند تا تهدیدات امنیتی شناسایی شوند.

---

## نکات نهایی

- **بهترین ابزار را انتخاب کنید**: برای پروژه‌های جاوا، ترکیب SLF4J و Logback توصیه می‌شود چون انعطاف‌پذیر و سریع است.
- **تنظیمات مناسب**: همیشه فایل تنظیمات (مثل `logback.xml`) را به‌درستی پیکربندی کنید تا لاگ‌ها به مقصد درست بروند.
- **تحلیل لاگ‌ها**: از ابزارهای تحلیل لاگ مثل ELK یا Splunk برای پروژه‌های بزرگ استفاده کنید.
- **عملکرد**: لاگینگ ناهمگام و محدود کردن سطح لاگ در Production به بهبود عملکرد کمک می‌کند.
- **امنیت**: مراقب اطلاعات حساس در لاگ‌ها باشید و از Masking استفاده کنید.


[[0 - Back-End]]