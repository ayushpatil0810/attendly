import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_typography.dart';

/// Screen scaffold implementing Apple's canonical Large Title collapsible navigation bar
/// with translucent frosted glass and iOS-inspired rubber-band scroll physics.
class AppleScaffold extends StatelessWidget {
  const AppleScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.slivers,
    this.child,
    this.trailing,
    this.leading,
    this.showBackButton = false,
    this.onBack,
    this.onRefresh,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.hasLargeTitle = true,
  }) : assert(slivers != null || child != null, 'Must provide either slivers or child');

  final String title;
  final String? subtitle;
  final List<Widget>? slivers;
  final Widget? child;
  final Widget? trailing;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool hasLargeTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = backgroundColor ?? colors.background;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton) {
      leadingWidget = IconButton(
        icon: AppIcon(
          AppIcons.back,
          size: 20,
          color: colors.textPrimary,
        ),
        tooltip: 'Back',
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    final appBar = SliverAppBar(
      pinned: true,
      expandedHeight:
          hasLargeTitle ? (subtitle != null ? 120.0 : 100.0) : null,
      backgroundColor: colors.surface.withValues(
        alpha: colors.isDark ? 0.75 : 0.85,
      ),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: leadingWidget,
      title: hasLargeTitle
          ? null
          : Text(
              title,
              style: AppTypography.headline.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
      centerTitle: false,
      actions: trailing != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: trailing!),
              ),
            ]
          : null,
      flexibleSpace: hasLargeTitle
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  expandedTitleScale: 1.4,
                  centerTitle: false,
                  title: Text(
                    title,
                    style: AppTypography.headline.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          : ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.transparent),
              ),
            ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          color: colors.border.withValues(
            alpha: colors.isDark ? 0.5 : 0.7,
          ),
          height: 0.5,
        ),
      ),
    );

    final Widget scrollView;
    if (slivers != null) {
      scrollView = CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          appBar,
          if (hasLargeTitle && subtitle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  subtitle!,
                  style: AppTypography.subhead.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ...?slivers,
          if (child != null)
            SliverToBoxAdapter(
              child: child!,
            ),
        ],
      );
    } else {
      scrollView = NestedScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          appBar,
          if (hasLargeTitle && subtitle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  subtitle!,
                  style: AppTypography.subhead.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: child!,
        ),
      );
    }

    Widget body = onRefresh != null
        ? RefreshIndicator(
            onRefresh: onRefresh!,
            color: colors.textPrimary,
            backgroundColor: colors.surface,
            child: scrollView,
          )
        : scrollView;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: false,
        bottom: bottomNavigationBar == null,
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
