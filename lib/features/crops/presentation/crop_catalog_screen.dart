
import 'package:flutter/material.dart';

import '../data/local_crop_data_source.dart';
import '../domain/models/crop_model.dart';
import 'crop_detail_screen.dart';

class CropCatalogScreen extends StatefulWidget {
  final LocalCropDataSource? dataSource;

  const CropCatalogScreen({
    super.key,
    this.dataSource,
  });

  @override
  State<CropCatalogScreen> createState() =>
      _CropCatalogScreenState();
}

class _CropCatalogScreenState extends State<CropCatalogScreen> {
  late Future<List<CropModel>> _cropsFuture;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  void _loadCrops() {
    _cropsFuture =
        (widget.dataSource ?? LocalCropDataSource()).loadCrops();
  }

  void _retry() {
    setState(_loadCrops);
  }

  void _openDetails(CropModel crop) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CropDetailScreen(crop: crop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog kultura'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Pretraži kulture',
                hintText: 'Npr. rajčica, paprika...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CropModel>>(
              future: _cropsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState !=
                    ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nije moguće učitati katalog kultura.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Pokušaj ponovno'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allCrops = snapshot.data ?? <CropModel>[];

                final filteredCrops = allCrops.where((crop) {
                  final searchText =
                  '${crop.name} ${crop.description}'
                      .toLowerCase();

                  return searchText.contains(_searchQuery);
                }).toList();

                if (filteredCrops.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            allCrops.isEmpty
                                ? 'Nema dostupnih kultura.'
                                : 'Nema rezultata za ovu pretragu.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 16,
                  ),
                  itemCount: filteredCrops.length,
                  separatorBuilder: (_, _) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final crop = filteredCrops[index];

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding:
                        const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          child: const Icon(Icons.eco_outlined),
                        ),
                        title: Text(
                          crop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                            top: 4,
                          ),
                          child: Text(
                            'Sadnja: ${crop.plantingPeriod}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing:
                        const Icon(Icons.chevron_right),
                        onTap: () => _openDetails(crop),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
