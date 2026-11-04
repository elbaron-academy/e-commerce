import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rocket_market/app/theme.dart';
import 'package:rocket_market/core/l10n/l10n.dart';
import 'package:rocket_market/features/cart/domain/cart.dart';
import 'package:rocket_market/features/cart/domain/cart_repository.dart';
import 'package:rocket_market/features/cart/presentation/cart_cubit.dart';

/// Real API responses captured from the Django backend.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

List<dynamic> fixtureList(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as List<dynamic>;

/// Cart storage in memory.
class MemoryCartRepository implements CartRepository {
  List<CartLine> lines = [];
  String? coupon;
  int saves = 0;

  @override
  ({List<CartLine> lines, String? coupon}) load() => (lines: lines, coupon: coupon);

  @override
  Future<void> save(List<CartLine> lines, String? coupon) async {
    this.lines = lines;
    this.coupon = coupon;
    saves++;
  }

  @override
  Future<Quote> quote(List<CartItemInput> items, {String? coupon, String? zone, String method = 'delivery'}) =>
      throw UnimplementedError();
}

/// Wraps a widget with theme, localization (Arabic by default) and a cart.
Widget testApp(Widget child, {CartCubit? cart, Locale locale = const Locale('ar')}) => BlocProvider(
  create: (_) => cart ?? CartCubit(MemoryCartRepository()),
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  ),
);
