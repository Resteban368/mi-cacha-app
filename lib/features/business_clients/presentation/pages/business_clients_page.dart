import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../business_reservations/domain/entities/customer.dart';
import '../../domain/entities/client_profile.dart';
import '../bloc/business_clients_bloc.dart';
import '../bloc/business_clients_event.dart';
import '../bloc/business_clients_state.dart';
import '../widgets/client_card_item.dart';
import '../widgets/client_detail_sheet.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/clients_data_table.dart';
import '../widgets/clients_filter_bar.dart';
import '../widgets/clients_metric_cards.dart';
import '../widgets/clients_shimmer.dart';

/// Pantalla principal optimizada para Web y Móvil: Directorio y CRM de Clientes del negocio.
class BusinessClientsPage extends StatefulWidget {
  const BusinessClientsPage({super.key, this.initialClients});

  final List<ClientProfile>? initialClients;

  @override
  State<BusinessClientsPage> createState() => _BusinessClientsPageState();
}

class _BusinessClientsPageState extends State<BusinessClientsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  /// A esta distancia del final se pide la página siguiente.
  static const _loadMoreThreshold = 600.0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Pide más clientes si el final de la lista está cerca (o si la lista
  /// no alcanza a llenar la pantalla).
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final state = context.read<BusinessClientsBloc>().state;
    if (widget.initialClients != null ||
        state.status != ClientsStatus.success ||
        !state.hasNextPage ||
        state.loadMore != LoadMoreStatus.idle) {
      return;
    }
    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      context.read<BusinessClientsBloc>().add(
        const BusinessClientsNextPageRequested(),
      );
    }
  }

  void _onWhatsApp(ClientProfile client) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando chat con ${client.name} (${client.phone})'),
        backgroundColor: AppColors.brandTeal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onNewReservation(ClientProfile client) {
    context.go(
      AppRoutes.businessNewReservation,
      extra: Customer(
        id: client.id,
        name: client.name,
        phone: client.phone,
        documentId: client.documentId,
      ),
    );
  }

  void _onOpenHistory(ClientProfile client) {
    context.go(AppRoutes.businessCustomerReservations(client.id, client.name));
  }

  Future<void> _openNewClientDialog() async {
    final newClient = await showClientFormDialog(context);
    if (newClient != null && mounted) {
      context.read<BusinessClientsBloc>().add(const BusinessClientsRefreshed());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente "${newClient.name}" registrado con éxito'),
          backgroundColor: AppColors.brandTeal,
        ),
      );
    }
  }

  Future<void> _openEditClientDialog(ClientProfile client) async {
    final updated = await showClientFormDialog(context, initialClient: client);
    if (updated != null && mounted) {
      context.read<BusinessClientsBloc>().add(const BusinessClientsRefreshed());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ficha de "${updated.name}" actualizada'),
          backgroundColor: AppColors.brandTeal,
        ),
      );
    }
  }

  void _openDetail(ClientProfile client) {
    showClientDetailSheet(
      context,
      client: client,
      onNewReservation: () => _onNewReservation(client),
      onOpenHistory: () => _onOpenHistory(client),
      onWhatsApp: () => _onWhatsApp(client),
      onEdit: () => _openEditClientDialog(client),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BusinessClientsBloc>();

    return Column(
      children: [
        const AppTopBar(
          title: 'Clientes',
          subtitle: 'Directorio de jugadores, fidelidad y contacto directo',
          icon: Icons.group_rounded,
        ),
        Expanded(
          child: BlocConsumer<BusinessClientsBloc, BusinessClientsState>(
            listenWhen: (prev, curr) =>
                prev.status != curr.status ||
                prev.clients.length != curr.clients.length,
            listener: (context, state) {
              if (state.errorMessage != null &&
                  state.status == ClientsStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.statusDue,
                  ),
                );
              }
              // Si la página no llena la pantalla, se pide la siguiente.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _maybeLoadMore();
              });
            },
            builder: (context, state) {
              final clients = widget.initialClients ?? state.clients;
              final isLoading = state.status == ClientsStatus.loading;
              final isFailure =
                  state.status == ClientsStatus.failure && clients.isEmpty;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isDesktop = width >= 840;
                  final gutter = isDesktop ? 24.0 : 16.0;
                  // Contenido centrado con un ancho máximo de 1440.
                  final side = width > 1440 + gutter * 2
                      ? (width - 1440) / 2
                      : gutter;

                  return RefreshIndicator(
                    onRefresh: () async {
                      bloc.add(const BusinessClientsRefreshed());
                    },
                    child: NotificationListener<ScrollUpdateNotification>(
                      onNotification: (_) {
                        _maybeLoadMore();
                        return false;
                      },
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(side, 16, side, 20),
                            sliver: SliverToBoxAdapter(
                              child: ClientsMetricCards(
                                overview: state.overview,
                                clients: clients,
                              ),
                            ),
                          ),
                          // Búsqueda y filtros: quedan fijos arriba al
                          // desplazar la lista.
                          PinnedHeaderSliver(
                            child: ColoredBox(
                              key: const Key('clients-pinned-filters'),
                              color: AppColors.surface,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(side, 0, side, 12),
                                child: ClientsFilterBar(
                                  searchController: _searchController,
                                  selectedFilter: state.query.segment,
                                  selectedSort: state.query.sort,
                                  totalClients: state.totalClients,
                                  filteredClients: clients.length,
                                  onSearchChanged: (query) {
                                    bloc.add(
                                      BusinessClientsSearchChanged(query),
                                    );
                                  },
                                  onFilterChanged: (filter) {
                                    bloc.add(
                                      BusinessClientsSegmentChanged(filter),
                                    );
                                  },
                                  onSortChanged: (sort) {
                                    bloc.add(BusinessClientsSortChanged(sort));
                                  },
                                  onNewClientPressed: _openNewClientDialog,
                                ),
                              ),
                            ),
                          ),
                          if (isLoading && clients.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(side, 0, side, 12),
                              sliver: const SliverToBoxAdapter(
                                child: LinearProgressIndicator(
                                  color: AppColors.brandTeal,
                                  backgroundColor: AppColors.brandTealLight,
                                ),
                              ),
                            ),
                          if (isFailure)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              sliver: SliverToBoxAdapter(
                                child: _buildErrorState(
                                  state.errorMessage,
                                  () => bloc.add(
                                    const BusinessClientsRefreshed(),
                                  ),
                                ),
                              ),
                            )
                          else if (isLoading && clients.isEmpty)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              sliver: SliverToBoxAdapter(
                                child: ClientsShimmer(isDesktop: isDesktop),
                              ),
                            )
                          // Tabla en web / escritorio.
                          else if (isDesktop)
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              sliver: SliverToBoxAdapter(
                                child: ClientsDataTable(
                                  clients: clients,
                                  onClientTap: _openDetail,
                                  onWhatsAppTap: _onWhatsApp,
                                  onNewReservationTap: _onNewReservation,
                                  onHistoryTap: _onOpenHistory,
                                ),
                              ),
                            )
                          // Tarjetas en móvil (se construyen solo las
                          // visibles).
                          else
                            SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              sliver: SliverList.separated(
                                itemCount: clients.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final client = clients[i];
                                  return ClientCardItem(
                                    client: client,
                                    onTap: () => _openDetail(client),
                                    onWhatsAppTap: () => _onWhatsApp(client),
                                    onNewReservationTap: () =>
                                        _onNewReservation(client),
                                    onHistoryTap: () => _onOpenHistory(client),
                                  );
                                },
                              ),
                            ),
                          if (!isFailure && clients.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _LoadMoreFooter(
                                status: state.loadMore,
                                hasMore:
                                    widget.initialClients == null &&
                                    state.hasNextPage,
                                loaded: clients.length,
                                total: state.totalClients,
                                onRetry: () => bloc.add(
                                  const BusinessClientsNextPageRequested(),
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String? message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 28,
              color: AppColors.statusDue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar clientes',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? 'No se pudo comunicar con el servidor.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.slate500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie de la lista: cargando más, reintentar o "ya están todos".
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.status,
    required this.hasMore,
    required this.loaded,
    required this.total,
    required this.onRetry,
  });

  final LoadMoreStatus status;
  final bool hasMore;
  final int loaded;
  final int total;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final child = switch (status) {
      LoadMoreStatus.loading => const SizedBox.square(
        key: Key('clients-loading-more'),
        dimension: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.brandTeal,
        ),
      ),
      LoadMoreStatus.failure => TextButton.icon(
        key: const Key('clients-load-more-retry'),
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('No pudimos cargar más clientes. Reintentar'),
      ),
      LoadMoreStatus.idle when !hasMore => Text(
        'Ya ves todos los resultados ($loaded de $total)',
        style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
      ),
      LoadMoreStatus.idle => const SizedBox(height: 24),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(child: child),
    );
  }
}
