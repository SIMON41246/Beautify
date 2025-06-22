import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:e_commerce_app/models/product.dart';
import 'package:e_commerce_app/controllers/cart_controller.dart';
import 'package:e_commerce_app/services/api_service.dart';
import 'package:e_commerce_app/screens/cart_screen.dart';
import 'product_details.dart';

/// ProductsScreen displays a masonry grid of products with animations and professional styling.
///
/// Features:
/// - Masonry grid layout with dynamic card heights
/// - Staggered animations for smooth loading
/// - Professional product cards with complete information
/// - Cart integration with GetX state management
/// - Loading states with shimmer effects
/// - Error handling with retry functionality
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  // MARK: - Dependencies
  final ApiService _apiService = ApiService();

  // MARK: - State Variables
  late Future<List<Product>> _productsFuture;
  late AnimationController _cartAnimationController;
  late Animation<double> _cartScaleAnimation;

  // MARK: - Constants
  static const double _cardBorderRadius = 20.0;
  static const double _badgeBorderRadius = 12.0;
  static const double _spacing = 16.0;
  static const double _imageHeight = 200.0;
  static const int _crossAxisCount = 2;
  static const int _maxTitleLines = 2;
  static const int _maxTagsToShow = 3;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    super.dispose();
  }

  /// Initialize data fetching and animations
  void _initializeData() {
    _productsFuture = _apiService.fetchProducts();
  }

  /// Setup cart animation controller and animations
  void _setupAnimations() {
    _cartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cartScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _cartAnimationController, curve: Curves.elasticOut),
    );
  }

  /// Navigate to cart screen with smooth transition
  void _navigateToCart() {
    Get.to(
      () => const CartScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Navigate to product details screen
  void _navigateToProductDetails(Product product) {
    Get.to(
      () => ProductDetailsScreen(product: product),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Retry loading products on error
  void _retryLoading() {
    setState(() {
      _productsFuture = _apiService.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Build the app bar with gradient title and cart icon
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _buildGradientTitle(),
      centerTitle: true,
      elevation: 0,
      actions: [_buildCartIcon()],
    );
  }

  /// Build gradient title text
  Widget _buildGradientTitle() {
    return Text(
      'Beautify Store',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        background: Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
          ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
      ),
    );
  }

  /// Build cart icon with badge and animation
  Widget _buildCartIcon() {
    return Stack(
      children: [
        _buildAnimatedCartButton(),
        _buildCartBadge(),
      ],
    );
  }

  /// Build animated cart button
  Widget _buildAnimatedCartButton() {
    return AnimatedBuilder(
      animation: _cartScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cartScaleAnimation.value,
          child: IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, size: 28),
            onPressed: _navigateToCart,
          ),
        );
      },
    );
  }

  /// Build cart badge showing item count
  Widget _buildCartBadge() {
    return GetBuilder<CartController>(
      builder: (controller) => controller.totalItems > 0
          ? Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D),
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '${controller.totalItems}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Build the main body content
  Widget _buildBody() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        return _buildProductsGrid(snapshot.data!);
      },
    );
  }

  /// Build the products grid with masonry layout
  Widget _buildProductsGrid(List<Product> products) {
    return AnimationLimiter(
      child: MasonryGridView.count(
        padding: const EdgeInsets.all(_spacing),
        crossAxisCount: _crossAxisCount,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildAnimatedProductCard(product, index);
        },
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
      ),
    );
  }

  /// Build animated product card with staggered animation
  Widget _buildAnimatedProductCard(Product product, int index) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: const Duration(milliseconds: 600),
      columnCount: _crossAxisCount,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: _buildProductCard(product),
        ),
      ),
    );
  }

  /// Build individual product card
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetails(product),
      child: Container(
        decoration: _buildCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImageSection(product),
            _buildProductInfoSection(product),
          ],
        ),
      ),
    );
  }

  /// Build card decoration with shadow and border radius
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Build product image section with overlays
  Widget _buildProductImageSection(Product product) {
    return Stack(
      children: [
        _buildProductImage(product),
        if (product.discountPercentage > 0) _buildDiscountBadge(product),
        _buildStockStatusBadge(product),
      ],
    );
  }

  /// Build product image with caching and error handling
  Widget _buildProductImage(Product product) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(_cardBorderRadius),
      ),
      child: CachedNetworkImage(
        imageUrl: product.thumbnail,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildImageError(),
      ),
    );
  }

  /// Build image placeholder with loading indicator
  Widget _buildImagePlaceholder() {
    return Container(
      height: _imageHeight,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
        ),
      ),
    );
  }

  /// Build image error widget
  Widget _buildImageError() {
    return Container(
      height: _imageHeight,
      color: Colors.grey[200],
      child: const Icon(Icons.error, color: Colors.grey),
    );
  }

  /// Build discount badge with gradient
  Widget _buildDiscountBadge(Product product) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(_badgeBorderRadius),
        ),
        child: Text(
          '-${product.discountPercentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Build stock status badge
  Widget _buildStockStatusBadge(Product product) {
    return Positioned(
      bottom: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: product.stock > 0
              ? Colors.green.withOpacity(0.9)
              : Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          product.stock > 0 ? 'In Stock' : 'Out of Stock',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Build product information section
  Widget _buildProductInfoSection(Product product) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrandName(product),
          const SizedBox(height: 6),
          _buildProductTitle(product),
          const SizedBox(height: 12),
          _buildRatingSection(product),
          const SizedBox(height: 12),
          _buildPriceSection(product),
          const SizedBox(height: 8),
          if (product.tags.isNotEmpty) _buildProductTags(product),
        ],
      ),
    );
  }

  /// Build brand name text
  Widget _buildBrandName(Product product) {
    return Text(
      product.brand,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Build product title
  Widget _buildProductTitle(Product product) {
    return Text(
      product.title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.3,
      ),
      maxLines: _maxTitleLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build rating section with star and review count
  Widget _buildRatingSection(Product product) {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16,
          color: Colors.amber[600],
        ),
        const SizedBox(width: 4),
        Text(
          product.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${product.reviews.length} reviews)',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Build price section with discount and add to cart icon
  Widget _buildPriceSection(Product product) {
    return Row(
      children: [
        if (product.discountPercentage > 0) ...[
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '\$${(product.price * (1 - product.discountPercentage / 100)).toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFFFF6B9D),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  /// Build add to cart icon
  Widget _buildAddToCartIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B9D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.add_shopping_cart,
        color: Color(0xFFFF6B9D),
        size: 18,
      ),
    );
  }

  /// Build product tags section
  Widget _buildProductTags(Product product) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: product.tags
          .take(_maxTagsToShow)
          .map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFFFF6B9D),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Build shimmer loading effect
  Widget _buildShimmerLoading() {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(_spacing),
      crossAxisCount: _crossAxisCount,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: _imageHeight +
                (index * 20), // Varying heights for masonry effect
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
          ),
        );
      },
      mainAxisSpacing: _spacing,
      crossAxisSpacing: _spacing,
    );
  }

  /// Build error state with retry functionality
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _retryLoading,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Build empty state when no products are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new arrivals',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
