import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:e_commerce_app/models/product.dart';
import 'package:e_commerce_app/controllers/cart_controller.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _addToCartController;
  late Animation<double> _addToCartScale;
  late Animation<double> _addToCartOpacity;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _addToCartController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _addToCartScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _addToCartController, curve: Curves.elasticOut),
    );
    _addToCartOpacity = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _addToCartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _addToCartController.dispose();
    super.dispose();
  }

  void _addToCart() {
    final cartController = Get.find<CartController>();
    
    // Add multiple items based on quantity
    for (int i = 0; i < _quantity; i++) {
      cartController.addItem(widget.product);
    }
    
    _addToCartController.forward().then((_) {
      _addToCartController.reverse();
    });
    
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final discountedPrice = widget.product.price * (1 - widget.product.discountPercentage / 100);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceSection(discountedPrice),
                      const SizedBox(height: 20),
                      _buildProductTitle(),
                      const SizedBox(height: 16),
                      _buildRatingSection(),
                      const SizedBox(height: 24),
                      _buildQuantitySection(),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      if (widget.product.tags.isNotEmpty) ...[
                        _buildTagsSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildAddToCartButton(cartController),
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildConfetti(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        onPressed: () => Get.back(),
      ),
    
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Hero(
              tag: widget.product.id,
              child: CachedNetworkImage(
                imageUrl: widget.product.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.grey),
                ),
              ),
            ),
            if (widget.product.discountPercentage > 0)
              Positioned(
                top: 80,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${widget.product.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(double discountedPrice) {
    return Row(
      children: [
        if (widget.product.discountPercentage > 0) ...[
          Text(
            '\$${widget.product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          '\$${discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Color(0xFFFF6B9D),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.product.stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.product.stock > 0 ? 'In Stock' : 'Out of Stock',
            style: TextStyle(
              color: widget.product.stock > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3);
  }

  Widget _buildProductTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.brand,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.3);
  }

  Widget _buildRatingSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 18),
              const SizedBox(width: 4),
              Text(
                widget.product.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '(${widget.product.reviews.length} reviews)',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.3);
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    color: _quantity > 1 ? Colors.black87 : Colors.grey,
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => setState(() => _quantity++),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'Total: \$${(widget.product.price * (1 - widget.product.discountPercentage / 100) * _quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6B9D),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideX(begin: -0.3);
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.product.description,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideX(begin: -0.3);
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.product.tags
              .map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B9D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF6B9D).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Color(0xFFFF6B9D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms).slideX(begin: -0.3);
  }

  Widget _buildAddToCartButton(CartController cartController) {
    return  AnimatedBuilder(
      animation: _addToCartController,
      builder: (context, child) {
        return Transform.scale(
          scale: _addToCartScale.value,
          child: Opacity(
            opacity: _addToCartOpacity.value,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: cartController.isAddingToCart.value ? null : _addToCart,
                child: cartController.isAddingToCart.value
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ADD TO CART',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 1200.ms, duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildConfetti() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: pi / 2,
        maxBlastForce: 5,
        minBlastForce: 2,
        emissionFrequency: 0.05,
        numberOfParticles: 50,
        gravity: 0.05,
        colors: const [
          Color(0xFFFF6B9D),
          Color(0xFFFF8E53),
          Color(0xFF4ECDC4),
          Color(0xFF45B7D1),
        ],
      ),
    );
  }
}
