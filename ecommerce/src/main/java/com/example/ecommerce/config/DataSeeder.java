package com.example.ecommerce.config;

import com.example.ecommerce.domain.*;
import com.example.ecommerce.repository.CategoryRepository;
import com.example.ecommerce.repository.CustomerRepository;
import com.example.ecommerce.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;

@Configuration
@RequiredArgsConstructor
public class DataSeeder {

    @Bean
    CommandLineRunner seed(CategoryRepository categoryRepository,
                           ProductRepository productRepository,
                           CustomerRepository customerRepository) {
        return args -> {
            if (categoryRepository.count() > 0) {
                return;
            }
            Category electronics = categoryRepository.save(Category.builder()
                    .name("Electronics")
                    .description("Phones, laptops, and gadgets")
                    .build());
            Category books = categoryRepository.save(Category.builder()
                    .name("Books")
                    .description("Fiction and non-fiction")
                    .build());

            productRepository.save(Product.builder()
                    .name("Smartphone X")
                    .description("Latest model with great camera")
                    .price(new BigDecimal("799.99"))
                    .category(electronics)
                    .stockQuantity(50)
                    .build());

            productRepository.save(Product.builder()
                    .name("Ultrabook Pro")
                    .description("Lightweight laptop for professionals")
                    .price(new BigDecimal("1299.00"))
                    .category(electronics)
                    .stockQuantity(20)
                    .build());

            productRepository.save(Product.builder()
                    .name("The Pragmatic Programmer")
                    .description("Classic software engineering book")
                    .price(new BigDecimal("39.99"))
                    .category(books)
                    .stockQuantity(100)
                    .build());

            customerRepository.save(Customer.builder()
                    .firstName("Alice")
                    .lastName("Doe")
                    .email("alice@example.com")
                    .address("123 Main St")
                    .build());

            customerRepository.save(Customer.builder()
                    .firstName("Bob")
                    .lastName("Smith")
                    .email("bob@example.com")
                    .address("456 Elm Ave")
                    .build());
        };
    }
}