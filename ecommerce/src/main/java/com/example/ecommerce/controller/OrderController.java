package com.example.ecommerce.controller;

import com.example.ecommerce.domain.Order;
import com.example.ecommerce.service.OrderService;
import jakarta.validation.constraints.Min;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {
    private final OrderService orderService;

    @GetMapping
    public List<Order> list() {
        return orderService.findAll();
    }

    @GetMapping("/{id}")
    public Order get(@PathVariable Long id) {
        return orderService.findById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Order place(@RequestBody PlaceOrderRequest request) {
        return orderService.placeOrder(request.getCustomerId(), request.getItems().stream()
                .map(i -> new OrderService.OrderItemRequest(i.getProductId(), i.getQuantity()))
                .toList());
    }

    @Data
    public static class PlaceOrderRequest {
        private Long customerId;
        private List<Item> items;

        @Data
        public static class Item {
            private Long productId;
            @Min(1)
            private int quantity;
        }
    }
}