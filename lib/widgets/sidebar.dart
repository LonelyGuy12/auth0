import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('▲', style: TextStyle(fontSize: 16, color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Agent',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Token Vault',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 1, color: const Color(0xFF1A1A1A)),

          // Navigation items
          _buildNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            index: 1,
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFF1A1A1A)),

          const Spacer(),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1A1A1A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Built for Authorized to Act\nPowered by Auth0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onItemSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0A0A0A) : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF666666),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF666666),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
