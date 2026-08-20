import 'package:flutter/material.dart';

/// A reusable currency selector dropdown widget.
/// Displays the current currency with a dropdown indicator when multiple currencies are available.
/// Matches GW3 UI design patterns.
class CurrencySelectorWidget extends StatefulWidget {
  /// The currently selected currency code (e.g., 'SGD', 'MYR')
  final String selectedCurrency;

  /// List of all supported currency codes for this payment method
  final List<String> supportedCurrencies;

  /// Callback when a new currency is selected
  final ValueChanged<String> onCurrencyChanged;

  /// Whether dark mode is enabled
  final bool isDarkMode;

  const CurrencySelectorWidget({
    Key? key,
    required this.selectedCurrency,
    required this.supportedCurrencies,
    required this.onCurrencyChanged,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<CurrencySelectorWidget> createState() => _CurrencySelectorWidgetState();
}

class _CurrencySelectorWidgetState extends State<CurrencySelectorWidget> {
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool get _hasMultipleCurrencies => widget.supportedCurrencies.length > 1;

  @override
  void dispose() {
    // Only remove overlay entry without calling setState
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _toggleDropdown() {
    if (!_hasMultipleCurrencies) return;

    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  void _selectCurrency(String currency) {
    widget.onCurrencyChanged(currency);
    _removeOverlay();
  }

  // Minimum width for dropdown to display currency codes properly
  static const double _minDropdownWidth = 100.0;

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    // Use the larger of button width or minimum width
    final dropdownWidth =
        size.width < _minDropdownWidth ? _minDropdownWidth : size.width;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown menu
          Positioned(
            width: dropdownWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                color:
                    widget.isDarkMode ? const Color(0xFF374151) : Colors.white,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: _minDropdownWidth),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? const Color(0xFF4A5568)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.supportedCurrencies
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final currency = entry.value;
                        final isSelected = currency == widget.selectedCurrency;
                        final isLast =
                            index == widget.supportedCurrencies.length - 1;

                        return InkWell(
                          onTap: () => _selectCurrency(currency),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (widget.isDarkMode
                                      ? const Color(0xFF4A5568)
                                      : const Color(0xFFF3F4F6))
                                  : Colors.transparent,
                              border: !isLast
                                  ? Border(
                                      bottom: BorderSide(
                                        color: widget.isDarkMode
                                            ? const Color(0xFF4A5568)
                                            : const Color(0xFFF3F4F6),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currency,
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: widget.isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7E01D7)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Color(0xFF7E01D7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF374151) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isDropdownOpen
                  ? const Color(0xFF7E01D7)
                  : (widget.isDarkMode
                      ? const Color(0xFF4A5568)
                      : const Color(0xFFE5E7EB)),
              width: _isDropdownOpen ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.selectedCurrency,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode
                      ? Colors.white
                      : const Color(0xFF374151),
                  letterSpacing: 0.5,
                ),
              ),
              if (_hasMultipleCurrencies) ...[
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _isDropdownOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: widget.isDarkMode
                        ? const Color(0xB3FFFFFF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
