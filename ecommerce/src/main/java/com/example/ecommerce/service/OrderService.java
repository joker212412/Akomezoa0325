package com.example.ecommerce.service;

import com.example.ecommerce.domain.*;
import com.example.ecommerce.repository.CustomerRepository;
import com.example.ecommerce.repository.OrderRepository;
import com.example.ecommerce.repository.ProductRepository;
import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class OrderService {
    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final ProductRepository productRepository;

    public Order placeOrder(Long customerId, List<OrderItemRequest> items) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new EntityNotFoundException("Customer not found"));

        Order order = Order.builder()
                .customer(customer)
                .createdAt(OffsetDateTime.now())
                .build();

        BigDecimal total = BigDecimal.ZERO;
        for (OrderItemRequest req : items) {
            Product product = productRepository.findById(req.productId())
                    .orElseThrow(() -> new EntityNotFoundException("Product not found: " + req.productId()));
            if (product.getStockQuantity() < req.quantity()) {
                throw new IllegalStateException("Insufficient stock for product: " + product.getName());
            }
            product.setStockQuantity(product.getStockQuantity() - req.quantity());
            BigDecimal unitPrice = product.getPrice();
            BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(req.quantity()));
            OrderItem item = OrderItem.builder()
                    .order(order)
                    .product(product)
                    .quantity(req.quantity())
                    .unitPrice(unitPrice)
                    .lineTotal(lineTotal)
                    .build();
            order.getItems().add(item);
            total = total.add(lineTotal);
        }
        order.setTotalAmount(total);
        return orderRepository.save(order);
    }

    public Order findById(Long id) {
        return orderRepository.findById(id).orElseThrow(() -> new EntityNotFoundException("Order not found"));
    }

    public List<Order> findAll() {
        return orderRepository.findAll();
    }

    public record OrderItemRequest(Long productId, int quantity) {}
}