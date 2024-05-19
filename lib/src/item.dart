import 'discount.dart';
import 'sellable.dart';
import 'tax.dart';

/// Represents a sale item (product or service).
class Item implements Sellable {
  final String code;
  final double quantity;
  final double unitPrice;
  final Discount? discount;
  final List<Tax> taxes;

  Item({
    required this.code,
    required this.quantity,
    required this.unitPrice,
    this.discount,
    List<Tax>? taxes,
  })  : assert(
          quantity >= 0,
          'Quantity must be zero or positive.',
        ),
        assert(
          unitPrice >= 0,
          'Unit price must be zero or positive.',
        ),
        taxes = <Tax>[] {
    if (taxes != null) {
      taxes.sort((tax1, tax2) {
        final byPriority = tax1.priority.compareTo(tax2.priority);
        if (byPriority != 0) {
          return byPriority;
        }
        if (tax1.affectTax == tax2.affectTax) {
          return 0;
        }
        return tax1.affectTax ? -1 : 1;
      });
      this.taxes.addAll(taxes);
    }
  }

  /// Calculates subtotal amount including [discount] (before taxes).
  @override
  double get subtotal {
    if (discount == null || discount!.affectTax) {
      return _subtotalOf(unitPrice, discount);
    }
    final base = _subtotalOf(unitPrice);
    final baseTax = _taxAmountOf(base);
    var baseTotal = base + baseTax;
    baseTotal -= discount!.discountOf(baseTotal);
    final inverse = _inverseSubtotalOf(baseTotal);
    return _subtotalOf(inverse / quantity);
  }

  /// Calculates subtotal amount including [discount] for given [taxCode] (before taxes).
  @override
  double subtotalOf(String taxCode) {
    var value = _subtotalOf(unitPrice, discount);
    var found = false;
    for (final tax in taxes) {
      if (tax.code == taxCode) {
        found = true;
        break;
      }
      final taxAmount = tax.taxOf(value);
      if (tax.affectTax) {
        value += taxAmount;
      }
    }
    if (found) {
      return value;
    }
    return 0;
  }

  @override
  double get tax {
    return _taxAmountOf(subtotal);
  }

  /// Calculates tax amount including [discount] for given [taxCode].
  @override
  double taxOf(String taxCode) {
    var subtotal = _subtotalOf(unitPrice, discount);
    for (final tax in taxes) {
      final taxAmount = tax.taxOf(subtotal);
      if (tax.code == taxCode) {
        return taxAmount;
      }
      if (tax.affectTax) {
        subtotal += taxAmount;
      }
    }
    return 0;
  }

  // Calculates discount amount before taxes.
  @override
  double get discountAmount {
    var baseSubtotal = _subtotalOf(unitPrice);
    return baseSubtotal - subtotal;
  }

  @override
  double get total {
    return subtotal + tax;
  }

  /// Calculates subtotal amount of given [price] including [discount] (before taxes).
  double _subtotalOf(double price, [Discount? discount]) {
    final theDiscount = discount ?? Discount.empty();
    if (theDiscount.isUnitary) {
      price -= theDiscount.discountOf(price);
    }
    var value = quantity * price;
    if (!theDiscount.isUnitary) {
      value -= theDiscount.discountOf(value);
    }
    return value;
  }

  /// Calculates tax amount of given [subtotal].
  double _taxAmountOf(double subtotal) {
    var value = .0;
    for (final tax in taxes) {
      final taxAmount = tax.taxOf(subtotal);
      value += taxAmount;
      if (tax.affectTax) {
        subtotal += taxAmount;
      }
    }
    return value;
  }

  /// Calculates associated subtotal of given [total] using [taxes].
  double _inverseSubtotalOf(double total) {
    var subtotal = total;
    for (final tax in taxes.reversed) {
      subtotal = tax.inverseSubtotalOf(subtotal);
    }
    return subtotal;
  }

  /// Creates a copy with new [discount].
  Item copyWith({required Discount? discount}) {
    return Item(
      code: code,
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      taxes: taxes,
    );
  }

  /// Adds given [addDiscount] to [discount].
  ///
  /// @return pair with:
  /// first parameter is result discount with the sum of [addDiscount] and [discount].
  /// second parameter is value of [addDiscount] that didn't fit for this item.
  Pair<Discount, Discount?> discountAdding(Discount addDiscount) {}
}
