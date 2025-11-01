import 'package:flutter/material.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_filter.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(8),
          height: size.height,
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors
              .white)),
                margin: EdgeInsets.only(top: size.height * 0.05),
                child: Column(
                  children: [
                    Text("Dreams", style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      "Some description on this page",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 40),
                decoration: BoxDecoration(border: Border.all(color: Colors
                    .white)),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 7,
                        child: CustomSearchBar()
                      ),
                      Expanded(
                        flex: 1,
                            child: SizedBox(),
                      ),
                      Expanded(
                        flex: 2,
                        child: CustomFilter(),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
