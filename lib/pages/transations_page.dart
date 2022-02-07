import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user/common/app_bar.dart';
import 'package:user/common/shared.dart';
import 'package:user/managers/database_manager.dart';
import 'package:user/models/transactions.dart';
import 'package:user/models/wallet.dart';

import 'order_page.dart';

DatabaseManager _databaseManager;

class TransactionsPage extends StatelessWidget {
  static final String route = "transactions";

  @override
  Widget build(BuildContext context) {
    double wallet = getIt.get<Wallet>().amount;

    return Scaffold(
      appBar: getAppBar(
        context,
        AppBarType.backOnly,
        title: "Transactions",
        onBackPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 10,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available credit in Wallet:",
                    style: AppTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    "${wallet.toStringAsFixed(2)}",
                    style: AppTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.transparent,
            ),
            Text(
              "Transactions:",
              style: AppTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 18,
              ),
            ),
            Divider(),
            Expanded(
              child: _TransactionsList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsList extends StatefulWidget {
  @override
  __TransactionsListState createState() => __TransactionsListState();

  _TransactionsList() {
    _databaseManager = DatabaseManager.instance;
  }
}

class __TransactionsListState extends State<_TransactionsList> {
  List<Transaction> transactionsList;

  @override
  void initState() {
    super.initState();

    loadTransactions();
  }

  void loadTransactions() async {
    Transactions transactions = await _databaseManager
        .loadTransactions(FirebaseAuth.instance.currentUser.uid);

    if (transactions != null) {
      if (mounted) {
        setState(() {
          this.transactionsList = transactions.transactions;
        });
      } else {
        this.transactionsList = transactions.transactions;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactionsList?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        return _TransactionItem(transactionsList[index]);
      },
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  _TransactionItem(
    this.transaction,
  );

  @override
  Widget build(BuildContext context) {
    String type;

    switch (transaction.type) {
      case TransactionType.PAID_BY_WALLET:
        type = "Paid by Wallet";
        break;
      case TransactionType.PAID_BY_CASH:
        type = "Paid by Cash";
        break;
      case TransactionType.REFUND:
        type = "Refund";
        break;
      case TransactionType.WALLET_DEPOSIT:
        type = "Added to wallet";
        break;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Order - ",
                        style: AppTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${DateFormat("dd/MM/yyyy").format(DateTime.fromMillisecondsSinceEpoch(transaction.datetime))}",
                      ),
                      VerticalDivider(
                        color: Colors.transparent,
                      ),
                      InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          OrderPage.route,
                          arguments: transaction.orderId,
                        ),
                        child: Icon(
                          Icons.open_in_new,
                          color: appPrimaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.transparent,
                    height: 8,
                  ),
                  Text("$type"),
                ],
              ),
            ),
            Text(
              "Rs. ${transaction.amount.toStringAsFixed(2)}",
              style: AppTextStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Divider(),
      ],
    );
  }
}
