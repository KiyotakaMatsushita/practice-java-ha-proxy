package com.example.haproxy.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.LongAdder;

@Service
@Slf4j
public class LoadTestService {

    private final AtomicLong requestCount = new AtomicLong(0);
    private final LongAdder totalProcessingTime = new LongAdder();
    private final AtomicLong processedRequests = new AtomicLong(0);
    private Instant startTime;

    @PostConstruct
    public void init() {
        startTime = Instant.now();
        log.info("LoadTestService initialized");
    }

    public long incrementAndGetRequestCount() {
        return requestCount.incrementAndGet();
    }

    public long getTotalRequests() {
        return requestCount.get();
    }

    public double performHeavyCalculation(int iterations) {
        long startTime = System.currentTimeMillis();
        double result = 0;

        // CPU intensive calculation
        for (int i = 0; i < iterations; i++) {
            for (int j = 0; j < 1000; j++) {
                result += Math.sqrt(i) * Math.sin(j);
            }
        }

        long processingTime = System.currentTimeMillis() - startTime;
        totalProcessingTime.add(processingTime);
        processedRequests.incrementAndGet();

        return result;
    }

    public double getAverageProcessingTime() {
        long processed = processedRequests.get();
        if (processed == 0) {
            return 0;
        }
        return (double) totalProcessingTime.sum() / processed;
    }

    public String getUptime() {
        Duration uptime = Duration.between(startTime, Instant.now());
        long hours = uptime.toHours();
        long minutes = uptime.toMinutesPart();
        long seconds = uptime.toSecondsPart();
        
        return String.format("%d hours, %d minutes, %d seconds", hours, minutes, seconds);
    }
} 