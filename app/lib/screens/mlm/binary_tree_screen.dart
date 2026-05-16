import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/mlm_provider.dart';
import '../../models/mlm_model.dart';

class BinaryTreeScreen extends StatefulWidget {
  const BinaryTreeScreen({super.key});

  @override
  State<BinaryTreeScreen> createState() => _BinaryTreeScreenState();
}

class _BinaryTreeScreenState extends State<BinaryTreeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MLMProvider>().fetchTree();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mlm = context.watch<MLMProvider>();

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('Binary Tree'),
        backgroundColor: AppColors.dark,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<MLMProvider>().fetchTree()),
        ],
      ),
      body: mlm.loading
          ? const Center(child: CircularProgressIndicator())
          : mlm.tree == null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.account_tree_rounded, size: 64, color: AppColors.textHint), const SizedBox(height: 16), Text('No tree data available', style: TextStyle(color: AppColors.textSecondary))]))
              : InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(80),
                  minScale: 0.3,
                  maxScale: 2.0,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: _TreeNodeWidget(node: mlm.tree!, depth: 0),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _TreeNodeWidget extends StatelessWidget {
  final MLMTreeNode node;
  final int depth;
  const _TreeNodeWidget({required this.node, required this.depth});

  Color get _rankColor {
    switch (node.userRank) {
      case 'Diamond': return const Color(0xFF00D2FF);
      case 'Platinum': return const Color(0xFF7B2FF7);
      case 'Gold': return const Color(0xFFFFD700);
      case 'Silver': return const Color(0xFFB0B0B0);
      default: return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Node
        GestureDetector(
          onTap: () => _showNodeInfo(context),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: node.userId != null ? AppColors.cardLight : Colors.transparent,
              border: Border.all(
                color: node.userId != null ? _rankColor : AppColors.border,
                width: node.userId != null ? 2.5 : 1.5,
                style: node.userId != null ? BorderStyle.solid : BorderStyle.solid,
              ),
              boxShadow: node.userId != null ? [BoxShadow(color: _rankColor.withOpacity(0.25), blurRadius: 10, spreadRadius: 1)] : null,
            ),
            child: node.userId != null
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        node.userName.isNotEmpty ? node.userName.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(color: _rankColor, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      Text(node.userRank.substring(0, 1), style: TextStyle(color: _rankColor.withOpacity(0.7), fontSize: 9)),
                    ]),
                  )
                : const Icon(Icons.add_circle_outline, color: AppColors.textHint, size: 28),
          ),
        ),
        if (node.userId != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            child: Text(
              node.userName,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Children
        if (depth < 3 && (node.left != null || node.right != null))
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _Connector(left: true),
                  _TreeNodeWidget(node: node.left ?? _emptyNode('left'), depth: depth + 1),
                ]),
                const SizedBox(width: 20),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  _Connector(left: false),
                  _TreeNodeWidget(node: node.right ?? _emptyNode('right'), depth: depth + 1),
                ]),
              ],
            ),
          ),
      ],
    );
  }

  MLMTreeNode _emptyNode(String position) => MLMTreeNode(id: '', position: position, level: 0, leftVolume: 0, rightVolume: 0, leftCount: 0, rightCount: 0);

  void _showNodeInfo(BuildContext context) {
    if (node.userId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(node.userName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(node.userRank, style: TextStyle(color: _rankColor, fontSize: 14)),
          const Divider(color: AppColors.border, height: 24),
          _InfoRow('Position', node.position.toUpperCase()),
          _InfoRow('Level', '${node.level}'),
          _InfoRow('Left Volume', '\$${node.leftVolume.toStringAsFixed(2)}'),
          _InfoRow('Right Volume', '\$${node.rightVolume.toStringAsFixed(2)}'),
          _InfoRow('Left Team', '${node.leftCount} members'),
          _InfoRow('Right Team', '${node.rightCount} members'),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _Connector extends StatelessWidget {
  final bool left;
  const _Connector({required this.left});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(50, 30),
    painter: _ConnectorPainter(isLeft: left),
  );
}

class _ConnectorPainter extends CustomPainter {
  final bool isLeft;
  const _ConnectorPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.border..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(isLeft ? size.width : 0, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
