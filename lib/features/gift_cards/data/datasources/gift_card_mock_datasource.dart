import 'dart:convert';
import 'package:dio/dio.dart' show DioException, DioExceptionType, RequestOptions;
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/gift_card_entity.dart';
import '../models/gift_card_model.dart';

class GiftCardMockDataSource {
  List<GiftCardModel>? _cache;

  bool simulateError = false;

  final Set<String> _redeemedCodes = {};

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 700));

  Future<List<GiftCardModel>> _loadSeed() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/mock/gift_cards.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => GiftCardModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<GiftCardModel>> fetchActiveCards() async {
    await _delay();
    if (simulateError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/gift-cards/active'),
        error: 'Unable to reach server',
        type: DioExceptionType.connectionError,
      );
    }
    final list = await _loadSeed();
    return list.where((c) => c.status == GiftCardStatus.active && DateTime(c.expiryDate.year, c.expiryDate.month, c.expiryDate.day).add(const Duration(days: 1)).isAfter(DateTime.now())).toList();
  }

  Future<List<GiftCardModel>> fetchRedeemedCards() async {
    await _delay();
    if (simulateError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/gift-cards/redeemed'),
        error: 'Unable to reach server',
        type: DioExceptionType.connectionError,
      );
    }
    final list = await _loadSeed();
    return list.where((c) => c.status == GiftCardStatus.redeemed).toList();
  }

  /// Simulates redeeming a code. Any code starting with "VALID" succeeds;
  /// codes starting with "USED" simulate an already-redeemed card;
  /// everything else simulates an invalid code.
  Future<GiftCardModel> redeemCard(String code) async {
    await _delay();
    final normalized = code.trim().toUpperCase();

    if (normalized.startsWith('USED')) {
      throw DioException(
        requestOptions: RequestOptions(path: '/gift-cards/redeem'),
        error: 'This gift card has already been redeemed',
        type: DioExceptionType.badResponse,
      );
    }

    if (!normalized.startsWith('VALID')) {
      throw DioException(
        requestOptions: RequestOptions(path: '/gift-cards/redeem'),
        error: 'Invalid gift card code',
        type: DioExceptionType.badResponse,
      );
    }

    final list = await _loadSeed();
    if (_redeemedCodes.contains(normalized)) {
      throw DioException(
        requestOptions: RequestOptions(path: '/gift-cards/redeem'),
        error: 'This gift card has already been redeemed',
        type: DioExceptionType.badResponse,
      );
    }
    _redeemedCodes.add(normalized);
    final newCard = GiftCardModel(
      id: 'gc_${DateTime.now().millisecondsSinceEpoch}',
      cardNumber:
          'GC-${normalized.substring(normalized.length > 12 ? normalized.length - 12 : 0)}',
      balance: 250.0,
      expiryDate: DateTime.now().add(const Duration(days: 365)),
      status: GiftCardStatus.active,
    );
    list.add(newCard);
    return newCard;
  }
}

