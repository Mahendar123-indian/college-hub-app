import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/routes.dart';
import '../../../../providers/resource_provider.dart';
import '../../../widgets/resource_card.dart';

class TrendingSection extends StatelessWidget {
  const TrendingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ResourceProvider>(
      builder: (context, resourceProvider, child) {
        final trendingResources = resourceProvider.trendingResources;

        if (trendingResources.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Now 🔥',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.resourceList,
                        arguments: {'category': 'trending'},
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: trendingResources.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final resource = trendingResources[index];
                  return SizedBox(
                    width: 300,
                    child: ResourceCard(
                      resource: resource,
                      onTap: () {
                        AppRoutes.navigateToResourceDetail(context, resource.id);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}