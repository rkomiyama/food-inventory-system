class InvoiceRow {
  final String item;
  final String description;
  final String packSize;
  final int qty;
  final double unitPrice;
  final double total;

  InvoiceRow({
    required this.item,
    required this.description,
    required this.packSize,
    required this.qty,
    required this.unitPrice,
    required this.total,
  });

  @override
  String toString() {
    return 'Item: $item, Desc: $description, Pack/Size: $packSize, '
        'Qty: $qty, Unit Price: $unitPrice, Total: $total';
  }
}