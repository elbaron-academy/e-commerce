import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/load_state.dart';
import '../../checkout/domain/delivery.dart';
import '../../settings/locale_cubit.dart';
import '../domain/catalog_repository.dart';
import '../domain/entities.dart';
import 'widgets/category_tile.dart';
import 'widgets/product_card.dart';

typedef HomeBundle = ({HomeData home, List<CategoryNode> categories, DeliveryInfo? delivery});

class HomeCubit extends LoadCubit<HomeBundle> {
  HomeCubit(CatalogRepository catalog, DeliveryRepository delivery)
    : super(() async {
        final results = await Future.wait([
          catalog.home(),
          catalog.categories(),
          delivery.info().then<DeliveryInfo?>((d) => d).catchError((_) => null),
        ]);
        return (
          home: results[0] as HomeData,
          categories: results[1] as List<CategoryNode>,
          delivery: results[2] as DeliveryInfo?,
        );
      });
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.lang),
      create: (_) => HomeCubit(sl(), sl())..load(),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().load(silent: true),
            child: LoadView<HomeCubit, HomeBundle>(
              loading: const _HomeSkeleton(),
              builder: (context, data) => CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: HomeHeader()),
                  SliverToBoxAdapter(child: _PromiseChips(delivery: data.delivery)),
                  SliverToBoxAdapter(child: _Banners(banners: data.home.banners)),
                  SliverToBoxAdapter(child: _CategoriesGrid(categories: data.categories)),
                  for (final section in data.home.sections)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ProductRow(
                          title: section.title,
                          products: section.products,
                          onSeeAll: section.link == null ? null : () => openLink(context, section.link!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo, language switch and the search field.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset('assets/images/logo.png', width: 34, height: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.brandName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brand700),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.read<LocaleCubit>().toggle(),
                icon: const Icon(Icons.language, size: 20),
                label: Text(l10n.headerSwitchLang),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/search'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.headerSearchPlaceholder, style: const TextStyle(color: AppColors.muted)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromiseChips extends StatelessWidget {
  const _PromiseChips({required this.delivery});

  final DeliveryInfo? delivery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = [
      (Icons.bolt, AppColors.accent500, l10n.homeExpress),
      if (delivery != null)
        (
          Icons.local_shipping_outlined,
          AppColors.brand600,
          l10n.homeFreeDelivery(context.fmt.money(delivery!.freeDeliveryThreshold)),
        ),
      (Icons.storefront_outlined, AppColors.brand600, l10n.homePickup),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
          child: Row(
            children: [
              Icon(chips[i].$1, size: 18, color: chips[i].$2),
              const SizedBox(width: 6),
              Text(chips[i].$3, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banners extends StatefulWidget {
  const _Banners({required this.banners});

  final List<HomeBanner> banners;

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(
        children: [
          SizedBox(
            height: 176,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: widget.banners.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: _BannerCard(banner: widget.banners[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.brand600 : AppColors.brand200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final color = switch (banner.tone) {
      'orange' => AppColors.accent500,
      'blue' => const Color(0xFF0369A1),
      _ => AppColors.brand600,
    };
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openLink(context, banner.link),
        child: Stack(
          children: [
            PositionedDirectional(end: 12, bottom: 4, child: Text(banner.emoji, style: const TextStyle(fontSize: 64))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.78,
                    child: Text(
                      banner.title,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: 0.72,
                    child: Text(
                      banner.subtitle,
                      maxLines: 2,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(banner.cta, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.categories});

  final List<CategoryNode> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: context.l10n.homeCategories, onSeeAll: () => context.go('/categories')),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: categories.length,
            itemBuilder: (_, i) => CategoryTile(category: categories[i]),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(height: 40),
        SizedBox(height: 16),
        Skeleton(height: 176, radius: 24),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Skeleton(height: 72)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 72)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 72)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 72)),
          ],
        ),
        SizedBox(height: 24),
        Skeleton(height: 280),
      ],
    );
  }
}
