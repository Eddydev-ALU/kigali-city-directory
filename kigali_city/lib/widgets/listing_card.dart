import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../theme/app_theme.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Hospital':
        return Icons.local_hospital_rounded;
      case 'Police Station':
        return Icons.local_police_rounded;
      case 'Library':
        return Icons.local_library_rounded;
      case 'Restaurant':
        return Icons.restaurant_rounded;
      case 'Café':
        return Icons.coffee_rounded;
      case 'Park':
        return Icons.park_rounded;
      case 'Tourist Attraction':
        return Icons.attractions_rounded;
      case 'School':
        return Icons.school_rounded;
      case 'Bank':
        return Icons.account_balance_rounded;
      case 'Hotel':
        return Icons.hotel_rounded;
      case 'Supermarket':
        return Icons.shopping_cart_rounded;
      case 'Embassy':
        return Icons.flag_rounded;
      case 'Government Office':
        return Icons.business_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Hospital':
        return Colors.red.shade400;
      case 'Police Station':
        return Colors.indigo.shade400;
      case 'Library':
        return Colors.brown.shade400;
      case 'Restaurant':
        return Colors.orange.shade600;
      case 'Café':
        return Colors.brown.shade300;
      case 'Park':
        return Colors.green.shade500;
      case 'Tourist Attraction':
        return Colors.purple.shade400;
      case 'School':
        return Colors.teal.shade400;
      case 'Bank':
        return Colors.blueGrey.shade500;
      case 'Hotel':
        return Colors.amber.shade700;
      case 'Supermarket':
        return Colors.green.shade700;
      case 'Embassy':
        return Colors.red.shade700;
      case 'Government Office':
        return AppColors.primaryBlue;
      default:
        return AppColors.lightBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(listing.category);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(listing.category),
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            listing.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showActions) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      tooltip: 'Edit',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      tooltip: 'Delete',
                      onPressed: onDelete,
                    ),
                  ] else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMedium,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textMedium,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      listing.address,
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (listing.contactNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppColors.textMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      listing.contactNumber,
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
