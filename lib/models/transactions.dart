class Transactions {
  List<Transaction> transactions;

  Transactions.fromMap(Map<dynamic, dynamic> data) {
    transactions = [];

    if (data != null) {
      Transaction transaction;
      String type;

      data.keys.forEach((key) {
        if (data[key] is Map) {
          transaction = Transaction();

          transaction.datetime = int.tryParse("$key") ?? 0;
          transaction.amount =
              double.tryParse("${data[key]["amount"] ?? "0"}") ?? 0;
          transaction.orderId = data[key]["orderId"] ?? "";

          type = data[key]["type"] ?? "";

          if (type == "paid_by_wallet") {
            transaction.type = TransactionType.PAID_BY_WALLET;
          } else if (type == "paid_by_cash") {
            transaction.type = TransactionType.PAID_BY_CASH;
          } else if (type == "refund") {
            transaction.type = TransactionType.REFUND;
          } else if (type == "wallet_deposit") {
            transaction.type = TransactionType.WALLET_DEPOSIT;
          }

          if (transaction.type != null) {
            transactions.add(transaction);
          }
        }
      });
    }

    transactions.sort((a, b) {
      return a.datetime.compareTo(b.datetime);
    });
    transactions = transactions.reversed.toList();
  }
}

class Transaction {
  int datetime;
  String orderId;
  double amount;
  TransactionType type;
}

enum TransactionType {
  PAID_BY_WALLET,
  PAID_BY_CASH,
  REFUND,
  WALLET_DEPOSIT,
}
