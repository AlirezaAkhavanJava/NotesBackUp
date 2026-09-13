```java
package com.arcade;  
  
import java.util.Random;  
import java.util.concurrent.atomic.AtomicInteger;  
  
public class BankAccount {  
    private static final AtomicInteger balance = new AtomicInteger(1_000);  
    private static final Random random = new Random();  
  
    // To deposit  
    private static void deposit(int amount) {  
        balance.addAndGet(amount);  
        System.out.println("Deposited " + String.format("%,d", amount) +  
                " to balance " + String.format("%,d", balance.get()));  
  
    }  
    // to withdraw  
    private static void withdraw(int amount) {  
        while (true) {  
            int current = balance.get();  
            if (current < amount) {  
                System.out.println("Not enough money");  
                return;  
            }            // Attempt CAS  
            if (balance.compareAndSet(current, current - amount)) {  
                System.out.println("Withdrawn " + String.format("%,d", amount) +  
                        " Balance : " + String.format("%,d", balance.get()));  
                return;  
            }            // else retry  
        }  
    }  
  
    // to randomly do one of them  
    private static void randomOperation() {  
        for (int i = 0; i < 50; i++) {  
            if (i % 2 == 0) {  
                withdraw(random.nextInt(1000));  
            } else deposit(random.nextInt(100_000) + 1);  
        }    }  
    public static void operate() {  
        Thread t1 = new Thread(BankAccount::randomOperation);  
        Thread t2 = new Thread(BankAccount::randomOperation);  
  
        t1.start();  
        t2.start();  
    }  
}
```



##### Tags : [[My mistakes in action]]