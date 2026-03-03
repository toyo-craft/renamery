import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/file_model.dart';

class PreviewList extends StatelessWidget {
  final List<FileModel> files;

  const PreviewList({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    // Determine the max width for columns slightly dynamically or fixed
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.grey[200],
          child: const Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text("Original Name",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              Icon(Symbols.arrow_right_alt,
                  color: Colors.transparent), // Spacer
              Expanded(
                  flex: 1,
                  child: Text("New Name (Preview)",
                      style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(
                  width: 50,
                  child: Text("Status",
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final isChanged = file.originalName != file.newName;

              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  color: index % 2 == 0
                      ? Colors.white
                      : Colors.grey[50], // Striped rows
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(file.originalName,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Icon(
                      Symbols.arrow_right_alt,
                      color: isChanged ? Colors.blue : Colors.grey[300],
                      size: 20,
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        file.newName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isChanged ? Colors.blue[800] : Colors.black,
                            fontWeight: isChanged
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: _buildStatusIcon(file.status),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(FileStatus status) {
    switch (status) {
      case FileStatus.original:
        return const Icon(Symbols.circle,
            size: 16,
            color: Colors
                .grey); // Using circle instead of circle_outlined since we have fill variant if needed or outlined by default
      case FileStatus.pending:
        return const Icon(Symbols.pending, size: 16, color: Colors.orange);
      case FileStatus.renamed:
        return const Icon(Symbols.check_circle, size: 16, color: Colors.green);
      case FileStatus.error:
        return const Icon(Symbols.error, size: 16, color: Colors.red);
    }
  }
}
