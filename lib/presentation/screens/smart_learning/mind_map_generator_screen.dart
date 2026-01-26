import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/smart_learning_provider.dart';
import 'dart:math' as math;

class MindMapGeneratorScreen extends StatefulWidget {
  final String? topic;
  final String? subject;

  const MindMapGeneratorScreen({super.key, this.topic, this.subject});

  @override
  State<MindMapGeneratorScreen> createState() => _MindMapGeneratorScreenState();
}

class _MindMapGeneratorScreenState extends State<MindMapGeneratorScreen>
    with TickerProviderStateMixin {
  final _topicController = TextEditingController();
  final _subjectController = TextEditingController();
  final TransformationController _transformationController = TransformationController();

  late AnimationController _fadeController;
  late AnimationController _scaleController;

  bool _isGenerating = false;
  String _selectedViewMode = 'radial'; // radial, tree, list

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) _topicController.text = widget.topic!;
    if (widget.subject != null) _subjectController.text = widget.subject!;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    context.read<SmartLearningProvider>().loadMindMaps();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _subjectController.dispose();
    _transformationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _generateMindMap() async {
    if (_topicController.text.isEmpty) {
      _showSnackBar('Please enter a topic', Colors.red);
      return;
    }

    setState(() => _isGenerating = true);
    _fadeController.forward(from: 0);
    _scaleController.forward(from: 0);

    try {
      await context.read<SmartLearningProvider>().generateMindMap(
        _topicController.text,
        _subjectController.text,
      );
      _showSnackBar('Mind map generated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to generate mind map', Colors.red);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900,
              Colors.deepPurple.shade700,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI Mind Maps',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildViewModeSelector(),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(Icons.account_tree, 'radial'),
          _buildViewModeButton(Icons.view_list, 'list'),
          _buildViewModeButton(Icons.hub, 'tree'),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(IconData icon, String mode) {
    final isSelected = _selectedViewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedViewMode = mode),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<SmartLearningProvider>(
      builder: (context, provider, _) {
        if (_isGenerating || provider.isLoading) {
          return _buildLoadingState();
        }

        if (provider.currentMindMap == null) {
          return _buildInputForm();
        }

        return _buildMindMapView(provider.currentMindMap!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade300),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Generating Mind Map...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI is creating connections',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.cyan.shade400, Colors.blue.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Create Your Mind Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI-powered visual knowledge mapping',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _topicController,
                  label: 'Topic',
                  hint: 'e.g., Quantum Physics',
                  icon: Icons.topic,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _subjectController,
                  label: 'Subject (Optional)',
                  hint: 'e.g., Physics',
                  icon: Icons.school,
                ),
                const SizedBox(height: 32),
                _buildGenerateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.cyan.shade300),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _generateMindMap,
          borderRadius: BorderRadius.circular(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Generate Mind Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMindMapView(dynamic mindMap) {
    return Column(
      children: [
        _buildMindMapHeader(mindMap),
        Expanded(
          child: FadeTransition(
            opacity: _fadeController,
            child: _selectedViewMode == 'list'
                ? _buildListView(mindMap)
                : _buildInteractiveMindMap(mindMap),
          ),
        ),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildMindMapHeader(dynamic mindMap) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            mindMap.title ?? 'Mind Map',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (mindMap.nodes != null && mindMap.nodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${mindMap.nodes.length} nodes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListView(dynamic mindMap) {
    if (mindMap.nodes == null || mindMap.nodes.isEmpty) {
      return const Center(
        child: Text(
          'No nodes available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mindMap.nodes.length,
      itemBuilder: (context, index) {
        return _buildAnimatedNode(mindMap.nodes[index], index);
      },
    );
  }

  Widget _buildAnimatedNode(dynamic node, int index) {
    final delay = index * 100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(
          left: (node.level ?? 0) * 20.0,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getNodeColor(node).withOpacity(0.8),
              _getNodeColor(node),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getNodeColor(node).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showNodeDetails(node),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNodeIcon(node.level ?? 0),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      node.text ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveMindMap(dynamic mindMap) {
    if (mindMap.nodes == null || mindMap.nodes.isEmpty) {
      return const Center(
        child: Text(
          'No nodes available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(100),
      child: Center(
        child: _selectedViewMode == 'radial'
            ? _buildRadialLayout(mindMap.nodes)
            : _buildTreeLayout(mindMap.nodes),
      ),
    );
  }

  Widget _buildRadialLayout(List<dynamic> nodes) {
    return SizedBox(
      width: 600,
      height: 600,
      child: Stack(
        children: [
          // Central node
          if (nodes.isNotEmpty)
            Positioned(
              left: 250,
              top: 250,
              child: _buildCentralNode(nodes[0]),
            ),
          // Surrounding nodes
          ...List.generate(nodes.length - 1, (index) {
            final angle = (2 * math.pi * (index + 1)) / (nodes.length - 1);
            final radius = 200.0;
            final x = 300 + radius * math.cos(angle) - 50;
            final y = 300 + radius * math.sin(angle) - 50;

            return Positioned(
              left: x,
              top: y,
              child: _buildRadialNode(nodes[index + 1], index + 1),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCentralNode(dynamic node) {
    return ScaleTransition(
      scale: _scaleController,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.cyan.shade300,
              Colors.blue.shade600,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              node.text ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadialNode(dynamic node, int index) {
    final delay = index * 100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _showNodeDetails(node),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _getNodeColor(node),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getNodeColor(node).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                node.text ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTreeLayout(List<dynamic> nodes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nodes.map((node) {
              return Padding(
                padding: EdgeInsets.only(left: (node.level ?? 0) * 40.0),
                child: _buildTreeNode(node),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTreeNode(dynamic node) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getNodeColor(node),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getNodeColor(node).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        node.text ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.refresh, 'New', _resetForm),
          _buildActionButton(Icons.download, 'Export', _exportMindMap),
          _buildActionButton(Icons.share, 'Share', _shareMindMap),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(dynamic node) {
    try {
      if (node.color != null) {
        return Color(int.parse(node.color.replaceFirst('#', '0xFF')));
      }
    } catch (e) {
      // Fallback to level-based colors
    }

    final colors = [
      Colors.cyan.shade600,
      Colors.blue.shade600,
      Colors.indigo.shade600,
      Colors.purple.shade600,
      Colors.pink.shade600,
    ];

    return colors[(node.level ?? 0) % colors.length];
  }

  IconData _getNodeIcon(int level) {
    final icons = [
      Icons.lightbulb,
      Icons.category,
      Icons.stream,
      Icons.edit_note,
      Icons.article,
    ];
    return icons[level % icons.length];
  }

  void _showNodeDetails(dynamic node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900,
              Colors.deepPurple.shade700,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              node.text ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Level: ${node.level ?? 0}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _topicController.clear();
      _subjectController.clear();
    });
    context.read<SmartLearningProvider>().setCurrentMindMap(null);
  }

  void _exportMindMap() {
    _showSnackBar('Export feature coming soon!', Colors.blue);
  }

  void _shareMindMap() {
    _showSnackBar('Share feature coming soon!', Colors.blue);
  }
}