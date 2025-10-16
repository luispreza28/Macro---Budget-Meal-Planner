import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tasteProfileServiceProvider = Provider<TasteProfileService>((_) => TasteProfileService());

class TasteProfileService {
  static const _k = 'taste.profile.v1'; // TasteProfile JSON

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<TasteProfile> get() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const TasteProfile();
    try {
      return TasteProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Taste] load failed, using defaults: $e');
      }
      return const TasteProfile();
    }
  }

  Future<void> save(TasteProfile p) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(p.toJson()))
        .whenComplete(() {
      if (kDebugMode) {
        debugPrint('[Taste] saved profile');
      }
    });
  }
}

class TasteProfile {
  final List<String> likeIngredients;   // ingredientId(s)
  final List<String> dislikeIngredients;
  final List<String> hardBanIngredients; // allergens/never
  final List<String> likeTags;          // cuisine/style tags: 'mexican','asian','salad','spicy'
  final List<String> dislikeTags;
  final List<String> hardBanTags;       // e.g., 'nuts','shellfish','gluten' (mapped via recipe.dietFlags or tags)
  final Map<String, double> cuisineWeights; // 'mexican': 1.2, 'italian': 0.9 ...
  final List<String> dietFlags;         // reinforce veg/gf/df
  final Map<String, bool> perRecipeAllow; // recipeId -> true (allow despite bans)
  final Map<String, bool> perRecipeHide;  // recipeId -> true (never suggest)

  const TasteProfile({
    this.likeIngredients = const [],
    this.dislikeIngredients = const [],
    this.hardBanIngredients = const [],
    this.likeTags = const [],
    this.dislikeTags = const [],
    this.hardBanTags = const [],
    this.cuisineWeights = const {},
    this.dietFlags = const [],
    this.perRecipeAllow = const {},
    this.perRecipeHide = const {},
  });

  TasteProfile copyWith({
    List<String>? likeIngredients,
    List<String>? dislikeIngredients,
    List<String>? hardBanIngredients,
    List<String>? likeTags,
    List<String>? dislikeTags,
    List<String>? hardBanTags,
    Map<String,double>? cuisineWeights,
    List<String>? dietFlags,
    Map<String,bool>? perRecipeAllow,
    Map<String,bool>? perRecipeHide,
  }) => TasteProfile(
    likeIngredients: likeIngredients ?? this.likeIngredients,
    dislikeIngredients: dislikeIngredients ?? this.dislikeIngredients,
    hardBanIngredients: hardBanIngredients ?? this.hardBanIngredients,
    likeTags: likeTags ?? this.likeTags,
    dislikeTags: dislikeTags ?? this.dislikeTags,
    hardBanTags: hardBanTags ?? this.hardBanTags,
    cuisineWeights: cuisineWeights ?? this.cuisineWeights,
    dietFlags: dietFlags ?? this.dietFlags,
    perRecipeAllow: perRecipeAllow ?? this.perRecipeAllow,
    perRecipeHide: perRecipeHide ?? this.perRecipeHide,
  );

  Map<String, dynamic> toJson() => {
    'likeIngredients': likeIngredients,
    'dislikeIngredients': dislikeIngredients,
    'hardBanIngredients': hardBanIngredients,
    'likeTags': likeTags,
    'dislikeTags': dislikeTags,
    'hardBanTags': hardBanTags,
    'cuisineWeights': cuisineWeights,
    'dietFlags': dietFlags,
    'perRecipeAllow': perRecipeAllow,
    'perRecipeHide': perRecipeHide,
  };

  factory TasteProfile.fromJson(Map<String, dynamic> j) => TasteProfile(
    likeIngredients: List<String>.from(j['likeIngredients'] ?? const []),
    dislikeIngredients: List<String>.from(j['dislikeIngredients'] ?? const []),
    hardBanIngredients: List<String>.from(j['hardBanIngredients'] ?? const []),
    likeTags: List<String>.from(j['likeTags'] ?? const []),
    dislikeTags: List<String>.from(j['dislikeTags'] ?? const []),
    hardBanTags: List<String>.from(j['hardBanTags'] ?? const []),
    cuisineWeights: (j['cuisineWeights'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
    dietFlags: List<String>.from(j['dietFlags'] ?? const []),
    perRecipeAllow: (j['perRecipeAllow'] as Map? ?? const {}).map((k,v)=>MapEntry(k as String, v as bool)),
    perRecipeHide: (j['perRecipeHide'] as Map? ?? const {}).map((k,v)=>MapEntry(k as String, v as bool)),
  );
}

