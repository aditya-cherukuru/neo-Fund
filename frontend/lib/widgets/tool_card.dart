import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget destinationScreen;
  final Color? color;
  final String? description;

  const ToolCard({
    super.key,
    required this.title,
    required this.icon,
    required this.destinationScreen,
    this.color,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final toolColor = color ?? Theme.of(context).primaryColor;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationScreen),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tool Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          toolColor.withOpacity(0.1),
                          toolColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: toolColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: toolColor,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tool Name
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Optional Description
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Arrow indicator
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: toolColor.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 