package com.example.haproxy.controller;

import com.example.haproxy.service.LoadTestService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class ApiController {

    private final LoadTestService loadTestService;
    private final String instanceId = UUID.randomUUID().toString().substring(0, 8);

    @Value("${server.port:8080}")
    private String serverPort;

    @GetMapping("/instance")
    public ResponseEntity<Map<String, Object>> getInstanceInfo() throws UnknownHostException {
        Map<String, Object> response = new HashMap<>();
        response.put("instanceId", instanceId);
        response.put("hostname", InetAddress.getLocalHost().getHostName());
        response.put("ipAddress", InetAddress.getLocalHost().getHostAddress());
        response.put("port", serverPort);
        response.put("timestamp", LocalDateTime.now());
        
        log.info("Instance info requested from instance: {}", instanceId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/test")
    public ResponseEntity<Map<String, Object>> testEndpoint() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Hello from instance: " + instanceId);
        response.put("timestamp", LocalDateTime.now());
        response.put("requestCount", loadTestService.incrementAndGetRequestCount());
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/heavy")
    public ResponseEntity<Map<String, Object>> heavyOperation(@RequestParam(defaultValue = "1000") int iterations) {
        long startTime = System.currentTimeMillis();
        
        // 負荷をシミュレート
        double result = loadTestService.performHeavyCalculation(iterations);
        
        long endTime = System.currentTimeMillis();
        
        Map<String, Object> response = new HashMap<>();
        response.put("instanceId", instanceId);
        response.put("result", result);
        response.put("processingTime", (endTime - startTime) + "ms");
        response.put("iterations", iterations);
        
        log.info("Heavy operation completed in {}ms on instance: {}", (endTime - startTime), instanceId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/metrics/custom")
    public ResponseEntity<Map<String, Object>> getCustomMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("instanceId", instanceId);
        metrics.put("totalRequests", loadTestService.getTotalRequests());
        metrics.put("averageProcessingTime", loadTestService.getAverageProcessingTime());
        metrics.put("uptime", loadTestService.getUptime());
        
        return ResponseEntity.ok(metrics);
    }
} 